<?php

namespace App\Http\Resources;

use App\Enums\RentalIssueStatus;
use App\Enums\RentalIssueType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RentalIssueResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $type = $this->type instanceof RentalIssueType ? $this->type->value : (string) $this->type;
        $status = $this->status instanceof RentalIssueStatus ? $this->status->value : (string) $this->status;

        return [
            'id' => $this->id,
            'rental_order_id' => $this->rental_order_id,
            'type' => $type,
            'status' => $status,
            'is_open' => $this->isOpen(),
            'description' => $this->description,
            'fine_amount' => $this->fine_amount,
            'fine_paid' => $this->fineIsPaid(),
            'fine_paid_at' => $this->fine_paid_at?->toISOString(),
            'replacement_cost' => $this->replacement_cost,
            'replacement_submitted_at' => $this->replacement_submitted_at?->toISOString(),
            'replacement_received_at' => $this->replacement_received_at?->toISOString(),
            'resolved_at' => $this->resolved_at?->toISOString(),
            'resolution_note' => $this->resolution_note,
            'has_evidence' => filled($this->evidence_path),
            'evidence_url' => $this->when(
                request()->user()?->isCosrentOwner() && filled($this->evidence_path),
                fn (): string => route('api.v1.owner.issues.evidence', [
                    'ownerOrder' => $this->rental_order_id,
                    'ownerIssue' => $this->id,
                ]),
            ),
            'reporter' => UserResource::make($this->whenLoaded('reporter')),
            'customer' => UserResource::make($this->whenLoaded('rentalOrder.customer')),
            'costume' => CostumeResource::make($this->whenLoaded('rentalOrder.costume')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
