<?php

use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Customer\CostumeController as CustomerCostumeController;
use App\Http\Controllers\Customer\DashboardController as CustomerDashboardController;
use App\Http\Controllers\Customer\OrderController as CustomerOrderController;
use App\Http\Controllers\Customer\OrderIssueController as CustomerOrderIssueController;
use App\Http\Controllers\Customer\OrderReturnController;
use App\Http\Controllers\Customer\RentalOrderController;
use App\Http\Controllers\LocaleController;
use App\Http\Controllers\Owner\CostumeController;
use App\Http\Controllers\Owner\DashboardController as OwnerDashboardController;
use App\Http\Controllers\Owner\OrderController;
use App\Http\Controllers\Owner\OrderDecisionController;
use App\Http\Controllers\Owner\OrderIssueController as OwnerOrderIssueController;
use App\Http\Controllers\Owner\OrderReturnController as OwnerOrderReturnController;
use App\Http\Controllers\ProfileController;
use App\Models\Costume;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/language', LocaleController::class)
    ->name('language.switch');

Route::middleware(['auth', 'verified'])->group(function (): void {
    Route::get('/dashboard', [CustomerDashboardController::class, 'index'])
        ->name('dashboard');

    Route::bind('customerRentalOrder', function (string $value): RentalOrder {
        $query = RentalOrder::query()
            ->with(['costume:id,name,character_name,image_url,images', 'issue']);
        $customerId = request()->user()?->getAuthIdentifier();

        if ($customerId !== null) {
            $query->where('customer_id', $customerId);
        }

        return $query->findOrFail($value);
    });

    Route::bind('availableCostume', function (string $value): Costume {
        return Costume::query()
            ->with('owner:id,name,bank_name,bank_account_number,bank_account_holder')
            ->where('is_published', true)
            ->where('stock', '>', 0)
            ->findOrFail($value);
    });

    Route::get('/dashboard/costumes/{availableCostume}', [CustomerCostumeController::class, 'show'])
        ->name('dashboard.costumes.show');

    Route::get('/dashboard/costumes/{availableCostume}/book', [RentalOrderController::class, 'create'])
        ->name('dashboard.costumes.book.create');
    Route::post('/dashboard/costumes/{availableCostume}/book', [RentalOrderController::class, 'store'])
        ->name('dashboard.costumes.book.store');
    Route::post('/dashboard/orders/{customerRentalOrder}/return', [OrderReturnController::class, 'store'])
        ->name('dashboard.orders.return');
    Route::get('/dashboard/orders/{customerRentalOrder}/loss-report', [CustomerOrderIssueController::class, 'create'])
        ->name('dashboard.orders.loss-report.create');
    Route::post('/dashboard/orders/{customerRentalOrder}/loss-report', [CustomerOrderIssueController::class, 'store'])
        ->name('dashboard.orders.loss-report.store');
    Route::get('/dashboard/orders/{customerRentalOrder}/payment-proof', [CustomerOrderController::class, 'paymentProof'])
        ->name('dashboard.orders.payment-proof');
});

Route::get('/admin', [AdminDashboardController::class, 'index'])
    ->middleware(['auth', 'admin'])
    ->name('admin.dashboard');

Route::middleware(['auth', 'cosrent-owner'])
    ->prefix('cosrent-owner')
    ->name('cosrent-owner.')
    ->group(function (): void {
        Route::bind('ownerCostume', function (string $value): Costume {
            $query = Costume::query();
            $ownerId = request()->user()?->getAuthIdentifier();

            if ($ownerId !== null) {
                $query->where('owner_id', $ownerId);
            }

            return $query->findOrFail($value);
        });

        Route::bind('ownerRentalOrder', function (string $value): RentalOrder {
            $query = RentalOrder::query()
                ->with(['customer:id,name,email', 'costume:id,name,character_name,category,description,image_url,images', 'issue.reporter']);
            $ownerId = request()->user()?->getAuthIdentifier();

            if ($ownerId !== null) {
                $query->where('owner_id', $ownerId);
            }

            return $query->findOrFail($value);
        });

        Route::bind('rentalIssue', function (string $value, Illuminate\Routing\Route $route): RentalIssue {
            $ownerRentalOrder = $route->parameter('ownerRentalOrder');

            return RentalIssue::query()
                ->where('rental_order_id', $ownerRentalOrder->id)
                ->with('reporter')
                ->findOrFail($value);
        });

        Route::get('/', [OwnerDashboardController::class, 'index'])
            ->name('dashboard');
        Route::resource('costumes', CostumeController::class)
            ->except('show')
            ->parameters(['costumes' => 'ownerCostume']);
        Route::resource('orders', OrderController::class)
            ->only(['index', 'show'])
            ->parameters(['orders' => 'ownerRentalOrder']);
        Route::patch('orders/{ownerRentalOrder}/approve', [OrderDecisionController::class, 'approve'])
            ->name('orders.approve');
        Route::patch('orders/{ownerRentalOrder}/reject', [OrderDecisionController::class, 'reject'])
            ->name('orders.reject');
        Route::patch('orders/{ownerRentalOrder}/complete', [OwnerOrderReturnController::class, 'store'])
            ->name('orders.complete');
        Route::post('orders/{ownerRentalOrder}/issues', [OwnerOrderIssueController::class, 'store'])
            ->name('orders.issues.store');
        Route::patch('orders/{ownerRentalOrder}/issues/{rentalIssue}/resolve', [OwnerOrderIssueController::class, 'resolve'])
            ->name('orders.issues.resolve');
        Route::get('orders/{ownerRentalOrder}/issues/{rentalIssue}/evidence', [OwnerOrderIssueController::class, 'evidence'])
            ->name('orders.issues.evidence');
        Route::get('orders/{ownerRentalOrder}/payment-proof', [OrderController::class, 'paymentProof'])
            ->name('orders.payment-proof');
    });

Route::middleware('auth')->group(function (): void {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
