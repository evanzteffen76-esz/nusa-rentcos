<?php

use App\Enums\RentalIssueStatus;
use App\Enums\RentalIssueType;
use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

test('customer can open the lost-costume report form', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->get(route('dashboard.orders.loss-report.create', $order))
        ->assertOk()
        ->assertViewIs('customer.issues.create')
        ->assertSee(__('customer.issues.replacement_required'));
});

test('customer reports a lost costume with replacement proof', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.orders.loss-report.store', $order), [
            'description' => 'Kostum tertinggal di venue setelah pemotretan.',
            'replacement_cost' => 350000,
            'replacement_proof' => UploadedFile::fake()->create('replacement.pdf', 120, 'application/pdf'),
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('dashboard')
        ->assertSessionHas('status');

    $issue = RentalIssue::query()->firstOrFail();

    expect($issue->type)->toBe(RentalIssueType::Lost)
        ->and($issue->status)->toBe(RentalIssueStatus::Open)
        ->and($issue->replacement_cost)->toBe(350000)
        ->and($issue->replacement_submitted_at)->not->toBeNull()
        ->and($order->refresh()->status)->toBe(RentalOrderStatus::Approved);

    Storage::disk('local')->assertExists($issue->evidence_path);
});

test('lost costume report requires replacement proof', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.orders.loss-report.store', $order), [
            'description' => 'Kostum hilang.',
            'replacement_cost' => 350000,
        ])
        ->assertSessionHasErrors('replacement_proof');

    expect(RentalIssue::query()->count())->toBe(0);
});

test('lost costume report rejects a zero replacement cost', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.orders.loss-report.store', $order), [
            'description' => 'Kostum hilang.',
            'replacement_cost' => 0,
            'replacement_proof' => UploadedFile::fake()->create('replacement.pdf', 120, 'application/pdf'),
        ])
        ->assertSessionHasErrors('replacement_cost');

    expect(RentalIssue::query()->count())->toBe(0);
});

test('customer cannot report a lost costume after returning it', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->get(route('dashboard.orders.loss-report.create', $order))
        ->assertForbidden();
});

test('customer cannot report loss for another customer order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($otherCustomer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($customer)
        ->get(route('dashboard.orders.loss-report.create', $order))
        ->assertNotFound();
});
