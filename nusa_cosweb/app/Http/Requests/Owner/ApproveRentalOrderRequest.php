<?php

namespace App\Http\Requests\Owner;

use App\Models\RentalOrder;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class ApproveRentalOrderRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $rentalOrder = $this->route('ownerRentalOrder');

        return $rentalOrder instanceof RentalOrder
            && $this->user()?->can('approve', $rentalOrder) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'payment_code' => ['nullable', 'string', 'max:32'],
            'owner_note' => ['nullable', 'string', 'max:1000'],
            // Optional: the quick-approve buttons omit it, and an omitted value
            // falls back to the included period.
            'rental_days' => [
                'nullable',
                'integer',
                'min:'.RentalOrder::INCLUDED_RENTAL_DAYS,
                'max:'.RentalOrder::MAX_RENTAL_DAYS,
            ],
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
                if ($validator->errors()->has('payment_code')) {
                    return;
                }

                $rentalOrder = $this->route('ownerRentalOrder');

                if (! $rentalOrder instanceof RentalOrder || ! $rentalOrder->isPaidAtOwner()) {
                    return;
                }

                $submitted = $this->normalizeCode($this->string('payment_code')->toString());
                $expected = $this->normalizeCode((string) $rentalOrder->payment_code);

                if ($submitted === '') {
                    $validator->errors()->add('payment_code', __('owner.orders.code_required'));

                    return;
                }

                if ($expected === '' || ! $this->matchesCode($expected, $submitted)) {
                    $validator->errors()->add('payment_code', __('owner.orders.code_mismatch'));
                }
            },
        ];
    }

    /**
     * Compare the submitted code, allowing the customer prefix to be omitted.
     */
    private function matchesCode(string $expected, string $submitted): bool
    {
        if (hash_equals($expected, $submitted)) {
            return true;
        }

        $prefix = 'COSPAY';

        return str_starts_with($expected, $prefix)
            && strlen($expected) > strlen($prefix)
            && hash_equals(substr($expected, strlen($prefix)), $submitted);
    }

    /**
     * Normalize a payment code for comparison.
     */
    private function normalizeCode(string $code): string
    {
        return (string) preg_replace('/[^A-Z0-9]/', '', strtoupper($code));
    }
}
