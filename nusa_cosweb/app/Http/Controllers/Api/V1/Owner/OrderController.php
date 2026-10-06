<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Actions\ApproveRentalOrder;
use App\Actions\CompleteRentalReturn;
use App\Actions\RejectRentalOrder;
use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Owner\OrderDecisionRequest;
use App\Http\Resources\RentalOrderResource;
use App\Models\RentalOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class OrderController extends Controller
{
    /**
     * List the authenticated owner's orders.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', RentalOrder::class);
        $status = $request->input('status');

        if ($status !== null && $status !== 'all' && RentalOrderStatus::tryFrom((string) $status) === null) {
            throw ValidationException::withMessages([
                'status' => 'The selected order status is invalid.',
            ]);
        }

        $query = RentalOrder::query()
            ->where('owner_id', $request->user()->id)
            ->with(['customer', 'costume', 'issue.reporter'])
            ->latest()
            ->orderByDesc('id');

        if ($status !== null && $status !== 'all') {
            $query->where('status', $status);
        }

        return RentalOrderResource::collection(
            $query->paginate(min(50, max(1, $request->integer('per_page', 20)))),
        );
    }

    /**
     * Show one owner order.
     */
    public function show(RentalOrder $ownerOrder): RentalOrderResource
    {
        Gate::authorize('view', $ownerOrder);
        $ownerOrder->load(['customer', 'costume', 'issue.reporter']);

        return new RentalOrderResource($ownerOrder);
    }

    /**
     * Approve a pending order.
     */
    public function approve(
        OrderDecisionRequest $request,
        RentalOrder $ownerOrder,
        ApproveRentalOrder $approveRentalOrder,
    ): JsonResponse {
        Gate::authorize('approve', $ownerOrder);
        $order = $approveRentalOrder->handle(
            $ownerOrder,
            $request->validated('owner_note'),
            $request->validated('rental_days') !== null
                ? (int) $request->validated('rental_days')
                : null,
        );
        $order->load(['customer', 'costume', 'issue.reporter']);

        return response()->json([
            'message' => 'Order approved successfully.',
            'data' => new RentalOrderResource($order),
        ]);
    }

    /**
     * Reject a pending order.
     */
    public function reject(
        OrderDecisionRequest $request,
        RentalOrder $ownerOrder,
        RejectRentalOrder $rejectRentalOrder,
    ): JsonResponse {
        Gate::authorize('reject', $ownerOrder);
        $data = $request->validated();

        if (blank($data['owner_note'] ?? null)) {
            throw ValidationException::withMessages([
                'owner_note' => __('validation.required', ['attribute' => 'owner note']),
            ]);
        }

        $order = $rejectRentalOrder->handle($ownerOrder, $data['owner_note']);
        $order->load(['customer', 'costume', 'issue.reporter']);

        return response()->json([
            'message' => 'Order rejected successfully.',
            'data' => new RentalOrderResource($order),
        ]);
    }

    /**
     * Complete a clean return.
     */
    public function complete(
        RentalOrder $ownerOrder,
        CompleteRentalReturn $completeRentalReturn,
    ): JsonResponse {
        Gate::authorize('completeReturn', $ownerOrder);
        $order = $completeRentalReturn->handle($ownerOrder);
        $order->load(['customer', 'costume', 'issue.reporter']);

        return response()->json([
            'message' => 'Return completed successfully.',
            'data' => new RentalOrderResource($order),
        ]);
    }

    /**
     * Download the private transfer receipt the customer uploaded.
     */
    public function paymentProof(RentalOrder $ownerOrder): StreamedResponse
    {
        Gate::authorize('view', $ownerOrder);
        abort_if(blank($ownerOrder->payment_proof_path), 404);

        return Storage::disk('local')->download(
            $ownerOrder->payment_proof_path,
            basename((string) $ownerOrder->payment_proof_path),
        );
    }
}
