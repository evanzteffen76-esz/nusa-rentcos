<?php

namespace App\Actions;

use App\Enums\RentalOrderStatus;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CompleteRentalReturn
{
    /**
     * Complete a clean return after the owner has inspected the costume.
     *
     * @throws ValidationException
     */
    public function handle(RentalOrder $rentalOrder): RentalOrder
    {
        return DB::transaction(function () use ($rentalOrder): RentalOrder {
            $lockedOrder = RentalOrder::query()
                ->with('issue')
                ->lockForUpdate()
                ->findOrFail($rentalOrder->id);

            if (! $lockedOrder->isReturned()) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.complete_status_error'),
                ]);
            }

            if ($lockedOrder->issue?->isOpen()) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.issue_open_error'),
                ]);
            }

            $lockedOrder->update([
                'status' => RentalOrderStatus::Completed,
                'completed_at' => now(),
            ]);

            return $lockedOrder->load(['customer:id,name,email', 'costume:id,name,character_name', 'issue']);
        }, 3);
    }
}
