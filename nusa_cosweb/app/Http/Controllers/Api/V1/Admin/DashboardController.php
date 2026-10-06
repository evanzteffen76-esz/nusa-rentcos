<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'data' => [
                'totalUsers' => User::query()->count(),
                'adminUsers' => User::query()->where('is_admin', true)->count(),
                'ownerUsers' => User::query()->where('is_cosrent_owner', true)->count(),
                'customerUsers' => User::query()->where('is_admin', false)->where('is_cosrent_owner', false)->count(),
                'totalOrders' => RentalOrder::query()->count(),
                'activeOrders' => RentalOrder::query()->whereIn('status', ['pending', 'approved'])->count(),
                'pendingOrders' => RentalOrder::query()->where('status', 'pending')->count(),
                'availableCostumes' => Costume::query()->where('is_published', true)->where('stock', '>', 0)->count(),
                'openIssues' => RentalIssue::query()->where('status', 'open')->count(),
            ],
        ]);
    }
}
