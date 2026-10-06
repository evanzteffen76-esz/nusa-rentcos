<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('rental_orders', function (Blueprint $table): void {
            $table->date('requested_rental_start')->nullable()->after('rental_end');
            $table->date('requested_rental_end')->nullable()->after('requested_rental_start');
            $table->date('return_due_at')->nullable()->after('rental_end');
            $table->timestamp('approved_at')->nullable()->after('decided_at');
            $table->timestamp('returned_at')->nullable()->after('approved_at');
            $table->boolean('returned_late')->default(false)->after('returned_at');
            $table->timestamp('completed_at')->nullable()->after('returned_late');
            $table->text('return_note')->nullable()->after('completed_at');

            $table->index(['status', 'return_due_at']);
        });

        DB::table('rental_orders')
            ->whereNull('requested_rental_start')
            ->update([
                'requested_rental_start' => DB::raw('rental_start'),
                'requested_rental_end' => DB::raw('rental_end'),
            ]);

        DB::table('rental_orders')
            ->where('status', 'approved')
            ->whereNull('approved_at')
            ->update(['approved_at' => DB::raw('decided_at')]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rental_orders', function (Blueprint $table): void {
            $table->dropIndex(['status', 'return_due_at']);
            $table->dropColumn([
                'requested_rental_start',
                'requested_rental_end',
                'return_due_at',
                'approved_at',
                'returned_at',
                'returned_late',
                'completed_at',
                'return_note',
            ]);
        });
    }
};
