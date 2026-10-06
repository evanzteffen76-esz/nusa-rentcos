<?php

namespace App\Models;

use App\Enums\RentalIssueStatus;
use App\Enums\RentalIssueType;
use Database\Factories\RentalIssueFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'rental_order_id',
    'reporter_id',
    'type',
    'status',
    'description',
    'evidence_path',
    'fine_amount',
    'replacement_cost',
    'fine_paid_at',
    'replacement_submitted_at',
    'replacement_received_at',
    'resolved_at',
    'resolution_note',
])]
class RentalIssue extends Model
{
    /** @use HasFactory<RentalIssueFactory> */
    use HasFactory;

    /**
     * Get the order affected by the issue.
     */
    public function rentalOrder(): BelongsTo
    {
        return $this->belongsTo(RentalOrder::class);
    }

    /**
     * Get the customer or owner who reported the issue.
     */
    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    /**
     * Determine whether the issue is still awaiting resolution.
     */
    public function isOpen(): bool
    {
        return $this->status === RentalIssueStatus::Open;
    }

    /**
     * Determine whether the issue concerns a stain.
     */
    public function isStain(): bool
    {
        return $this->type === RentalIssueType::Stain;
    }

    /**
     * Determine whether the issue concerns a lost costume.
     */
    public function isLost(): bool
    {
        return $this->type === RentalIssueType::Lost;
    }

    /**
     * Determine whether the damage fine has been paid.
     */
    public function fineIsPaid(): bool
    {
        return $this->fine_amount === 0 || $this->fine_paid_at !== null;
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => RentalIssueType::class,
            'status' => RentalIssueStatus::class,
            'fine_amount' => 'integer',
            'replacement_cost' => 'integer',
            'fine_paid_at' => 'datetime',
            'replacement_submitted_at' => 'datetime',
            'replacement_received_at' => 'datetime',
            'resolved_at' => 'datetime',
        ];
    }
}
