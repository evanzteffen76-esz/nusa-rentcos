<?php

use App\Enums\PaymentMethod;
use App\Models\Costume;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

test('pay at owner booking receives a unique payment code', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(5)->toDateString(),
            'payment_method' => 'pay_at_owner',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('dashboard');

    $order = RentalOrder::query()->firstOrFail();

    expect($order->payment_method)->toBe(PaymentMethod::PayAtOwner)
        ->and($order->payment_code)->toStartWith('COSPAY-')
        ->and($order->payment_code)->toHaveLength(16)
        ->and($order->payment_proof_path)->toBeNull();

    $second = $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(8)->toDateString(),
            'rental_end' => today()->addDays(10)->toDateString(),
            'payment_method' => 'pay_at_owner',
        ]);

    $second->assertSessionHasNoErrors();

    expect(RentalOrder::query()->count())->toBe(2)
        ->and(RentalOrder::query()->pluck('payment_code')->unique())->toHaveCount(2);
});

test('bank transfer booking stores the payment proof privately', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'BCA',
        'bank_account_number' => '1234567890',
        'bank_account_holder' => 'Luna Starweaver',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(5)->toDateString(),
            'payment_method' => 'bank_transfer',
            'payment_proof' => UploadedFile::fake()->image('transfer.png'),
        ])
        ->assertSessionHasNoErrors();

    $order = RentalOrder::query()->firstOrFail();

    expect($order->payment_method)->toBe(PaymentMethod::BankTransfer)
        ->and($order->payment_code)->toBeNull()
        ->and($order->payment_proof_path)->not->toBeNull();

    Storage::disk('local')->assertExists($order->payment_proof_path);
});

test('bank transfer booking requires a payment proof', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'BCA',
        'bank_account_number' => '1234567890',
        'bank_account_holder' => 'Luna Starweaver',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(5)->toDateString(),
            'payment_method' => 'bank_transfer',
        ])
        ->assertSessionHasErrors('payment_proof');

    expect(RentalOrder::query()->count())->toBe(0);
});

test('bank transfer is unavailable when the owner has no bank details', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($customer)
        ->post(route('dashboard.costumes.book.store', $costume), [
            'quantity' => 1,
            'rental_start' => today()->addDays(3)->toDateString(),
            'rental_end' => today()->addDays(5)->toDateString(),
            'payment_method' => 'bank_transfer',
            'payment_proof' => UploadedFile::fake()->image('transfer.png'),
        ])
        ->assertSessionHasErrors('payment_method');

    expect(RentalOrder::query()->count())->toBe(0);
});

test('booking form offers both payment methods and the owner bank details', function (): void {
    $owner = User::factory()->cosrentOwner()->create([
        'bank_name' => 'Mandiri',
        'bank_account_number' => '9876543210',
        'bank_account_holder' => 'Luna Starweaver',
    ]);
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $response = $this->actingAs($customer)
        ->get(route('dashboard.costumes.book.create', $costume));

    $response
        ->assertOk()
        ->assertSee('name="payment_method"', false)
        ->assertSee('value="pay_at_owner"', false)
        ->assertSee('value="bank_transfer"', false)
        ->assertSee('name="payment_proof"', false)
        ->assertSee('accept=".jpg,.jpeg,.png,.webp,.pdf"', false)
        ->assertSee('x-on:submit="if (! paymentReady()) $event.preventDefault()"', false)
        ->assertSee(__('customer.payment.proof_required_badge'))
        ->assertSee('9876543210')
        ->assertSee('Mandiri')
        ->assertSee('Luna Starweaver');

    $transferCard = Str::after($response->getContent(), 'value="bank_transfer"');
    $transferCard = Str::before($transferCard, '</label>');

    expect($transferCard)
        ->toContain('9876543210')
        ->toContain('Mandiri')
        ->toContain('Luna Starweaver');
});

test('owner reviews the payment method, code and proof before approving', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => 'rental-orders/payments/transfer.png',
        ]);

    Storage::disk('local')->put('rental-orders/payments/transfer.png', 'proof');

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $order))
        ->assertOk()
        ->assertSee(__('customer.payment.method_bank_transfer'))
        ->assertSee(__('customer.payment.proof_view'))
        ->assertSee(route('cosrent-owner.orders.payment-proof', $order), false);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.payment-proof', $order))
        ->assertOk();

    $this->actingAs($customer)
        ->get(route('cosrent-owner.orders.payment-proof', $order))
        ->assertNotFound();
});

test('pay at owner order shows the code to both customer and owner', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::PayAtOwner,
            'payment_code' => 'COSPAY-AB2C-9XYZ',
        ]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $order))
        ->assertOk()
        ->assertSee('COSPAY-AB2C-9XYZ');

    $this->actingAs($customer)
        ->get(route('dashboard'))
        ->assertOk()
        ->assertSee('COSPAY-AB2C-9XYZ');
});

test('owner must enter the matching code before approving a pay at owner order', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create(['stock' => 5]);
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'quantity' => 1,
            'payment_method' => PaymentMethod::PayAtOwner,
            'payment_code' => 'COSPAY-AB2C-9XYZ',
        ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order))
        ->assertSessionHasErrors('payment_code');

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'payment_code' => 'COSPAY-WRONG-CODE',
        ])
        ->assertSessionHasErrors('payment_code');

    expect($order->refresh()->isPending())->toBeTrue();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order), [
            'payment_code' => 'cospay-ab2c-9xyz',
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.orders.show', $order);

    expect($order->refresh()->isApproved())->toBeTrue();
});

test('owner may approve a bank transfer order without a code', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create(['stock' => 5]);
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'quantity' => 1,
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => 'rental-orders/payments/proof.png',
        ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.orders.approve', $order))
        ->assertSessionHasNoErrors();

    expect($order->refresh()->isApproved())->toBeTrue();
});

test('owner order page asks for the code only on pay at owner orders', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $payAtOwner = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::PayAtOwner,
            'payment_code' => 'COSPAY-AB2C-9XYZ',
        ]);

    $transfer = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['payment_method' => PaymentMethod::BankTransfer]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $payAtOwner))
        ->assertOk()
        ->assertSee('name="payment_code"', false)
        ->assertSee('COSPAY-AB2C-9XYZ');

    $this->actingAs($owner)
        ->get(route('cosrent-owner.orders.show', $transfer))
        ->assertOk()
        ->assertDontSee('name="payment_code"', false);
});

test('customer can review the payment proof they submitted while the order is pending', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $otherCustomer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create([
            'payment_method' => PaymentMethod::BankTransfer,
            'payment_proof_path' => 'rental-orders/payments/transfer.png',
        ]);

    Storage::disk('local')->put('rental-orders/payments/transfer.png', 'proof');

    $this->actingAs($customer)
        ->get(route('dashboard'))
        ->assertOk()
        ->assertSee(route('dashboard.orders.payment-proof', $order), false);

    $this->actingAs($customer)
        ->get(route('dashboard.orders.payment-proof', $order))
        ->assertOk();

    $this->actingAs($otherCustomer)
        ->get(route('dashboard.orders.payment-proof', $order))
        ->assertNotFound();
});

test('customer payment proof download is not found when nothing was uploaded', function (): void {
    Storage::fake('local');

    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();
    $order = RentalOrder::factory()
        ->for($owner, 'owner')
        ->for($customer, 'customer')
        ->for($costume, 'costume')
        ->create(['payment_method' => PaymentMethod::PayAtOwner]);

    $this->actingAs($customer)
        ->get(route('dashboard.orders.payment-proof', $order))
        ->assertNotFound();
});

test('booking form keeps the alpine state intact inside the attribute', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $html = $this->actingAs($customer)
        ->get(route('dashboard.costumes.book.create', $costume))
        ->getContent();

    $document = new DOMDocument;
    @$document->loadHTML($html);
    $xpath = new DOMXPath($document);

    $state = collect($xpath->query('//*[@x-data]'))
        ->map(fn (DOMElement $node): string => trim($node->getAttribute('x-data')))
        ->first(fn (string $value): bool => str_contains($value, 'paymentMethod'));

    expect($state)
        ->not->toBeNull()
        ->toStartWith('{')
        ->toEndWith('}')
        ->toContain('paymentMethod')
        ->toContain('paymentReady')
        ->toContain('onProofSelected')
        ->toContain('formatPrice')
        ->toContain('quantity:');
});

test('owner profile shows the bank account fields', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();

    $this->actingAs($owner)
        ->get(route('profile.edit'))
        ->assertOk()
        ->assertSee('name="bank_name"', false)
        ->assertSee('name="bank_account_number"', false)
        ->assertSee('name="bank_account_holder"', false);

    $this->actingAs($customer)
        ->get(route('profile.edit'))
        ->assertOk()
        ->assertDontSee('name="bank_name"', false);
});

test('owner bank details are required for a cosrent owner profile update', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->patch(route('profile.update'), [
            'name' => $owner->name,
            'email' => $owner->email,
        ])
        ->assertSessionHasErrors(['bank_name', 'bank_account_number', 'bank_account_holder']);

    $this->actingAs($owner)
        ->patch(route('profile.update'), [
            'name' => $owner->name,
            'email' => $owner->email,
            'bank_name' => 'BRI',
            'bank_account_number' => '1122334455',
            'bank_account_holder' => 'Luna Starweaver',
        ])
        ->assertSessionHasNoErrors();

    expect($owner->refresh())
        ->bank_name->toBe('BRI')
        ->bank_account_number->toBe('1122334455')
        ->bank_account_holder->toBe('Luna Starweaver');
});
