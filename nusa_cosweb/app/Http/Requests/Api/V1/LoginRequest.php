<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class LoginRequest extends FormRequest
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
            'login' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * Accept the mobile identifier while remaining compatible with the
     * original email-only API clients.
     */
    protected function prepareForValidation(): void
    {
        $login = $this->input('login')
            ?? $this->input('identifier')
            ?? $this->input('username')
            ?? $this->input('email');

        if (is_string($login)) {
            $this->merge(['login' => Str::lower(trim($login))]);
        }
    }
}
