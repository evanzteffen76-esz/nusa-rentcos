<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Return the mobile dashboard counters for the authenticated role.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $orderQuery = RentalOrder::query();
        $costumeQuery = Costume::query();
        $issueQuery = RentalIssue::query();

        if ($user->isCosrentOwner()) {
            $orderQuery->where('owner_id', $user->id);
            $costumeQuery->where('owner_id', $user->id);
            $issueQuery->whereHas(
                'rentalOrder',
                fn ($query) => $query->where('owner_id', $user->id),
            );
        } elseif (! $user->isAdmin()) {
            $orderQuery->where('customer_id', $user->id);
            $costumeQuery->where('is_published', true)->where('stock', '>', 0);
            $issueQuery->whereHas(
                'rentalOrder',
                fn ($query) => $query->where('customer_id', $user->id),
            );
        }

        $stats = [
            'totalOrders' => (clone $orderQuery)->count(),
            'activeOrders' => (clone $orderQuery)
                ->whereIn('status', ['pending', 'approved'])
                ->count(),
            'pendingOrders' => (clone $orderQuery)->where('status', 'pending')->count(),
            'availableCostumes' => (clone $costumeQuery)
                ->where('is_published', true)
                ->where('stock', '>', 0)
                ->count(),
            'openIssues' => (clone $issueQuery)->where('status', 'open')->count(),
        ];

        if ($user->isCosrentOwner()) {
            $stats['totalCostumes'] = Costume::query()
                ->where('owner_id', $user->id)
                ->whereNull('deleted_at')
                ->count();
            $stats['publishedCostumes'] = Costume::query()
                ->where('owner_id', $user->id)
                ->whereNull('deleted_at')
                ->where('is_published', true)
                ->count();
            $stats['approvedRevenue'] = (int) RentalOrder::query()
                ->where('owner_id', $user->id)
                ->whereIn('status', ['approved', 'returned', 'completed'])
                ->sum('total_price');
        }

        return response()->json(['data' => $stats]);
    }
}
