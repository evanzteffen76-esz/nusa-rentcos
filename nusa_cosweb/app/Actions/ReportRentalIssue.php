<?php

namespace App\Actions;

use App\Enums\RentalIssueStatus;
use App\Enums\RentalIssueType;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ReportRentalIssue
{
    /**
     * Create a stain or lost-costume report for an order.
     *
     * @throws ValidationException
     */
    public function handle(
        RentalOrder $rentalOrder,
        RentalIssueType $type,
        User $reporter,
        string $description,
        ?string $evidencePath,
        int $fineAmount = 0,
        ?int $replacementCost = null,
    ): RentalIssue {
        return DB::transaction(function () use (
            $rentalOrder,
            $type,
            $reporter,
            $description,
            $evidencePath,
            $fineAmount,
            $replacementCost,
        ): RentalIssue {
            $lockedOrder = RentalOrder::query()
                ->with('issue')
                ->lockForUpdate()
                ->findOrFail($rentalOrder->id);

            if ($lockedOrder->issue()->exists()) {
                throw ValidationException::withMessages([
                    'issue' => __('rental_issues.duplicate_error'),
                ]);
            }

            if ($type === RentalIssueType::Stain && ! $lockedOrder->isReturned()) {
                throw ValidationException::withMessages([
                    'issue' => __('owner.issues.stain_status_error'),
                ]);
            }

            if ($type === RentalIssueType::Lost && ! $lockedOrder->isApproved()) {
                throw ValidationException::withMessages([
                    'issue' => __('customer.issues.lost_status_error'),
                ]);
            }

            if ($type === RentalIssueType::Stain && ($fineAmount < 1 || blank($evidencePath))) {
                throw ValidationException::withMessages([
                    'issue' => __('owner.issues.stain_evidence_error'),
                ]);
            }

            if ($type === RentalIssueType::Lost && (blank($evidencePath) || $replacementCost === null || $replacementCost < 1)) {
                throw ValidationException::withMessages([
                    'issue' => __('customer.issues.replacement_evidence_error'),
                ]);
            }

            return RentalIssue::query()->create([
                'rental_order_id' => $lockedOrder->id,
                'reporter_id' => $reporter->id,
                'type' => $type,
                'status' => RentalIssueStatus::Open,
                'description' => trim($description),
                'evidence_path' => $evidencePath,
                'fine_amount' => $type === RentalIssueType::Stain ? $fineAmount : 0,
                'replacement_cost' => $type === RentalIssueType::Lost ? $replacementCost : null,
                'replacement_submitted_at' => $type === RentalIssueType::Lost ? now() : null,
            ]);
        }, 3);
    }
}
