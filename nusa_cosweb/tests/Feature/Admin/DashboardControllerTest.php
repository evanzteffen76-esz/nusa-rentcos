<?php

use App\Models\User;

test('redirects guests to the login page', function (): void {
    $this->get(route('admin.dashboard'))
        ->assertRedirectToRoute('login');
});

test('forbids authenticated users without administrator access', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('admin.dashboard'))
        ->assertForbidden();
});

test('renders the admin dashboard for an administrator', function (): void {
    $admin = User::factory()->admin()->create();

    $response = $this->actingAs($admin)
        ->get(route('admin.dashboard'));

    $response
        ->assertOk()
        ->assertViewIs('admin.dashboard')
        ->assertViewHas('totalUsers', 1)
        ->assertViewHas('adminCount', 1)
        ->assertViewHas('ownerCount', 0)
        ->assertViewHas('regularUserCount', 0)
        ->assertSee('Admin dashboard');
});

test('escapes the administrator name in the dashboard', function (): void {
    $admin = User::factory()->admin()->create([
        'name' => '<script>alert("x")</script>',
    ]);

    $response = $this->actingAs($admin)
        ->get(route('admin.dashboard'));

    $response
        ->assertOk()
        ->assertSee('&lt;script&gt;', false)
        ->assertDontSee('<script>alert("x")</script>', false);
});
