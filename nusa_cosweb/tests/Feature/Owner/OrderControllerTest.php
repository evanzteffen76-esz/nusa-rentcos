<?php

use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;

test('redirects guests from owner orders to login', function (): void {
    $this->get(route('cosrent-owner.orders.index'))
        ->assertRedirectToRoute('login');
});

test('forbids regular users from viewing owner orders', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('cosrent-owner.orders.index'))
        ->assertForbidden();
});

test('owner order index only includes orders for that owner', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create(['name' => 'Visible Customer']);
    $otherCustomer = User::factory()->create(['name' => 'Hidden Customer']);
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $otherCostume = Costume::factory()->for($otherOwner, 'owner')->create();

    RentalOrder::factory()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    RentalOrder::factory()->for($otherOwner, 'owner')->for($otherCustomer, 'customer')->for($otherCostume, 'costume')->create();

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.index'))
        ->assertOk()
        ->assertSee('Visible Customer')
        ->assertDontSee('Hidden Customer');
});

test('owner order index filters by a valid status', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create(['name' => 'Pending Customer']);
    $approvedCustomer = User::factory()->create(['name' => 'Approved Customer']);
    $costume = Costume::factory()->for($owner, 'owner')->create();

    RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    RentalOrder::factory()->approved()->for($owner, 'owner')->for($approvedCustomer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.index', ['status' => 'pending']))
        ->assertOk()
        ->assertSee('Pending Customer')
        ->assertDontSee('Approved Customer');
});

test('invalid order status is not found', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.index', ['status' => 'unknown']))
        ->assertNotFound();
});

test('owner cannot view another owner order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($otherOwner, 'owner')->create();
    $order = RentalOrder::factory()->for($otherOwner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $order))
        ->assertNotFound();
});

test('owner order detail escapes customer supplied text', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create(['name' => '<script>alert("name")</script>']);
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'customer_note' => '<script>alert("note")</script>',
    ]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $order))
        ->assertOk()
        ->assertSee('&lt;script&gt;', false)
        ->assertDontSee('<script>alert("name")</script>', false)
        ->assertDontSee('<script>alert("note")</script>', false);
});
