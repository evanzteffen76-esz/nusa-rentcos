@props(['tab' => 'login'])

@php
    $isRegister = $tab === 'register';
@endphp

<div class="auth-card w-full overflow-hidden rounded-[2rem] border border-white/80 bg-white/90 p-2 shadow-[0_24px_80px_-28px_rgba(30,24,70,0.35)] backdrop-blur-xl dark:border-slate-700 dark:bg-slate-900/90">
    <div class="rounded-[1.5rem] bg-slate-50/80 p-5 sm:p-7 dark:bg-slate-900/80">
        <div class="flex items-start justify-between gap-4">
            <div>
                <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('site.auth.member_access') }}</p>
                <h1 class="mt-2 text-2xl font-extrabold tracking-[-0.04em] text-slate-950 dark:text-white sm:text-[1.75rem]">
                    {{ $isRegister ? __('site.auth.register_title') : __('site.auth.login_title') }}
                </h1>
                <p class="mt-2 max-w-sm text-sm leading-6 text-slate-500 dark:text-slate-400">
                    {{ $isRegister ? __('site.auth.register_description') : __('site.auth.description') }}
                </p>
            </div>
            <span class="hidden h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-violet-100 text-violet-700 dark:bg-violet-950 dark:text-violet-300 sm:flex">
                <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                    <path d="M12 3.5 14.25 8l4.75.7-3.45 3.35.82 4.75L12 14.5l-4.37 2.3.82-4.75L5 8.7 9.75 8 12 3.5Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                </svg>
            </span>
        </div>

        <nav class="mt-7 grid grid-cols-2 rounded-2xl bg-slate-200/70 p-1 dark:bg-slate-800" aria-label="{{ __('site.auth.member_access') }}">
            <a
                href="{{ route('login') }}"
                @if (! $isRegister) aria-current="page" @endif
                @class([
                    'rounded-xl px-4 py-3 text-center text-sm font-bold transition',
                    'bg-white text-slate-950 shadow-sm dark:bg-slate-700 dark:text-white' => ! $isRegister,
                    'text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200' => $isRegister,
                ])
            >
                {{ __('site.auth.tab_login') }}
            </a>
            <a
                href="{{ route('register') }}"
                @if ($isRegister) aria-current="page" @endif
                @class([
                    'rounded-xl px-4 py-3 text-center text-sm font-bold transition',
                    'bg-white text-slate-950 shadow-sm dark:bg-slate-700 dark:text-white' => $isRegister,
                    'text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200' => ! $isRegister,
                ])
            >
                {{ __('site.auth.tab_register') }}
            </a>
        </nav>

        <div class="mt-6">
            @if (session('status'))
                <div class="mb-5 rounded-2xl border border-emerald-100 bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-950/30 dark:text-emerald-300" role="status">
                    {{ session('status') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="mb-5 rounded-2xl border border-rose-100 bg-rose-50 px-4 py-3 text-sm text-rose-700 dark:border-rose-500/30 dark:bg-rose-950/30 dark:text-rose-300" role="alert">
                    <p class="font-bold">{{ __('site.auth.error_title') }}</p>
                    <p class="mt-1 text-xs leading-5 text-rose-600 dark:text-rose-400">{{ __('site.auth.error_description') }}</p>
                </div>
            @endif

            @if ($isRegister)
                <form method="POST" action="{{ route('register') }}" class="space-y-5">
                    @csrf

                    <div>
                        <label for="register-name" class="auth-label">{{ __('site.auth.register_name') }}</label>
                        <input
                            id="register-name"
                            name="name"
                            type="text"
                            value="{{ old('name') }}"
                            autocomplete="name"
                            placeholder="{{ __('site.auth.register_name_placeholder') }}"
                            required
                            autofocus
                            class="auth-input mt-2 {{ $errors->has('name') ? 'auth-input-error' : '' }}"
                        >
                        @error('name')
                            <p class="auth-error" role="alert">{{ $message }}</p>
                        @enderror
                    </div>

                    <fieldset>
                        <legend class="auth-label">{{ __('site.auth.account_type') }}</legend>
                        <p class="mt-1 text-xs leading-5 text-slate-500 dark:text-slate-400">{{ __('site.auth.account_type_description') }}</p>
                        <div class="mt-3 grid gap-2.5 sm:grid-cols-2">
                            <label class="relative cursor-pointer rounded-2xl border bg-white/75 p-3 transition has-[:checked]:border-violet-500 has-[:checked]:bg-violet-50 dark:border-slate-700 dark:bg-slate-900/75 dark:has-[:checked]:border-violet-400 dark:has-[:checked]:bg-violet-950/40 {{ old('account_type', 'customer') === 'customer' ? 'border-violet-500 bg-violet-50 dark:border-violet-400 dark:bg-violet-950/40' : 'border-slate-200 dark:border-slate-700' }}">
                                <input type="radio" name="account_type" value="customer" @checked(old('account_type', 'customer') === 'customer') class="sr-only">
                                <span class="block text-sm font-extrabold text-slate-900 dark:text-slate-100">{{ __('site.auth.customer') }}</span>
                                <span class="mt-1 block text-[0.68rem] leading-4 text-slate-500 dark:text-slate-400">{{ __('site.auth.customer_description') }}</span>
                            </label>
                            <label class="relative cursor-pointer rounded-2xl border bg-white/75 p-3 transition has-[:checked]:border-violet-500 has-[:checked]:bg-violet-50 dark:border-slate-700 dark:bg-slate-900/75 dark:has-[:checked]:border-violet-400 dark:has-[:checked]:bg-violet-950/40 {{ old('account_type') === 'cosrent_owner' ? 'border-violet-500 bg-violet-50 dark:border-violet-400 dark:bg-violet-950/40' : 'border-slate-200 dark:border-slate-700' }}">
                                <input type="radio" name="account_type" value="cosrent_owner" @checked(old('account_type') === 'cosrent_owner') class="sr-only">
                                <span class="block text-sm font-extrabold text-slate-900 dark:text-slate-100">{{ __('site.auth.cosrent_owner') }}</span>
                                <span class="mt-1 block text-[0.68rem] leading-4 text-slate-500 dark:text-slate-400">{{ __('site.auth.cosrent_owner_description') }}</span>
                            </label>
                        </div>
                        @error('account_type')
                            <p class="auth-error" role="alert">{{ $message }}</p>
                        @enderror
                    </fieldset>

                    <div>
                        <label for="register-email" class="auth-label">{{ __('site.auth.email') }}</label>
                        <div class="relative mt-2">
                            <svg viewBox="0 0 24 24" fill="none" class="auth-input-icon" aria-hidden="true">
                                <path d="M4 6.75h16v10.5H4V6.75Zm.75.75L12 13l7.25-5.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                            <input
                                id="register-email"
                                name="email"
                                type="email"
                                value="{{ old('email') }}"
                                autocomplete="email"
                                placeholder="{{ __('site.auth.email_placeholder') }}"
                                required
                                class="auth-input auth-input-with-icon {{ $errors->has('email') ? 'auth-input-error' : '' }}"
                            >
                        </div>
                        @error('email')
                            <p class="auth-error" role="alert">{{ $message }}</p>
                        @enderror
                    </div>

                    <div class="grid gap-5 sm:grid-cols-2">
                        <div>
                            <label for="register-password" class="auth-label">{{ __('site.auth.password') }}</label>
                            <input
                                id="register-password"
                                name="password"
                                type="password"
                                autocomplete="new-password"
                                placeholder="{{ __('site.auth.register_password_placeholder') }}"
                                required
                                class="auth-input mt-2 {{ $errors->has('password') ? 'auth-input-error' : '' }}"
                            >
                            @error('password')
                                <p class="auth-error" role="alert">{{ $message }}</p>
                            @enderror
                        </div>
                        <div>
                            <label for="register-password-confirmation" class="auth-label">{{ __('site.auth.confirm') }}</label>
                            <input
                                id="register-password-confirmation"
                                name="password_confirmation"
                                type="password"
                                autocomplete="new-password"
                                placeholder="{{ __('site.auth.confirm_placeholder') }}"
                                required
                                class="auth-input mt-2 {{ $errors->has('password_confirmation') ? 'auth-input-error' : '' }}"
                            >
                            @error('password_confirmation')
                                <p class="auth-error" role="alert">{{ $message }}</p>
                            @enderror
                        </div>
                    </div>

                    <p class="text-xs leading-5 text-slate-400 dark:text-slate-500">{{ __('site.auth.terms') }}</p>

                    <button type="submit" class="auth-submit group">
                        {{ __('site.auth.register_button') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true">
                            <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                </form>
            @else
                <form method="POST" action="{{ route('login') }}" class="space-y-5" x-data="{ showPassword: false }">
                    @csrf

                    <div>
                        <label for="login-email" class="auth-label">{{ __('site.auth.email') }}</label>
                        <div class="relative mt-2">
                            <svg viewBox="0 0 24 24" fill="none" class="auth-input-icon" aria-hidden="true">
                                <path d="M4 6.75h16v10.5H4V6.75Zm.75.75L12 13l7.25-5.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                            <input
                                id="login-email"
                                name="email"
                                type="email"
                                value="{{ old('email') }}"
                                autocomplete="username"
                                placeholder="{{ __('site.auth.email_placeholder') }}"
                                required
                                autofocus
                                class="auth-input auth-input-with-icon {{ $errors->has('email') ? 'auth-input-error' : '' }}"
                            >
                        </div>
                        @error('email')
                            <p class="auth-error" role="alert">{{ $message }}</p>
                        @enderror
                    </div>

                    <div>
                        <label for="login-password" class="auth-label">{{ __('site.auth.password') }}</label>
                        <div class="relative mt-2">
                            <svg viewBox="0 0 24 24" fill="none" class="auth-input-icon" aria-hidden="true">
                                <path d="M7 10V7.75a5 5 0 0 1 10 0V10m-11 0h12v9H6v-9Zm6 3v3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                            <input
                                id="login-password"
                                name="password"
                                :type="showPassword ? 'text' : 'password'"
                                autocomplete="current-password"
                                placeholder="{{ __('site.auth.password_placeholder') }}"
                                required
                                class="auth-input auth-input-with-icon auth-input-with-action {{ $errors->has('password') ? 'auth-input-error' : '' }}"
                            >
                            <button
                                type="button"
                                @click="showPassword = ! showPassword"
                                class="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 dark:text-slate-500 dark:hover:bg-slate-800 dark:hover:text-slate-200"
                                aria-label="{{ __('site.auth.password') }}"
                            >
                                <svg x-show="! showPassword" viewBox="0 0 24 24" fill="none" class="h-4 w-4" aria-hidden="true">
                                    <path d="M3.5 12s3.1-5 8.5-5 8.5 5 8.5 5-3.1 5-8.5 5-8.5-5-8.5-5Z" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                                    <circle cx="12" cy="12" r="2.2" stroke="currentColor" stroke-width="1.7"/>
                                </svg>
                                <svg x-show="showPassword" x-cloak viewBox="0 0 24 24" fill="none" class="h-4 w-4" aria-hidden="true">
                                    <path d="m4 4 16 16M10.6 6.9c.45-.1.92-.15 1.4-.15 5.4 0 8.5 5.25 8.5 5.25a15.2 15.2 0 0 1-3.2 3.6M6.7 6.8C4.65 8.1 3.5 12 3.5 12s3.1 5.25 8.5 5.25c.7 0 1.35-.09 1.95-.25" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </button>
                        </div>
                        @error('password')
                            <p class="auth-error" role="alert">{{ $message }}</p>
                        @enderror
                    </div>

                    <div class="flex flex-wrap items-center justify-between gap-3">
                        <label for="remember-me" class="inline-flex cursor-pointer items-center gap-2.5 text-sm font-medium text-slate-500 dark:text-slate-400">
                            <input id="remember-me" type="checkbox" name="remember" value="1" class="auth-checkbox">
                            <span>{{ __('site.auth.remember') }}</span>
                        </label>
                        <a href="{{ route('password.request') }}" class="text-xs font-bold text-violet-600 transition hover:text-violet-800">{{ __('site.auth.forgot') }}</a>
                    </div>

                    <button type="submit" class="auth-submit group">
                        {{ __('site.auth.login_button') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true">
                            <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                </form>
            @endif
        </div>

        <p class="mt-6 flex items-center justify-center gap-2 text-center text-[0.68rem] font-semibold text-slate-400 dark:text-slate-500">
            <svg viewBox="0 0 24 24" fill="none" class="h-3.5 w-3.5" aria-hidden="true">
                <path d="M7.5 10V7.5a4.5 4.5 0 0 1 9 0V10m-10.5 0h12v9h-12v-9Z" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            {{ __('site.auth.secure') }}
        </p>
    </div>
</div>
