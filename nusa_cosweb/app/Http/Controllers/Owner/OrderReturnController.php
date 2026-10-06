<?php

namespace App\Http\Controllers\Owner;

use App\Actions\CompleteRentalReturn;
use App\Http\Controllers\Controller;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Gate;

class OrderReturnController extends Controller
{
    /**
     * Complete a clean customer return.
     */
    public function store(
        RentalOrder $ownerRentalOrder,
        CompleteRentalReturn $completeRentalReturn,
    ): RedirectResponse {
        Gate::authorize('completeReturn', $ownerRentalOrder);

        $completeRentalReturn->handle($ownerRentalOrder);

        return redirect()
            ->route('cosrent-owner.orders.show', $ownerRentalOrder)
            ->with('status', __('owner.orders.completed'));
    }
}
