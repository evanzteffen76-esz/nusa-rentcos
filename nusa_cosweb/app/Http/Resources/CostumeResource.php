<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CostumeResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $imageUrls = $this->imageUrls();
        $videoUrls = $this->videoUrls();
        // A costume may only have gallery uploads, only a cover URL, or both.
        // The cover falls back to the first gallery image so the client always
        // has something to render in a list tile.
        $cover = $this->image_url ?: ($imageUrls[0] ?? null);

        return [
            'id' => $this->id,
            'owner_id' => $this->owner_id,
            'owner' => UserResource::make($this->whenLoaded('owner')),
            // Bank coordinates of the supplier, needed by a customer choosing a
            // bank transfer at booking time.
            'owner_bank' => $this->whenLoaded('owner')
                ? BankDetailsResource::make($this->owner)
                : null,
            'name' => $this->name,
            'character_name' => $this->character_name,
            'category' => $this->category,
            'size' => $this->size,
            'color' => $this->color,
            'description' => $this->description,
            'image_url' => $this->image_url,
            'cover_image_url' => $cover,
            'image_urls' => $imageUrls,
            'video_urls' => $videoUrls,
            'image_count' => $this->imageCount(),
            'video_count' => $this->videoCount(),
            'price_per_day' => $this->price_per_day,
            'extra_price_per_day' => $this->extra_price_per_day,
            'stock' => $this->stock,
            'is_published' => $this->is_published,
            'is_available' => $this->is_published && $this->stock > 0,
            'rental_orders_count' => $this->whenCounted('rentalOrders'),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}