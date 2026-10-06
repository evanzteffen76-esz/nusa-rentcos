<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\RentalOrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\RentalOrderResource;
use App\Models\RentalOrder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class OrderController extends Controller
{
    /**
     * List all rental orders for the administration console.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = RentalOrder::query()
            ->with(['customer', 'owner', 'costume.owner', 'issue.reporter'])
            ->latest('id');
        $status = $request->input('status');
        $search = trim((string) $request->input('search', ''));

        if ($status !== null && $status !== 'all') {
            if (RentalOrderStatus::tryFrom((string) $status) === null) {
                throw ValidationException::withMessages([
                    'status' => 'The selected order status is invalid.',
                ]);
            }
            $query->where('status', $status);
        }

        if ($search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder->whereHas('customer', fn ($customer) => $customer->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('customer', fn ($customer) => $customer->where('email', 'like', "%{$search}%"))
                    ->orWhereHas('costume', fn ($costume) => $costume->where('name', 'like', "%{$search}%"));
            });
        }

        return RentalOrderResource::collection(
            $query->paginate(min(100, max(1, $request->integer('per_page', 50)))),
        );
    }

    /**
     * Show one order with all mobile relations.
     */
    public function show(RentalOrder $order): RentalOrderResource
    {
        return new RentalOrderResource(
            $order->load(['customer', 'owner', 'costume.owner', 'issue.reporter']),
        );
    }

    /**
     * Apply a controlled status transition for admin support.
     */
    public function updateStatus(Request $request, RentalOrder $order): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', Rule::enum(RentalOrderStatus::class)],
        ]);
        $status = $data['status'] instanceof RentalOrderStatus
            ? $data['status']
            : RentalOrderStatus::from((string) $data['status']);

        if ($order->status === $status) {
            return (new RentalOrderResource($order->load(['customer', 'owner', 'costume.owner', 'issue.reporter'])))
                ->response();
        }

        $updates = ['status' => $status];

        if ($status === RentalOrderStatus::Approved) {
            $start = today()->startOfDay();
            $days = RentalOrder::INCLUDED_RENTAL_DAYS;
            $end = $start->copy()->addDays($days - 1);
            $costume = $order->costume()->withTrashed()->first();
            $basePrice = (int) ($costume?->price_per_day ?? 0);
            $extraRate = (int) ($costume?->extra_price_per_day ?? 0);
            $updates = [
                ...$updates,
                'rental_start' => $start,
                'rental_end' => $end,
                'return_due_at' => $end->copy()->addDay(),
                'price_per_day' => $basePrice,
                'extra_price_per_day' => $extraRate,
                'total_price' => RentalOrder::priceFor($basePrice, $extraRate, $days, (int) $order->quantity),
                'approved_at' => now(),
                'decided_at' => now(),
            ];
        } elseif ($status === RentalOrderStatus::Rejected) {
            $updates['decided_at'] = now();
        } elseif ($status === RentalOrderStatus::Returned) {
            $updates['returned_at'] = now();
        } elseif ($status === RentalOrderStatus::Completed) {
            $updates['completed_at'] = now();
        }

        $order->update($updates);

        return response()->json([
            'message' => 'Order status updated successfully.',
            'data' => new RentalOrderResource(
                $order->fresh(['customer', 'owner', 'costume.owner', 'issue.reporter']),
            ),
        ]);
    }

    /**
     * Delete an order for administrative cleanup.
     */
    public function destroy(RentalOrder $order): JsonResponse
    {
        $order->delete();

        return response()->json(['message' => 'Order deleted successfully.']);
    }
}
