<?php

namespace App\Http\Requests\Api\V1\Customer;

use App\Enums\PaymentMethod;
use App\Models\Costume;
use App\Models\RentalOrder;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreRentalOrderRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()?->can('create', RentalOrder::class) === true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'quantity' => ['required', 'integer', 'min:1', 'max:100'],
            'rental_start' => ['required', Rule::date()->format('Y-m-d')->todayOrAfter()],
            'rental_end' => ['required', 'date_format:Y-m-d', 'after_or_equal:rental_start'],
            'payment_method' => ['required', Rule::enum(PaymentMethod::class)],
            'payment_proof' => [
                Rule::requiredIf($this->isBankTransfer()),
                'nullable',
                'file',
                'mimes:jpg,jpeg,png,webp,pdf',
                'max:5120',
            ],
            'customer_note' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * Get the custom validation messages.
     *
     * The payment method itself falls back to the generic validation strings:
     * the language files only carry the payment *copy*, not the rule
     * descriptions, and the API answers in the default locale anyway.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'payment_proof.required' => __('customer.payment.proof_required'),
            'payment_proof.mimes' => __('customer.payment.proof_invalid'),
            'payment_proof.max' => __('customer.payment.proof_too_large'),
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
                if ($validator->errors()->hasAny(['quantity', 'rental_start', 'rental_end'])) {
                    return;
                }

                $costume = $this->route('apiCostume');

                if (! $costume instanceof Costume) {
                    return;
                }

                $start = CarbonImmutable::parse($this->string('rental_start')->toString());
                $end = CarbonImmutable::parse($this->string('rental_end')->toString());

                if ($this->integer('quantity') > $costume->availableQuantityFor($start, $end)) {
                    $validator->errors()->add('quantity', __('customer.booking.unavailable'));
                }

                if ($this->isBankTransfer() && ! $costume->owner?->hasBankAccount()) {
                    $validator->errors()->add('payment_method', __('customer.payment.bank_missing'));
                }
            },
        ];
    }

    /**
     * Determine whether the customer chose a bank transfer payment.
     */
    public function isBankTransfer(): bool
    {
        return $this->input('payment_method') === PaymentMethod::BankTransfer->value;
    }
}