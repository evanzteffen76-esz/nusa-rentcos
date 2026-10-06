<?php

namespace App\Actions;

use App\Models\RentalOrder;

class GeneratePaymentCode
{
    /**
     * The characters used for a payment code, without ambiguous glyphs.
     */
    private const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    /**
     * The number of characters per code segment.
     */
    private const SEGMENT_LENGTH = 4;

    /**
     * Generate a unique payment code for a pay-at-owner order.
     */
    public function handle(): string
    {
        do {
            $code = 'COSPAY-'.$this->segment().'-'.$this->segment();
        } while (RentalOrder::query()->where('payment_code', $code)->exists());

        return $code;
    }

    /**
     * Build a random code segment.
     */
    private function segment(): string
    {
        $characters = '';

        for ($index = 0; $index < self::SEGMENT_LENGTH; $index++) {
            $characters .= self::ALPHABET[random_int(0, strlen(self::ALPHABET) - 1)];
        }

        return $characters;
    }
}
