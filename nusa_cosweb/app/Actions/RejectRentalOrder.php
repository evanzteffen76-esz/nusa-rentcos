<?php

namespace App\Actions;

use App\Enums\RentalOrderStatus;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RejectRentalOrder
{
    /**
     * Reject a pending customer order.
     *
     * @throws ValidationException
     */
    public function handle(RentalOrder $rentalOrder, string $ownerNote): RentalOrder
    {
        return DB::transaction(function () use ($rentalOrder, $ownerNote): RentalOrder {
            $lockedOrder = RentalOrder::query()
                ->lockForUpdate()
                ->findOrFail($rentalOrder->id);

            if (! $lockedOrder->isPending()) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.status_error'),
                ]);
            }

            $lockedOrder->update([
                'status' => RentalOrderStatus::Rejected,
                'owner_note' => trim($ownerNote),
                'decided_at' => now(),
            ]);

            return $lockedOrder->load([
                'customer:id,name,email',
                'costume:id,name,character_name,image_url,images',
            ]);
        }, 3);
    }
}
