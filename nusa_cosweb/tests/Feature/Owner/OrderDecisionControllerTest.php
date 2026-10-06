<?php

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;

test('owner approves a pending order and records the decision', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 2,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'quantity' => 2,
    ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'owner_note' => 'Pickup at 10:00.',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    $order->refresh();

    expect($order->status)->toBe(RentalOrderStatus::Approved)
        ->and($order->rental_start->toDateString())->toBe(today()->toDateString())
        ->and($order->rental_end->toDateString())->toBe(today()->addDays(2)->toDateString())
        ->and($order->return_due_at->toDateString())->toBe(today()->addDays(3)->toDateString())
        ->and($order->total_price)->toBe(200000)
        ->and($order->owner_note)->toBe('Pickup at 10:00.')
        ->and($order->decided_at)->not->toBeNull()
        ->and($order->approved_at)->not->toBeNull();
});

test('approval fails when approved bookings consume the requested stock', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create(['stock' => 1]);
    $rentalStart = today()->toDateString();
    $rentalEnd = today()->addDays(2)->toDateString();

    RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'rental_start' => $rentalStart,
            'rental_end' => $rentalEnd,
            'quantity' => 1,
        ]);

    $pendingOrder = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'rental_start' => $rentalStart,
            'rental_end' => $rentalEnd,
            'quantity' => 1,
        ]);

    $this->actingAs($owner)
        ->from(route('cosrent-owner.orders.show', $pendingOrder))
        ->patch(route('cosrent-owner.orders.approve', $pendingOrder))
        ->assertSessionHasErrors('order');

    expect($pendingOrder->refresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('approval fails when the costume is no longer published', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create(['is_published' => false]);
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->from(route('cosrent-owner.orders.show', $order))
        ->patch(route('cosrent-owner.orders.approve', $order))
        ->assertSessionHasErrors('order');

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('rejection requires an owner note', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->from(route('cosrent-owner.orders.show', $order))
        ->patch(route('cosrent-owner.orders.reject', $order), [])
        ->assertSessionHasErrors('owner_note');

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('owner rejects a pending order with a reason', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.reject', $order), [
            'owner_note' => 'The set is already reserved for that date.',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    $order->refresh();

    expect($order->status)->toBe(RentalOrderStatus::Rejected)
        ->and($order->owner_note)->toBe('The set is already reserved for that date.')
        ->and($order->decided_at)->not->toBeNull();
});

test('owner cannot decide another owner order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($otherOwner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($otherOwner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'owner_note' => 'Unauthorized approval.',
        ])
        ->assertNotFound();

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('owner cannot decide an order more than once', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.reject', $order), [
            'owner_note' => 'Changed after approval.',
        ])
        ->assertForbidden();

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Approved);
});
