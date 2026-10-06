<x-guest-layout>
    <div class="mb-4 text-sm text-gray-600">
        {{ __('auth.forgot.description') }}
    </div>

    <!-- Session Status -->
    <x-auth-session-status class="mb-4" :status="session('status')" />

    <form method="POST" action="{{ route('password.email') }}">
        @csrf

        <!-- Email Address -->
        <div>
            <x-input-label for="email" :value="__('auth.login.email')" />
            <x-text-input id="email" class="mt-1 block w-full" type="email" name="email" :value="old('email')" required autofocus />
            <x-input-error :messages="$errors->get('email')" class="mt-2" />
        </div>

        <div class="mt-4 flex items-center justify-end gap-4">
            <a href="{{ route('login') }}" class="text-sm text-gray-600 underline hover:text-gray-900">
                {{ __('auth.forgot.back') }}
            </a>
            <x-primary-button>
                {{ __('auth.forgot.submit') }}
            </x-primary-button>
        </div>
    </form>
</x-guest-layout>
