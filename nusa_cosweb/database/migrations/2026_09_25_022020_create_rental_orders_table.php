<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rental_orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('costume_id')->constrained()->restrictOnDelete();
            $table->unsignedSmallInteger('quantity');
            $table->date('rental_start');
            $table->date('rental_end');
            $table->unsignedBigInteger('total_price');
            $table->string('status')->default('pending');
            $table->text('customer_note')->nullable();
            $table->text('owner_note')->nullable();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();

            $table->index(['owner_id', 'status', 'created_at']);
            $table->index(['costume_id', 'status', 'rental_start', 'rental_end']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rental_orders');
    }
};
