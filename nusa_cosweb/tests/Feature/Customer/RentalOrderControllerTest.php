<?php

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;

test('redirects guests from booking to login', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->post(route('dashboard.costumes.book.store', $costume), [])
        ->assertRedirectToRoute('login');
});

test('forbids a Cosrent Owner from placing a customer booking', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($otherOwner, 'owner')->create();

    $this->actingAs($owner)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(4)->toDateString(),
        ])
        ->assertForbidden();
});

test('customer creates a booking with a server calculated total', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 75000,
        'extra_price_per_day' => 20000,
        'stock' => 2,
    ]);
    $rentalStart = today()->addDays(5)->toDateString();
    $rentalEnd = today()->addDays(7)->toDateString();

    $response = $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 2,
            'rental_start' => $rentalStart,
            'rental_end' => $rentalEnd,
            'payment_method' => 'pay_at_owner',
            'customer_note' => 'Photoshoot in Bandung.',
        ]);

    $response
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('dashboard')
        ->assertSessionHas('status');

    $order = RentalOrder::query()->firstOrFail();

    $this->assertModelExists($order);

    expect($order)
        ->owner_id->toBe($owner->id)
        ->customer_id->toBe($customer->id)
        ->costume_id->toBe($costume->id)
        ->quantity->toBe(2)
        ->total_price->toBe(150000)
        ->status->toBe(RentalOrderStatus::Pending)
        ->customer_note->toBe('Photoshoot in Bandung.');
});

test('customer receives validation errors for invalid booking dates and quantity', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 0,
            'rental_start' => today()->addDays(5)->toDateString(),
            'rental_end' => today()->addDay()->toDateString(),
            'payment_method' => 'pay_at_owner',
        ])
        ->assertSessionHasErrors(['quantity', 'rental_end']);

    expect(RentalOrder::query()->count())->toBe(0);
});

test('customer cannot request quantity beyond an approved booking range', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $approvedCustomer = User::factory()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create(['stock' => 1]);
    $rentalStart = today()->addDays(8)->toDateString();
    $rentalEnd = today()->addDays(9)->toDateString();

    RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($approvedCustomer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'rental_start' => $rentalStart,
            'rental_end' => $rentalEnd,
            'quantity' => 1,
        ]);

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => $rentalStart,
            'rental_end' => $rentalEnd,
            'payment_method' => 'pay_at_owner',
        ])
        ->assertSessionHasErrors('quantity');

    expect(RentalOrder::query()->count())->toBe(1);
});

test('customer can open the booking form for a published costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'name' => 'Nebula Witch Set',
        'stock' => 2,
    ]);

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.book.create', $costume))
        ->assertOk()
        ->assertViewIs('customer.booking.create')
        ->assertSee('Nebula Witch Set')
        ->assertSee('form');
});

test('unpublished costume booking page is not found', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->unpublished()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.book.create', $costume))
        ->assertNotFound();
});

test('customer dashboard only lists published in-stock costumes', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $publishedCostume = Costume::factory()->published()->for($owner, 'owner')->create([
        'name' => 'Published Set',
    ]);
    Costume::factory()->unpublished()->for($owner, 'owner')->create([
        'name' => 'Hidden Draft Set',
    ]);
    Costume::factory()->published()->for($owner, 'owner')->create([
        'name' => 'Sold Out Set',
        'stock' => 0,
    ]);

    $this->actingAs($customer)
        ->get(route('dashboard'))
        ->assertOk()
        ->assertViewIs('customer.dashboard')
        ->assertSee($publishedCostume->name)
        ->assertDontSee('Hidden Draft Set')
        ->assertDontSee('Sold Out Set');
});

test('owner is redirected away from the customer booking dashboard', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->get(route('dashboard'))
        ->assertRedirectToRoute('cosrent-owner.dashboard');
});
