<?php

namespace Database\Factories;

use App\Models\Costume;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Costume>
 */
class CostumeFactory extends Factory
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
            'name' => fake()->unique()->words(2, true).' Cosplay',
            'character_name' => fake()->name(),
            'category' => fake()->randomElement(['Fantasy', 'Heroic', 'Modern', 'Anime']),
            'size' => fake()->randomElement(['S', 'M', 'L', 'XL']),
            'description' => fake()->sentence(12),
            'image_url' => null,
            'images' => [],
            'videos' => [],
            'price_per_day' => fake()->numberBetween(50, 200) * 1000,
            'extra_price_per_day' => fake()->numberBetween(10, 60) * 1000,
            'stock' => fake()->numberBetween(1, 5),
            'is_published' => false,
        ];
    }

    /**
     * Indicate that the costume is published in the customer catalog.
     */
    public function published(): static
    {
        return $this->state(fn (array $attributes): array => [
            'is_published' => true,
        ]);
    }

    /**
     * Indicate that the costume is hidden from the customer catalog.
     */
    public function unpublished(): static
    {
        return $this->state(fn (array $attributes): array => [
            'is_published' => false,
        ]);
    }
}
