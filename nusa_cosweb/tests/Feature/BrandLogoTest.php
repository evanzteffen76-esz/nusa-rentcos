<?php

use App\Models\User;

test('every dashboard renders the CosplayNusa brand logo', function (string $role): void {
    $user = match ($role) {
        'owner' => User::factory()->cosrentOwner()->create(),
        'admin' => User::factory()->admin()->create(),
        default => User::factory()->create(),
    };

    $url = match ($role) {
        'owner' => route('cosrent-owner.dashboard'),
        'admin' => route('admin.dashboard'),
        default => route('dashboard'),
    };

    $this->actingAs($user)
        ->get($url)
        ->assertOk()
        ->assertSee('>COSPLAY<', false)
        ->assertSee('>NUSA<', false)
        ->assertDontSee('viewBox="0 0 316 316"', false);
})->with(['customer', 'owner', 'admin']);

test('the guest sign in screen uses the same brand logo', function (): void {
    $this->get(route('login'))
        ->assertOk()
        ->assertSee('>COSPLAY<', false)
        ->assertSee('>NUSA<', false)
        ->assertDontSee('viewBox="0 0 316 316"', false);
});
