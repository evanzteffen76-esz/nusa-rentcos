<?php

namespace App\Enums;

enum PaymentMethod: string
{
    case PayAtOwner = 'pay_at_owner';
    case BankTransfer = 'bank_transfer';

    /**
     * Determine whether the customer pays the owner in person.
     */
    public function isPayAtOwner(): bool
    {
        return $this === self::PayAtOwner;
    }

    /**
     * Determine whether the customer pays through a bank transfer.
     */
    public function isBankTransfer(): bool
    {
        return $this === self::BankTransfer;
    }

    /**
     * Get the translation key for the payment method label.
     */
    public function label(): string
    {
        return "customer.payment.method_{$this->value}";
    }
}
