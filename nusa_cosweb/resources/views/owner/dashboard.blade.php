<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.header.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('owner.header.title') }}</h2>
            </div>
            <span class="inline-flex w-fit items-center gap-2 rounded-full border border-violet-200 bg-violet-50 px-3.5 py-2 text-xs font-extrabold uppercase tracking-[0.14em] text-violet-700">
                <svg viewBox="0 0 24 24" fill="none" class="h-4 w-4" aria-hidden="true">
                    <path d="M12 3.5 14.3 8l4.7.7-3.4 3.3.8 4.7-4.4-2.3-4.4 2.3.8-4.7L5 8.7 9.7 8 12 3.5Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                </svg>
                {{ __('nav.cosrent_owner') }}
            </span>
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

            <div class="grid gap-6 lg:grid-cols-[minmax(0,1.45fr)_minmax(280px,0.55fr)]">
                <section class="relative overflow-hidden rounded-[2rem] bg-slate-950 p-7 text-white shadow-2xl shadow-slate-950/15 sm:p-9">
                    <div aria-hidden="true" class="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-violet-500/30 blur-3xl"></div>
                    <div aria-hidden="true" class="absolute -bottom-28 left-1/3 h-64 w-64 rounded-full bg-cyan-500/20 blur-3xl"></div>
                    <div class="relative">
                        <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-300">{{ __('owner.hero.welcome') }}</p>
                        <h3 class="mt-3 max-w-2xl text-3xl font-extrabold tracking-[-0.045em] sm:text-4xl">{{ __('owner.hero.greeting', ['name' => $owner->name]) }}</h3>
                        <p class="mt-4 max-w-2xl text-sm leading-7 text-white/60 sm:text-base">{{ __('owner.hero.description') }}</p>
                        <div class="mt-8 flex flex-wrap gap-3">
                            <a href="{{ route('cosrent-owner.costumes.create') }}" class="inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-extrabold text-slate-950 transition hover:-translate-y-0.5 hover:bg-violet-100">
                                {{ __('owner.hero.add_costume') }}
                                <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M10 4v12M4 10h12" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                            </a>
                            <a href="{{ route('cosrent-owner.orders.index') }}" class="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-sm font-extrabold text-white transition hover:-translate-y-0.5 hover:bg-white/15">
                                {{ __('owner.hero.review_orders') }}
                            </a>
                        </div>
                    </div>
                </section>

                <aside class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                    <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.quick.eyebrow') }}</p>
                    <h3 class="mt-2 text-xl font-extrabold tracking-tight text-slate-950">{{ __('owner.quick.title') }}</h3>
                    <div class="mt-6 grid gap-3">
                        <a href="{{ route('cosrent-owner.costumes.index') }}" class="group flex items-center justify-between rounded-2xl border border-slate-200 px-4 py-3.5 text-sm font-bold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                            <span>{{ __('owner.quick.costumes') }}</span>
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>
                        <a href="{{ route('cosrent-owner.orders.index') }}" class="group flex items-center justify-between rounded-2xl border border-slate-200 px-4 py-3.5 text-sm font-bold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                            <span>{{ __('owner.quick.orders') }}</span>
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>
                        <a href="{{ route('profile.edit') }}" class="group flex items-center justify-between rounded-2xl border border-slate-200 px-4 py-3.5 text-sm font-bold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                            <span>{{ __('owner.quick.profile') }}</span>
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>
                    </div>
                </aside>
            </div>

            <div class="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
                @foreach ([
                    ['label' => __('owner.stats.costumes'), 'value' => $totalCostumes, 'description' => __('owner.stats.costumes_desc'), 'icon' => 'M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z'],
                    ['label' => __('owner.stats.published'), 'value' => $publishedCostumes, 'description' => __('owner.stats.published_desc'), 'icon' => 'M5 12.5 9.5 17 19 7.5'],
                    ['label' => __('owner.stats.pending'), 'value' => $pendingOrderCount, 'description' => __('owner.stats.pending_desc'), 'icon' => 'M12 6v6l4 2M20 12a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z'],
                    ['label' => __('owner.stats.approved'), 'value' => $approvedOrderCount, 'description' => __('owner.stats.approved_desc'), 'icon' => 'm5 12 4 4L19 6'],
                    ['label' => __('owner.stats.revenue'), 'value' => \Number::currency($approvedRevenue, in: 'IDR', locale: app()->getLocale()), 'description' => __('owner.stats.revenue_desc'), 'icon' => 'M7 5h10M7 9h10M7 15h3M14 13c2.2 0 4 1.1 4 2.5S16.2 18 14 18h-1v2'],
                ] as $stat)
                    <div class="rounded-3xl border border-white/80 bg-white p-5 shadow-lg shadow-slate-950/5">
                        <div class="flex items-center justify-between gap-3">
                            <span class="text-sm font-bold text-slate-500">{{ $stat['label'] }}</span>
                            <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                                <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="{{ $stat['icon'] }}" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
                            </span>
                        </div>
                        <p class="mt-5 text-2xl font-extrabold tracking-tight text-slate-950">{{ $stat['value'] }}</p>
                        <p class="mt-1 text-xs font-semibold text-slate-500">{{ $stat['description'] }}</p>
                    </div>
                @endforeach
            </div>

            <div class="mt-6 grid gap-6 xl:grid-cols-[minmax(0,1.4fr)_minmax(320px,0.6fr)]">
                <section class="rounded-[2rem] border border-white/80 bg-white p-5 shadow-xl shadow-slate-950/5 sm:p-7">
                    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.orders.eyebrow') }}</p>
                            <h3 class="mt-2 text-xl font-extrabold tracking-tight text-slate-950">{{ __('owner.orders.title') }}</h3>
                        </div>
                        <a href="{{ route('cosrent-owner.orders.index', ['status' => 'pending']) }}" class="text-sm font-extrabold text-violet-700 transition hover:text-violet-900">{{ __('owner.orders.view') }} →</a>
                    </div>

                    @if ($pendingOrders->isEmpty())
                        <div class="mt-6 rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-10 text-center">
                            <span class="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-100 text-emerald-700">
                                <svg viewBox="0 0 24 24" fill="none" class="h-6 w-6" aria-hidden="true"><path d="m5 12 4 4L19 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                            </span>
                            <h4 class="mt-4 text-base font-extrabold text-slate-950">{{ __('owner.empty_orders.title') }}</h4>
                            <p class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">{{ __('owner.empty_orders.description') }}</p>
                        </div>
                    @else
                        <div class="mt-6 grid gap-4">
                            @foreach ($pendingOrders as $order)
                                <article class="rounded-2xl border border-slate-200 p-4 transition hover:border-violet-200 hover:shadow-lg hover:shadow-violet-100/50 sm:p-5">
                                    <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                                        <div class="min-w-0">
                                            <div class="flex flex-wrap items-center gap-2">
                                                <span class="text-xs font-extrabold uppercase tracking-[0.12em] text-slate-400">#{{ str_pad((string) $order->id, 5, '0', STR_PAD_LEFT) }}</span>
                                                <x-order-status :status="$order->status" />
                                            </div>
                                            <h4 class="mt-2 truncate text-base font-extrabold text-slate-950">{{ $order->costume->name }}</h4>
                                            <p class="mt-1 text-sm text-slate-500">{{ $order->customer->name }} · {{ $order->rental_start->format('d M Y') }} — {{ $order->rental_end->format('d M Y') }}</p>
                                        </div>
                                        <div class="flex flex-wrap items-center gap-2">
                                            <span class="mr-2 text-sm font-extrabold text-slate-950">{{ \Number::currency($order->total_price, in: 'IDR', locale: app()->getLocale()) }}</span>
                                            @if ($order->isPending())
                                                @if ($order->isPaidAtOwner())
                                                    <a href="{{ route('cosrent-owner.orders.show', $order) }}" class="inline-flex items-center justify-center rounded-full bg-emerald-600 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-emerald-700">
                                                        {{ __('owner.orders.verify_and_approve') }}
                                                    </a>
                                                @else
                                                    <form method="POST" action="{{ route('cosrent-owner.orders.approve', $order) }}">
                                                        @csrf
                                                        @method('PATCH')
                                                        <button type="submit" class="inline-flex items-center justify-center rounded-full bg-emerald-600 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-white transition hover:bg-emerald-700">
                                                            {{ __('owner.orders.approve') }}
                                                        </button>
                                                    </form>
                                                @endif
                                                <a href="{{ route('cosrent-owner.orders.show', $order) }}" class="inline-flex items-center justify-center rounded-full border border-rose-200 bg-white px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-rose-700 transition hover:bg-rose-50">
                                                    {{ __('owner.orders.reject') }}
                                                </a>
                                            @else
                                                <a href="{{ route('cosrent-owner.orders.show', $order) }}" class="inline-flex items-center justify-center rounded-full border border-slate-200 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-slate-700 transition hover:bg-slate-50">{{ __('common.view') }}</a>
                                            @endif
                                        </div>
                                    </div>
                                </article>
                            @endforeach
                        </div>
                    @endif
                </section>

                <section class="rounded-[2rem] border border-white/80 bg-white p-5 shadow-xl shadow-slate-950/5 sm:p-7">
                    <div class="flex items-center justify-between gap-3">
                        <div>
                            <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.costumes.eyebrow') }}</p>
                            <h3 class="mt-2 text-xl font-extrabold tracking-tight text-slate-950">{{ __('owner.costumes.title') }}</h3>
                        </div>
                        <a href="{{ route('cosrent-owner.costumes.create') }}" class="flex h-10 w-10 items-center justify-center rounded-full bg-slate-950 text-white transition hover:bg-violet-700" aria-label="{{ __('owner.costumes.add') }}">
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M10 4v12M4 10h12" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                        </a>
                    </div>

                    <div class="mt-6 grid gap-3">
                        @forelse ($recentCostumes as $costume)
                            <a href="{{ route('cosrent-owner.costumes.edit', $costume) }}" class="group flex items-center gap-3 rounded-2xl border border-slate-200 p-3 transition hover:border-violet-200 hover:bg-violet-50/50">
                                <x-costume-artwork :costume="$costume" class="h-14 w-14 shrink-0 rounded-xl" />
                                <span class="min-w-0 flex-1">
                                    <span class="block truncate text-sm font-extrabold text-slate-950">{{ $costume->name }}</span>
                                    <span class="mt-1 block text-xs text-slate-500">{{ $costume->stock }} {{ __('owner.costumes.stock') }} · {{ \Number::currency($costume->price_per_day, in: 'IDR', locale: app()->getLocale()) }}</span>
                                </span>
                                <span class="h-2 w-2 shrink-0 rounded-full {{ $costume->is_published ? 'bg-emerald-500' : 'bg-slate-300' }}"></span>
                            </a>
                        @empty
                            <div class="rounded-2xl border border-dashed border-slate-200 px-4 py-8 text-center">
                                <p class="text-sm font-bold text-slate-600">{{ __('owner.costumes.empty.title') }}</p>
                                <a href="{{ route('cosrent-owner.costumes.create') }}" class="mt-3 inline-flex text-xs font-extrabold text-violet-700">{{ __('owner.costumes.add') }} →</a>
                            </div>
                        @endforelse
                    </div>
                </section>
            </div>
        </div>
    </div>
</x-app-layout>
