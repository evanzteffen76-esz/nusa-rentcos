<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $isSelf = $viewer !== null && $viewer->getAuthIdentifier() === $this->getKey();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $this->email,
            'role' => $this->isAdmin() ? 'admin' : ($this->isCosrentOwner() ? 'owner' : 'customer'),
            'is_admin' => $this->isAdmin(),
            'is_cosrent_owner' => $this->isCosrentOwner(),
            // Bank coordinates are private: an owner only ever sees and edits
            // their own, so the booking screen reads them from the costume's
            // `owner_bank` block instead.
            'bank_details' => $isSelf
                ? BankDetailsResource::make($this->resource)
                : null,
            'has_bank_account' => $this->hasBankAccount(),
        ];
    }
}