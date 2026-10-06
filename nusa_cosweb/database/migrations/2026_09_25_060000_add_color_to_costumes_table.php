<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('costumes', function (Blueprint $table): void {
            if (! Schema::hasColumn('costumes', 'color')) {
                $table->string('color', 80)->nullable()->after('size');
            }
        });
    }

    public function down(): void
    {
        Schema::table('costumes', function (Blueprint $table): void {
            if (Schema::hasColumn('costumes', 'color')) {
                $table->dropColumn('color');
            }
        });
    }
};
