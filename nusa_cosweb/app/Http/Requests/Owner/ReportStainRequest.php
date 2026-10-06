<?php

namespace App\Http\Requests\Owner;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ReportStainRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalOrder = $this->route('ownerRentalOrder');

        return $rentalOrder instanceof RentalOrder
            && $this->user()?->can('reportStain', $rentalOrder) === true;
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
            'fine_amount' => ['required', 'integer', 'min:1', 'max:100000000'],
            'evidence' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
        ];
    }
}
