<?php

use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;

test('the first three days are included and every day after that costs the extra rate', function (): void {
    expect(RentalOrder::priceFor(100000, 20000, 1, 1))->toBe(100000)
        ->and(RentalOrder::priceFor(100000, 20000, 3, 1))->toBe(100000)
        ->and(RentalOrder::priceFor(100000, 20000, 4, 1))->toBe(120000)
        ->and(RentalOrder::priceFor(100000, 20000, 6, 1))->toBe(160000);
});

test('the extra charge scales with the quantity', function (): void {
    expect(RentalOrder::priceFor(100000, 20000, 5, 2))->toBe(280000)
        ->and(RentalOrder::extraDaysFor(1))->toBe(0)
        ->and(RentalOrder::extraDaysFor(3))->toBe(0)
        ->and(RentalOrder::extraDaysFor(4))->toBe(1)
        ->and(RentalOrder::extraDaysFor(9))->toBe(6);
});

test('a rental period always counts at least one day', function (): void {
    expect(RentalOrder::daysBetween('2026-10-01', '2026-10-01'))->toBe(1)
        ->and(RentalOrder::daysBetween('2026-10-01', '2026-10-03'))->toBe(3)
        ->and(RentalOrder::daysBetween('2026-10-01', '2026-10-04'))->toBe(4);
});

test('customer booking beyond the included period is priced with the extra rate', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 2,
            'rental_start' => today()->addDays(5)->toDateString(),
            // Six inclusive days: 3 included + 3 extra days.
            'rental_end' => today()->addDays(10)->toDateString(),
            'payment_method' => 'pay_at_owner',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('dashboard');

    $order = RentalOrder::query()->firstOrFail();

    expect($order->durationInDays())->toBe(6)
        ->and($order->extraDays())->toBe(3)
        ->and($order->includedFeeTotal())->toBe(200000)
        ->and($order->extraFeeTotal())->toBe(120000)
        // (100.000 + 3 x 20.000) x 2
        ->and($order->total_price)->toBe(320000);
});

test('owner approves a longer rental and charges the extra days', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 2]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'rental_days' => 5,
            'owner_note' => 'Keep it for the weekend.',
        ])
        ->assertSessionHasNoErrors();

    $order->refresh();

    expect($order->status)->toBe(RentalOrderStatus::Approved)
        ->and($order->rental_end->toDateString())->toBe(today()->addDays(4)->toDateString())
        ->and($order->return_due_at->toDateString())->toBe(today()->addDays(5)->toDateString())
        ->and($order->durationInDays())->toBe(5)
        ->and($order->extraDays())->toBe(2)
        // (100.000 + 2 x 20.000) x 2
        ->and($order->total_price)->toBe(280000);
});

test('approving without a length falls back to the included period', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 2]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order))
        ->assertSessionHasNoErrors();

    $order->refresh();

    expect($order->durationInDays())->toBe(RentalOrder::INCLUDED_RENTAL_DAYS)
        ->and($order->extraDays())->toBe(0)
        ->and($order->total_price)->toBe(200000);
});

test('an approval length below the included period is rejected', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'rental_days' => RentalOrder::INCLUDED_RENTAL_DAYS - 1,
        ])
        ->assertSessionHasErrors('rental_days');

    expect($order->fresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('an approval length beyond the maximum is rejected', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'rental_days' => RentalOrder::MAX_RENTAL_DAYS + 1,
        ])
        ->assertSessionHasErrors('rental_days');

    expect($order->fresh()->status)->toBe(RentalOrderStatus::Pending);
});

test('changing the costume rate later never rewrites an approved order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 1]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), ['rental_days' => 5])
        ->assertSessionHasNoErrors();

    $costume->update([
        'price_per_day' => 500000,
        'extra_price_per_day' => 90000,
    ]);

    $order->refresh();

    expect($order->price_per_day)->toBe(100000)
        ->and($order->extra_price_per_day)->toBe(20000)
        ->and($order->total_price)->toBe(140000)
        ->and($order->extraFeeTotal())->toBe(40000);
});

test('a costume without an extra rate never charges beyond the included period', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 0,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 2]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), ['rental_days' => 10])
        ->assertSessionHasNoErrors();

    $order->refresh();

    expect($order->durationInDays())->toBe(10)
        ->and($order->extraDays())->toBe(7)
        ->and($order->extraFeeTotal())->toBe(0)
        ->and($order->total_price)->toBe(200000);
});

test('the owner costume form exposes both the base and the extra rate field', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->get(route('cosrent-owner.costumes.create'))
        ->assertOk()
        ->assertSee('name="price_per_day"', false)
        ->assertSee('name="extra_price_per_day"', false);
});

test('the booking form renders the extra rate for a costume that charges one', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 100000,
        'extra_price_per_day' => 25000,
    ]);

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.book.create', $costume))
        ->assertOk()
        ->assertSee('extraPricePerDay: 25000', false);
});

test('the owner order page shows the rental length control and the extra charge', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 1]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $order))
        ->assertOk()
        ->assertSee('name="rental_days"', false);
});

test('the API costume payload exposes the extra rate', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 100000,
        'extra_price_per_day' => 25000,
    ]);

    $this->withToken(ownerApiToken($owner))
        ->getJson(route('api.v1.owner.costumes.show', $costume))
        ->assertOk()
        ->assertJsonPath('data.price_per_day', 100000)
        ->assertJsonPath('data.extra_price_per_day', 25000);
});

test('the API order payload exposes the extra day breakdown', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'stock' => 3,
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
    ]);
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['quantity' => 2]);

    $this->withToken(ownerApiToken($owner))
        ->patchJson(route('api.v1.owner.orders.approve', $order), ['rental_days' => 5])
        ->assertOk()
        ->assertJsonPath('data.duration_in_days', 5)
        ->assertJsonPath('data.extra_days', 2)
        ->assertJsonPath('data.price_per_day', 100000)
        ->assertJsonPath('data.extra_price_per_day', 20000)
        ->assertJsonPath('data.included_fee_total', 200000)
        ->assertJsonPath('data.extra_fee_total', 80000)
        ->assertJsonPath('data.included_rental_days', RentalOrder::INCLUDED_RENTAL_DAYS)
        ->assertJsonPath('data.total_price', 280000);
});
