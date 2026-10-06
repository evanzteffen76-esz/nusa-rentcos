<?php

namespace App\Http\Controllers\Customer;

use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Models\Costume;
use App\Models\RentalOrder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Display the customer catalog and recent bookings.
     */
    public function index(Request $request): View|RedirectResponse
    {
        $user = $request->user();

        if ($user->isAdmin()) {
            return redirect()->route('admin.dashboard');
        }

        if ($user->isCosrentOwner()) {
            return redirect()->route('cosrent-owner.dashboard');
        }

        $costumes = Costume::query()
            ->where('is_published', true)
            ->where('stock', '>', 0)
            ->with('owner:id,name')
            ->latest()
            ->orderByDesc('id')
            ->paginate(6);

        $customerOrders = RentalOrder::query()->whereBelongsTo($user, 'customer');

        $orders = (clone $customerOrders)
            ->with(['costume:id,name,character_name,image_url,images', 'issue'])
            ->latest()
            ->orderByDesc('id')
            ->limit(5)
            ->get();

        return view('customer.dashboard', [
            'costumes' => $costumes,
            'orders' => $orders,
            'pendingCustomerOrderCount' => (clone $customerOrders)
                ->where('status', RentalOrderStatus::Pending)
                ->count(),
            'approvedCustomerOrderCount' => (clone $customerOrders)
                ->where('status', RentalOrderStatus::Approved)
                ->count(),
        ]);
    }
}
