<?php

namespace App\Http\Requests\Api\V1;

use App\Models\User;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\Validator;

class UpdateProfileRequest extends FormRequest
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
        $userId = $this->user()?->getKey();

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'username' => [
                'sometimes',
                'nullable',
                'string',
                'min:3',
                'max:50',
                'regex:/^[a-z0-9._-]+$/',
                Rule::unique(User::class, 'username')->ignore($userId),
            ],
            'email' => [
                'sometimes',
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique(User::class, 'email')->ignore($userId),
            ],
            'password' => ['sometimes', 'nullable', 'confirmed', Password::defaults()],
            'current_password' => ['required_with:password', 'nullable', 'string'],
            // Bank coordinates a customer uses to fund a transfer. The trio is
            // checked as a unit in withValidator(), because `required_with_all`
            // only fires when the *other* fields are present and would happily
            // accept a lone `bank_name`.
            'bank_name' => ['nullable', 'string', 'max:120'],
            'bank_account_number' => ['nullable', 'string', 'max:64'],
            'bank_account_holder' => ['nullable', 'string', 'max:120'],
        ];
    }

    /**
     * Get the custom validation messages for the bank fields.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'bank_name.bank_trio' => __('customer.payment.bank_missing'),
            'bank_account_number.bank_trio' => __('customer.payment.bank_missing'),
            'bank_account_holder.bank_trio' => __('customer.payment.bank_missing'),
        ];
    }

    /**
     * Confirm the caller owns the account before changing its password, and
     * keep the bank fields consistent with each other.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->guardBankDetails($validator);

            if (! $this->filled('password')) {
                return;
            }

            $current = (string) $this->input('current_password');
            $user = $this->user();

            if ($user === null || ! Hash::check($current, $user->password)) {
                $validator->errors()->add('current_password', 'Password saat ini salah.');
            }
        });
    }

    /**
     * Require the three bank fields together, or all of them empty.
     *
     * Sending only part of the trio would leave an account number a customer
     * can transfer to but nobody can name, so a partial payload is rejected.
     * All three are flagged, not just the ones the client sent, so a form can
     * highlight the whole group. Sending the trio fully empty stays legal and
     * clears the account.
     */
    private function guardBankDetails(Validator $validator): void
    {
        $fields = ['bank_name', 'bank_account_number', 'bank_account_holder'];
        $filled = array_values(array_filter(
            $fields,
            fn (string $field): bool => filled($this->input($field)),
        ));

        // Nothing to check: the payload never touches the bank fields.
        if ($filled === []) {
            return;
        }

        if (count($filled) === count($fields)) {
            return;
        }

        foreach ($fields as $field) {
            $validator->errors()->add($field, __('customer.payment.bank_missing'));
        }
    }

    /**
     * Normalize the email and username before validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge(array_filter([
            'email' => $this->filled('email')
                ? Str::lower(trim($this->string('email')->toString()))
                : null,
            'username' => $this->filled('username')
                ? Str::lower(trim($this->string('username')->toString()))
                : null,
        ], static fn (mixed $value): bool => $value !== null));
    }
}
