<?php

use App\Models\User;

test('guests cannot access the mobile API', function (): void {
    $this->getJson(route('api.v1.costumes.index'))
        ->assertUnauthorized();
});

test('a customer can register and receive a bearer token', function (): void {
    $response = $this->postJson(route('api.v1.auth.register'), [
        'name' => 'Raka Mobile',
        'email' => 'raka.mobile@example.test',
        'password' => 'password123',
        'password_confirmation' => 'password123',
        'account_type' => 'customer',
        'device_name' => 'android-test',
    ]);

    $response->assertCreated()
        ->assertJsonPath('token_type', 'Bearer')
        ->assertJsonPath('user.role', 'customer')
        ->assertJsonStructure(['token', 'token_type', 'user' => ['id', 'name', 'email', 'role']]);

    $this->assertDatabaseHas('users', [
        'email' => 'raka.mobile@example.test',
        'is_cosrent_owner' => false,
    ]);

    $this->withToken($response->json('token'))
        ->getJson(route('api.v1.auth.me'))
        ->assertOk()
        ->assertJsonPath('data.email', 'raka.mobile@example.test');
});

test('an owner can register through the mobile API', function (): void {
    $this->postJson(route('api.v1.auth.register'), [
        'name' => 'Nadia Mobile',
        'email' => 'nadia.mobile@example.test',
        'password' => 'password123',
        'password_confirmation' => 'password123',
        'account_type' => 'cosrent_owner',
    ])->assertCreated()
        ->assertJsonPath('user.role', 'owner');

    $this->assertDatabaseHas('users', [
        'email' => 'nadia.mobile@example.test',
        'is_cosrent_owner' => true,
    ]);
});

test('a user can log in and revoke the current token', function (): void {
    $user = User::factory()->create([
        'email' => 'login.mobile@example.test',
        'password' => 'password123',
    ]);

    $login = $this->postJson(route('api.v1.auth.login'), [
        'email' => $user->email,
        'password' => 'password123',
        'device_name' => 'ios-test',
    ])->assertOk()
        ->assertJsonPath('user.email', $user->email);

    $token = $login->json('token');
    $this->assertNotEmpty($token);
    $this->assertDatabaseCount('personal_access_tokens', 1);

    $this->withToken($token)
        ->postJson(route('api.v1.auth.logout'))
        ->assertOk();

    auth()->forgetGuards();

    $this->withToken($token)
        ->getJson(route('api.v1.auth.me'))
        ->assertUnauthorized();
});

test('invalid mobile credentials are rejected', function (): void {
    $this->postJson(route('api.v1.auth.login'), [
        'email' => 'missing@example.test',
        'password' => 'wrong-password',
    ])->assertUnprocessable()
        ->assertJsonValidationErrors('login');
});

test('a user can log in with username instead of email', function (): void {
    $user = User::factory()->create([
        'username' => 'mobile-raka',
        'email' => 'raka.username@example.test',
        'password' => 'password123',
    ]);

    $this->postJson(route('api.v1.auth.login'), [
        'login' => 'mobile-raka',
        'password' => 'password123',
        'device_name' => 'android-test',
    ])->assertOk()
        ->assertJsonPath('user.username', 'mobile-raka')
        ->assertJsonPath('user.email', 'raka.username@example.test');
});
