<?php

use App\Http\Controllers\Api\V1\Admin\CostumeController as AdminCostumeController;
use App\Http\Controllers\Api\V1\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\V1\Admin\IssueController as AdminIssueController;
use App\Http\Controllers\Api\V1\Admin\OrderController as AdminOrderController;
use App\Http\Controllers\Api\V1\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CostumeController;
use App\Http\Controllers\Api\V1\Customer\IssueController as CustomerIssueController;
use App\Http\Controllers\Api\V1\Customer\OrderController as CustomerOrderController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\Owner\CostumeController as OwnerCostumeController;
use App\Http\Controllers\Api\V1\Owner\IssueController as OwnerIssueController;
use App\Http\Controllers\Api\V1\Owner\OrderController as OwnerOrderController;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::bind('apiCostume', function (string $value): Costume {
    return Costume::query()
        ->with(Costume::OWNER_RELATION)
        ->where('is_published', true)
        ->where('stock', '>', 0)
        ->findOrFail($value);
});

Route::bind('customerOrder', function (string $value): RentalOrder {
    return RentalOrder::query()
        ->with(['owner', 'costume.owner', 'issue.reporter'])
        ->where('customer_id', request()->user()?->getAuthIdentifier())
        ->findOrFail($value);
});



Route::bind('ownerCostume', function (string $value): Costume {
    $ownerId = request()->user()?->getAuthIdentifier();

    abort_if($ownerId === null, 401);

    return Costume::query()
        ->where('owner_id', $ownerId)
        ->findOrFail($value);
});

Route::bind('ownerOrder', function (string $value): RentalOrder {
    return RentalOrder::query()
        ->with(['owner', 'customer', 'costume', 'issue.reporter'])
        ->where('owner_id', request()->user()?->getAuthIdentifier())
        ->findOrFail($value);
});

Route::bind('ownerIssue', function (string $value, Illuminate\Routing\Route $route): RentalIssue {
    $ownerOrder = $route->parameter('ownerOrder');

    return RentalIssue::query()
        ->where('rental_order_id', $ownerOrder->id)
        ->with(['reporter', 'rentalOrder'])
        ->findOrFail($value);
});

Route::prefix('v1')->group(function (): void {
    Route::get('health', function () {
        try {
            DB::connection()->getPdo();

            return response()->json([
                'status' => 'ok',
                'database' => config('database.default'),
                'timestamp' => now()->toISOString(),
            ]);
        } catch (Throwable) {
            return response()->json([
                'status' => 'degraded',
                'database' => config('database.default'),
            ], 503);
        }
    })->name('api.v1.health');

    Route::post('auth/register', [AuthController::class, 'register'])
        ->middleware('throttle:6,1')
        ->name('api.v1.auth.register');
    Route::post('auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('api.v1.auth.login');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('auth/me', [AuthController::class, 'me'])
            ->name('api.v1.auth.me');
        Route::patch('auth/profile', [AuthController::class, 'updateProfile'])
            ->name('api.v1.auth.profile.update');
        Route::delete('auth/account', [AuthController::class, 'destroyAccount'])
            ->name('api.v1.auth.account.destroy');
        Route::post('auth/logout', [AuthController::class, 'logout'])
            ->name('api.v1.auth.logout');

        Route::get('dashboard', DashboardController::class)
            ->name('api.v1.dashboard');
        Route::get('costumes/categories', [CostumeController::class, 'categories'])
            ->name('api.v1.costumes.categories');
        Route::get('costumes', [CostumeController::class, 'index'])
            ->name('api.v1.costumes.index');
        Route::get('costumes/{apiCostume}', [CostumeController::class, 'show'])
            ->name('api.v1.costumes.show');

        Route::get('customer/orders', [CustomerOrderController::class, 'index'])
            ->name('api.v1.customer.orders.index');
        Route::post('customer/costumes/{apiCostume}/orders', [CustomerOrderController::class, 'store'])
            ->name('api.v1.customer.orders.store');
        Route::get('customer/orders/{customerOrder}', [CustomerOrderController::class, 'show'])
            ->name('api.v1.customer.orders.show');
        Route::post('customer/orders/{customerOrder}/return', [CustomerOrderController::class, 'submitReturn'])
            ->name('api.v1.customer.orders.return');
        Route::post('customer/orders/{customerOrder}/loss-report', [CustomerIssueController::class, 'store'])
            ->name('api.v1.customer.orders.loss-report');
        Route::get('customer/orders/{customerOrder}/payment-proof', [CustomerOrderController::class, 'paymentProof'])
            ->name('api.v1.customer.orders.payment-proof');
        Route::delete('customer/orders/{customerOrder}', [CustomerOrderController::class, 'destroy'])
            ->name('api.v1.customer.orders.destroy');

        Route::get('owner/costumes', [OwnerCostumeController::class, 'index'])
            ->name('api.v1.owner.costumes.index');
        Route::post('owner/costumes', [OwnerCostumeController::class, 'store'])
            ->name('api.v1.owner.costumes.store');
        Route::get('owner/costumes/{ownerCostume}', [OwnerCostumeController::class, 'show'])
            ->name('api.v1.owner.costumes.show');
        Route::patch('owner/costumes/{ownerCostume}', [OwnerCostumeController::class, 'update'])
            ->name('api.v1.owner.costumes.update');
        Route::delete('owner/costumes/{ownerCostume}', [OwnerCostumeController::class, 'destroy'])
            ->name('api.v1.owner.costumes.destroy');

        Route::get('owner/orders', [OwnerOrderController::class, 'index'])
            ->name('api.v1.owner.orders.index');
        Route::get('owner/issues', [OwnerIssueController::class, 'index'])
            ->name('api.v1.owner.issues.index');
        Route::get('owner/orders/{ownerOrder}', [OwnerOrderController::class, 'show'])
            ->name('api.v1.owner.orders.show');
        Route::patch('owner/orders/{ownerOrder}/approve', [OwnerOrderController::class, 'approve'])
            ->name('api.v1.owner.orders.approve');
        Route::patch('owner/orders/{ownerOrder}/reject', [OwnerOrderController::class, 'reject'])
            ->name('api.v1.owner.orders.reject');
        Route::patch('owner/orders/{ownerOrder}/complete', [OwnerOrderController::class, 'complete'])
            ->name('api.v1.owner.orders.complete');
        Route::get('owner/orders/{ownerOrder}/payment-proof', [OwnerOrderController::class, 'paymentProof'])
            ->name('api.v1.owner.orders.payment-proof');
        Route::post('owner/orders/{ownerOrder}/issues', [OwnerIssueController::class, 'store'])
            ->name('api.v1.owner.issues.store');
        Route::patch('owner/orders/{ownerOrder}/issues/{ownerIssue}/resolve', [OwnerIssueController::class, 'resolve'])
            ->name('api.v1.owner.issues.resolve');
        Route::get('owner/orders/{ownerOrder}/issues/{ownerIssue}/evidence', [OwnerIssueController::class, 'evidence'])
            ->name('api.v1.owner.issues.evidence');

        Route::middleware('admin')->prefix('admin')->group(function (): void {
            Route::get('dashboard', AdminDashboardController::class)
                ->name('api.v1.admin.dashboard');
            Route::get('users', [AdminUserController::class, 'index'])
                ->name('api.v1.admin.users.index');
            Route::post('users', [AdminUserController::class, 'store'])
                ->name('api.v1.admin.users.store');
            Route::patch('users/{user}', [AdminUserController::class, 'update'])
                ->name('api.v1.admin.users.update');
            Route::delete('users/{user}', [AdminUserController::class, 'destroy'])
                ->name('api.v1.admin.users.destroy');
            Route::get('costumes', [AdminCostumeController::class, 'index'])
                ->name('api.v1.admin.costumes.index');
            Route::post('costumes', [AdminCostumeController::class, 'store'])
                ->name('api.v1.admin.costumes.store');
            Route::get('costumes/{costume}', [AdminCostumeController::class, 'show'])
                ->name('api.v1.admin.costumes.show');
            Route::patch('costumes/{costume}', [AdminCostumeController::class, 'update'])
                ->name('api.v1.admin.costumes.update');
            Route::delete('costumes/{costume}', [AdminCostumeController::class, 'destroy'])
                ->name('api.v1.admin.costumes.destroy');
            Route::get('orders', [AdminOrderController::class, 'index'])
                ->name('api.v1.admin.orders.index');
            Route::get('orders/{order}', [AdminOrderController::class, 'show'])
                ->name('api.v1.admin.orders.show');
            Route::patch('orders/{order}/status', [AdminOrderController::class, 'updateStatus'])
                ->name('api.v1.admin.orders.status');
            Route::delete('orders/{order}', [AdminOrderController::class, 'destroy'])
                ->name('api.v1.admin.orders.destroy');
            Route::get('issues', [AdminIssueController::class, 'index'])
                ->name('api.v1.admin.issues.index');
            Route::patch('issues/{issue}/resolve', [AdminIssueController::class, 'resolve'])
                ->name('api.v1.admin.issues.resolve');
            Route::delete('issues/{issue}', [AdminIssueController::class, 'destroy'])
                ->name('api.v1.admin.issues.destroy');
        });
    });
});
