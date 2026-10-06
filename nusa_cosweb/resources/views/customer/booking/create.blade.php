@use('App\Enums\PaymentMethod')

<x-app-layout>
    <x-slot name="header">
        <a href="{{ route('dashboard') }}" class="inline-flex items-center gap-2 text-sm font-bold text-slate-500 transition hover:text-violet-700">
            <span aria-hidden="true">←</span>
            {{ __('customer.booking.back') }}
        </a>
        <div class="mt-3 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('customer.dashboard.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('customer.booking.title') }}</h2>
                <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">{{ __('customer.booking.description') }}</p>
            </div>
        </div>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            @if ($errors->any())
                <div class="mb-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-bold text-rose-700" role="alert">
                    {{ $errors->first() }}
                </div>
            @endif

            <div
                class="grid gap-6 xl:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)]"
                x-data="{
                    quantity: {{ (int) old('quantity', 1) }},
                    rentalStart: {{ Js::from(old('rental_start', '')) }},
                    rentalEnd: {{ Js::from(old('rental_end', '')) }},
                    pricePerDay: {{ $availableCostume->price_per_day }},
                    extraPricePerDay: {{ $availableCostume->extra_price_per_day }},
                    includedDays: {{ \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS }},
                    paymentMethod: @js(old('payment_method', PaymentMethod::PayAtOwner->value)),
                    hasBankAccount: @js($availableCostume->owner?->hasBankAccount() ?? false),
                    proofRequiredMessage: @js(__('customer.payment.proof_required')),
                    proofName: '',
                    proofError: '',
                    get rentalDays() {
                        if (! this.rentalStart || ! this.rentalEnd) {
                            return this.includedDays;
                        }

                        const start = new Date(this.rentalStart + 'T00:00:00');
                        const end = new Date(this.rentalEnd + 'T00:00:00');

                        if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end < start) {
                            return this.includedDays;
                        }

                        return Math.floor((end - start) / 86400000) + 1;
                    },
                    get extraDays() {
                        return Math.max(0, this.rentalDays - this.includedDays);
                    },
                    get total() {
                        return (this.pricePerDay + this.extraPricePerDay * this.extraDays) * this.quantity;
                    },
                    get isTransfer() {
                        return this.paymentMethod === 'bank_transfer';
                    },
                    onProofSelected(event) {
                        const files = event.target.files;
                        this.proofName = files.length > 0 ? files[0].name : '';
                        this.proofError = '';
                    },
                    paymentReady() {
                        if (! this.isTransfer) {
                            this.proofError = '';
                            return true;
                        }

                        if (this.proofName === '') {
                            this.proofError = this.proofRequiredMessage;
                            this.$nextTick(() => this.$refs.proof?.focus());
                            return false;
                        }

                        this.proofError = '';
                        return true;
                    },
                    formatPrice(value) {
                        return new Intl.NumberFormat('id-ID', {
                            style: 'currency',
                            currency: 'IDR',
                            maximumFractionDigits: 0
                        }).format(value);
                    }
                }"
            >
                <aside class="overflow-hidden rounded-[2rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5">
                    <x-costume-artwork :costume="$availableCostume" class="h-72" />
                    <div class="p-6 sm:p-7">
                        <p class="text-xs font-extrabold uppercase tracking-[0.14em] text-violet-600">{{ __('customer.booking.costume_details') }}</p>
                        <h3 class="mt-3 text-2xl font-extrabold tracking-tight text-slate-950">{{ $availableCostume->name }}</h3>
                        <p class="mt-1 text-sm font-bold text-violet-700">{{ $availableCostume->character_name }}</p>
                        <p class="mt-4 text-sm leading-6 text-slate-500">{{ $availableCostume->description }}</p>
                        <dl class="mt-6 grid grid-cols-2 gap-3">
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-[0.62rem] font-extrabold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.size') }}</dt>
                                <dd class="mt-1 text-sm font-extrabold text-slate-950">{{ $availableCostume->size }}</dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-[0.62rem] font-extrabold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.stock') }}</dt>
                                <dd class="mt-1 text-sm font-extrabold text-slate-950">{{ $availableCostume->stock }}</dd>
                            </div>
                        </dl>
                    </div>
                </aside>

                <form
                    method="POST"
                    action="{{ route('dashboard.costumes.book.store', $availableCostume) }}"
                    enctype="multipart/form-data"
                    x-on:submit="if (! paymentReady()) $event.preventDefault()"
                    class="space-y-6"
                >
                    @csrf
                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-8">
                        <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('customer.booking.requested_period') }}</h3>
                        <p class="mt-2 text-sm leading-6 text-slate-500">{{ __('customer.booking.fixed_period') }}</p>
                        <div class="mt-6 grid gap-5 sm:grid-cols-2">
                            <div>
                                <label for="rental_start" class="text-sm font-extrabold text-slate-800">{{ __('customer.booking.preferred_start') }}</label>
                                <input id="rental_start" name="rental_start" type="date" value="{{ old('rental_start') }}" min="{{ now()->toDateString() }}" required x-model="rentalStart" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                                <x-input-error :messages="$errors->get('rental_start')" class="mt-2" />
                            </div>
                            <div>
                                <label for="rental_end" class="text-sm font-extrabold text-slate-800">{{ __('customer.booking.preferred_end') }}</label>
                                <input id="rental_end" name="rental_end" type="date" value="{{ old('rental_end') }}" min="{{ old('rental_start', now()->toDateString()) }}" required x-model="rentalEnd" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                                <x-input-error :messages="$errors->get('rental_end')" class="mt-2" />
                            </div>
                        </div>

                        <div class="mt-6">
                            <label for="quantity" class="text-sm font-extrabold text-slate-800">{{ __('customer.booking.quantity') }}</label>
                            <input id="quantity" name="quantity" type="number" value="{{ old('quantity', 1) }}" min="1" max="{{ $availableCostume->stock }}" required x-model.number="quantity" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                            <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('customer.booking.quantity_hint') }}</p>
                            <x-input-error :messages="$errors->get('quantity')" class="mt-2" />
                        </div>
                    </section>

                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-8">
                        <fieldset>
                            <legend class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('customer.payment.method_title') }}</legend>
                            <p class="mt-2 text-sm leading-6 text-slate-500">{{ __('customer.payment.method_description') }}</p>

                            <div class="mt-6 grid gap-3 sm:grid-cols-2">
                                @foreach ($paymentMethods as $method)
                                    <label
                                        class="relative cursor-pointer rounded-2xl border p-4 transition has-[:checked]:border-violet-500 has-[:checked]:bg-violet-50 dark:border-slate-700 dark:bg-slate-900/60 dark:has-[:checked]:border-violet-400 dark:has-[:checked]:bg-violet-950/40"
                                        x-bind:class="{
                                            'opacity-50': '{{ $method->value }}' === 'bank_transfer' && ! hasBankAccount,
                                        }"
                                    >
                                        <input
                                            type="radio"
                                            name="payment_method"
                                            value="{{ $method->value }}"
                                            x-model="paymentMethod"
                                            @checked(old('payment_method', PaymentMethod::PayAtOwner->value) === $method->value)
                                            @disabled($method->isBankTransfer() && ! $availableCostume->owner?->hasBankAccount())
                                            class="sr-only"
                                        >
                                        <span class="flex items-start gap-3">
                                            <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl {{ $method->isBankTransfer() ? 'bg-amber-100 text-amber-700' : 'bg-violet-100 text-violet-700' }}">
                                                @if ($method->isBankTransfer())
                                                    <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M3.5 9.5 12 4.5l8.5 5m-17 0h17m-17 0v9h17v-9m-11 9v-4h5v4" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
                                                @else
                                                    <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M12 21s7-5.35 7-11a7 7 0 1 0-14 0c0 5.65 7 11 7 11Z" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><circle cx="12" cy="10" r="2.5" stroke="currentColor" stroke-width="1.6"/></svg>
                                                @endif
                                            </span>
                                            <span class="min-w-0 flex-1">
                                                <span class="block text-sm font-extrabold text-slate-900 dark:text-slate-100">{{ __($method->label()) }}</span>
                                                <span class="mt-1 block text-xs leading-5 text-slate-500 dark:text-slate-400">{{ __($method->isBankTransfer() ? 'customer.payment.method_bank_transfer_hint' : 'customer.payment.method_pay_at_owner_hint') }}</span>

                                                @if ($method->isBankTransfer())
                                                    @if ($availableCostume->owner?->hasBankAccount())
                                                        <span class="mt-3 block space-y-2 rounded-xl border border-amber-200/80 bg-white/80 p-3 dark:border-amber-500/30 dark:bg-slate-900/70">
                                                            <span class="flex flex-wrap items-baseline justify-between gap-2">
                                                                <span class="text-[0.62rem] font-extrabold uppercase tracking-wider text-amber-700 dark:text-amber-300">{{ __('customer.payment.bank_name') }}</span>
                                                                <span class="text-sm font-extrabold text-amber-950 dark:text-amber-100">{{ $availableCostume->owner->bank_name }}</span>
                                                            </span>
                                                            <span class="flex flex-wrap items-baseline justify-between gap-2">
                                                                <span class="text-[0.62rem] font-extrabold uppercase tracking-wider text-amber-700 dark:text-amber-300">{{ __('customer.payment.bank_account_holder') }}</span>
                                                                <span class="text-sm font-extrabold text-amber-950 dark:text-amber-100">{{ $availableCostume->owner->bank_account_holder }}</span>
                                                            </span>
                                                            <span class="flex flex-wrap items-baseline justify-between gap-2">
                                                                <span class="text-[0.62rem] font-extrabold uppercase tracking-wider text-amber-700 dark:text-amber-300">{{ __('customer.payment.bank_account_number') }}</span>
                                                                <span class="font-mono text-sm font-extrabold tracking-wider text-amber-950 dark:text-amber-100">{{ $availableCostume->owner->bank_account_number }}</span>
                                                            </span>
                                                        </span>
                                                    @else
                                                        <span class="mt-2 block text-xs font-bold text-amber-700 dark:text-amber-400">{{ __('customer.payment.bank_missing') }}</span>
                                                    @endif
                                                @endif
                                            </span>
                                        </span>
                                    </label>
                                @endforeach
                            </div>
                            <x-input-error :messages="$errors->get('payment_method')" class="mt-2" />
                        </fieldset>

                        <div class="mt-6" x-show="! isTransfer" x-cloak>
                            <div class="rounded-2xl border border-violet-200 bg-violet-50 p-5 dark:border-violet-500/30 dark:bg-violet-950/30">
                                <p class="text-sm font-extrabold text-violet-900 dark:text-violet-200">{{ __('customer.payment.code_title') }}</p>
                                <p class="mt-2 text-xs leading-5 text-violet-800 dark:text-violet-300">{{ __('customer.payment.code_description') }}</p>
                            </div>
                        </div>

                        <div class="mt-6" x-show="isTransfer" x-cloak>
                            <div class="rounded-2xl border border-amber-200 bg-amber-50 p-5 dark:border-amber-500/30 dark:bg-amber-950/30">
                                <label for="payment_proof" class="text-sm font-extrabold text-amber-900 dark:text-amber-200">
                                    {{ __('customer.payment.proof_label') }}
                                    <span class="ml-1 rounded-full bg-amber-600 px-2 py-0.5 text-[0.6rem] font-extrabold uppercase tracking-wider text-white">{{ __('customer.payment.proof_required_badge') }}</span>
                                </label>
                                <p class="mt-2 text-xs leading-5 text-amber-800 dark:text-amber-300">{{ __('customer.payment.proof_hint') }}</p>
                                <input
                                    id="payment_proof"
                                    name="payment_proof"
                                    type="file"
                                    accept=".jpg,.jpeg,.png,.webp,.pdf"
                                    x-ref="proof"
                                    x-on:change="onProofSelected($event)"
                                    x-bind:aria-invalid="proofError !== ''"
                                    class="mt-4 block w-full rounded-2xl border bg-white px-4 py-3 text-sm shadow-sm file:mr-3 file:rounded-full file:border-0 file:bg-amber-100 file:px-4 file:py-2 file:text-xs file:font-extrabold file:text-amber-800"
                                    x-bind:class="proofError !== '' ? 'border-rose-400' : 'border-amber-200'"
                                >
                                <p
                                    x-show="proofName !== ''"
                                    x-text="proofName"
                                    class="mt-2 flex items-center gap-2 text-xs font-bold text-emerald-700 dark:text-emerald-300"
                                >
                                </p>
                                <p
                                    x-show="proofError !== ''"
                                    x-text="proofError"
                                    class="mt-2 text-xs font-extrabold text-rose-700 dark:text-rose-300"
                                    role="alert"
                                >
                                </p>
                                <x-input-error :messages="$errors->get('payment_proof')" class="mt-2" />
                            </div>
                        </div>
                    </section>

                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-8">
                        <label for="customer_note" class="text-sm font-extrabold text-slate-800">{{ __('customer.booking.customer_note') }}</label>
                        <textarea id="customer_note" name="customer_note" rows="4" maxlength="1000" placeholder="{{ __('customer.booking.customer_note_placeholder') }}" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">{{ old('customer_note') }}</textarea>
                        <x-input-error :messages="$errors->get('customer_note')" class="mt-2" />
                    </section>

                    <section class="rounded-[2rem] bg-slate-950 p-6 text-white shadow-xl shadow-slate-950/15 sm:p-8">
                        <div class="grid gap-5 sm:grid-cols-2 sm:items-center">
                            <div>
                                <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.16em] text-violet-300">{{ __('customer.booking.estimate') }}</p>
                                <p class="mt-2 text-3xl font-extrabold tracking-tight" x-text="formatPrice(total)">{{ \Number::currency($availableCostume->price_per_day, in: 'IDR', locale: app()->getLocale()) }}</p>
                                <p class="mt-2 text-xs text-white/50">
                                    <span x-text="rentalDays">{{ \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS }}</span> {{ __('customer.booking.days') }}
                                    × <span x-text="quantity">1</span> {{ __('customer.booking.unit') }}
                                </p>
                                <p class="mt-1 text-xs font-bold text-violet-300" x-show="extraDays > 0" x-cloak>
                                    <span x-text="extraDays"></span> {{ __('customer.booking.days') }}
                                    {{ __('owner.orders.extra_rate_short') }}
                                    <span x-text="formatPrice(extraPricePerDay)"></span>
                                </p>
                            </div>
                            <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-full bg-white px-6 py-3.5 text-sm font-extrabold text-slate-950 transition hover:bg-violet-100">
                                {{ __('customer.booking.submit') }}
                                <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                            </button>
                        </div>
                        <p class="mt-5 border-t border-white/10 pt-4 text-xs leading-5 text-white/45">{{ __('customer.booking.estimate_hint') }}</p>
                    </section>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
