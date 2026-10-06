<section>
    <header>
        <h2 class="text-lg font-medium text-gray-900">
            {{ __('profile.info_title') }}
        </h2>

        <p class="mt-1 text-sm text-gray-600">
            {{ __('profile.info_description') }}
        </p>
    </header>

    <form id="send-verification" method="post" action="{{ route('verification.send') }}">
        @csrf
    </form>

    <form method="post" action="{{ route('profile.update') }}" class="mt-6 space-y-6">
        @csrf
        @method('patch')

        <div>
            <x-input-label for="name" :value="__('profile.name')" />
            <x-text-input id="name" name="name" type="text" class="mt-1 block w-full" :value="old('name', $user->name)" required autofocus autocomplete="name" />
            <x-input-error class="mt-2" :messages="$errors->get('name')" />
        </div>
        <div>
            <x-input-label for="email" :value="__('profile.email')" />
            <x-text-input id="email" name="email" type="email" class="mt-1 block w-full" :value="old('email', $user->email)" required autocomplete="username" />
            <x-input-error class="mt-2" :messages="$errors->get('email')" />

            @if ($user instanceof \Illuminate\Contracts\Auth\MustVerifyEmail && ! $user->hasVerifiedEmail())
                <div>
                    <p class="text-sm mt-2 text-gray-800">
                        {{ __('profile.unverified') }}

                        <button form="send-verification" class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            {{ __('profile.resend') }}
                        </button>
                    </p>

                    @if (session('status') === 'verification-link-sent')
                        <p class="mt-2 font-medium text-sm text-green-600">
                            {{ __('profile.verification_sent') }}
                        </p>
                    @endif
                </div>
            @endif
        </div>

        @if ($user->isCosrentOwner())
            <div class="rounded-2xl border border-slate-200 bg-slate-50 p-5">
                <p class="text-sm font-extrabold text-slate-800">{{ __('profile.bank_title') }}</p>
                <p class="mt-1 text-xs leading-5 text-slate-500">{{ __('profile.bank_description') }}</p>

                <div class="mt-4 space-y-4">
                    <div>
                        <x-input-label for="bank_name" :value="__('profile.bank_name')" />
                        <x-text-input id="bank_name" name="bank_name" type="text" class="mt-1 block w-full" :value="old('bank_name', $user->bank_name)" maxlength="80" placeholder="BCA" />
                        <x-input-error class="mt-2" :messages="$errors->get('bank_name')" />
                    </div>

                    <div>
                        <x-input-label for="bank_account_number" :value="__('profile.bank_account_number')" />
                        <x-text-input id="bank_account_number" name="bank_account_number" type="text" inputmode="numeric" class="mt-1 block w-full" :value="old('bank_account_number', $user->bank_account_number)" maxlength="64" placeholder="1234567890" />
                        <x-input-error class="mt-2" :messages="$errors->get('bank_account_number')" />
                    </div>

                    <div>
                        <x-input-label for="bank_account_holder" :value="__('profile.bank_account_holder')" />
                        <x-text-input id="bank_account_holder" name="bank_account_holder" type="text" class="mt-1 block w-full" :value="old('bank_account_holder', $user->bank_account_holder)" maxlength="120" placeholder="Nama pemilik rekening" />
                        <x-input-error class="mt-2" :messages="$errors->get('bank_account_holder')" />
                    </div>
                </div>
            </div>
        @endif

        <div class="flex items-center gap-4">
            <x-primary-button>{{ __('profile.save') }}</x-primary-button>

            @if (session('status') === 'profile-updated')
                <p
                    x-data="{ show: true }"
                    x-show="show"
                    x-transition
                    x-init="setTimeout(() => show = false, 2000)"
                    class="text-sm text-gray-600"
                >{{ __('profile.saved') }}</p>
            @endif
        </div>
    </form>
</section>
