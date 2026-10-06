<?php

namespace Database\Seeders;

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CosrentOwnerSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed a local owner account with a pending customer order.
     */
    public function run(): void
    {
        $owner = User::query()->firstOrCreate(
            ['email' => 'owner@cosplaynusa.test'],
            [
                'name' => 'Nadia Cosrent',
                'username' => 'owner',
                'password' => 'password',
                'is_admin' => false,
                'is_cosrent_owner' => true,
                'email_verified_at' => now(),
            ],
        );

        $owner->forceFill([
            'name' => 'Nadia Cosrent',
            'username' => 'owner',
            'password' => 'password',
            'is_cosrent_owner' => true,
        ])->save();

        $customer = User::query()->firstOrCreate(
            ['email' => 'customer@cosplaynusa.test'],
            [
                'name' => 'Raka Pradana',
                'username' => 'customer',
                'password' => 'password',
                'is_admin' => false,
                'is_cosrent_owner' => false,
                'email_verified_at' => now(),
            ],
        );

        $customer->forceFill([
            'name' => 'Raka Pradana',
            'username' => 'customer',
            'password' => 'password',
        ])->save();

        $costume = Costume::query()->firstOrCreate(
            [
                'owner_id' => $owner->id,
                'name' => 'Nebula Witch Signature Set',
            ],
            [
                'character_name' => 'Luna Starweaver',
                'category' => 'Fantasy',
                'size' => 'M',
                'color' => 'Ungu / emas',
                'description' => 'Lengkap dengan mantle, tiara, wand, dan clutch karakter.',
                'image_url' => null,
                'price_per_day' => 85000,
                'extra_price_per_day' => 25000,
                'stock' => 3,
                'is_published' => true,
            ],
        );

        $costume->fill([
            'character_name' => 'Luna Starweaver',
            'category' => 'Fantasy',
            'size' => 'M',
            'description' => 'Lengkap dengan mantle, tiara, wand, dan clutch karakter.',
            'price_per_day' => 85000,
            'extra_price_per_day' => 25000,
            'stock' => 3,
            'is_published' => true,
        ])->save();

        $order = RentalOrder::query()->firstOrCreate(
            [
                'owner_id' => $owner->id,
                'customer_id' => $customer->id,
                'costume_id' => $costume->id,
                'rental_start' => today()->addDays(7),
                'rental_end' => today()->addDays(8),
            ],
            [
                'quantity' => 1,
                'requested_rental_start' => today()->addDays(7),
                'requested_rental_end' => today()->addDays(8),
                'price_per_day' => $costume->price_per_day,
                'extra_price_per_day' => $costume->extra_price_per_day,
                'total_price' => $costume->rentalTotalFor(2, 1),
                'status' => RentalOrderStatus::Pending,
                'customer_note' => 'Digunakan untuk photoshoot di Jakarta.',
                'owner_note' => null,
                'decided_at' => null,
            ],
        );

        if ($order->status === RentalOrderStatus::Pending) {
            $order->fill([
                'requested_rental_start' => $order->rental_start,
                'requested_rental_end' => $order->rental_end,
                'price_per_day' => $costume->price_per_day,
                'extra_price_per_day' => $costume->extra_price_per_day,
                'total_price' => $costume->rentalTotalFor(2, (int) $order->quantity),
            ])->save();
        }
    }
}
