<?php

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;

test('guests are redirected to login before returning a costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'rental_start' => today()->subDays(5),
        'rental_end' => today()->subDays(3),
        'return_due_at' => today()->subDays(2),
    ]);

    $this->post(route('dashboard.orders.return', $order))
        ->assertRedirectToRoute('login');
});

test('customer can return an approved costume after the rental period', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'rental_start' => today()->subDays(5),
        'rental_end' => today()->subDays(3),
        'return_due_at' => today()->subDays(2),
    ]);

    $this->actingAs($customer)
        ->post(route('dashboard.orders.return', $order), [
            'return_note' => 'Kostum dikembalikan dengan kondisi baik.',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('dashboard')
        ->assertSessionHas('status');

    $order->refresh();

    expect($order->status)->toBe(RentalOrderStatus::Returned)
        ->and($order->returned_at)->not->toBeNull()
        ->and($order->returned_late)->toBeTrue()
        ->and($order->return_note)->toBe('Kostum dikembalikan dengan kondisi baik.');
});

test('customer cannot return before the rental period ends', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->from(route('dashboard'))
        ->post(route('dashboard.orders.return', $order))
        ->assertSessionHasErrors('order');

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Approved);
});

test('customer cannot return another customer order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($otherCustomer, 'customer')->for($costume, 'costume')->create([
        'rental_start' => today()->subDays(5),
        'rental_end' => today()->subDays(3),
        'return_due_at' => today()->subDays(2),
    ]);

    $this->actingAs($customer)
        ->post(route('dashboard.orders.return', $order))
        ->assertNotFound();

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Approved);
});

test('customer cannot return an order after reporting it lost', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'rental_start' => today()->subDays(5),
        'rental_end' => today()->subDays(3),
        'return_due_at' => today()->subDays(2),
    ]);
    RentalIssue::factory()->lost()->for($order, 'rentalOrder')->for($customer, 'reporter')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.orders.return', $order))
        ->assertForbidden();

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Approved);
});

test('a returned order cannot be returned twice', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.orders.return', $order))
        ->assertForbidden();
});
