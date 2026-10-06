<?php

namespace App\Http\Resources;

use App\Enums\PaymentMethod;
use App\Enums\RentalOrderStatus;
use App\Models\RentalOrder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RentalOrderResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $status = $this->status instanceof RentalOrderStatus ? $this->status->value : (string) $this->status;
        $user = $request->user();
        $paymentMethod = $this->payment_method instanceof PaymentMethod
            ? $this->payment_method
            : ($this->payment_method !== null ? PaymentMethod::tryFrom((string) $this->payment_method) : null);

        return [
            'id' => $this->id,
            'owner_id' => $this->owner_id,
            'customer_id' => $this->customer_id,
            'costume_id' => $this->costume_id,
            'status' => $status,
            'quantity' => $this->quantity,
            'rental_start' => ($this->rental_start ?? $this->requested_rental_start)?->toDateString(),
            'rental_end' => ($this->rental_end ?? $this->requested_rental_end)?->toDateString(),
            'requested_rental_start' => $this->requested_rental_start?->toDateString(),
            'requested_rental_end' => $this->requested_rental_end?->toDateString(),
            'return_due_at' => $this->return_due_at?->toDateString(),
            'duration_in_days' => $this->durationInDays(),
            // Price breakdown. The rates are a snapshot taken when the order was
            // priced, so a later costume rate change never rewrites the history.
            'price_per_day' => $this->price_per_day,
            'extra_price_per_day' => $this->extra_price_per_day,
            'extra_days' => $this->extraDays(),
            'included_fee_total' => $this->includedFeeTotal(),
            'extra_fee_total' => $this->extraFeeTotal(),
            'included_rental_days' => RentalOrder::INCLUDED_RENTAL_DAYS,
            'total_price' => $this->total_price,
            'customer_note' => $this->customer_note,
            'owner_note' => $this->owner_note,
            'decided_at' => $this->decided_at?->toISOString(),
            'approved_at' => $this->approved_at?->toISOString(),
            'returned_at' => $this->returned_at?->toISOString(),
            'returned_late' => $this->wasReturnedLate(),
            'completed_at' => $this->completed_at?->toISOString(),
            'return_note' => $this->return_note,
            'is_return_overdue' => $this->isReturnOverdue(),
            // Payment. `payment_code` is only issued for a pay-at-owner order;
            // `has_payment_proof` is only true for a bank transfer with an
            // uploaded receipt. The proof itself is served by a separate
            // authenticated download endpoint, never inlined here.
            'payment_method' => $paymentMethod?->value,
            'payment_code' => $this->payment_code,
            'is_paid_at_owner' => $paymentMethod?->isPayAtOwner() ?? false,
            'is_paid_by_transfer' => $paymentMethod?->isBankTransfer() ?? false,
            'has_payment_proof' => $this->hasPaymentProof(),
            'payment_proof_filename' => $this->hasPaymentProof()
                ? basename((string) $this->payment_proof_path)
                : null,
            'can_view_payment_proof' => $user !== null
                && $this->hasPaymentProof()
                && ($this->customer_id === $user->getAuthIdentifier()
                    || $this->owner_id === $user->getAuthIdentifier()
                    || $user->isAdmin()),
            'customer' => UserResource::make($this->whenLoaded('customer')),
            'owner' => UserResource::make($this->whenLoaded('owner')),
            // Bank coordinates of the supplier, needed to complete a transfer.
            'owner_bank' => $this->whenLoaded('owner')
                ? BankDetailsResource::make($this->owner)
                : null,
            'costume' => CostumeResource::make($this->whenLoaded('costume')),
            'issue' => RentalIssueResource::make($this->whenLoaded('issue')),
            'can_approve' => $user?->can('approve', $this->resource) ?? false,
            'can_reject' => $user?->can('reject', $this->resource) ?? false,
            'can_return' => ($user?->can('returnOrder', $this->resource) ?? false)
                && ($this->rental_end === null || ! today()->lt($this->rental_end)),
            'can_report_lost' => $user?->can('reportLostCostume', $this->resource) ?? false,
            'can_complete' => $user?->can('completeReturn', $this->resource) ?? false,
            'can_report_stain' => $user?->can('reportStain', $this->resource) ?? false,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}