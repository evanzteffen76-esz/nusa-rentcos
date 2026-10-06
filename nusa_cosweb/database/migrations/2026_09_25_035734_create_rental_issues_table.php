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
        Schema::create('rental_issues', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('rental_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('type');
            $table->string('status')->default('open');
            $table->text('description');
            $table->string('evidence_path', 2048)->nullable();
            $table->unsignedBigInteger('fine_amount')->default(0);
            $table->unsignedBigInteger('replacement_cost')->nullable();
            $table->timestamp('fine_paid_at')->nullable();
            $table->timestamp('replacement_submitted_at')->nullable();
            $table->timestamp('replacement_received_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->text('resolution_note')->nullable();
            $table->timestamps();

            $table->unique('rental_order_id');
            $table->index(['reporter_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rental_issues');
    }
};
