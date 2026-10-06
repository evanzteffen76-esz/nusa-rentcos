<x-app-layout>
    <x-slot name="header">
        <a href="{{ route('cosrent-owner.orders.index') }}" class="inline-flex items-center gap-2 text-sm font-bold text-slate-500 transition hover:text-violet-700">
            <span aria-hidden="true">←</span>
            {{ __('owner.orders.back') }}
        </a>
        <div class="mt-3 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.orders.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('owner.orders.detail_title') }} #{{ str_pad((string) $ownerRentalOrder->id, 5, '0', STR_PAD_LEFT) }}</h2>
            </div>
            <x-order-status :status="$ownerRentalOrder->status" />
        </div>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            @if (session('status'))
                <div class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-bold text-emerald-700" role="status">
                    {{ session('status') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="mb-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-bold text-rose-700" role="alert">
                    {{ $errors->first() }}
                </div>
            @endif

            <div class="grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(340px,0.75fr)]">
                <div class="space-y-6">
                    <section class="overflow-hidden rounded-[2rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5">
                        <div class="grid sm:grid-cols-[220px_minmax(0,1fr)]">
                            <x-costume-artwork :costume="$ownerRentalOrder->costume" class="min-h-56" />
                            <div class="p-6 sm:p-7">
                                <p class="text-xs font-extrabold uppercase tracking-[0.14em] text-violet-600">{{ $ownerRentalOrder->costume->category }}</p>
                                <h3 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ $ownerRentalOrder->costume->name }}</h3>
                                <p class="mt-1 text-sm font-bold text-slate-500">{{ $ownerRentalOrder->costume->character_name }}</p>
                                <p class="mt-5 text-sm leading-6 text-slate-500">{{ $ownerRentalOrder->costume->description }}</p>
                            </div>
                        </div>
                    </section>

                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                        <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('owner.orders.detail_title') }}</h3>
                        <dl class="mt-6 grid gap-5 sm:grid-cols-2">
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-xs font-extrabold uppercase tracking-[0.12em] text-slate-400">{{ $ownerRentalOrder->approved_at ? __('owner.orders.return_window') : __('customer.booking.requested_period') }}</dt>
                                <dd class="mt-2 text-sm font-extrabold text-slate-900">{{ $ownerRentalOrder->rental_start->format('d M Y') }} — {{ $ownerRentalOrder->rental_end->format('d M Y') }}</dd>
                                <dd class="mt-1 text-xs text-slate-500">{{ $ownerRentalOrder->durationInDays() }} {{ __('customer.booking.days') }}</dd>
                                @if ($ownerRentalOrder->approved_at && $ownerRentalOrder->extraDays() > 0)
                                    <dd class="mt-1 text-xs font-bold text-violet-700">
                                        {{ $ownerRentalOrder->extraDays() }} {{ __('customer.booking.days') }} {{ __('owner.orders.extra_rate_short') }}
                                        {{ \Number::currency($ownerRentalOrder->extra_price_per_day, in: 'IDR', locale: app()->getLocale()) }}
                                    </dd>
                                @endif
                            </div>
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-xs font-extrabold uppercase tracking-[0.12em] text-slate-400">{{ __('customer.booking.quantity') }}</dt>
                                <dd class="mt-2 text-sm font-extrabold text-slate-900">{{ $ownerRentalOrder->quantity }}</dd>
                            </div>
                            @if ($ownerRentalOrder->return_due_at)
                                <div class="rounded-2xl bg-amber-50 p-4 sm:col-span-2">
                                    <dt class="text-xs font-extrabold uppercase tracking-[0.12em] text-amber-700">{{ __('owner.orders.return_due') }}</dt>
                                    <dd class="mt-2 text-sm font-extrabold text-amber-900">{{ $ownerRentalOrder->return_due_at->format('d M Y') }}</dd>
                                    <dd class="mt-1 text-xs text-amber-700">{{ $ownerRentalOrder->returned_late ? __('owner.orders.return_overdue') : __('owner.orders.return_window_description') }}</dd>
                                </div>
                            @endif
                            @if ($ownerRentalOrder->extraDays() > 0)
                                <div class="rounded-2xl border border-violet-200 bg-violet-50 p-4 sm:col-span-2">
                                    <dt class="text-xs font-extrabold uppercase tracking-[0.12em] text-violet-700">{{ __('owner.orders.extra_fee_title') }}</dt>
                                    <dd class="mt-2 text-sm leading-6 text-violet-900">
                                        {{ __('owner.orders.extra_fee_detail', [
                                            'days' => $ownerRentalOrder->extraDays(),
                                            'rate' => \Number::currency($ownerRentalOrder->extra_price_per_day, in: 'IDR', locale: app()->getLocale()),
                                            'total' => \Number::currency($ownerRentalOrder->extraFeeTotal(), in: 'IDR', locale: app()->getLocale()),
                                        ]) }}
                                    </dd>
                                </div>
                            @endif
                            <div class="rounded-2xl bg-slate-950 p-4 text-white sm:col-span-2">
                                <dt class="text-xs font-extrabold uppercase tracking-[0.12em] text-white/45">{{ __('owner.orders.total') }}</dt>
                                <dd class="mt-2 text-2xl font-extrabold">{{ \Number::currency($ownerRentalOrder->total_price, in: 'IDR', locale: app()->getLocale()) }}</dd>
                            </div>
                        </dl>

                        <div class="mt-6 border-t border-slate-100 pt-6">
                            <p class="text-xs font-extrabold uppercase tracking-[0.12em] text-slate-400">{{ __('owner.orders.customer_note') }}</p>
                            <p class="mt-2 whitespace-pre-line text-sm leading-6 text-slate-600">{{ $ownerRentalOrder->customer_note ?: __('owner.orders.no_note') }}</p>
                        </div>
                    </section>

                    @if ($ownerRentalOrder->payment_method)
                        <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                            <div class="flex flex-wrap items-start justify-between gap-3">
                                <div>
                                    <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('customer.payment.owner_title') }}</p>
                                    <h3 class="mt-2 text-lg font-extrabold tracking-tight text-slate-950">{{ __($ownerRentalOrder->payment_method->label()) }}</h3>
                                </div>
                                <span class="rounded-full px-2.5 py-1 text-[0.62rem] font-extrabold uppercase tracking-wider {{ $ownerRentalOrder->isPending() ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700' }}">
                                    {{ $ownerRentalOrder->isPending() ? __('owner.orders.payment_waiting') : __('owner.orders.payment_checked') }}
                                </span>
                            </div>

                            @if ($ownerRentalOrder->isPaidAtOwner())
                                <div class="mt-5 rounded-2xl border border-violet-200 bg-violet-50 p-5">
                                    <p class="text-xs font-extrabold uppercase tracking-wider text-violet-700">{{ __('customer.payment.code_label') }}</p>
                                    <p class="mt-2 font-mono text-2xl font-extrabold tracking-[0.2em] text-violet-950">{{ $ownerRentalOrder->payment_code }}</p>
                                    <p class="mt-3 text-xs leading-5 text-violet-800">{{ __('customer.payment.code_owner_hint') }}</p>
                                </div>
                            @endif

                            @if ($ownerRentalOrder->hasPaymentProof())
                                <a
                                    href="{{ route('cosrent-owner.orders.payment-proof', $ownerRentalOrder) }}"
                                    target="_blank"
                                    rel="noopener"
                                    class="mt-5 inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-violet-700"
                                >
                                    <svg viewBox="0 0 24 24" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M4 6.75h16v10.5H4V6.75Zm.75.75L12 13l7.25-5.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>
                                    {{ __('customer.payment.proof_view') }}
                                </a>
                            @elseif ($ownerRentalOrder->isPaidByTransfer())
                                <p class="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">{{ __('customer.payment.proof_missing') }}</p>
                            @endif
                        </section>
                    @endif
                </div>

                <div class="space-y-6">
                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                        <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.orders.customer') }}</p>
                        <div class="mt-4 flex items-center gap-4">
                            <span class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-violet-100 text-base font-extrabold text-violet-700">{{ mb_strtoupper(mb_substr($ownerRentalOrder->customer->name, 0, 1)) }}</span>
                            <div class="min-w-0">
                                <p class="truncate text-base font-extrabold text-slate-950">{{ $ownerRentalOrder->customer->name }}</p>
                                <p class="mt-1 truncate text-sm text-slate-500">{{ $ownerRentalOrder->customer->email }}</p>
                            </div>
                        </div>
                    </section>

                    @if ($ownerRentalOrder->isPending())
                        <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                            <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.orders.decision_title') }}</p>
                            <p class="mt-2 text-sm leading-6 text-slate-500">{{ __('owner.orders.decision_description') }}</p>

                            <form method="POST" action="{{ route('cosrent-owner.orders.approve', $ownerRentalOrder) }}" class="mt-5" x-data="{
                                rentalDays: {{ (int) old('rental_days', \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS) }},
                                includedDays: {{ \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS }},
                                basePrice: {{ $ownerRentalOrder->costume->price_per_day }},
                                extraRate: {{ $ownerRentalOrder->costume->extra_price_per_day }},
                                quantity: {{ $ownerRentalOrder->quantity }},
                                formatPrice(value) {
                                    return new Intl.NumberFormat('id-ID', {
                                        style: 'currency',
                                        currency: 'IDR',
                                        maximumFractionDigits: 0
                                    }).format(value);
                                },
                                get extraDays() {
                                    return Math.max(0, this.rentalDays - this.includedDays);
                                },
                                get total() {
                                    return (this.basePrice + this.extraRate * this.extraDays) * this.quantity;
                                }
                            }">
                                @csrf
                                @method('PATCH')

                                <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                                    <label for="rental_days" class="text-xs font-extrabold uppercase tracking-wider text-slate-500">
                                        {{ __('owner.orders.rental_days_label') }}
                                    </label>
                                    <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('owner.orders.rental_days_hint', ['days' => \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS]) }}</p>
                                    <input
                                        id="rental_days"
                                        name="rental_days"
                                        type="number"
                                        value="{{ old('rental_days', \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS) }}"
                                        min="{{ \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS }}"
                                        max="{{ \App\Models\RentalOrder::MAX_RENTAL_DAYS }}"
                                        x-model.number="rentalDays"
                                        class="mt-3 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500"
                                    >
                                    <x-input-error :messages="$errors->get('rental_days')" class="mt-2" />

                                    <dl class="mt-4 space-y-1.5 border-t border-slate-200 pt-4 text-xs">
                                        <div class="flex items-center justify-between gap-3">
                                            <dt class="text-slate-500">{{ __('owner.orders.included_fee_line', ['days' => \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS]) }}</dt>
                                            <dd class="font-extrabold text-slate-900" x-text="formatPrice(basePrice * quantity)"></dd>
                                        </div>
                                        <div class="flex items-center justify-between gap-3" x-show="extraDays > 0" x-cloak>
                                            <dt class="text-slate-500">
                                                <span x-text="extraDays"></span> {{ __('customer.booking.days') }} × {{ __('owner.orders.extra_rate_short') }}
                                                <span x-text="formatPrice(extraRate)"></span>
                                            </dt>
                                            <dd class="font-extrabold text-slate-900" x-text="formatPrice(extraRate * extraDays * quantity)"></dd>
                                        </div>
                                        <div class="flex items-center justify-between gap-3 border-t border-slate-200 pt-2">
                                            <dt class="font-extrabold uppercase tracking-wider text-slate-500">{{ __('customer.booking.estimate') }}</dt>
                                            <dd class="text-base font-extrabold text-slate-950" x-text="formatPrice(total)"></dd>
                                        </div>
                                    </dl>
                                </div>

                                @if ($ownerRentalOrder->isPaidAtOwner())
                                    <div class="rounded-2xl border border-violet-200 bg-violet-50 p-4">
                                        <label for="payment_code" class="text-xs font-extrabold uppercase tracking-wider text-violet-700">
                                            {{ __('owner.orders.code_input_label') }}
                                            <span class="ml-1 rounded-full bg-violet-600 px-2 py-0.5 text-[0.6rem] font-extrabold uppercase tracking-wider text-white">{{ __('customer.payment.proof_required_badge') }}</span>
                                        </label>
                                        <p class="mt-2 text-xs leading-5 text-violet-800">{{ __('owner.orders.code_hint') }}</p>
                                        <input
                                            id="payment_code"
                                            name="payment_code"
                                            type="text"
                                            value="{{ old('payment_code') }}"
                                            maxlength="32"
                                            autocomplete="off"
                                            spellcheck="false"
                                            placeholder="{{ __('owner.orders.code_input_placeholder') }}"
                                            class="mt-3 block w-full rounded-2xl border border-violet-200 bg-white px-4 py-3 font-mono text-sm uppercase tracking-[0.2em] shadow-sm focus:border-violet-500 focus:ring-violet-500"
                                        >
                                        <x-input-error :messages="$errors->get('payment_code')" class="mt-2" />
                                    </div>
                                @endif

                                <label for="owner_note" class="mt-5 block text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.orders.note_owner') }}</label>
                                <textarea id="owner_note" name="owner_note" rows="3" maxlength="1000" placeholder="{{ __('owner.orders.note_owner_placeholder') }}" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">{{ old('owner_note') }}</textarea>
                                <x-input-error :messages="$errors->get('owner_note')" class="mt-2" />

                                <button type="submit" class="mt-5 inline-flex w-full items-center justify-center gap-2 rounded-full bg-emerald-600 px-5 py-3 text-sm font-extrabold text-white transition hover:bg-emerald-700">
                                    {{ __('owner.orders.approve') }}
                                    <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="m4 10 4 4 8-8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                                </button>
                            </form>

                            <form method="POST" action="{{ route('cosrent-owner.orders.reject', $ownerRentalOrder) }}" class="mt-3">
                                @csrf
                                @method('PATCH')
                                <button type="submit" class="inline-flex w-full items-center justify-center rounded-full border border-rose-200 px-5 py-3 text-xs font-extrabold uppercase tracking-wider text-rose-700 transition hover:bg-rose-50">
                                    {{ __('owner.orders.reject') }}
                                </button>
                            </form>
                        </section>
                    @elseif ($ownerRentalOrder->issue)
                        @php($issue = $ownerRentalOrder->issue)
                        <section class="rounded-[2rem] border border-rose-200 bg-rose-50 p-6 sm:p-7">
                            <div class="flex items-start justify-between gap-4">
                                <div>
                                    <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-rose-600">{{ __('owner.issues.issue_title') }}</p>
                                    <h3 class="mt-2 text-lg font-extrabold text-rose-950">{{ $issue->isLost() ? __('owner.issues.issue_type_lost') : __('owner.issues.issue_type_stain') }}</h3>
                                </div>
                                <span class="rounded-full bg-white px-2.5 py-1 text-[0.62rem] font-extrabold uppercase tracking-wider text-rose-700">{{ $issue->isOpen() ? __('owner.issues.issue_status_open') : __('owner.issues.issue_status_resolved') }}</span>
                            </div>
                            <p class="mt-4 whitespace-pre-line text-sm leading-6 text-rose-800">{{ $issue->description }}</p>
                            <p class="mt-4 text-xs font-semibold text-rose-700">{{ __('owner.issues.reporter') }}: {{ $issue->reporter?->name }}</p>
                            @if ($issue->evidence_path)
                                <a href="{{ route('cosrent-owner.orders.issues.evidence', [$ownerRentalOrder, $issue]) }}" target="_blank" rel="noopener" class="mt-3 inline-flex text-xs font-extrabold text-rose-700 underline decoration-rose-300 underline-offset-4 transition hover:text-rose-900">
                                    {{ __('owner.issues.view_evidence') }}
                                </a>
                            @endif

                            @if ($issue->isStain())
                                <div class="mt-5 rounded-2xl border border-rose-200 bg-white p-4">
                                    <p class="text-xs font-extrabold uppercase tracking-wider text-rose-600">{{ __('owner.issues.stain_fine') }}</p>
                                    <p class="mt-2 text-xl font-extrabold text-rose-950">{{ \Number::currency($issue->fine_amount, in: 'IDR', locale: app()->getLocale()) }}</p>
                                    <p class="mt-1 text-xs font-bold {{ $issue->fineIsPaid() ? 'text-emerald-700' : 'text-rose-700' }}">{{ $issue->fineIsPaid() ? __('owner.issues.fine_paid') : __('owner.issues.fine_unpaid') }}</p>
                                </div>
                            @else
                                <div class="mt-5 rounded-2xl border border-rose-200 bg-white p-4 text-xs text-rose-800">
                                    <p><span class="font-extrabold">{{ __('owner.issues.replacement_cost') }}:</span> {{ \Number::currency($issue->replacement_cost, in: 'IDR', locale: app()->getLocale()) }}</p>
                                    <p class="mt-2 font-bold">{{ $issue->replacement_submitted_at ? __('owner.issues.replacement_submitted') : __('owner.issues.replacement_pending') }}</p>
                                    @if ($issue->replacement_received_at)
                                        <p class="mt-1 font-bold text-emerald-700">{{ __('owner.issues.replacement_received') }} — {{ $issue->replacement_received_at->format('d M Y') }}</p>
                                    @endif
                                </div>
                            @endif

                            @if ($issue->isOpen())
                                <form method="POST" action="{{ route('cosrent-owner.orders.issues.resolve', [$ownerRentalOrder, $issue]) }}" class="mt-5 rounded-2xl border border-rose-200 bg-white p-4">
                                    @csrf
                                    @method('PATCH')
                                    <h4 class="text-sm font-extrabold text-rose-900">{{ __('owner.issues.resolve_title') }}</h4>
                                    <label class="mt-4 flex cursor-pointer items-start gap-3 text-sm font-bold text-slate-700">
                                        <input type="checkbox" name="{{ $issue->isStain() ? 'fine_paid' : 'replacement_received' }}" value="1" class="mt-0.5 rounded border-slate-300 text-rose-600 focus:ring-rose-500">
                                        <span>{{ $issue->isStain() ? __('owner.issues.mark_fine_paid') : __('owner.issues.mark_replacement_received') }}</span>
                                    </label>
                                    <label for="resolution_note" class="mt-4 block text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.issues.resolution_note') }}</label>
                                    <textarea id="resolution_note" name="resolution_note" rows="3" maxlength="1000" placeholder="{{ __('owner.issues.resolution_note_placeholder') }}" class="mt-2 block w-full rounded-xl border-slate-200 px-3 py-2.5 text-sm shadow-sm focus:border-rose-500 focus:ring-rose-500"></textarea>
                                    <button type="submit" class="mt-4 inline-flex w-full items-center justify-center rounded-full bg-rose-600 px-4 py-3 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-rose-700">{{ __('owner.issues.resolve') }}</button>
                                </form>
                            @elseif ($issue->resolution_note)
                                <p class="mt-5 rounded-2xl bg-white p-4 text-sm leading-6 text-rose-800">{{ $issue->resolution_note }}</p>
                            @endif
                        </section>
                    @elseif ($ownerRentalOrder->isReturned())
                        <section class="rounded-[2rem] border border-sky-200 bg-sky-50 p-6 sm:p-7">
                            <h3 class="text-lg font-extrabold text-sky-950">{{ __('customer.return.title') }}</h3>
                            <p class="mt-2 text-sm leading-6 text-sky-800">{{ __('customer.return.description') }}</p>
                            @if ($ownerRentalOrder->returned_at)
                                <p class="mt-4 text-xs font-extrabold text-sky-900">{{ __('owner.orders.returned_at') }}: {{ $ownerRentalOrder->returned_at->format('d M Y, H:i') }}</p>
                            @endif
                            @if ($ownerRentalOrder->return_note)
                                <p class="mt-3 text-xs font-extrabold uppercase tracking-wider text-sky-900">{{ __('owner.orders.return_note') }}</p>
                                <p class="mt-1 whitespace-pre-line rounded-2xl bg-white p-3 text-sm leading-6 text-slate-600">{{ $ownerRentalOrder->return_note }}</p>
                            @endif
                            <form method="POST" action="{{ route('cosrent-owner.orders.complete', $ownerRentalOrder) }}" class="mt-5">
                                @csrf
                                @method('PATCH')
                                <button type="submit" class="inline-flex w-full items-center justify-center rounded-full bg-sky-600 px-4 py-3 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-sky-700">{{ __('owner.orders.clean_return') }}</button>
                            </form>
                            <form method="POST" action="{{ route('cosrent-owner.orders.issues.store', $ownerRentalOrder) }}" enctype="multipart/form-data" class="mt-5 rounded-2xl border border-rose-200 bg-white p-4">
                                @csrf
                                <h4 class="text-sm font-extrabold text-rose-800">{{ __('owner.orders.report_stain') }}</h4>
                                <label for="stain_description" class="mt-4 block text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.issues.stain_description') }}</label>
                                <textarea id="stain_description" name="description" rows="3" required maxlength="1000" placeholder="{{ __('owner.issues.stain_description_placeholder') }}" class="mt-2 block w-full rounded-xl border-slate-200 px-3 py-2.5 text-sm shadow-sm focus:border-rose-500 focus:ring-rose-500"></textarea>
                                <label for="fine_amount" class="mt-4 block text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.issues.stain_fine') }}</label>
                                <input id="fine_amount" name="fine_amount" type="number" min="1" max="100000000" step="1000" required class="mt-2 block w-full rounded-xl border-slate-200 px-3 py-2.5 text-sm shadow-sm focus:border-rose-500 focus:ring-rose-500">
                                <label for="evidence" class="mt-4 block text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.issues.stain_evidence') }}</label>
                                <input id="evidence" name="evidence" type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" required class="mt-2 block w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm file:mr-3 file:rounded-full file:border-0 file:bg-rose-100 file:px-3 file:py-1.5 file:text-xs file:font-extrabold file:text-rose-700">
                                <p class="mt-2 text-xs text-slate-500">{{ __('owner.issues.evidence_hint') }}</p>
                                <button type="submit" class="mt-4 inline-flex w-full items-center justify-center rounded-full bg-rose-600 px-4 py-3 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-rose-700">{{ __('owner.orders.report_stain') }}</button>
                            </form>
                        </section>
                    @elseif ($ownerRentalOrder->isApproved())
                        <section class="rounded-[2rem] border border-amber-200 bg-amber-50 p-6 sm:p-7">
                            <h3 class="text-lg font-extrabold text-amber-950">{{ __('owner.orders.return_window') }}</h3>
                            <p class="mt-2 text-sm leading-6 text-amber-800">{{ __('owner.orders.return_window_description') }}</p>
                            @if ($ownerRentalOrder->return_due_at)
                                <p class="mt-4 text-sm font-extrabold text-amber-900">{{ __('owner.orders.return_due') }}: {{ $ownerRentalOrder->return_due_at->format('d M Y') }}</p>
                            @endif
                        </section>
                    @else
                        <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                            <div class="flex items-center justify-between gap-4">
                                <h3 class="text-sm font-extrabold text-slate-950">{{ __('owner.orders.decision_note') }}</h3>
                                @if ($ownerRentalOrder->decided_at)
                                    <span class="text-xs font-semibold text-slate-400">{{ __('owner.orders.decided_at') }} {{ $ownerRentalOrder->decided_at->format('d M Y, H:i') }}</span>
                                @endif
                            </div>
                            <p class="mt-4 whitespace-pre-line text-sm leading-6 text-slate-600">{{ $ownerRentalOrder->owner_note ?: __('owner.orders.no_note') }}</p>
                        </section>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
