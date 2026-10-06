<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Costume owners can charge an extra rate once a rental runs past the included
 * period. The order stores a snapshot of both rates so that later edits to the
 * costume can never rewrite the price breakdown of an already-priced order.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('costumes', function (Blueprint $table) {
            $table->unsignedBigInteger('extra_price_per_day')->default(0)->after('price_per_day');
        });

        Schema::table('rental_orders', function (Blueprint $table) {
            $table->unsignedBigInteger('price_per_day')->default(0)->after('quantity');
            $table->unsignedBigInteger('extra_price_per_day')->default(0)->after('price_per_day');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rental_orders', function (Blueprint $table) {
            $table->dropColumn(['price_per_day', 'extra_price_per_day']);
        });

        Schema::table('costumes', function (Blueprint $table) {
            $table->dropColumn('extra_price_per_day');
        });
    }
};
