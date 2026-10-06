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

test('guests are redirected before an owner reports an issue', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->post(route('cosrent-owner.orders.issues.store', $order))
        ->assertRedirectToRoute('login');
});

test('owner reports a stain with evidence and a fine', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->post(route('cosrent-owner.orders.issues.store', $order), [
            'description' => 'Noda merah ditemukan di bagian lengan.',
            'fine_amount' => 75000,
            'evidence' => UploadedFile::fake()->create('stain.jpg', 120, 'image/jpeg'),
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    $issue = RentalIssue::query()->firstOrFail();

    $this->get(route('cosrent-owner.orders.show', $order))
        ->assertOk()
        ->assertSee(__('owner.issues.view_evidence'))
        ->assertSee($issue->description);

    expect($issue->type)->toBe(RentalIssueType::Stain)
        ->and($issue->status)->toBe(RentalIssueStatus::Open)
        ->and($issue->fine_amount)->toBe(75000)
        ->and($issue->evidence_path)->not->toBeNull();

    Storage::disk('local')->assertExists($issue->evidence_path);
});

test('owner can download private evidence for an issue', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    Storage::disk('local')->put('rental-issues/stains/evidence.jpg', 'private evidence');
    $issue = RentalIssue::factory()->stain()->for($order, 'rentalOrder')->for($owner, 'reporter')->create([
        'evidence_path' => 'rental-issues/stains/evidence.jpg',
    ]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.issues.evidence', [$order, $issue]))
        ->assertOk()
        ->assertDownload('evidence.jpg');
});

test('owner cannot report a stain before the customer returns', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->post(route('cosrent-owner.orders.issues.store', $order), [
            'description' => 'Noda ditemukan.',
            'fine_amount' => 50000,
            'evidence' => UploadedFile::fake()->create('stain.jpg', 120, 'image/jpeg'),
        ])
        ->assertForbidden();
});

test('stain issue cannot be resolved until the fine is marked paid', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $issue = RentalIssue::factory()->stain()->for($order, 'rentalOrder')->for($owner, 'reporter')->create([
        'fine_amount' => 50000,
    ]);

    $this->actingAs($owner)
        ->from(route('cosrent-owner.orders.show', $order))
        ->patch(route('cosrent-owner.orders.issues.resolve', [$order, $issue]), [])
        ->assertSessionHasErrors('fine_paid');

    expect($issue->refresh()->status)->toBe(RentalIssueStatus::Open)
        ->and($order->refresh()->status)->toBe(RentalOrderStatus::Returned);
});

test('owner resolves a stain after receiving the fine and completes the order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $issue = RentalIssue::factory()->stain()->for($order, 'rentalOrder')->for($owner, 'reporter')->create([
        'fine_amount' => 50000,
    ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.issues.resolve', [$order, $issue]), [
            'fine_paid' => '1',
            'resolution_note' => 'Pembayaran diterima via transfer.',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    expect($issue->refresh()->status)->toBe(RentalIssueStatus::Resolved)
        ->and($issue->fine_paid_at)->not->toBeNull()
        ->and($order->refresh()->status)->toBe(RentalOrderStatus::Completed);
});

test('lost costume issue is resolved after owner receives the replacement', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $issue = RentalIssue::factory()->lost()->for($order, 'rentalOrder')->for($customer, 'reporter')->create([
        'replacement_cost' => 350000,
    ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.issues.resolve', [$order, $issue]), [
            'replacement_received' => '1',
            'resolution_note' => 'Kostum pengganti sudah diterima owner.',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    expect($issue->refresh()->status)->toBe(RentalIssueStatus::Resolved)
        ->and($issue->replacement_received_at)->not->toBeNull()
        ->and($order->refresh()->status)->toBe(RentalOrderStatus::Completed);
});

test('owner can complete a clean return', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.complete', $order))
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    expect($order->refresh()->status)->toBe(RentalOrderStatus::Completed);
});

test('owner cannot complete a return while an issue is open', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    RentalIssue::factory()->stain()->for($order, 'rentalOrder')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.complete', $order))
        ->assertForbidden();
});

test('owner cannot resolve another owner issue', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->for($otherOwner, 'owner')->create();
    $order = RentalOrder::factory()->approved()->returned()->for($otherOwner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();
    $issue = RentalIssue::factory()->stain()->for($order, 'rentalOrder')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.issues.resolve', [$order, $issue]), [
            'fine_paid' => '1',
        ])
        ->assertNotFound();
});
