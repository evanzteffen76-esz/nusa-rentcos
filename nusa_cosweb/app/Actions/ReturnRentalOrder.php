<?php

namespace App\Actions;

use App\Enums\RentalOrderStatus;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ReturnRentalOrder
{
    /**
     * Mark an approved order as returned by the customer.
     *
     * @throws ValidationException
     */
    public function handle(RentalOrder $rentalOrder, ?string $returnNote = null): RentalOrder
    {
        return DB::transaction(function () use ($rentalOrder, $returnNote): RentalOrder {
            $lockedOrder = RentalOrder::query()
                ->with('issue')
                ->lockForUpdate()
                ->findOrFail($rentalOrder->id);

            if (! $lockedOrder->isApproved()) {
                throw ValidationException::withMessages([
                    'order' => __('customer.return.status_error'),
                ]);
            }

            if ($lockedOrder->issue()->exists()) {
                throw ValidationException::withMessages([
                    'order' => __('customer.issues.already_reported'),
                ]);
            }

            if (today()->lt($lockedOrder->rental_end)) {
                throw ValidationException::withMessages([
                    'order' => __('customer.return.too_early'),
                ]);
            }

            $lockedOrder->update([
                'status' => RentalOrderStatus::Returned,
                'returned_at' => now(),
                'returned_late' => $lockedOrder->return_due_at !== null
                    && today()->isAfter($lockedOrder->return_due_at),
                'return_note' => filled($returnNote) ? trim($returnNote) : null,
            ]);

            return $lockedOrder->load(['costume:id,name,character_name', 'issue']);
        }, 3);
    }
}
