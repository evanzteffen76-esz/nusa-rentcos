<?php

namespace App\Http\Requests\Customer;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ReportLostCostumeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalOrder = $this->route('customerRentalOrder');

        return $rentalOrder instanceof RentalOrder
            && $this->user()?->can('reportLostCostume', $rentalOrder) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'description' => ['required', 'string', 'max:1000'],
            'replacement_cost' => ['required', 'integer', 'min:1', 'max:100000000'],
            'replacement_proof' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
        ];
    }
}
