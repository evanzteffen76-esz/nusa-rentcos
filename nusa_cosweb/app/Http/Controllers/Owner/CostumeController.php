<?php

namespace App\Http\Controllers\Owner;

use App\Actions\SyncCostumeMedia;
use App\Http\Controllers\Controller;
use App\Http\Requests\Owner\SaveCostumeRequest;
use App\Models\Costume;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\View\View;

class CostumeController extends Controller
{
    /**
     * Display the owner's costume catalog.
     */
    public function index(Request $request): View
    {
        Gate::authorize('viewAny', Costume::class);

        $costumes = Costume::query()
            ->whereBelongsTo($request->user(), 'owner')
            ->withCount('rentalOrders')
            ->latest()
            ->orderByDesc('id')
            ->paginate(9);

        return view('owner.costumes.index', compact('costumes'));
    }

    /**
     * Show the form for adding a costume listing.
     */
    public function create(): View
    {
        Gate::authorize('create', Costume::class);

        return view('owner.costumes.create');
    }

    /**
     * Store a new costume listing.
     */
    public function store(SaveCostumeRequest $request, SyncCostumeMedia $syncCostumeMedia): RedirectResponse
    {
        DB::transaction(function () use ($request, $syncCostumeMedia): void {
            $costume = $request->user()->costumes()->create($this->attributes($request));

            $syncCostumeMedia->handle(
                $costume,
                uploadedImages: Arr::wrap($request->file('images')),
                uploadedVideos: Arr::wrap($request->file('videos')),
                removedImages: Arr::wrap($request->input('remove_images')),
                removedVideos: Arr::wrap($request->input('remove_videos')),
            );
        });

        return redirect()
            ->route('cosrent-owner.costumes.index')
            ->with('status', __('owner.costumes.created'));
    }

    /**
     * Show the form for editing a costume listing.
     */
    public function edit(Costume $ownerCostume): View
    {
        Gate::authorize('update', $ownerCostume);

        return view('owner.costumes.edit', compact('ownerCostume'));
    }

    /**
     * Update a costume listing.
     */
    public function update(
        SaveCostumeRequest $request,
        Costume $ownerCostume,
        SyncCostumeMedia $syncCostumeMedia,
    ): RedirectResponse {
        DB::transaction(function () use ($request, $ownerCostume, $syncCostumeMedia): void {
            $ownerCostume->update($this->attributes($request));

            $syncCostumeMedia->handle(
                $ownerCostume,
                uploadedImages: Arr::wrap($request->file('images')),
                uploadedVideos: Arr::wrap($request->file('videos')),
                removedImages: Arr::wrap($request->input('remove_images')),
                removedVideos: Arr::wrap($request->input('remove_videos')),
            );
        });

        return redirect()
            ->route('cosrent-owner.costumes.index')
            ->with('status', __('owner.costumes.updated'));
    }

    /**
     * Remove a costume listing from the active catalog.
     */
    public function destroy(Request $request, Costume $ownerCostume): RedirectResponse
    {
        Gate::authorize('delete', $ownerCostume);

        $ownerCostume->delete();

        return redirect()
            ->route('cosrent-owner.costumes.index')
            ->with('status', __('owner.costumes.deleted'));
    }

    /**
     * Get the costume attributes without the uploaded media.
     *
     * @return array<string, mixed>
     */
    private function attributes(SaveCostumeRequest $request): array
    {
        $attributes = Arr::except($request->validated(), ['images', 'videos']);

        $attributes['is_published'] = $request->boolean('is_published');

        return $attributes;
    }
}
