<?php

use App\Models\Costume;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

test('redirects guests from costume management to login', function (): void {
    $this->get(route('cosrent-owner.costumes.create'))
        ->assertRedirectToRoute('login');
});

test('forbids regular users from managing costumes', function (): void {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('cosrent-owner.costumes.create'))
        ->assertForbidden();
});

test('owner creates a costume listing', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $response = $this->actingAs($owner)
        ->post(route('cosrent-owner.costumes.store'), [
            'name' => 'Nebula Witch Set',
            'character_name' => 'Luna Starweaver',
            'category' => 'Fantasy',
            'size' => 'M',
            'description' => 'Mantle, tiara, wand, and clutch.',
            'image_url' => 'https://example.com/nebula-witch.jpg',
            'price_per_day' => 85000,
            'extra_price_per_day' => 20000,
            'stock' => 3,
            'is_published' => '1',
        ]);

    $response
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.costumes.index')
        ->assertSessionHas('status');

    $costume = Costume::query()->firstOrFail();

    $this->assertModelExists($costume);

    expect($costume)
        ->owner_id->toBe($owner->id)
        ->name->toBe('Nebula Witch Set')
        ->price_per_day->toBe(85000)
        ->stock->toBe(3)
        ->is_published->toBeTrue();
});

test('owner receives validation errors for an incomplete costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->post(route('cosrent-owner.costumes.store'), [])
        ->assertSessionHasErrors(['name', 'character_name', 'category', 'size', 'price_per_day', 'stock']);

    expect(Costume::query()->count())->toBe(0);
});

test('owner updates and unpublishes their costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->published()->for($owner, 'owner')->create();

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.costumes.update', $costume), [
            'name' => 'Updated Set',
            'character_name' => $costume->character_name,
            'category' => $costume->category,
            'size' => 'L',
            'description' => $costume->description,
            'image_url' => $costume->image_url,
            'price_per_day' => 90000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.costumes.index');

    expect($costume->refresh())
        ->name->toBe('Updated Set')
        ->size->toBe('L')
        ->price_per_day->toBe(90000)
        ->stock->toBe(2)
        ->is_published->toBeFalse();
});

test('owner cannot update another owner costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $otherOwner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($otherOwner, 'owner')->create([
        'name' => 'Private Other Set',
    ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.costumes.update', $costume), [
            'name' => 'Hijacked Set',
            'character_name' => $costume->character_name,
            'category' => $costume->category,
            'size' => $costume->size,
            'description' => $costume->description,
            'image_url' => $costume->image_url,
            'price_per_day' => $costume->price_per_day,
            'extra_price_per_day' => 20000,
            'stock' => $costume->stock,
        ])
        ->assertNotFound();

    expect($costume->refresh()->name)->toBe('Private Other Set');
});

test('owner archives their costume', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();

    $this->actingAs($owner)
        ->delete(route('cosrent-owner.costumes.destroy', $costume))
        ->assertRedirectToRoute('cosrent-owner.costumes.index');

    $this->assertSoftDeleted($costume);
});

test('owner sees the media upload fields on the costume form', function (): void {
    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create([
        'images' => ['costumes/1/images/photo.jpg'],
        'videos' => ['costumes/1/videos/clip.mp4'],
    ]);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.costumes.create'))
        ->assertOk()
        ->assertSee('enctype="multipart/form-data"', false)
        ->assertSee('name="images[]"', false)
        ->assertSee('name="videos[]"', false)
        ->assertSee('name="price_per_day"', false)
        ->assertDontSee('name="image_url"', false)
        ->assertSee('multiple', false);

    $this->actingAs($owner)
        ->get(route('cosrent-owner.costumes.edit', $costume))
        ->assertOk()
        ->assertSee('name="remove_images[]"', false)
        ->assertSee('name="remove_videos[]"', false);
});

test('owner uploads a photo gallery and videos when adding a costume', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();

    $images = collect(range(1, 8))
        ->map(fn (int $index): UploadedFile => UploadedFile::fake()->image("costume-{$index}.jpg"))
        ->all();

    $videos = [
        UploadedFile::fake()->create('walk.mp4', 120, 'video/mp4'),
        UploadedFile::fake()->create('spin.webm', 120, 'video/webm'),
    ];

    $this->actingAs($owner)
        ->post(route('cosrent-owner.costumes.store'), [
            'name' => 'Nebula Witch Set',
            'character_name' => 'Luna Starweaver',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 85000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'images' => $images,
            'videos' => $videos,
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.costumes.index');

    $costume = Costume::query()->firstOrFail();

    expect($costume->imageCount())->toBe(8)
        ->and($costume->videoCount())->toBe(2);

    foreach ($costume->images as $image) {
        Storage::disk(Costume::MEDIA_DISK)->assertExists($image);
    }

    foreach ($costume->videos as $video) {
        Storage::disk(Costume::MEDIA_DISK)->assertExists($video);
    }
});

test('owner cannot upload more than eight images or two videos', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();

    $images = collect(range(1, 9))
        ->map(fn (int $index): UploadedFile => UploadedFile::fake()->image("costume-{$index}.jpg"))
        ->all();

    $videos = collect(range(1, 3))
        ->map(fn (int $index): UploadedFile => UploadedFile::fake()->create("clip-{$index}.mp4", 120, 'video/mp4'))
        ->all();

    $this->actingAs($owner)
        ->post(route('cosrent-owner.costumes.store'), [
            'name' => 'Overloaded Set',
            'character_name' => 'Luna Starweaver',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 85000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'images' => $images,
            'videos' => $videos,
        ])
        ->assertSessionHasErrors(['images', 'videos']);

    expect(Costume::query()->count())->toBe(0);
});

test('owner cannot upload documents as costume media', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();

    $this->actingAs($owner)
        ->post(route('cosrent-owner.costumes.store'), [
            'name' => 'Document Set',
            'character_name' => 'Luna Starweaver',
            'category' => 'Fantasy',
            'size' => 'M',
            'price_per_day' => 85000,
            'extra_price_per_day' => 20000,
            'stock' => 2,
            'images' => [UploadedFile::fake()->create('notes.pdf', 40, 'application/pdf')],
            'videos' => [UploadedFile::fake()->create('clip.avi', 120, 'video/x-msvideo'), UploadedFile::fake()->create('broken.txt', 10, 'text/plain')],
        ])
        ->assertSessionHasErrors(['images.0', 'videos.1']);

    expect(Costume::query()->count())->toBe(0);
});

test('owner keeps saved media when editing and adds more', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create([
        'images' => ['costumes/'.$owner->id.'/images/kept.jpg'],
    ]);

    Storage::disk(Costume::MEDIA_DISK)->put('costumes/'.$costume->id.'/images/kept.jpg', 'kept');

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.costumes.update', $costume), [
            'name' => $costume->name,
            'character_name' => $costume->character_name,
            'category' => $costume->category,
            'size' => $costume->size,
            'price_per_day' => $costume->price_per_day,
            'extra_price_per_day' => 20000,
            'stock' => $costume->stock,
            'images' => [UploadedFile::fake()->image('added.png')],
        ])
        ->assertSessionHasNoErrors()
        ->assertRedirectToRoute('cosrent-owner.costumes.index');

    expect($costume->refresh()->imageCount())->toBe(2)
        ->and($costume->images[0])->toBe('costumes/'.$costume->id.'/images/kept.jpg');
});

test('owner removes saved media and stays within the gallery limit', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create();

    $paths = collect(range(1, 8))
        ->map(function (int $index) use ($costume): string {
            $path = sprintf('costumes/%d/images/photo-%d.jpg', $costume->id, $index);
            Storage::disk(Costume::MEDIA_DISK)->put($path, 'photo');

            return $path;
        })
        ->all();

    $costume->update(['images' => $paths]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.costumes.update', $costume), [
            'name' => $costume->name,
            'character_name' => $costume->character_name,
            'category' => $costume->category,
            'size' => $costume->size,
            'price_per_day' => $costume->price_per_day,
            'extra_price_per_day' => 20000,
            'stock' => $costume->stock,
            'remove_images' => [$paths[0], $paths[1]],
            'images' => [UploadedFile::fake()->image('replacement.jpg')],
        ])
        ->assertSessionHasNoErrors();

    expect($costume->refresh()->imageCount())->toBe(7)
        ->and($costume->images)->not->toContain($paths[0])
        ->and($costume->images)->not->toContain($paths[1]);

    Storage::disk(Costume::MEDIA_DISK)->assertMissing($paths[0]);
    Storage::disk(Costume::MEDIA_DISK)->assertMissing($paths[1]);
});

test('owner cannot exceed the gallery limit after removals are ignored', function (): void {
    Storage::fake(Costume::MEDIA_DISK);

    $owner = User::factory()->cosrentOwner()->create();
    $costume = Costume::factory()->for($owner, 'owner')->create([
        'images' => ['costumes/1/images/photo-1.jpg', 'costumes/1/images/photo-2.jpg'],
    ]);

    $this->actingAs($owner)
        ->patch(route('cosrent-owner.costumes.update', $costume), [
            'name' => $costume->name,
            'character_name' => $costume->character_name,
            'category' => $costume->category,
            'size' => $costume->size,
            'price_per_day' => $costume->price_per_day,
            'extra_price_per_day' => 20000,
            'stock' => $costume->stock,
            'remove_images' => ['costumes/1/images/unknown.jpg'],
            'images' => collect(range(1, 7))
                ->map(fn (int $index): UploadedFile => UploadedFile::fake()->image("extra-{$index}.jpg"))
                ->all(),
        ])
        ->assertSessionHasErrors('images');

    expect($costume->refresh()->imageCount())->toBe(2);
});
