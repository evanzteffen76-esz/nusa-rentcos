<?php

use App\Models\User;

test('registration screen can be rendered', function () {
    $response = $this->get('/register');

    $response->assertStatus(200);
});

test('new users can register', function () {
    $response = $this->post('/register', [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
    ]);

    $this->assertAuthenticated();
    $response->assertRedirect(route('dashboard', absolute: false));
});

test('users can register as a Cosrent Owner', function (): void {
    $response = $this->post('/register', [
        'name' => 'Cosrent Owner',
        'email' => 'owner@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
        'account_type' => 'cosrent_owner',
    ]);

    $user = User::query()->firstOrFail();

    $this->assertAuthenticatedAs($user);
    $response->assertRedirect(route('cosrent-owner.dashboard', absolute: false));

    expect($user->is_cosrent_owner)->toBeTrue();
});

test('registration rejects an unknown account type', function (): void {
    $this->post('/register', [
        'name' => 'Unknown Role',
        'email' => 'unknown@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
        'account_type' => 'administrator',
    ])
        ->assertSessionHasErrors('account_type');

    $this->assertGuest();
    expect(User::query()->count())->toBe(0);
});
