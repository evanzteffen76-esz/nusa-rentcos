<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /**
     * Display the admin dashboard.
     */
    public function index(Request $request): View
    {
        return view('admin.dashboard', [
            'admin' => $request->user(),
            'totalUsers' => User::query()->count(),
            'adminCount' => User::query()->where('is_admin', true)->count(),
            'ownerCount' => User::query()->where('is_cosrent_owner', true)->count(),
            'regularUserCount' => User::query()
                ->where('is_admin', false)
                ->where('is_cosrent_owner', false)
                ->count(),
            'databaseConnection' => config('database.default'),
        ]);
    }
}
