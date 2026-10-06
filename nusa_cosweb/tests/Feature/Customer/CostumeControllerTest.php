<?php

use App\Models\Costume;
use App\Models\User;

test('redirects guests from the costume detail page to login', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->get(route('dashboard.costumes.show', $costume))
        ->assertRedirectToRoute('login');
});

test('customer opens the detail page of a published costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create([
        'name' => 'Nebula Witch Set',
        'images' => ['costumes/1/images/first.jpg', 'costumes/1/images/second.jpg'],
        'videos' => ['costumes/1/videos/spin.mp4'],
    ]);

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.show', $costume))
        ->assertOk()
        ->assertSee('Nebula Witch Set')
        ->assertSee(route('dashboard.costumes.book.create', $costume), false)
        ->assertSee('costumes/1/images/first.jpg')
        ->assertSee('costumes/1/images/second.jpg')
        ->assertSee('costumes/1/videos/spin.mp4');
});

test('customer cannot open an unpublished or empty costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $hidden = Costume::factory()->unpublished()->for($owner, 'owner')->create();
    $empty = Costume::factory()->published()->for($owner, 'owner')->create(['stock' => 0]);

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.show', $hidden))
        ->assertNotFound();

    $this->actingAs($customer)
        ->get(route('dashboard.costumes.show', $empty))
        ->assertNotFound();
});

test('catalog cards link to the detail page without the owner price caption', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $customer = User::factory()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $response = $this->actingAs($customer)
        ->get(route('dashboard'));

    $response
        ->assertOk()
        ->assertSee(route('dashboard.costumes.show', $costume), false)
        ->assertDontSee(__('owner.costumes.price'));
});
