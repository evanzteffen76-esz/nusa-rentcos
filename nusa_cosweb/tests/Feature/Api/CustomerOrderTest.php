<?php

use App\Enums\PaymentMethod;
use App\Enums\RentalOrderStatus;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

function customerApiToken(User $user): string
{
    return $user->createToken('customer-test')->plainTextToken;
}

test('a customer can browse the published catalog', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $published = Costume::factory()->published()->for($owner, 'owner')->create(['name' => 'Published Mobile Set']);
    Costume::factory()->for($owner, 'owner')->create(['is_published' => false]);

    $this->withToken(customerApiToken($customer))
        ->getJson(route('api.v1.costumes.index'))
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $published->id)
        ->assertJsonPath('data.0.name', 'Published Mobile Set');

    $this->withToken(customerApiToken($customer))
        ->getJson(route('api.v1.costumes.show', $published))
        ->assertOk()
        ->assertJsonPath('data.id', $published->id)
        ->assertJsonPath('data.name', 'Published Mobile Set');
});

test('a customer can create a booking through the API', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'price_per_day' => 90000,
        'extra_price_per_day' => 20000,
        'stock' => 2,
    ]);

    $response = $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.store', $costume), [
            'quantity' => 2,
            'rental_start' => today()->addDays(5)->toDateString(),
            'rental_end' => today()->addDays(7)->toDateString(),
            'payment_method' => PaymentMethod::PayAtOwner->value,
            'customer_note' => 'Mobile booking.',
        ]);

    $response->assertCreated()
        ->assertJsonPath('data.status', RentalOrderStatus::Pending->value)
        ->assertJsonPath('data.quantity', 2)
        ->assertJsonPath('data.total_price', 180000)
        ->assertJsonPath('data.requested_rental_start', today()->addDays(5)->toDateString())
        ->assertJsonPath('data.payment_method', PaymentMethod::PayAtOwner->value)
        ->assertJsonPath('data.is_paid_at_owner', true)
        ->assertJsonPath('data.is_paid_by_transfer', false);

    $this->assertDatabaseHas('rental_orders', [
        'customer_id' => $customer->id,
        'costume_id' => $costume->id,
        'total_price' => 180000,
        'payment_method' => PaymentMethod::PayAtOwner->value,
    ]);

    // A pay-at-owner booking is settled in cash against a unique code.
    expect($response->json('data.payment_code'))
        ->toStartWith('COSPAY-');
});

test('a customer must choose a payment method when booking', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDay()->toDateString(),
            'rental_end' => today()->addDays(2)->toDateString(),
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors('payment_method');
});

test('a bank transfer booking stores the receipt and exposes the owner bank details', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'Bank Nusantara',
        'bank_account_number' => '1234567890',
        'bank_account_holder' => 'CosplayNusa Studio',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $response = $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDay()->toDateString(),
            'rental_end' => today()->addDays(3)->toDateString(),
            'payment_method' => PaymentMethod::BankTransfer->value,
            'payment_proof' => UploadedFile::fake()->create('transfer.png', 40, 'image/png'),
        ]);

    $response->assertCreated()
        ->assertJsonPath('data.payment_method', PaymentMethod::BankTransfer->value)
        ->assertJsonPath('data.is_paid_by_transfer', true)
        ->assertJsonPath('data.has_payment_proof', true)
        ->assertJsonPath('data.can_view_payment_proof', true)
        ->assertJsonPath('data.owner_bank.bank_name', 'Bank Nusantara')
        ->assertJsonPath('data.owner_bank.is_complete', true);

    // A transfer never mints a cash payment code.
    expect($response->json('data.payment_code'))->toBeNull();

    $order = RentalOrder::query()->latest('id')->firstOrFail();
    Storage::disk('local')->assertExists($order->payment_proof_path);
});

test('a bank transfer booking is rejected without a receipt', function (): void {
    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'Bank Nusantara',
        'bank_account_number' => '1234567890',
        'bank_account_holder' => 'CosplayNusa Studio',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDay()->toDateString(),
            'rental_end' => today()->addDays(3)->toDateString(),
            'payment_method' => PaymentMethod::BankTransfer->value,
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors('payment_proof');
});

test('a bank transfer booking is rejected when the owner has no bank account', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDay()->toDateString(),
            'rental_end' => today()->addDays(3)->toDateString(),
            'payment_method' => PaymentMethod::BankTransfer->value,
            'payment_proof' => UploadedFile::fake()->create('transfer.png', 40, 'image/png'),
        ])
        ->assertStatus(422)
        ->assertJsonValidationErrors('payment_method');
});

test('a customer cannot list another customer order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for($otherCustomer, 'customer')->for($costume, 'costume')->create();

    $this->withToken(customerApiToken($customer))
        ->getJson(route('api.v1.customer.orders.show', $order))
        ->assertNotFound();
});

test('a customer can submit a return and a lost-costume report', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $returnOrder = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create([
        'rental_start' => today()->subDays(5),
        'rental_end' => today()->subDays(3),
        'return_due_at' => today()->subDays(2),
    ]);
    $lostOrder = RentalOrder::factory()->approved()->for($owner, 'owner')->for($customer, 'customer')->for($costume, 'costume')->create();

    $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.return', $returnOrder), [
            'return_note' => 'Returned safely.',
        ])->assertOk()
        ->assertJsonPath('data.status', RentalOrderStatus::Returned->value)
        ->assertJsonPath('data.returned_late', true);

    $this->withToken(customerApiToken($customer))
        ->postJson(route('api.v1.customer.orders.loss-report', $lostOrder), [
            'description' => 'Lost at the venue.',
            'replacement_cost' => 450000,
            'replacement_proof' => UploadedFile::fake()->create('replacement.pdf', 120, 'application/pdf'),
        ])->assertCreated()
        ->assertJsonPath('data.issue.type', 'lost')
        ->assertJsonPath('data.issue.replacement_cost', 450000);
});

test('an owner cannot use customer order endpoints', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()->for($owner, 'owner')->for(User::factory(), 'customer')->for($costume, 'costume')->create();

    $this->withToken($owner->createToken('owner-test')->plainTextToken)
        ->getJson(route('api.v1.customer.orders.index'))
        ->assertForbidden();
});

test('the customer can download their own transfer receipt', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => $path = 'rental-orders/payments/receipt.pdf',
        ]);

    Storage::disk('local')->put($path, 'receipt-body');

    $this->withToken(customerApiToken($customer))
        ->get(route('api.v1.customer.orders.payment-proof', $order))
        ->assertOk()
        ->assertDownload('receipt.pdf');
});

test('the owner can download the transfer receipt of their own order', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => $path = 'rental-orders/payments/receipt.pdf',
        ]);

    Storage::disk('local')->put($path, 'receipt-body');

    $this->withToken(ownerApiToken($owner))
        ->get(route('api.v1.owner.orders.payment-proof', $order))
        ->assertOk()
        ->assertDownload('receipt.pdf');
});

test('another owner cannot download the transfer receipt', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => 'rental-orders/payments/receipt.pdf',
        ]);

    Storage::disk('local')->put('rental-orders/payments/receipt.pdf', 'receipt-body');

    $this->withToken(ownerApiToken($otherOwner))
        ->get(route('api.v1.owner.orders.payment-proof', $order))
        ->assertNotFound();
});

test('a customer cannot download a receipt that belongs to someone else', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($otherCustomer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => 'rental-orders/payments/receipt.pdf',
        ]);

    Storage::disk('local')->put('rental-orders/payments/receipt.pdf', 'receipt-body');

    $this->withToken(customerApiToken($customer))
        ->get(route('api.v1.customer.orders.payment-proof', $order))
        ->assertNotFound();
});

test('a pay-at-owner order has no receipt to download', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->approved()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::PayAtOwner,
            'payment_code' => 'COSPAY-TEST-0001',
        ]);

    $this->withToken(customerApiToken($customer))
        ->get(route('api.v1.customer.orders.payment-proof', $order))
        ->assertNotFound();
});

test('cancelling a pending transfer booking discards the stored receipt', function (): void {
    Storage::fake('local');
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()->pending()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => $path = 'rental-orders/payments/receipt.pdf',
        ]);

    Storage::disk('local')->put($path, 'receipt-body');

    $this->withToken(customerApiToken($customer))
        ->deleteJson(route('api.v1.customer.orders.destroy', $order))
        ->assertOk();

    $this->assertDatabaseMissing('rental_orders', ['id' => $order->id]);
    Storage::disk('local')->assertMissing($path);
});
