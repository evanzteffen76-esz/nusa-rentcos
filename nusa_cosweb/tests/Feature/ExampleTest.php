<?php

use App\Models\User;

it('returns a successful response', function () {
    $response = $this->get('/');

    $response->assertStatus(200);
});

it('renders the theme toggle and system preference bootstrap', function () {
    $response = $this->get('/');

    $response
        ->assertOk()
        ->assertSee('data-theme-toggle', false)
        ->assertSee('prefers-color-scheme: dark', false)
        ->assertSee('cosrent-theme', false);
});

it('applies the automatic theme bootstrap to all dashboard roles', function () {
    $admin = User::factory()->admin()->create();
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();

    $this->actingAs($admin)
        ->get(route('admin.dashboard'))
        ->assertOk()
        ->assertSee('prefers-color-scheme: dark', false);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.dashboard'))
        ->assertOk()
        ->assertSee('prefers-color-scheme: dark', false);

    $this->actingAs($customer)
        ->get(route('dashboard'))
        ->assertOk()
        ->assertSee('prefers-color-scheme: dark', false);
});
