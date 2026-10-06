<?php

namespace App\Http\Requests\Customer;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ReturnRentalOrderRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalOrder = $this->route('customerRentalOrder');

        return $rentalOrder instanceof RentalOrder
            && $this->user()?->can('returnOrder', $rentalOrder) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'return_note' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
