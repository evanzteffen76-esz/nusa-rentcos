<?php

namespace App\Http\Controllers\Owner;

use App\Actions\ApproveRentalOrder;
use App\Actions\RejectRentalOrder;
use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\ApproveRentalOrderRequest;
use App\Http\Requests\Owner\RejectRentalOrderRequest;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;

class OrderDecisionController extends Controller
{
    /**
     * Approve a pending customer order.
     */
    public function approve(
        ApproveRentalOrderRequest $request,
        RentalOrder $ownerRentalOrder,
        ApproveRentalOrder $approveRentalOrder,
    ): RedirectResponse {
        $approveRentalOrder->handle(
            $ownerRentalOrder,
            $request->validated('owner_note'),
            $this->rentalDays($request->validated('rental_days')),
        );

        return redirect()
            ->route('cosrent-owner.orders.show', $ownerRentalOrder)
            ->with('status', __('owner.orders.approved'));
    }

    /**
     * Normalise the submitted rental length.
     *
     * The quick-approve buttons on the index and dashboard omit the field, so a
     * missing value simply means "use the included period".
     */
    private function rentalDays(mixed $value): ?int
    {
        return filled($value) ? (int) $value : null;
    }

    /**
     * Reject a pending customer order.
     */
    public function reject(
        RejectRentalOrderRequest $request,
        RentalOrder $ownerRentalOrder,
        RejectRentalOrder $rejectRentalOrder,
    ): RedirectResponse {
        $rejectRentalOrder->handle(
            $ownerRentalOrder,
            $request->validated('owner_note'),
        );

        return redirect()
            ->route('cosrent-owner.orders.show', $ownerRentalOrder)
            ->with('status', __('owner.orders.rejected'));
    }
}
