<?php

use App\Models\Costume;
use App\Models\User;
use Illuminate\Support\Facades\Gate;

test('Cosrent Owner can manage only their own costume listings', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $ownCostume = Costume::factory()->for($owner, 'owner')->create();
    $otherCostume = Costume::factory()->for($otherOwner, 'owner')->create();

    expect(Gate::forUser($owner)->allows('create', Costume::class))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('update', $ownCostume))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('delete', $ownCostume))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('update', $otherCostume))->toBeFalse()
        ->and(Gate::forUser($customer)->allows('create', Costume::class))->toBeFalse();
});
