<?php

namespace Database\Seeders;

use App\Models\Costume;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the local CosplayNusa demo accounts and catalog.
     */
    public function run(): void
    {
        $this->call(CosrentOwnerSeeder::class);

        User::query()->updateOrCreate(
            ['email' => 'admin@cosplaynusa.test'],
            [
                'name' => 'Admin CosplayNusa',
                'username' => 'admin',
                'password' => 'password',
                'is_admin' => true,
                'is_cosrent_owner' => false,
                'email_verified_at' => now(),
            ],
        );

        $owner = User::query()->where('email', 'owner@cosplaynusa.test')->firstOrFail();
        $catalog = [
            [
                'name' => 'Nebula Witch Signature Set',
                'character_name' => 'Luna Starweaver',
                'category' => 'Fantasy',
                'size' => 'M',
                'color' => 'Ungu / emas',
                'description' => 'Lengkap dengan mantle, tiara, wand, dan clutch karakter.',
                'price_per_day' => 85000,
                'extra_price_per_day' => 25000,
                'stock' => 3,
                'is_published' => true,
            ],
            [
                'name' => 'Midnight Detective',
                'character_name' => 'Luna Starweaver',
                'category' => 'Heroic',
                'size' => 'M',
                'color' => 'Navy / emas',
                'description' => 'Set detektif misterius dengan jas panjang, aksen emas, dan aksesori detektif.',
                'price_per_day' => 185000,
                'extra_price_per_day' => 45000,
                'stock' => 2,
                'is_published' => true,
            ],
            [
                'name' => 'Ocean Guardian',
                'character_name' => 'Nereus',
                'category' => 'Fantasy',
                'size' => 'L',
                'color' => 'Biru laut',
                'description' => 'Kostum guardian samudra dengan sirip, mutiara, dan cloak ringan.',
                'price_per_day' => 175000,
                'extra_price_per_day' => 40000,
                'stock' => 2,
                'is_published' => true,
            ],
            [
                'name' => 'Cyber Academy',
                'character_name' => 'Aiko Tanaka',
                'category' => 'School',
                'size' => 'M',
                'color' => 'Ungu / cyan',
                'description' => 'Seragam akademi futuristik dengan layer stocking, vest, dan aksen LED.',
                'price_per_day' => 125000,
                'extra_price_per_day' => 30000,
                'stock' => 4,
                'is_published' => true,
            ],
            [
                'name' => 'Crimson Phantom',
                'character_name' => 'Phantom Thief',
                'category' => 'Anime',
                'size' => 'L',
                'color' => 'Merah / hitam',
                'description' => 'Phantom elegan dengan jubah merah, topeng, dan aksen lateks yang dramatis.',
                'price_per_day' => 195000,
                'extra_price_per_day' => 50000,
                'stock' => 2,
                'is_published' => true,
            ],
        ];

        foreach ($catalog as $item) {
            Costume::query()->updateOrCreate(
                ['owner_id' => $owner->id, 'name' => $item['name']],
                $item,
            );
        }
    }
}
