<?php

namespace App\Models;

use App\Enums\RentalOrderStatus;
use Carbon\CarbonInterface;
use Database\Factories\CostumeFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

#[Fillable([
    'owner_id',
    'name',
    'character_name',
    'category',
    'size',
    'color',
    'description',
    'image_url',
    'images',
    'videos',
    'price_per_day',
    'extra_price_per_day',
    'stock',
    'is_published',
])]
class Costume extends Model
{
    /** @use HasFactory<CostumeFactory> */
    use HasFactory, SoftDeletes;

    /**
     * The disk that keeps the uploaded costume media.
     */
    public const MEDIA_DISK = 'public';

    /**
     * The eager-load spec for the owner relation.
     *
     * The bank columns travel with it so a customer browsing the catalog can
     * fund a transfer without a second request.
     */
    public const OWNER_RELATION = 'owner:id,name,email,is_admin,is_cosrent_owner,bank_name,bank_account_number,bank_account_holder';

    /**
     * Get the owner who supplies the costume.
     */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get the rental orders for the costume.
     */
    public function rentalOrders(): HasMany
    {
        return $this->hasMany(RentalOrder::class);
    }

    /**
     * Get the directory that holds the uploaded media for the costume.
     */
    public function mediaDirectory(string $type): string
    {
        return sprintf('costumes/%d/%s', $this->getKey(), $type);
    }

    /**
     * Build a public URL for a stored media path.
     */
    public static function mediaUrl(?string $path): ?string
    {
        return filled($path) ? Storage::disk(self::MEDIA_DISK)->url($path) : null;
    }

    /**
     * Get the first gallery image, used when no cover URL is supplied.
     */
    public function coverImageUrl(): ?string
    {
        return self::mediaUrl($this->images[0] ?? null);
    }

    /**
     * Get the public URLs of the gallery images.
     *
     * @return array<int, string>
     */
    public function imageUrls(): array
    {
        return $this->mediaUrls($this->images);
    }

    /**
     * Get the public URLs of the gallery videos.
     *
     * @return array<int, string>
     */
    public function videoUrls(): array
    {
        return $this->mediaUrls($this->videos);
    }

    /**
     * Get the number of gallery images attached to the costume.
     */
    public function imageCount(): int
    {
        return count($this->images ?? []);
    }

    /**
     * Get the number of gallery videos attached to the costume.
     */
    public function videoCount(): int
    {
        return count($this->videos ?? []);
    }

    /**
     * Map stored media paths to their public URLs.
     *
     * @param  array<int, mixed>|null  $paths
     * @return array<int, string>
     */
    private function mediaUrls(?array $paths): array
    {
        return array_values(array_filter(array_map(self::mediaUrl(...), $paths ?? [])));
    }

    /**
     * Remove the stored media once the costume is permanently deleted.
     */
    protected static function booted(): void
    {
        static::forceDeleted(function (self $costume): void {
            Storage::disk(self::MEDIA_DISK)->deleteDirectory('costumes/'.$costume->getKey());
        });
    }

    /**
     * Get the number of units available for the requested date range.
     */
    public function availableQuantityFor(CarbonInterface $start, CarbonInterface $end): int
    {
        $approvedQuantity = $this->rentalOrders()
            ->where('status', RentalOrderStatus::Approved->value)
            ->whereDate('rental_start', '<=', $end->toDateString())
            ->whereDate('rental_end', '>=', $start->toDateString())
            ->sum('quantity');

        return max(0, $this->stock - (int) $approvedQuantity);
    }

    /**
     * Get the total rental price for a given duration and quantity.
     *
     * The first RentalOrder::INCLUDED_RENTAL_DAYS are covered by
     * price_per_day; every day beyond that adds extra_price_per_day.
     */
    public function rentalTotalFor(int $days, int $quantity): int
    {
        return RentalOrder::priceFor(
            $this->price_per_day,
            $this->extra_price_per_day,
            $days,
            $quantity,
        );
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'price_per_day' => 'integer',
            'extra_price_per_day' => 'integer',
            'stock' => 'integer',
            'images' => 'array',
            'videos' => 'array',
            'is_published' => 'boolean',
        ];
    }
}
