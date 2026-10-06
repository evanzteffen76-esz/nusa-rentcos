<?php

namespace App\Http\Requests;

use App\Models\User;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProfileUpdateRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $required = $this->user()?->isCosrentOwner() === true ? 'required' : 'nullable';

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                Rule::unique(User::class)->ignore($this->user()->id),
            ],
            'bank_name' => [$required, 'string', 'max:80'],
            'bank_account_number' => [$required, 'string', 'max:64', 'regex:/^[0-9][0-9\s-]{3,63}$/'],
            'bank_account_holder' => [$required, 'string', 'max:120'],
        ];
    }
}
