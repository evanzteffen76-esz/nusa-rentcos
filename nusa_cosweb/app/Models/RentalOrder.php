<?php

namespace App\Models;

use App\Enums\PaymentMethod;
use App\Enums\RentalOrderStatus;
use Carbon\CarbonImmutable;
use Database\Factories\RentalOrderFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable([
    'owner_id',
    'customer_id',
    'costume_id',
    'quantity',
    'price_per_day',
    'extra_price_per_day',
    'rental_start',
    'rental_end',
    'requested_rental_start',
    'requested_rental_end',
    'return_due_at',
    'total_price',
    'status',
    'payment_method',
    'payment_code',
    'payment_proof_path',
    'customer_note',
    'owner_note',
    'decided_at',
    'approved_at',
    'returned_at',
    'returned_late',
    'completed_at',
    'return_note',
])]
class RentalOrder extends Model
{
    /**
     * Rental days covered by the base price. Renting longer than this adds the
     * costume owner's extra rate for each additional day.
     */
    public const INCLUDED_RENTAL_DAYS = 3;

    /**
     * Upper bound for an approved rental period.
     */
    public const MAX_RENTAL_DAYS = 30;

    public const RETURN_GRACE_DAYS = 1;

    /** @use HasFactory<RentalOrderFactory> */
    use HasFactory;

    /**
     * Get the owner responsible for fulfilling the order.
     */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get the customer who placed the order.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the requested costume.
     */
    public function costume(): BelongsTo
    {
        return $this->belongsTo(Costume::class)->withTrashed();
    }

    /**
     * Get the issue reported for this order, if any.
     */
    public function issue(): HasOne
    {
        return $this->hasOne(RentalIssue::class);
    }

    /**
     * Determine whether the order is waiting for a decision.
     */
    public function isPending(): bool
    {
        return $this->status === RentalOrderStatus::Pending;
    }

    /**
     * Determine whether the order is approved and ready for customer use.
     */
    public function isApproved(): bool
    {
        return $this->status === RentalOrderStatus::Approved;
    }

    /**
     * Determine whether the customer has submitted the return.
     */
    public function isReturned(): bool
    {
        return $this->status === RentalOrderStatus::Returned;
    }

    /**
     * Determine whether the owner has completed the return process.
     */
    public function isCompleted(): bool
    {
        return $this->status === RentalOrderStatus::Completed;
    }

    /**
     * Determine whether the customer pays the owner in person.
     */
    public function isPaidAtOwner(): bool
    {
        return $this->payment_method === PaymentMethod::PayAtOwner;
    }

    /**
     * Determine whether the customer pays through a bank transfer.
     */
    public function isPaidByTransfer(): bool
    {
        return $this->payment_method === PaymentMethod::BankTransfer;
    }

    /**
     * Determine whether a payment proof was attached to the order.
     */
    public function hasPaymentProof(): bool
    {
        return filled($this->payment_proof_path);
    }

    /**
     * Determine whether the customer is past the return deadline.
     */
    public function isReturnOverdue(): bool
    {
        return $this->isApproved()
            && $this->return_due_at !== null
            && today()->isAfter($this->return_due_at);
    }

    /**
     * Determine whether the customer returned the costume after the deadline.
     */
    public function wasReturnedLate(): bool
    {
        return (bool) $this->returned_late;
    }

    /**
     * Get the inclusive number of days between two dates.
     *
     * A single day counts as 1, never 0.
     */
    public static function daysBetween(mixed $start, mixed $end): int
    {
        $from = CarbonImmutable::parse($start)->startOfDay();
        $to = CarbonImmutable::parse($end)->startOfDay();

        return max(1, (int) $from->diffInDays($to) + 1);
    }

    /**
     * Get the number of rental days covered by the order.
     */
    public function durationInDays(): int
    {
        $start = ($this->approved_at ? $this->rental_start : $this->requested_rental_start) ?? $this->rental_start;
        $end = ($this->approved_at ? $this->rental_end : $this->requested_rental_end) ?? $this->rental_end;

        return self::daysBetween($start, $end);
    }

    /**
     * Calculate the total rental price for a duration and quantity.
     *
     * The first INCLUDED_RENTAL_DAYS are covered by the base price; each day
     * beyond that adds the owner's extra rate. This is the single source of
     * truth used by booking, approval and the API so they cannot drift apart.
     */
    public static function priceFor(int $basePrice, int $extraRate, int $days, int $quantity): int
    {
        $extraDays = self::extraDaysFor($days);

        return ($basePrice + ($extraRate * $extraDays)) * max(1, $quantity);
    }

    /**
     * Get the number of billable days beyond the included period.
     */
    public static function extraDaysFor(int $days): int
    {
        return max(0, $days - self::INCLUDED_RENTAL_DAYS);
    }

    /**
     * Get the billable days beyond the included period for this order.
     */
    public function extraDays(): int
    {
        return self::extraDaysFor($this->durationInDays());
    }

    /**
     * Get the extra fee charged for renting past the included period.
     */
    public function extraFeeTotal(): int
    {
        return $this->extra_price_per_day * $this->extraDays() * max(1, $this->quantity);
    }

    /**
     * Get the part of the total covered by the included period.
     */
    public function includedFeeTotal(): int
    {
        return $this->price_per_day * max(1, $this->quantity);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'rental_start' => 'date',
            'rental_end' => 'date',
            'requested_rental_start' => 'date',
            'requested_rental_end' => 'date',
            'return_due_at' => 'date',
            'quantity' => 'integer',
            'price_per_day' => 'integer',
            'extra_price_per_day' => 'integer',
            'total_price' => 'integer',
            'status' => RentalOrderStatus::class,
            'payment_method' => PaymentMethod::class,
            'decided_at' => 'datetime',
            'approved_at' => 'datetime',
            'returned_at' => 'datetime',
            'returned_late' => 'boolean',
            'completed_at' => 'datetime',
        ];
    }
}
