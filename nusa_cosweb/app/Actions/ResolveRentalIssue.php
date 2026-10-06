<?php

namespace App\Actions;

use App\Enums\RentalIssueStatus;
use App\Enums\RentalOrderStatus;
use App\Models\RentalIssue;
use App\Models\RentalOrder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ResolveRentalIssue
{
    /**
     * Resolve an issue after its fine is paid or replacement costume is received.
     *
     * @throws ValidationException
     */
    public function handle(
        RentalIssue $rentalIssue,
        bool $finePaid = false,
        bool $replacementReceived = false,
        ?string $resolutionNote = null,
    ): RentalIssue {
        return DB::transaction(function () use (
            $rentalIssue,
            $finePaid,
            $replacementReceived,
            $resolutionNote,
        ): RentalIssue {
            $lockedIssue = RentalIssue::query()
                ->lockForUpdate()
                ->findOrFail($rentalIssue->id);

            if (! $lockedIssue->isOpen()) {
                throw ValidationException::withMessages([
                    'issue' => __('rental_issues.resolved_error'),
                ]);
            }

            $updates = [
                'status' => RentalIssueStatus::Resolved,
                'resolved_at' => now(),
                'resolution_note' => filled($resolutionNote) ? trim($resolutionNote) : null,
            ];

            if ($lockedIssue->isStain()) {
                if (! $finePaid) {
                    throw ValidationException::withMessages([
                        'issue' => __('owner.issues.fine_payment_required'),
                    ]);
                }

                $updates['fine_paid_at'] = now();
            }

            if ($lockedIssue->isLost()) {
                if (! $replacementReceived) {
                    throw ValidationException::withMessages([
                        'issue' => __('owner.issues.replacement_receipt_required'),
                    ]);
                }

                $updates['replacement_received_at'] = now();
            }

            $lockedIssue->update($updates);

            $order = RentalOrder::query()->lockForUpdate()->findOrFail($lockedIssue->rental_order_id);
            $order->update([
                'status' => RentalOrderStatus::Completed,
                'completed_at' => now(),
            ]);

            return $lockedIssue->fresh(['rentalOrder:id,status,completed_at']);
        }, 3);
    }
}
