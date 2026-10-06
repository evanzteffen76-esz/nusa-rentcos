<?php

namespace App\Policies;

use App\Models\RentalOrder;
use App\Models\User;

class RentalOrderPolicy
{
    /**
     * Determine whether the user can review owner orders.
     */
    public function viewAny(User $user): bool
    {
        return $user->isCosrentOwner();
    }

    /**
     * Determine whether the user can view the rental order.
     */
    public function view(User $user, RentalOrder $rentalOrder): bool
    {
        return $user->isCosrentOwner() && $user->id === $rentalOrder->owner_id;
    }

    /**
     * Determine whether the user can place a customer booking.
     */
    public function create(User $user): bool
    {
        return ! $user->isAdmin() && ! $user->isCosrentOwner();
    }

    /**
     * Determine whether the owner can approve the rental order.
     */
    public function approve(User $user, RentalOrder $rentalOrder): bool
    {
        return $this->view($user, $rentalOrder) && $rentalOrder->isPending();
    }

    /**
     * Determine whether the owner can reject the rental order.
     */
    public function reject(User $user, RentalOrder $rentalOrder): bool
    {
        return $this->view($user, $rentalOrder) && $rentalOrder->isPending();
    }

    /**
     * Determine whether the customer can view the rental order.
     */
    public function viewCustomer(User $user, RentalOrder $rentalOrder): bool
    {
        return $user->id === $rentalOrder->customer_id
            && ! $user->isAdmin();
    }

    /**
     * Determine whether the customer can view the payment proof they uploaded.
     */
    public function viewPaymentProof(User $user, RentalOrder $rentalOrder): bool
    {
        return $user->id === $rentalOrder->customer_id
            && ! $user->isAdmin();
    }

    /**
     * Determine whether the customer can submit the return.
     */
    public function returnOrder(User $user, RentalOrder $rentalOrder): bool
    {
        return $user->id === $rentalOrder->customer_id
            && ! $user->isAdmin()
            && $rentalOrder->isApproved()
            && $rentalOrder->issue === null;
    }

    /**
     * Determine whether the customer can report a lost costume.
     */
    public function reportLostCostume(User $user, RentalOrder $rentalOrder): bool
    {
        return $user->id === $rentalOrder->customer_id
            && ! $user->isAdmin()
            && $rentalOrder->isApproved()
            && $rentalOrder->issue === null;
    }

    /**
     * Determine whether the owner can report a stain after a return.
     */
    public function reportStain(User $user, RentalOrder $rentalOrder): bool
    {
        return $this->view($user, $rentalOrder)
            && $rentalOrder->isReturned()
            && $rentalOrder->issue === null;
    }

    /**
     * Determine whether the owner can complete a clean return.
     */
    public function completeReturn(User $user, RentalOrder $rentalOrder): bool
    {
        return $this->view($user, $rentalOrder)
            && $rentalOrder->isReturned()
            && ! $rentalOrder->issue?->isOpen();
    }
}
