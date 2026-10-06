<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\SyncCostumeMedia;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SaveCostumeRequest;
use App\Http\Resources\CostumeResource;
use App\Models\Costume;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class CostumeController extends Controller
{
    /**
     * List every costume, including unpublished listings.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Costume::query()->with(Costume::OWNER_RELATION)->withCount('rentalOrders')->latest('id');
        $this->applyFilters($query, $request);

        return CostumeResource::collection(
            $query->paginate(min(100, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Store a costume on behalf of an administrator.
     */
    public function store(
        SaveCostumeRequest $request,
        SyncCostumeMedia $syncCostumeMedia,
    ): JsonResponse {
        $ownerId = $request->integer('owner_id')
            ?: User::query()->where('is_cosrent_owner', true)->value('id');

        abort_if($ownerId === null, 422, 'Tidak ada owner untuk menerima kostum.');

        $costume = DB::transaction(function () use ($request, $syncCostumeMedia, $ownerId): Costume {
            $costume = Costume::query()->create([
                ...$this->attributes($request),
                'owner_id' => $ownerId,
            ]);

            $this->syncMedia($request, $costume, $syncCostumeMedia);

            return $costume;
        });

        $costume->load(Costume::OWNER_RELATION);

        return (new CostumeResource($costume))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Show a costume regardless of publication state.
     */
    public function show(Costume $costume): CostumeResource
    {
        return new CostumeResource($costume->load(Costume::OWNER_RELATION));
    }

    /**
     * Update a costume regardless of publication state.
     */
    public function update(
        SaveCostumeRequest $request,
        Costume $costume,
        SyncCostumeMedia $syncCostumeMedia,
    ): CostumeResource {
        DB::transaction(function () use ($request, $costume, $syncCostumeMedia): void {
            $costume->update($this->attributes($request));

            $this->syncMedia($request, $costume, $syncCostumeMedia);
        });

        return new CostumeResource($costume->fresh(Costume::OWNER_RELATION));
    }

    /**
     * Soft-delete a costume.
     */
    public function destroy(Costume $costume): JsonResponse
    {
        $costume->delete();

        return response()->json(['message' => 'Costume deleted successfully.']);
    }

    private function applyFilters($query, Request $request): void
    {
        $search = trim((string) $request->input('search', ''));
        $category = trim((string) $request->input('category', ''));
        $availability = $request->input('availability');

        if ($search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder->where('name', 'like', "%{$search}%")
                    ->orWhere('character_name', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        if ($category !== '' && strtolower($category) !== 'semua') {
            $query->where('category', $category);
        }

        if ($request->boolean('published_only')) {
            $query->where('is_published', true);
        }

        if ($availability === 'available') {
            $query->where('is_published', true)->where('stock', '>', 0);
        } elseif ($availability === 'unavailable') {
            $query->where(function ($builder): void {
                $builder->where('is_published', false)->orWhere('stock', '<=', 0);
            });
        }
    }

    /**
     * Apply the uploaded gallery and the flagged removals to a costume.
     */
    private function syncMedia(
        SaveCostumeRequest $request,
        Costume $costume,
        SyncCostumeMedia $syncCostumeMedia,
    ): void {
        $syncCostumeMedia->handle(
            $costume,
            uploadedImages: Arr::wrap($request->file('images')),
            uploadedVideos: Arr::wrap($request->file('videos')),
            removedImages: Arr::wrap($request->input('remove_images')),
            removedVideos: Arr::wrap($request->input('remove_videos')),
        );
    }

    /**
     * Get the costume attributes without the uploaded media.
     *
     * @return array<string, mixed>
     */
    private function attributes(SaveCostumeRequest $request): array
    {
        $attributes = Arr::except(
            $request->validated(),
            ['images', 'videos', 'remove_images', 'remove_videos', 'owner_id'],
        );

        // The owner is resolved from the resolved owner id, never from client
        // input, so an admin cannot silently reassign a listing by accident.
        $attributes['is_published'] = $request->boolean('is_published');

        return $attributes;
    }
}