<?php

use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Support\Facades\Gate;

test('owner can decide only pending orders assigned to them', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $otherCostume = Costume::factory()->for($otherOwner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $otherOrder = RentalOrder::factory()->pending()->for($otherOwner, 'owner')->for($customer, 'customer')->for($otherCostume, 'costume')->create();
    $approvedOrder = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    expect(Gate::forUser($owner)->allows('viewAny', RentalOrder::class))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('view', $order))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('approve', $order))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('reject', $order))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('view', $otherOrder))->toBeFalse()
        ->and(Gate::forUser($owner)->allows('approve', $approvedOrder))->toBeFalse();
});

test('only non-admin customers can create bookings', function (): void {
    $customer = User::factory()->create();
    $owner = User::factory()->cosrentOwner()->create();
    $admin = User::factory()->admin()->create();

    expect(Gate::forUser($customer)->allows('create', RentalOrder::class))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('create', RentalOrder::class))->toBeFalse()
        ->and(Gate::forUser($admin)->allows('create', RentalOrder::class))->toBeFalse();
});

test('customer return and loss permissions are limited to the order owner', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $otherOrder = RentalOrder::factory()->approved()->for($owner, 'owner')->for($otherCustomer, 'customer')->for($costume, 'costume')->create();

    expect(Gate::forUser($customer)->allows('returnOrder', $order))->toBeTrue()
        ->and(Gate::forUser($customer)->allows('reportLostCostume', $order))->toBeTrue()
        ->and(Gate::forUser($customer)->allows('returnOrder', $otherOrder))->toBeFalse()
        ->and(Gate::forUser($owner)->allows('returnOrder', $order))->toBeFalse();
});

test('owner issue permissions require a returned order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $approvedOrder = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $returnedOrder = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    expect(Gate::forUser($owner)->allows('reportStain', $approvedOrder))->toBeFalse()
        ->and(Gate::forUser($owner)->allows('reportStain', $returnedOrder))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('completeReturn', $returnedOrder))->toBeTrue();
});
