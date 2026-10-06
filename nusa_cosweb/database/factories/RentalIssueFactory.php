<?php

namespace Database\Factories;

use App\Enums\RentalIssueStatus;
use App\Enums\RentalIssueType;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RentalIssue>
 */
class RentalIssueFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'rental_order_id' => RentalOrder::factory(),
            'reporter_id' => User::factory(),
            'type' => RentalIssueType::Stain,
            'status' => RentalIssueStatus::Open,
            'description' => fake()->sentence(),
            'evidence_path' => null,
            'fine_amount' => 0,
            'replacement_cost' => null,
            'fine_paid_at' => null,
            'replacement_submitted_at' => null,
            'replacement_received_at' => null,
            'resolved_at' => null,
            'resolution_note' => null,
        ];
    }

    /**
     * Indicate that the issue is a stain report.
     */
    public function stain(): static
    {
        return $this->state(fn (array $attributes): array => [
            'type' => RentalIssueType::Stain,
            'fine_amount' => 50000,
        ]);
    }

    /**
     * Indicate that the costume was lost.
     */
    public function lost(): static
    {
        return $this->state(fn (array $attributes): array => [
            'type' => RentalIssueType::Lost,
            'replacement_cost' => 350000,
            'replacement_submitted_at' => now(),
        ]);
    }

    /**
     * Indicate that the issue has been resolved.
     */
    public function resolved(): static
    {
        return $this->state(fn (array $attributes): array => [
            'status' => RentalIssueStatus::Resolved,
            'resolved_at' => now(),
        ]);
    }
}
