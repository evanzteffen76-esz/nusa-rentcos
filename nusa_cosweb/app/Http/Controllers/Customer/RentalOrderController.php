<?php

namespace App\Http\Controllers\Customer;

use App\Actions\GeneratePaymentCode;
use App\Enums\PaymentMethod;
use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\StoreRentalOrderRequest;
use App\Models\Costume;
use App\Models\RentalOrder;
use Carbon\CarbonImmutable;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Throwable;

class RentalOrderController extends Controller
{
    /**
     * Show the booking form for a published costume.
     */
    public function create(Costume $availableCostume): View
    {
        Gate::authorize('create', RentalOrder::class);

        return view('customer.booking.create', [
            'availableCostume' => $availableCostume,
            'paymentMethods' => PaymentMethod::cases(),
        ]);
    }

    /**
     * Store a customer booking request for owner approval.
     */
    public function store(
        StoreRentalOrderRequest $request,
        Costume $availableCostume,
        GeneratePaymentCode $generatePaymentCode,
    ): RedirectResponse {
        $data = $request->validated();
        $requestedStart = CarbonImmutable::parse($data['rental_start'])->startOfDay();
        $requestedEnd = CarbonImmutable::parse($data['rental_end'])->startOfDay();
        $paymentMethod = PaymentMethod::from($data['payment_method']);
        $paymentProofPath = $paymentMethod->isBankTransfer()
            ? $request->file('payment_proof')?->store('rental-orders/payments', 'local')
            : null;

        try {
            RentalOrder::query()->create([
                'owner_id' => $availableCostume->owner_id,
                'customer_id' => $request->user()->id,
                'costume_id' => $availableCostume->id,
                'quantity' => $data['quantity'],
                'rental_start' => $requestedStart,
                'rental_end' => $requestedEnd,
                'requested_rental_start' => $requestedStart,
                'requested_rental_end' => $requestedEnd,
                'price_per_day' => $availableCostume->price_per_day,
                'extra_price_per_day' => $availableCostume->extra_price_per_day,
                'total_price' => $availableCostume->rentalTotalFor(
                    RentalOrder::daysBetween($requestedStart, $requestedEnd),
                    (int) $data['quantity'],
                ),
                'status' => RentalOrderStatus::Pending,
                'payment_method' => $paymentMethod,
                'payment_code' => $paymentMethod->isPayAtOwner()
                    ? $generatePaymentCode->handle()
                    : null,
                'payment_proof_path' => $paymentProofPath,
                'customer_note' => filled($data['customer_note'] ?? null)
                    ? trim($data['customer_note'])
                    : null,
            ]);
        } catch (Throwable $exception) {
            if ($paymentProofPath !== null) {
                Storage::disk('local')->delete($paymentProofPath);
            }

            throw $exception;
        }

        return redirect()
            ->route('dashboard')
            ->with('status', $paymentMethod->isPayAtOwner()
                ? __('customer.booking.created_with_code')
                : __('customer.booking.created'));
    }
}
