<?php

use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;

test('redirects guests to the login page', function (): void {
    $this->get(route('cosrent-owner.dashboard'))
        ->assertRedirectToRoute('login');
});

test('forbids authenticated users without Cosrent Owner access', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('cosrent-owner.dashboard'))
        ->assertForbidden();
});

test('renders owner metrics and only the current owner records', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create(['name' => 'Owned Customer']);
    $otherCustomer = User::factory()->create(['name' => 'Other Customer']);
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $otherCostume = Costume::factory()->for($otherOwner, 'owner')->create();

    RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['total_price' => 175000]);

    RentalOrder::factory()->pending()
        ->for($otherOwner, 'owner')
        ->for($otherCustomer, 'customer')
        ->for($otherCostume, 'costume')
        ->create();

    $response = $this->actingAs($owner)
        ->get(route('cosrent-owner.dashboard'));

    $response
        ->assertOk()
        ->assertViewIs('owner.dashboard')
        ->assertViewHas('totalCostumes', 1)
        ->assertViewHas('publishedCostumes', 1)
        ->assertViewHas('pendingOrderCount', 1)
        ->assertViewHas('approvedOrderCount', 0)
        ->assertViewHas('approvedRevenue', 0)
        ->assertSee('Owned Customer')
        ->assertDontSee('Other Customer');
});

test('escapes the owner name on the dashboard', function (): void {
    $owner = User::factory()->cosrentOwner()->create([
        'name' => '<script>alert("x")</script>',
    ]);

    $response = $this->actingAs($owner)
        ->get(route('cosrent-owner.dashboard'));

    $response
        ->assertOk()
        ->assertSee('&lt;script&gt;', false)
        ->assertDontSee('<script>alert("x")</script>', false);
});
