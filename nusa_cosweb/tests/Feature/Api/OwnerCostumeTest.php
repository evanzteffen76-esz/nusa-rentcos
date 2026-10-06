<?php

use App\Http\Requests\Api\V1\SaveCostumeRequest;
use App\Models\Costume;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

function ownerCostumeApiToken(User $user): string
{
    return $user->createToken('owner-costume-test')->plainTextToken;
}

test('an owner can list only their own costume listings', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $ownCostume = Costume::factory()->for($owner, 'owner')->create();
    Costume::factory()->for($otherOwner, 'owner')->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->getJson(route('api.v1.owner.costumes.index'))
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $ownCostume->id);
});

test('an owner can create and update a costume listing', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $token = ownerCostumeApiToken($owner);

    $createResponse = $this->withToken($token)
        ->postJson(route('api.v1.owner.costumes.store'), [
            'name' => 'Mobile Fantasy Set',
            'character_name' => 'Luna',
            'category' => 'Fantasy',
            'size' => 'M',
            'description' => 'A complete mobile-friendly costume set.',
            'image_url' => 'https://example.com/costume.jpg',
            'price_per_day' => 90000,
            'extra_price_per_day' => 20000,
            'stock' => 3,
            'is_published' => true,
        ]);

    $createResponse->assertCreated()
        ->assertJsonPath('data.name', 'Mobile Fantasy Set')
        ->assertJsonPath('data.is_published', true);

    $costume = Costume::query()->firstOrFail();

    $this->withToken($token)
        ->patchJson(route('api.v1.owner.costumes.update', $costume), [
            'name' => 'Updated Fantasy Set',
            'character_name' => 'Luna',
            'category' => 'Fantasy',
            'size' => 'L',
            'price_per_day' => 100000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'is_published' => false,
        ])
        ->assertOk()
        ->assertJsonPath('data.name', 'Updated Fantasy Set')
        ->assertJsonPath('data.size', 'L')
        ->assertJsonPath('data.is_published', false);
});

test('an owner can delete their own costume listing', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->deleteJson(route('api.v1.owner.costumes.destroy', $costume))
        ->assertOk()
        ->assertJsonPath('message', 'Costume deleted successfully.');

    $this->assertSoftDeleted('costumes', ['id' => $costume->id]);
});

test('a customer cannot manage owner costumes', function (): void {
    $customer = User::factory()->create();
    $costume = Costume::factory()->create();

    $this->withToken(ownerCostumeApiToken($customer))
        ->getJson(route('api.v1.owner.costumes.index'))
        ->assertForbidden();

    $this->withToken(ownerCostumeApiToken($customer))
        ->patchJson(route('api.v1.owner.costumes.update', $costume), [])
        ->assertNotFound();
});

test('an owner cannot access another owner costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherCostume = Costume::factory()->for(User::factory()->cosrentOwner(), 'owner')->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->getJson(route('api.v1.owner.costumes.show', $otherCostume))
        ->assertNotFound();
});

test('an owner can upload and remove a costume gallery through the API', function (): void {
    Storage::fake(Costume::MEDIA_DISK);
    $owner = User::factory()->cosrentOwner()->create();
    $token = ownerCostumeApiToken($owner);

    $create = $this->withToken($token)
        ->post(route('api.v1.owner.costumes.store'), [
            'name' => 'Gallery Set',
            'character_name' => 'Nova',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 75000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'is_published' => true,
            'images' => [
                UploadedFile::fake()->image('front.jpg'),
                UploadedFile::fake()->image('back.jpg'),
            ],
        ], ['Accept' => 'application/json']);

    $create->assertCreated()
        ->assertJsonPath('data.image_count', 2)
        ->assertJsonPath('data.video_count', 0)
        ->assertJsonCount(2, 'data.image_urls')
        // With no cover URL supplied the first gallery image becomes the cover.
        ->assertJsonPath('data.cover_image_url', $create->json('data.image_urls.0'));

    $costume = Costume::query()->firstOrFail();
    expect($costume->images)->toHaveCount(2);
    Storage::disk(Costume::MEDIA_DISK)->assertExists($costume->images[0]);

    // Removing one image keeps the other and deletes only the flagged file.
    $removed = $costume->images[0];
    $kept = $costume->images[1];

    $update = $this->withToken($token)
        ->patch(route('api.v1.owner.costumes.update', $costume), [
            'name' => 'Gallery Set',
            'character_name' => 'Nova',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 75000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'remove_images' => [$removed],
            'images' => [UploadedFile::fake()->image('extra.png')],
        ], ['Accept' => 'application/json']);

    $update->assertOk()
        ->assertJsonPath('data.image_count', 2);

    $costume->refresh();
    Storage::disk(Costume::MEDIA_DISK)->assertExists($kept);
    Storage::disk(Costume::MEDIA_DISK)->assertMissing($removed);
    expect($costume->images)->toContain($kept);
});

test('a costume gallery upload beyond the image limit is rejected', function (): void {
    Storage::fake(Costume::MEDIA_DISK);
    $owner = User::factory()->cosrentOwner()->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->post(route('api.v1.owner.costumes.store'), [
            'name' => 'Too Many Photos',
            'character_name' => 'Nova',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 75000,
            'extra_price_per_day' => 20000,
            'stock' => 1,
            'images' => array_map(
                static fn (int $index): UploadedFile => UploadedFile::fake()->image("photo-{$index}.jpg"),
                range(1, SaveCostumeRequest::MAX_IMAGES + 1),
            ),
        ], ['Accept' => 'application/json'])
        ->assertStatus(422)
        ->assertJsonValidationErrors('images');
});

test('an owner gallery upload that is not an image is rejected', function (): void {
    Storage::fake(Costume::MEDIA_DISK);
    $owner = User::factory()->cosrentOwner()->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->post(route('api.v1.owner.costumes.store'), [
            'name' => 'Bad Upload',
            'character_name' => 'Nova',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 75000,
            'extra_price_per_day' => 20000,
            'stock' => 1,
            'images' => [UploadedFile::fake()->create('notes.pdf', 10, 'application/pdf')],
        ], ['Accept' => 'application/json'])
        ->assertStatus(422)
        ->assertJsonValidationErrors('images.0');
});

test('an owner can upload a costume video', function (): void {
    Storage::fake(Costume::MEDIA_DISK);
    $owner = User::factory()->cosrentOwner()->create();

    $this->withToken(ownerCostumeApiToken($owner))
        ->post(route('api.v1.owner.costumes.store'), [
            'name' => 'Video Set',
            'character_name' => 'Nova',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 75000,
            'extra_price_per_day' => 20000,
            'stock' => 1,
            'videos' => [UploadedFile::fake()->create('clip.mp4', 200, 'video/mp4')],
        ], ['Accept' => 'application/json'])
        ->assertCreated()
        ->assertJsonPath('data.video_count', 1)
        ->assertJsonCount(1, 'data.video_urls');
});
