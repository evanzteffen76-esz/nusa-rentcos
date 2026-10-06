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
        Schema::table('users', function (Blueprint $table): void {
            $table->string('bank_name', 80)->nullable();
            $table->string('bank_account_number', 64)->nullable();
            $table->string('bank_account_holder', 120)->nullable();
        });

        Schema::table('rental_orders', function (Blueprint $table): void {
            $table->string('payment_method', 32)->nullable();
            $table->string('payment_code', 16)->nullable()->unique();
            $table->string('payment_proof_path')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('rental_orders', function (Blueprint $table): void {
            $table->dropColumn(['payment_method', 'payment_code', 'payment_proof_path']);
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['bank_name', 'bank_account_number', 'bank_account_holder']);
        });
    }
};
