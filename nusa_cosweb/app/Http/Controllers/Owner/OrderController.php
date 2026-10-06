<?php

namespace App\Http\Controllers\Owner;

use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Models\RentalOrder;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class OrderController extends Controller
{
    /**
     * Display rental orders assigned to the owner.
     */
    public function index(Request $request): View
    {
        Gate::authorize('viewAny', RentalOrder::class);

        $status = $request->string('status')->toString() ?: 'all';

        abort_unless(
            $status === 'all' || RentalOrderStatus::tryFrom($status) !== null,
            404,
        );

        $orders = RentalOrder::query()
            ->whereBelongsTo($request->user(), 'owner')
            ->with(['customer:id,name,email', 'costume:id,name,character_name,image_url,images'])
            ->when(
                $status !== 'all',
                fn (Builder $query) => $query->where('status', RentalOrderStatus::from($status)),
            )
            ->latest()
            ->orderByDesc('id')
            ->paginate(12)
            ->withQueryString();

        return view('owner.orders.index', compact('orders', 'status'));
    }

    /**
     * Display a customer rental order.
     */
    public function show(RentalOrder $ownerRentalOrder): View
    {
        Gate::authorize('view', $ownerRentalOrder);

        return view('owner.orders.show', compact('ownerRentalOrder'));
    }

    /**
     * Download the private payment proof after owner authorization.
     */
    public function paymentProof(RentalOrder $ownerRentalOrder): StreamedResponse
    {
        Gate::authorize('view', $ownerRentalOrder);

        abort_if(blank($ownerRentalOrder->payment_proof_path), 404);

        return Storage::disk('local')->download(
            $ownerRentalOrder->payment_proof_path,
            basename($ownerRentalOrder->payment_proof_path),
        );
    }
}
