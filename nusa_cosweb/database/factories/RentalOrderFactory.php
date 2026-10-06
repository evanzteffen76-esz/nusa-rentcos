<?php

namespace Database\Factories;

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RentalOrder>
 */
class RentalOrderFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'owner_id' => User::factory()->cosrentOwner(),
            'customer_id' => User::factory(),
            'costume_id' => function (array $attributes): int {
                $owner = User::query()->findOrFail($attributes['owner_id']);

                return Costume::factory()->for($owner, 'owner')->create()->id;
            },
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(4)->toDateString(),
            'requested_rental_start' => today()->addDays(3)->toDateString(),
            'requested_rental_end' => today()->addDays(4)->toDateString(),
            'return_due_at' => null,
            'quantity' => fake()->numberBetween(1, 2),
            'price_per_day' => fake()->numberBetween(50, 200) * 1000,
            'extra_price_per_day' => fake()->numberBetween(10, 60) * 1000,
            'total_price' => fake()->numberBetween(75, 300) * 1000,
            'status' => RentalOrderStatus::Pending,
            'customer_note' => null,
            'owner_note' => null,
            'decided_at' => null,
            'approved_at' => null,
            'returned_at' => null,
            'returned_late' => false,
            'completed_at' => null,
            'return_note' => null,
        ];
    }

    /**
     * Indicate that the order is awaiting a decision.
     */
    public function pending(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => RentalOrderStatus::Pending,
            'decided_at' => null,
            'approved_at' => null,
            'returned_at' => null,
            'returned_late' => false,
            'completed_at' => null,
        ]);
    }

    /**
     * Indicate that the order has been approved.
     */
    public function approved(): static
    {
        return $this->state(function (array $attributes): array {
            $approvedAt = now();
            $days = RentalOrder::INCLUDED_RENTAL_DAYS;
            $rentalStart = $approvedAt->copy()->startOfDay();
            $rentalEnd = $rentalStart->copy()->addDays($days - 1);

            return [
                'status' => RentalOrderStatus::Approved,
                'rental_start' => $rentalStart,
                'rental_end' => $rentalEnd,
                'return_due_at' => $rentalEnd->copy()->addDays(RentalOrder::RETURN_GRACE_DAYS),
                // Keep the stored total consistent with the snapshotted rates.
                'total_price' => RentalOrder::priceFor(
                    (int) $attributes['price_per_day'],
                    (int) $attributes['extra_price_per_day'],
                    $days,
                    (int) $attributes['quantity'],
                ),
                'decided_at' => $approvedAt,
                'approved_at' => $approvedAt,
                'owner_note' => 'Order confirmed.',
            ];
        });
    }

    /**
     * Indicate that the customer has returned the costume.
     */
    public function returned(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => RentalOrderStatus::Returned,
            'returned_at' => now(),
            'returned_late' => false,
            'return_note' => 'Returned by customer.',
        ]);
    }

    /**
     * Indicate that the owner has completed the return process.
     */
    public function completed(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => RentalOrderStatus::Completed,
            'completed_at' => now(),
        ]);
    }

    /**
     * Indicate that the order has been rejected.
     */
    public function rejected(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => RentalOrderStatus::Rejected,
            'decided_at' => now(),
            'owner_note' => 'The requested dates are unavailable.',
        ]);
    }
}
