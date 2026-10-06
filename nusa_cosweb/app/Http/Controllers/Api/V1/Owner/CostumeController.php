<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Actions\SyncCostumeMedia;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SaveCostumeRequest;
use App\Http\Resources\CostumeResource;
use App\Models\Costume;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class CostumeController extends Controller
{
    /**
     * List the authenticated owner's costume listings.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Gate::authorize('viewAny', Costume::class);

        $query = Costume::query()
            ->whereBelongsTo($request->user(), 'owner')
            ->with(Costume::OWNER_RELATION)
            ->withCount('rentalOrders')
            ->latest()
            ->orderByDesc('id');

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

        $costumes = $query->paginate(min(50, max(1, $request->integer('per_page', 50))));

        return CostumeResource::collection($costumes);
    }

    /**
     * Store a new costume listing.
     */
    public function store(
        SaveCostumeRequest $request,
        SyncCostumeMedia $syncCostumeMedia,
    ): JsonResponse {
        $costume = DB::transaction(function () use ($request, $syncCostumeMedia): Costume {
            $costume = $request->user()->costumes()->create($this->attributes($request));

            $this->syncMedia($request, $costume, $syncCostumeMedia);

            return $costume;
        });

        $costume->load(Costume::OWNER_RELATION);

        return (new CostumeResource($costume))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Show one of the owner's costume listings.
     */
    public function show(Costume $ownerCostume): CostumeResource
    {
        Gate::authorize('view', $ownerCostume);

        $ownerCostume->load(Costume::OWNER_RELATION);

        return new CostumeResource($ownerCostume);
    }

    /**
     * Update one of the owner's costume listings.
     */
    public function update(
        SaveCostumeRequest $request,
        Costume $ownerCostume,
        SyncCostumeMedia $syncCostumeMedia,
    ): CostumeResource {
        Gate::authorize('update', $ownerCostume);

        DB::transaction(function () use ($request, $ownerCostume, $syncCostumeMedia): void {
            $ownerCostume->update($this->attributes($request));

            $this->syncMedia($request, $ownerCostume, $syncCostumeMedia);
        });

        $ownerCostume->load(Costume::OWNER_RELATION);

        return new CostumeResource($ownerCostume);
    }

    /**
     * Remove one of the owner's costume listings.
     */
    public function destroy(Costume $ownerCostume): JsonResponse
    {
        Gate::authorize('delete', $ownerCostume);

        $ownerCostume->delete();

        return response()->json([
            'message' => 'Costume deleted successfully.',
        ]);
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
            ['images', 'videos', 'remove_images', 'remove_videos'],
        );

        $attributes['is_published'] = $request->boolean('is_published');

        return $attributes;
    }
}
