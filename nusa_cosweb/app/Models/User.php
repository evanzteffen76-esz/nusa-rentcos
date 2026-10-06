<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable([
    'name',
    'username',
    'email',
    'password',
    'is_admin',
    'is_cosrent_owner',
    'bank_name',
    'bank_account_number',
    'bank_account_holder',
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'is_cosrent_owner' => 'boolean',
        ];
    }

    /**
     * Determine whether the user has administrator access.
     */
    public function isAdmin(): bool
    {
        return (bool) $this->is_admin;
    }

    /**
     * Determine whether the user has Cosrent Owner access.
     */
    public function isCosrentOwner(): bool
    {
        return (bool) $this->is_cosrent_owner;
    }

    /**
     * Determine whether the owner has bank details for customer transfers.
     */
    public function hasBankAccount(): bool
    {
        return filled($this->bank_name)
            && filled($this->bank_account_number)
            && filled($this->bank_account_holder);
    }

    /**
     * Get the costume listings supplied by the owner.
     */
    public function costumes(): HasMany
    {
        return $this->hasMany(Costume::class, 'owner_id');
    }

    /**
     * Get the rental orders assigned to the owner.
     */
    public function rentalOrders(): HasMany
    {
        return $this->hasMany(RentalOrder::class, 'owner_id');
    }

    /**
     * Get the rental orders placed by the customer.
     */
    public function customerOrders(): HasMany
    {
        return $this->hasMany(RentalOrder::class, 'customer_id');
    }
}
