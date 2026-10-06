<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.orders.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('owner.orders.title') }}</h2>
            </div>
            <a href="{{ route('cosrent-owner.dashboard') }}" class="inline-flex w-fit items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2.5 text-sm font-extrabold text-slate-700 shadow-sm transition hover:border-violet-200 hover:text-violet-700">
                <span aria-hidden="true">←</span>
                {{ __('owner.header.title') }}
            </a>
        </div>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            @if (session('status'))
                <div class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-bold text-emerald-700" role="status">
                    {{ session('status') }}
                </div>
            @endif

            <div class="mb-6 flex flex-wrap gap-2" role="navigation" aria-label="{{ __('owner.orders.title') }}">
                @foreach ([
                    'all' => __('owner.orders.all'),
                    'pending' => __('owner.orders.pending'),
                    'approved' => __('owner.orders.approved'),
                    'returned' => __('owner.orders.returned'),
                    'completed' => __('owner.orders.completed'),
                    'rejected' => __('owner.orders.rejected'),
                ] as $value => $label)
                    @php
                        $active = $status === $value;
                        $classes = $active
                            ? 'border-slate-950 bg-slate-950 text-white shadow-lg shadow-slate-950/10'
                            : 'border-slate-200 bg-white text-slate-600 hover:border-violet-200 hover:text-violet-700';
                    @endphp
                    <a href="{{ route('cosrent-owner.orders.index', $value === 'all' ? [] : ['status' => $value]) }}" class="rounded-full border px-4 py-2 text-xs font-extrabold uppercase tracking-wider transition {{ $classes }}">
                        {{ $label }}
                    </a>
                @endforeach
            </div>

            <section class="overflow-hidden rounded-[2rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5">
                @if ($orders->isEmpty())
                    <div class="px-6 py-16 text-center">
                        <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-7 w-7" aria-hidden="true"><path d="M6 4.75h12v15H6v-15Zm3 0V3.5h6v1.25M9 9h6M9 13h6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </span>
                        <h3 class="mt-5 text-xl font-extrabold text-slate-950">{{ __('owner.orders.no_orders.title') }}</h3>
                        <p class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">{{ __('owner.orders.no_orders.description') }}</p>
                    </div>
                @else
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-slate-200">
                            <thead class="bg-slate-50">
                                <tr>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.order_number') }}</th>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.customer') }}</th>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.costume') }}</th>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.schedule') }}</th>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.total') }}</th>
                                    <th class="px-5 py-4 text-left text-[0.65rem] font-extrabold uppercase tracking-[0.14em] text-slate-500">{{ __('owner.orders.actions') }}</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 bg-white">
                                @foreach ($orders as $order)
                                    <tr class="transition hover:bg-violet-50/30">
                                        <td class="whitespace-nowrap px-5 py-5">
                                            <span class="block text-sm font-extrabold text-slate-950">#{{ str_pad((string) $order->id, 5, '0', STR_PAD_LEFT) }}</span>
                                            <span class="mt-1 block text-xs text-slate-400">{{ $order->created_at->format('d M Y, H:i') }}</span>
                                            @if ($order->payment_method)
                                                <span class="mt-2 inline-flex rounded-full bg-violet-50 px-2.5 py-1 text-[0.62rem] font-extrabold uppercase tracking-wider text-violet-700">
                                                    {{ __($order->payment_method->label()) }}
                                                </span>
                                            @endif
                                        </td>
                                        <td class="min-w-48 px-5 py-5">
                                            <span class="block text-sm font-extrabold text-slate-950">{{ $order->customer->name }}</span>
                                            <span class="mt-1 block text-xs text-slate-500">{{ $order->customer->email }}</span>
                                        </td>
                                        <td class="min-w-56 px-5 py-5">
                                            <span class="block text-sm font-bold text-slate-800">{{ $order->costume->name }}</span>
                                            <span class="mt-1 block text-xs text-slate-500">{{ $order->costume->character_name }} · {{ $order->quantity }} {{ __('customer.booking.unit') }}</span>
                                        </td>
                                        <td class="whitespace-nowrap px-5 py-5 text-sm font-semibold text-slate-600">
                                            {{ $order->rental_start->format('d M Y') }}<br>
                                            <span class="text-slate-400">→ {{ $order->rental_end->format('d M Y') }}</span>
                                        </td>
                                        <td class="whitespace-nowrap px-5 py-5 text-sm font-extrabold text-slate-950">
                                            {{ \Number::currency($order->total_price, in: 'IDR', locale: app()->getLocale()) }}
                                        </td>
                                        <td class="px-5 py-5">
                                            <x-order-status :status="$order->status" class="mb-3" />
                                            <div class="flex flex-wrap gap-2">
                                                <a href="{{ route('cosrent-owner.orders.show', $order) }}" class="inline-flex items-center justify-center rounded-full border border-slate-200 px-3.5 py-2 text-[0.65rem] font-extrabold uppercase tracking-wider text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                                                    {{ __('common.view') }}
                                                </a>
                                                @if ($order->isPending())
                                                    @if ($order->isPaidAtOwner())
                                                        <a href="{{ route('cosrent-owner.orders.show', $order) }}" class="inline-flex items-center justify-center rounded-full bg-emerald-600 px-3.5 py-2 text-[0.65rem] font-extrabold uppercase tracking-wider text-white transition hover:bg-emerald-700">
                                                            {{ __('owner.orders.verify_and_approve') }}
                                                        </a>
                                                    @else
                                                        <form method="POST" action="{{ route('cosrent-owner.orders.approve', $order) }}">
                                                            @csrf
                                                            @method('PATCH')
                                                            <button type="submit" class="inline-flex items-center justify-center rounded-full bg-emerald-600 px-3.5 py-2 text-[0.65rem] font-extrabold uppercase tracking-wider text-white transition hover:bg-emerald-700">
                                                                {{ __('owner.orders.approve') }}
                                                            </button>
                                                        </form>
                                                    @endif
                                                @endif
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @endif
            </section>

            @if ($orders->hasPages())
                <div class="mt-8">
                    {{ $orders->links() }}
                </div>
            @endif
        </div>
    </div>
</x-app-layout>
