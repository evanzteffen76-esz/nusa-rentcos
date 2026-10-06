<?php

namespace App\Policies;

use App\Models\Costume;
use App\Models\User;

class CostumePolicy
{
    /**
     * Determine whether the user can manage costume listings.
     */
    public function viewAny(User $user): bool
    {
        return $user->isCosrentOwner();
    }

    /**
     * Determine whether the user can view the costume listing.
     */
    public function view(User $user, Costume $costume): bool
    {
        return $user->isCosrentOwner() && $user->id === $costume->owner_id;
    }

    /**
     * Determine whether the user can create a costume listing.
     */
    public function create(User $user): bool
    {
        return $user->isCosrentOwner();
    }

    /**
     * Determine whether the user can update the costume listing.
     */
    public function update(User $user, Costume $costume): bool
    {
        return $this->view($user, $costume);
    }

    /**
     * Determine whether the user can remove the costume listing.
     */
    public function delete(User $user, Costume $costume): bool
    {
        return $this->view($user, $costume);
    }
}
