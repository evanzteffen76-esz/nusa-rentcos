<?php

namespace App\Policies;

use App\Models\RentalIssue;
use App\Models\User;

class RentalIssuePolicy
{
    /**
     * Determine whether the owner can view an issue.
     */
    public function view(User $user, RentalIssue $rentalIssue): bool
    {
        return $user->isCosrentOwner()
            && $user->id === $rentalIssue->rentalOrder?->owner_id;
    }

    /**
     * Determine whether the owner can resolve an issue.
     */
    public function resolve(User $user, RentalIssue $rentalIssue): bool
    {
        return $this->view($user, $rentalIssue) && $rentalIssue->isOpen();
    }
}
