<?php

namespace App\Http\Requests\Owner;

use App\Enums\RentalIssueType;
use App\Models\RentalIssue;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class ResolveRentalIssueRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalIssue = $this->route('rentalIssue');

        return $rentalIssue instanceof RentalIssue
            && $this->user()?->can('resolve', $rentalIssue) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'fine_paid' => ['nullable', 'boolean'],
            'replacement_received' => ['nullable', 'boolean'],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * Run validation checks after the field rules pass.
     *
     * @return array<int, callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $rentalIssue = $this->route('rentalIssue');

                if (! $rentalIssue instanceof RentalIssue) {
                    return;
                }

                if ($rentalIssue->type === RentalIssueType::Stain && ! $this->boolean('fine_paid')) {
                    $validator->errors()->add('fine_paid', __('owner.issues.fine_payment_required'));
                }

                if ($rentalIssue->type === RentalIssueType::Lost && ! $this->boolean('replacement_received')) {
                    $validator->errors()->add('replacement_received', __('owner.issues.replacement_receipt_required'));
                }
            },
        ];
    }
}
