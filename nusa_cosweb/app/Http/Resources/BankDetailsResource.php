<?php

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Expose the bank coordinates a customer needs to fund a transfer.
 *
 * The values are only meaningful when the wrapped user actually filled them
 * in, so `is_complete` travels with them: the mobile client shows the transfer
 * option as unavailable instead of rendering an empty account number.
 */
class BankDetailsResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $name = filled($this->resource->bank_name)
            ? (string) $this->resource->bank_name
            : null;
        $number = filled($this->resource->bank_account_number)
            ? (string) $this->resource->bank_account_number
            : null;
        $holder = filled($this->resource->bank_account_holder)
            ? (string) $this->resource->bank_account_holder
            : null;

        return [
            'bank_name' => $name,
            'account_number' => $number,
            'account_holder' => $holder,
            'is_complete' => $this->resource instanceof User
                && $this->resource->hasBankAccount(),
        ];
    }
}