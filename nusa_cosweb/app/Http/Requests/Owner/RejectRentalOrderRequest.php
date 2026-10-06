<?php

namespace App\Http\Requests\Owner;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class RejectRentalOrderRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalOrder = $this->route('ownerRentalOrder');

        return $rentalOrder instanceof RentalOrder
            && $this->user()?->can('reject', $rentalOrder) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'owner_note' => ['required', 'string', 'max:1000'],
        ];
    }
}
