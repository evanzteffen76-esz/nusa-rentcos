<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CostumeResource;
use App\Models\Costume;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CostumeController extends Controller
{
    /**
     * List published costumes available to customers.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Costume::query()
            ->where('is_published', true)
            ->where('stock', '>', 0)
            ->with(Costume::OWNER_RELATION)
            ->latest('id');
        $search = trim((string) $request->input('search', ''));
        $category = trim((string) $request->input('category', ''));

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

        return CostumeResource::collection(
            $query->paginate(min(50, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Return the categories used by the public catalog.
     */
    public function categories(): JsonResponse
    {
        $categories = Costume::query()
            ->where('is_published', true)
            ->where('stock', '>', 0)
            ->distinct()
            ->orderBy('category')
            ->pluck('category')
            ->values()
            ->all();

        return response()->json(['data' => $categories]);
    }

    /**
     * Show a published costume.
     */
    public function show(Costume $apiCostume): CostumeResource
    {
        abort_unless($apiCostume->is_published && $apiCostume->stock > 0, 404);

        return new CostumeResource($apiCostume->load(Costume::OWNER_RELATION));
    }
}
