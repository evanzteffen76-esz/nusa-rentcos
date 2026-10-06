<?php

use App\Enums\RentalIssueStatus;
use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

function ownerApiToken(User $user): string
{
    return $user->createToken('owner-test')->plainTextToken;
}

test('an owner can list only their own orders', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $otherCostume = Costume::factory()->for($otherOwner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    RentalOrder::factory()->pending()->for($otherOwner, 'owner')->for($customer, 'customer')->for($otherCostume, 'costume')->create();

    $this->withToken(ownerApiToken($owner))
        ->getJson(route('api.v1.owner.orders.index'))
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $order->id);
});

test('an owner can approve an order and receives the fixed rental schedule', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 100000,
        'extra_price_per_day' => 20000,
        'stock' => 2,
    ]);
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'quantity' => 2,
    ]);

    $this->withToken(ownerApiToken($owner))
        ->patchJson(route('api.v1.owner.orders.approve', $order), [
            'owner_note' => 'Pickup at 10:00.',
        ])->assertOk()
        ->assertJsonPath('data.status', RentalOrderStatus::Approved->value)
        ->assertJsonPath('data.rental_start', today()->toDateString())
        ->assertJsonPath('data.rental_end', today()->addDays(2)->toDateString())
        ->assertJsonPath('data.return_due_at', today()->addDays(3)->toDateString())
        ->assertJsonPath('data.total_price', 200000);
});

test('an owner must provide a note when rejecting an order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->withToken(ownerApiToken($owner))
        ->patchJson(route('api.v1.owner.orders.reject', $order))
        ->assertUnprocessable()
        ->assertJsonValidationErrors('owner_note');

    $this->withToken(ownerApiToken($owner))
        ->patchJson(route('api.v1.owner.orders.reject', $order), [
            'owner_note' => 'The costume is unavailable.',
        ])->assertOk()
        ->assertJsonPath('data.status', RentalOrderStatus::Rejected->value);
});

test('an owner can report and resolve a stain issue', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $token = ownerApiToken($owner);

    $this->withToken($token)
        ->postJson(route('api.v1.owner.issues.store', $order), [
            'description' => 'Red stain on the sleeve.',
            'fine_amount' => 75000,
            'evidence' => UploadedFile::fake()->create('stain.jpg', 120, 'image/jpeg'),
        ])->assertCreated()
        ->assertJsonPath('data.issue.type', 'stain')
        ->assertJsonPath('data.issue.status', RentalIssueStatus::Open->value);

    $issue = RentalIssue::query()->firstOrFail();

    $this->withToken($token)
        ->getJson(route('api.v1.owner.issues.evidence', [$order, $issue]))
        ->assertOk();

    $this->withToken($token)
        ->patchJson(route('api.v1.owner.issues.resolve', [$order, $issue]), [
            'fine_paid' => true,
            'resolution_note' => 'Paid by bank transfer.',
        ])->assertOk()
        ->assertJsonPath('data.status', RentalOrderStatus::Completed->value)
        ->assertJsonPath('data.issue.status', RentalIssueStatus::Resolved->value);
});

test('an owner can complete a clean return', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->withToken(ownerApiToken($owner))
        ->patchJson(route('api.v1.owner.orders.complete', $order))
        ->assertOk()
        ->assertJsonPath('data.status', RentalOrderStatus::Completed->value);
});
