<?php

namespace App\Actions;

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ApproveRentalOrder
{
    /**
     * Approve a pending order when the costume is available for every requested unit.
     *
     * The owner decides how long the customer may keep the costume. The first
     * RentalOrder::INCLUDED_RENTAL_DAYS come with the base price; longer rentals
     * are billed with the costume's extra rate for each additional day.
     *
     * @throws ValidationException
     */
    public function handle(
        RentalOrder $rentalOrder,
        ?string $ownerNote = null,
        ?int $rentalDays = null,
    ): RentalOrder {
        return DB::transaction(function () use ($rentalOrder, $ownerNote, $rentalDays): RentalOrder {
            $lockedOrder = RentalOrder::query()
                ->lockForUpdate()
                ->findOrFail($rentalOrder->id);

            if (! $lockedOrder->isPending()) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.status_error'),
                ]);
            }

            $costume = Costume::withTrashed()
                ->lockForUpdate()
                ->findOrFail($lockedOrder->costume_id);

            if ($costume->trashed() || ! $costume->is_published) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.unavailable_error'),
                ]);
            }

            $approvedAt = now();
            $days = min(
                max(RentalOrder::INCLUDED_RENTAL_DAYS, $rentalDays ?? RentalOrder::INCLUDED_RENTAL_DAYS),
                RentalOrder::MAX_RENTAL_DAYS,
            );
            $rentalStart = $approvedAt->copy()->startOfDay();
            $rentalEnd = $rentalStart->copy()->addDays($days - 1);
            $returnDueAt = $rentalEnd->copy()->addDays(RentalOrder::RETURN_GRACE_DAYS);

            $availableQuantity = $costume->availableQuantityFor(
                $rentalStart,
                $rentalEnd,
            );

            if ($lockedOrder->quantity > $availableQuantity) {
                throw ValidationException::withMessages([
                    'order' => __('owner.orders.inventory_error'),
                ]);
            }

            $lockedOrder->update([
                'status' => RentalOrderStatus::Approved,
                'rental_start' => $rentalStart,
                'rental_end' => $rentalEnd,
                'return_due_at' => $returnDueAt,
                'price_per_day' => $costume->price_per_day,
                'extra_price_per_day' => $costume->extra_price_per_day,
                'total_price' => $costume->rentalTotalFor($days, $lockedOrder->quantity),
                'owner_note' => filled($ownerNote) ? trim($ownerNote) : null,
                'decided_at' => $approvedAt,
                'approved_at' => $approvedAt,
            ]);

            return $lockedOrder->load([
                'customer:id,name,email',
                'costume:id,name,character_name,image_url,images',
            ]);
        }, 3);
    }
}
