<?php

namespace App\Http\Controllers\Api\V1\Customer;

use App\Actions\GeneratePaymentCode;
use App\Actions\ReturnRentalOrder as ReturnRentalOrderAction;
use App\Enums\PaymentMethod;
use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Customer\StoreRentalOrderRequest;
use App\Http\Resources\RentalOrderResource;
use App\Models\Costume;
use App\Models\RentalOrder;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class OrderController extends Controller
{
    /**
     * List the authenticated customer's orders.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('create', RentalOrder::class);

        $query = RentalOrder::query()
            ->whereBelongsTo($request->user(), 'customer')
            ->with(['costume.owner', 'issue.reporter'])
            ->latest()
            ->orderByDesc('id');
        $status = $request->input('status');

        if ($status !== null && $status !== 'all') {
            abort_unless(RentalOrderStatus::tryFrom((string) $status) !== null, 422, 'The selected order status is invalid.');
            $query->where('status', $status);
        }

        $orders = $query->paginate(min(50, max(1, $request->integer('per_page', 50))));

        return RentalOrderResource::collection($orders);
    }

    /**
     * Show one customer order.
     */
    public function show(RentalOrder $customerOrder): RentalOrderResource
    {
        Gate::authorize('viewCustomer', $customerOrder);

        $customerOrder->load(['costume.owner', 'issue.reporter']);

        return new RentalOrderResource($customerOrder);
    }

    /**
     * Create a customer booking request.
     *
     * A pay-at-owner booking gets a unique payment code to settle in cash; a
     * bank transfer requires an uploaded receipt, which is stored on the
     * private disk and only ever served back through an authenticated
     * download endpoint.
     */
    public function store(
        StoreRentalOrderRequest $request,
        Costume $apiCostume,
        GeneratePaymentCode $generatePaymentCode,
    ): JsonResponse {
        Gate::authorize('create', RentalOrder::class);
        abort_unless($apiCostume->is_published && $apiCostume->stock > 0, 404);

        $data = $request->validated();
        $requestedStart = CarbonImmutable::parse($data['rental_start'])->startOfDay();
        $requestedEnd = CarbonImmutable::parse($data['rental_end'])->startOfDay();
        $paymentMethod = $request->isBankTransfer()
            ? PaymentMethod::BankTransfer
            : PaymentMethod::PayAtOwner;
        $paymentProofPath = $paymentMethod->isBankTransfer()
            ? $request->file('payment_proof')?->store('rental-orders/payments', 'local')
            : null;

        try {
            $order = RentalOrder::query()->create([
                'owner_id' => $apiCostume->owner_id,
                'customer_id' => $request->user()->id,
                'costume_id' => $apiCostume->id,
                'quantity' => $data['quantity'],
                'rental_start' => $requestedStart,
                'rental_end' => $requestedEnd,
                'requested_rental_start' => $requestedStart,
                'requested_rental_end' => $requestedEnd,
                'price_per_day' => $apiCostume->price_per_day,
                'extra_price_per_day' => $apiCostume->extra_price_per_day,
                'total_price' => $apiCostume->rentalTotalFor(
                    RentalOrder::daysBetween($requestedStart, $requestedEnd),
                    (int) $data['quantity'],
                ),
                'status' => RentalOrderStatus::Pending,
                'payment_method' => $paymentMethod,
                'payment_code' => $paymentMethod->isPayAtOwner()
                    ? $generatePaymentCode->handle()
                    : null,
                'payment_proof_path' => $paymentProofPath,
                'customer_note' => filled($data['customer_note'] ?? null) ? trim($data['customer_note']) : null,
            ]);
        } catch (Throwable $exception) {
            if ($paymentProofPath !== null) {
                Storage::disk('local')->delete($paymentProofPath);
            }

            throw $exception;
        }

        $order->load(['costume.owner', 'issue.reporter']);

        return (new RentalOrderResource($order))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Submit a normal costume return.
     */
    public function submitReturn(
        Request $request,
        RentalOrder $customerOrder,
        ReturnRentalOrderAction $returnRentalOrder,
    ): JsonResponse {
        Gate::authorize('returnOrder', $customerOrder);
        $data = $request->validate([
            'return_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $returnRentalOrder->handle($customerOrder, $data['return_note'] ?? null);
        $customerOrder->refresh()->load(['costume.owner', 'issue.reporter']);

        return response()->json([
            'message' => 'Return submitted successfully.',
            'data' => new RentalOrderResource($customerOrder),
        ]);
    }

    /**
     * Cancel a pending booking before the owner makes a decision.
     */
    public function destroy(RentalOrder $customerOrder): JsonResponse
    {
        Gate::authorize('viewCustomer', $customerOrder);
        abort_unless($customerOrder->isPending(), 422, 'Hanya pesanan menunggu yang dapat dibatalkan.');

        // Drop the stored receipt with the booking so a cancelled transfer
        // never leaves an orphaned file on the private disk.
        if ($customerOrder->hasPaymentProof()) {
            Storage::disk('local')->delete((string) $customerOrder->payment_proof_path);
        }

        $customerOrder->delete();

        return response()->json(['message' => 'Booking cancelled successfully.']);
    }

    /**
     * Download the payment proof the customer uploaded for their own order.
     */
    public function paymentProof(RentalOrder $customerOrder): StreamedResponse
    {
        Gate::authorize('viewPaymentProof', $customerOrder);
        abort_if(blank($customerOrder->payment_proof_path), 404);

        return Storage::disk('local')->download(
            $customerOrder->payment_proof_path,
            basename((string) $customerOrder->payment_proof_path),
        );
    }
}