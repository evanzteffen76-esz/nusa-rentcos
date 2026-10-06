<?php

namespace App\Http\Requests\Api\V1\Owner;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class OrderDecisionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'owner_note' => ['nullable', 'string', 'max:1000'],
            // Only meaningful when approving; an omitted value falls back to the
            // included period so existing quick-approve calls keep working.
            'rental_days' => [
                'nullable',
                'integer',
                'min:'.RentalOrder::INCLUDED_RENTAL_DAYS,
                'max:'.RentalOrder::MAX_RENTAL_DAYS,
            ],
        ];
    }
}
