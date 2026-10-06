<?php

namespace App\Http\Controllers\Owner;

use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Costume;
use App\Models\RentalOrder;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Display the Cosrent Owner dashboard.
     */
    public function index(Request $request): View
    {
        $owner = $request->user();

        $costumes = Costume::query()->whereBelongsTo($owner, 'owner');
        $orders = RentalOrder::query()->whereBelongsTo($owner, 'owner');

        return view('owner.dashboard', [
            'owner' => $owner,
            'totalCostumes' => (clone $costumes)->count(),
            'publishedCostumes' => (clone $costumes)->where('is_published', true)->count(),
            'pendingOrderCount' => (clone $orders)
                ->where('status', RentalOrderStatus::Pending)
                ->count(),
            'approvedOrderCount' => (clone $orders)
                ->where('status', RentalOrderStatus::Approved)
                ->count(),
            'approvedRevenue' => (int) (clone $orders)
                ->where('status', RentalOrderStatus::Approved)
                ->sum('total_price'),
            'pendingOrders' => (clone $orders)
                ->with(['customer:id,name,email', 'costume:id,name,character_name,image_url,images'])
                ->where('status', RentalOrderStatus::Pending)
                ->latest()
                ->orderByDesc('id')
                ->limit(5)
                ->get(),
            'recentCostumes' => (clone $costumes)
                ->latest()
                ->orderByDesc('id')
                ->limit(4)
                ->get(),
        ]);
    }
}
