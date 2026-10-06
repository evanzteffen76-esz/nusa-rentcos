<x-app-layout>
    <x-slot name="header">
        <div>
            <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('customer.dashboard.eyebrow') }}</p>
            <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('customer.dashboard.title') }}</h2>
        </div>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            @if (session('status'))
                <div class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-bold text-emerald-700" role="status">
                    {{ session('status') }}
                </div>
            @endif

            <section class="relative overflow-hidden rounded-[2rem] bg-slate-950 p-7 text-white shadow-2xl shadow-slate-950/15 sm:p-9">
                <div aria-hidden="true" class="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-fuchsia-500/25 blur-3xl"></div>
                <div aria-hidden="true" class="absolute -bottom-24 left-1/3 h-60 w-60 rounded-full bg-violet-500/25 blur-3xl"></div>
                <div class="relative grid gap-8 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-end">
                    <div>
                        <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-300">{{ __('customer.dashboard.eyebrow') }}</p>
                        <h3 class="mt-3 text-3xl font-extrabold tracking-[-0.045em] sm:text-4xl">{{ __('customer.dashboard.greeting', ['name' => auth()->user()->name]) }}</h3>
                        <p class="mt-4 max-w-2xl text-sm leading-7 text-white/60 sm:text-base">{{ __('customer.dashboard.description') }}</p>
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div class="rounded-2xl border border-white/10 bg-white/10 px-5 py-4 backdrop-blur">
                            <p class="text-2xl font-extrabold">{{ $pendingCustomerOrderCount }}</p>
                            <p class="mt-1 text-[0.65rem] font-extrabold uppercase tracking-[0.12em] text-white/50">{{ __('owner.orders.pending') }}</p>
                        </div>
                        <div class="rounded-2xl border border-white/10 bg-white/10 px-5 py-4 backdrop-blur">
                            <p class="text-2xl font-extrabold">{{ $approvedCustomerOrderCount }}</p>
                            <p class="mt-1 text-[0.65rem] font-extrabold uppercase tracking-[0.12em] text-white/50">{{ __('owner.orders.approved') }}</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="mt-8">
                <div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                    <div>
                        <h3 class="text-2xl font-extrabold tracking-tight text-slate-950">{{ __('customer.dashboard.catalog') }}</h3>
                        <p class="mt-2 text-sm text-slate-500">{{ __('customer.dashboard.catalog_description') }}</p>
                    </div>
                </div>

                @if ($costumes->isEmpty())
                    <div class="mt-6 rounded-[2rem] border border-dashed border-slate-300 bg-white px-6 py-16 text-center shadow-lg shadow-slate-950/5">
                        <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-7 w-7" aria-hidden="true"><path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="m4 7.5 8 4.5 8-4.5M12 12v9" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>
                        </span>
                        <h4 class="mt-5 text-xl font-extrabold text-slate-950">{{ __('customer.dashboard.empty_catalog.title') }}</h4>
                        <p class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">{{ __('customer.dashboard.empty_catalog.description') }}</p>
                    </div>
                @else
                    <div class="mt-6 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
                        @foreach ($costumes as $costume)
                            <article class="group relative overflow-hidden rounded-[1.75rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5 transition hover:-translate-y-1 hover:shadow-2xl hover:shadow-violet-100/50">
                                <x-costume-artwork :costume="$costume" class="h-56" />
                                <div class="p-5">
                                    <div class="flex items-center justify-between gap-3">
                                        <span class="rounded-full bg-violet-100 px-2.5 py-1 text-[0.62rem] font-extrabold uppercase tracking-wider text-violet-700">{{ $costume->category }} · {{ $costume->size }}</span>
                                        <span class="text-xs font-bold text-slate-500">{{ $costume->stock }} {{ __('owner.costumes.stock') }}</span>
                                    </div>
                                    <h3 class="mt-4 text-xl font-extrabold tracking-tight text-slate-950 transition group-hover:text-violet-700">
                                        <a
                                            href="{{ route('dashboard.costumes.show', $costume) }}"
                                            class="after:absolute after:inset-0 after:z-10 focus-visible:underline focus-visible:outline-none"
                                        >
                                            {{ $costume->name }}
                                        </a>
                                    </h3>
                                    <p class="mt-1 text-sm font-bold text-violet-700">{{ $costume->character_name }}</p>
                                    <p class="mt-4 line-clamp-2 min-h-10 text-sm leading-5 text-slate-500">{{ $costume->description }}</p>
                                    <p class="mt-4 text-xs font-semibold text-slate-400">{{ __('customer.dashboard.owner') }}: {{ $costume->owner->name }}</p>
                                    <div class="mt-5 flex items-center justify-between gap-4 border-t border-slate-100 pt-5">
                                        <p class="text-lg font-extrabold text-slate-950">{{ \Number::currency($costume->price_per_day, in: 'IDR', locale: app()->getLocale()) }}</p>
                                        <a href="{{ route('dashboard.costumes.book.create', $costume) }}" class="relative z-20 inline-flex items-center justify-center gap-2 rounded-full bg-slate-950 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-violet-700">
                                            {{ __('customer.dashboard.book') }}
                                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                                        </a>
                                    </div>
                                </div>
                            </article>
                        @endforeach
                    </div>

                    @if ($costumes->hasPages())
                        <div class="mt-8">
                            {{ $costumes->links() }}
                        </div>
                    @endif
                @endif
            </section>

            <section class="mt-10 rounded-[2rem] border border-white/80 bg-white p-5 shadow-xl shadow-slate-950/5 sm:p-7">
                <h3 class="text-xl font-extrabold tracking-tight text-slate-950">{{ __('customer.dashboard.recent_orders') }}</h3>

                @if ($orders->isEmpty())
                    <div class="mt-5 rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-10 text-center">
                        <p class="text-base font-extrabold text-slate-800">{{ __('customer.dashboard.no_orders.title') }}</p>
                        <p class="mt-2 text-sm text-slate-500">{{ __('customer.dashboard.no_orders.description') }}</p>
                    </div>
                @else
                    <div class="mt-5 divide-y divide-slate-100">
                        @foreach ($orders as $order)
                            <div class="flex flex-col gap-4 py-4 first:pt-0 last:pb-0 sm:flex-row sm:items-center sm:justify-between">
                                <div class="flex min-w-0 items-center gap-4">
                                    <x-costume-artwork :costume="$order->costume" class="h-14 w-14 shrink-0 rounded-2xl" />
                                    <div class="min-w-0">
                                        <p class="truncate text-sm font-extrabold text-slate-950">{{ $order->costume->name }}</p>
                                        <p class="mt-1 text-xs text-slate-500">#{{ str_pad((string) $order->id, 5, '0', STR_PAD_LEFT) }} · {{ $order->rental_start->format('d M Y') }} — {{ $order->rental_end->format('d M Y') }}</p>
                                        @if ($order->extraDays() > 0 && $order->extraFeeTotal() > 0)
                                            <p class="mt-1 text-xs font-bold text-violet-700">
                                                {{ $order->durationInDays() }} {{ __('customer.booking.days') }} ·
                                                {{ $order->extraDays() }} {{ __('owner.orders.extra_rate_short') }}
                                                {{ \Number::currency($order->extraFeeTotal(), in: 'IDR', locale: app()->getLocale()) }}
                                            </p>
                                        @endif
                                    </div>
                                </div>
                                <div class="flex flex-col items-stretch gap-3 sm:items-end">
                                    <div class="flex items-center justify-between gap-4 sm:justify-end">
                                        <span class="text-sm font-extrabold text-slate-950">{{ \Number::currency($order->total_price, in: 'IDR', locale: app()->getLocale()) }}</span>
                                        <x-order-status :status="$order->status" />
                                    </div>
                                    @if ($order->isPending() && $order->isPaidAtOwner())
                                        <div class="rounded-2xl border border-violet-200 bg-violet-50 px-3 py-2 text-right text-xs text-violet-800">
                                            <span class="font-extrabold uppercase tracking-wider">{{ __('customer.payment.code_label') }}:</span>
                                            <strong class="ml-1 font-mono text-sm tracking-wider">{{ $order->payment_code }}</strong>
                                            <span class="mt-1 block font-semibold">{{ __('customer.payment.code_reminder') }}</span>
                                        </div>
                                    @elseif ($order->isPending() && $order->isPaidByTransfer() && $order->hasPaymentProof())
                                        <a
                                            href="{{ route('dashboard.orders.payment-proof', $order) }}"
                                            target="_blank"
                                            rel="noopener"
                                            class="rounded-2xl border border-amber-200 bg-amber-50 px-3 py-2 text-right text-xs font-bold text-amber-800 transition hover:bg-amber-100"
                                        >
                                            {{ __('customer.payment.proof_view_own') }}
                                            <span class="mt-1 block text-[0.65rem] font-semibold text-amber-700">{{ __('customer.payment.proof_awaiting_review') }}</span>
                                        </a>
                                    @elseif ($order->isApproved() && !$order->issue)
                                        <p class="text-right text-xs font-semibold {{ $order->isReturnOverdue() ? 'text-rose-600' : 'text-slate-500' }}">
                                            {{ $order->isReturnOverdue() ? __('customer.return.overdue') : __('customer.return.due') }}: {{ $order->return_due_at?->format('d M Y') }}
                                        </p>
                                        <div class="flex flex-wrap justify-end gap-2">
                                            @if (today()->gte($order->rental_end))
                                                <form method="POST" action="{{ route('dashboard.orders.return', $order) }}">
                                                    @csrf
                                                    <button type="submit" class="rounded-full bg-sky-600 px-3.5 py-2 text-[0.65rem] font-extrabold uppercase tracking-wider text-white transition hover:bg-sky-700">
                                                        {{ __('customer.return.submit') }}
                                                    </button>
                                                </form>
                                            @endif
                                            <a href="{{ route('dashboard.orders.loss-report.create', $order) }}" class="rounded-full border border-rose-200 px-3.5 py-2 text-[0.65rem] font-extrabold uppercase tracking-wider text-rose-700 transition hover:bg-rose-50">
                                                {{ __('customer.issues.lost_title') }}
                                            </a>
                                        </div>
                                    @elseif ($order->isApproved() && $order->issue)
                                        <p class="text-right text-xs font-semibold text-amber-700">
                                            {{ $order->issue->isLost() ? __('owner.issues.issue_type_lost') : __('owner.issues.issue_type_stain') }} · {{ $order->issue->isOpen() ? __('owner.issues.issue_status_open') : __('owner.issues.issue_status_resolved') }}
                                        </p>
                                        @if ($order->issue->isLost())
                                            <div class="rounded-2xl border border-amber-200 bg-amber-50 px-3 py-2 text-right text-xs text-amber-800">
                                                <span class="font-extrabold">{{ __('owner.issues.replacement_cost') }}:</span>
                                                <strong>{{ \Number::currency($order->issue->replacement_cost ?? 0, in: 'IDR', locale: app()->getLocale()) }}</strong>
                                                <span class="mt-1 block font-bold">{{ $order->issue->replacement_received_at ? __('owner.issues.replacement_received') : __('customer.issues.replacement_under_review') }}</span>
                                            </div>
                                        @endif
                                    @elseif ($order->isReturned() || ($order->isCompleted() && $order->issue))
                                        <p class="text-right text-xs font-semibold {{ $order->wasReturnedLate() ? 'text-rose-600' : 'text-sky-700' }}">
                                            {{ $order->wasReturnedLate() ? __('customer.return.overdue') : __('customer.return.title') }}
                                            @if ($order->issue)
                                                · {{ $order->issue->isLost() ? __('owner.issues.issue_type_lost') : __('owner.issues.issue_type_stain') }} · {{ $order->issue->isOpen() ? __('owner.issues.issue_status_open') : __('owner.issues.issue_status_resolved') }}
                                            @endif
                                        </p>
                                        @if ($order->issue?->isStain())
                                            <div class="rounded-2xl border border-rose-200 bg-rose-50 px-3 py-2 text-right text-xs text-rose-800">
                                                <span class="font-extrabold">{{ __('owner.issues.stain_fine') }}:</span>
                                                <strong>{{ \Number::currency($order->issue->fine_amount, in: 'IDR', locale: app()->getLocale()) }}</strong>
                                                <span class="mt-1 block font-bold">{{ $order->issue->fineIsPaid() ? __('owner.issues.fine_paid') : __('customer.issues.payment_instruction') }}</span>
                                            </div>
                                        @elseif ($order->issue?->isLost())
                                            <div class="rounded-2xl border border-amber-200 bg-amber-50 px-3 py-2 text-right text-xs text-amber-800">
                                                <span class="font-extrabold">{{ __('owner.issues.replacement_cost') }}:</span>
                                                <strong>{{ \Number::currency($order->issue->replacement_cost ?? 0, in: 'IDR', locale: app()->getLocale()) }}</strong>
                                                <span class="mt-1 block font-bold">{{ $order->issue->replacement_received_at ? __('owner.issues.replacement_received') : __('customer.issues.replacement_under_review') }}</span>
                                            </div>
                                        @endif
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                @endif
            </section>
        </div>
    </div>
</x-app-layout>
