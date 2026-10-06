<?php

use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

test('a user can update their own profile', function (): void {
    $user = User::factory()->create([
        'name' => 'Raka Lama',
        'username' => 'raka',
        'email' => 'raka@example.test',
    ]);

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), [
            'name' => 'Raka Baru',
            'username' => 'RakaBaru',
            'email' => 'Raka.Baru@Example.test',
        ])
        ->assertOk()
        ->assertJsonPath('data.name', 'Raka Baru')
        ->assertJsonPath('data.username', 'rakabaru')
        ->assertJsonPath('data.email', 'raka.baru@example.test');

    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'name' => 'Raka Baru',
        'username' => 'rakabaru',
        'email' => 'raka.baru@example.test',
    ]);
});

test('profile updates keep the current values when fields are omitted', function (): void {
    $user = User::factory()->create([
        'name' => 'Tetap Sama',
        'username' => 'tetap',
        'email' => 'tetap@example.test',
    ]);

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), ['name' => 'Tetap Sama'])
        ->assertOk()
        ->assertJsonPath('data.username', 'tetap')
        ->assertJsonPath('data.email', 'tetap@example.test');
});

test('a username or email already taken by someone else is rejected', function (): void {
    User::factory()->create(['username' => 'terpakai', 'email' => 'terpakai@example.test']);
    $user = User::factory()->create(['username' => 'saya', 'email' => 'saya@example.test']);

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), ['username' => 'terpakai'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('username');

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), ['email' => 'terpakai@example.test'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('email');
});

test('changing the password requires the correct current password', function (): void {
    $user = User::factory()->create(['password' => Hash::make('password123')]);

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), [
            'password' => 'rahasia456',
            'password_confirmation' => 'rahasia456',
            'current_password' => 'salah-sekali',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('current_password');

    $this->assertTrue(Hash::check('password123', $user->fresh()->password));

    $this->actingAs($user, 'sanctum')
        ->patchJson(route('api.v1.auth.profile.update'), [
            'password' => 'rahasia456',
            'password_confirmation' => 'rahasia456',
            'current_password' => 'password123',
        ])
        ->assertOk();

    $this->assertTrue(Hash::check('rahasia456', $user->fresh()->password));
});

test('a user can delete their own account and all issued tokens', function (): void {
    $user = User::factory()->create(['password' => Hash::make('password123')]);
    $token = $user->createToken('android-test')->plainTextToken;

    $this->assertDatabaseHas('users', ['id' => $user->id]);

    $this->withToken($token)
        ->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'password123'])
        ->assertOk();

    $this->assertDatabaseMissing('users', ['id' => $user->id]);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

test('deleting an account requires the correct password', function (): void {
    $user = User::factory()->create(['password' => Hash::make('password123')]);

    $this->actingAs($user, 'sanctum')
        ->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'salah'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('password');

    $this->assertDatabaseHas('users', ['id' => $user->id]);
});

test('an account with an active rental cannot be deleted', function (): void {
    $owner = User::factory()->cosrentOwner()->create(['password' => Hash::make('password123')]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();

    RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner, 'sanctum')
        ->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'password123'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('account');

    $this->assertDatabaseHas('users', ['id' => $owner->id]);
});

test('a settled rental does not block account deletion', function (): void {
    $owner = User::factory()->cosrentOwner()->create(['password' => Hash::make('password123')]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();

    RentalOrder::factory()->approved()->completed()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner, 'sanctum')
        ->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'password123'])
        ->assertOk();

    $this->assertDatabaseMissing('users', ['id' => $owner->id]);
});

test('the last administrator cannot delete their own account', function (): void {
    $admin = User::factory()->admin()->create(['password' => Hash::make('password123')]);

    $this->actingAs($admin, 'sanctum')
        ->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'password123'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('account');

    $this->assertDatabaseHas('users', ['id' => $admin->id]);
});

test('guests cannot update or delete an account', function (): void {
    $this->patchJson(route('api.v1.auth.profile.update'), ['name' => 'Bom'])
        ->assertUnauthorized();

    $this->deleteJson(route('api.v1.auth.account.destroy'), ['password' => 'x'])
        ->assertUnauthorized();
});

test('an owner can store and clear their bank details through the API', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->withToken($owner->createToken('bank-test')->plainTextToken)
        ->patchJson(route('api.v1.auth.profile.update'), [
            'bank_name' => 'Bank Nusantara',
            'bank_account_number' => '1234567890',
            'bank_account_holder' => 'CosplayNusa Studio',
        ])
        ->assertOk()
        ->assertJsonPath('data.bank_details.bank_name', 'Bank Nusantara')
        ->assertJsonPath('data.bank_details.account_number', '1234567890')
        ->assertJsonPath('data.bank_details.account_holder', 'CosplayNusa Studio')
        ->assertJsonPath('data.bank_details.is_complete', true)
        ->assertJsonPath('data.has_bank_account', true);

    // Sending the trio empty clears the account again.
    $this->withToken($owner->createToken('bank-test')->plainTextToken)
        ->patchJson(route('api.v1.auth.profile.update'), [
            'bank_name' => '',
            'bank_account_number' => '',
            'bank_account_holder' => '',
        ])
        ->assertOk()
        ->assertJsonPath('data.bank_details.is_complete', false);
});

test('a partial bank details update is rejected', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->withToken($owner->createToken('bank-test')->plainTextToken)
        ->patchJson(route('api.v1.auth.profile.update'), [
            'bank_name' => 'Bank Nusantara',
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors([
            'bank_account_number',
            'bank_account_holder',
        ]);
});

test('a customer never receives bank details for another account', function (): void {
    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'Bank Nusantara',
        'bank_account_number' => '1234567890',
        'bank_account_holder' => 'CosplayNusa Studio',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    // The catalog hides another account's coordinates...
    $this->withToken($customer->createToken('catalog-test')->plainTextToken)
        ->getJson(route('api.v1.costumes.show', $costume))
        ->assertOk()
        ->assertJsonPath('data.owner.bank_details', null)
        ->assertJsonPath('data.owner.has_bank_account', true);

    // ...but the booking flow still gets what it needs to fund a transfer.
    $this->withToken($customer->createToken('catalog-test')->plainTextToken)
        ->getJson(route('api.v1.costumes.show', $costume))
        ->assertOk()
        ->assertJsonPath('data.owner_bank.bank_name', 'Bank Nusantara')
        ->assertJsonPath('data.owner_bank.is_complete', true);
});
