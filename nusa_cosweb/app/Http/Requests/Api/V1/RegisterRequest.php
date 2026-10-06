<?php

namespace App\Http\Requests\Api\V1;

use App\Models\User;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'username' => [
                'nullable',
                'string',
                'min:3',
                'max:50',
                'regex:/^[a-z0-9._-]+$/',
                Rule::unique(User::class, 'username'),
            ],
            'email' => ['required', 'string', 'email', 'max:255', 'lowercase', Rule::unique(User::class)],
            'password' => ['required', 'confirmed', Password::defaults()],
            'account_type' => ['nullable', Rule::in(['customer', 'cosrent_owner'])],
            'device_name' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * Normalize the email and username before validation.
     */
    protected function prepareForValidation(): void
    {
        if ($this->filled('email')) {
            $this->merge(['email' => Str::lower($this->string('email')->toString())]);
        }
        if ($this->filled('username')) {
            $this->merge(['username' => Str::lower(trim($this->string('username')->toString()))]);
        }
    }
}
