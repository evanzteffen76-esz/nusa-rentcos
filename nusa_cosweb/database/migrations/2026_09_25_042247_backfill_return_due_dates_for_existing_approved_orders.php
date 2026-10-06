<?php

use Carbon\CarbonImmutable;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Populate return deadlines for approved orders created before the return policy.
     */
    public function up(): void
    {
        DB::table('rental_orders')
            ->where('status', 'approved')
            ->whereNull('return_due_at')
            ->select(['id', 'rental_end'])
            ->orderBy('id')
            ->chunkById(100, function (Collection $orders): void {
                foreach ($orders as $order) {
                    DB::table('rental_orders')
                        ->where('id', $order->id)
                        ->update([
                            'return_due_at' => CarbonImmutable::parse($order->rental_end)
                                ->addDay()
                                ->toDateString(),
                        ]);
                }
            });
    }

    /**
     * The original deadlines cannot be distinguished from values entered after this migration.
     */
    public function down(): void
    {
        // Intentionally left blank; this is a forward-only data backfill.
    }
};
