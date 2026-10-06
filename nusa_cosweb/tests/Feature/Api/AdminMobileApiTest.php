<?php

use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;

test('an admin can manage mobile users and read the dashboard', function (): void {
    $admin = User::factory()->admin()->create();

    $response = $this->withToken($admin->createToken('admin-mobile')->plainTextToken)
        ->getJson(route('api.v1.admin.users.index'))
        ->assertOk()
        ->assertJsonPath('data.0.is_admin', true);

    $create = $this->withToken($admin->createToken('admin-mobile-create')->plainTextToken)
        ->postJson(route('api.v1.admin.users.store'), [
            'name' => 'Owner Mobile',
            'email' => 'owner.mobile@example.test',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'owner',
        ])
        ->assertCreated()
        ->assertJsonPath('data.role', 'owner')
        ->assertJsonPath('data.is_cosrent_owner', true);

    $userId = $create->json('data.id');

    $this->withToken($admin->createToken('admin-mobile-update')->plainTextToken)
        ->patchJson(route('api.v1.admin.users.update', $userId), [
            'name' => 'Owner Mobile Updated',
            'email' => 'owner.mobile@example.test',
            'role' => 'customer',
        ])
        ->assertOk()
        ->assertJsonPath('data.role', 'customer');

    $this->withToken($admin->createToken('admin-mobile-delete')->plainTextToken)
        ->deleteJson(route('api.v1.admin.users.destroy', $userId))
        ->assertOk();

    $this->withToken($admin->createToken('admin-mobile-dashboard')->plainTextToken)
        ->getJson(route('api.v1.admin.dashboard'))
        ->assertOk()
        ->assertJsonStructure([
            'data' => ['totalUsers', 'totalOrders', 'pendingOrders', 'openIssues'],
        ]);

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create();
    $this->withToken($admin->createToken('admin-mobile-status')->plainTextToken)
        ->patchJson(route('api.v1.admin.orders.status', $order), ['status' => 'rejected'])
        ->assertOk()
        ->assertJsonPath('data.status', 'rejected');

    expect($response->json('data'))->toBeArray();
});

test('a non-admin cannot access admin mobile endpoints', function (): void {
    $customer = User::factory()->create();

    $this->withToken($customer->createToken('customer-mobile')->plainTextToken)
        ->getJson(route('api.v1.admin.dashboard'))
        ->assertForbidden();
});

test('a customer can cancel a pending booking through the mobile API', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create();

    $this->withToken($customer->createToken('customer-cancel')->plainTextToken)
        ->deleteJson(route('api.v1.customer.orders.destroy', $order))
        ->assertOk()
        ->assertJsonPath('message', 'Booking cancelled successfully.');

    $this->assertDatabaseMissing('rental_orders', ['id' => $order->id]);
});

test('an owner can list mobile issue reports', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create();
    RentalIssue::factory()->stain()
        ->for($order, 'rentalOrder')
        ->for($customer, 'reporter')
        ->create();

    $this->withToken($owner->createToken('owner-issues')->plainTextToken)
        ->getJson(route('api.v1.owner.issues.index'))
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.type', 'stain');
});
