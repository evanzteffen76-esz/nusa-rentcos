<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('owner.costumes.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('owner.costumes.title') }}</h2>
            </div>
            <a href="{{ route('cosrent-owner.costumes.create') }}" class="inline-flex w-fit items-center gap-2 rounded-full bg-slate-950 px-5 py-3 text-sm font-extrabold text-white shadow-lg shadow-slate-950/15 transition hover:-translate-y-0.5 hover:bg-violet-700">
                <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M10 4v12M4 10h12" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                {{ __('owner.costumes.add') }}
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

            <div class="mb-6 max-w-2xl">
                <p class="text-sm leading-6 text-slate-600">{{ __('owner.costumes.subtitle') }}</p>
            </div>

            @if ($costumes->isEmpty())
                <div class="rounded-[2rem] border border-dashed border-slate-300 bg-white px-6 py-16 text-center shadow-lg shadow-slate-950/5">
                    <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                        <svg viewBox="0 0 24 24" fill="none" class="h-7 w-7" aria-hidden="true"><path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="m4 7.5 8 4.5 8-4.5M12 12v9" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>
                    </span>
                    <h3 class="mt-5 text-xl font-extrabold text-slate-950">{{ __('owner.costumes.empty.title') }}</h3>
                    <p class="mx-auto mt-2 max-w-md text-sm leading-6 text-slate-500">{{ __('owner.costumes.empty.description') }}</p>
                    <a href="{{ route('cosrent-owner.costumes.create') }}" class="mt-6 inline-flex items-center gap-2 rounded-full bg-violet-700 px-5 py-3 text-sm font-extrabold text-white transition hover:bg-violet-800">
                        {{ __('owner.costumes.add') }}
                    </a>
                </div>
            @else
                <div class="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
                    @foreach ($costumes as $costume)
                        <article class="group overflow-hidden rounded-[1.75rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5 transition hover:-translate-y-1 hover:shadow-2xl hover:shadow-violet-100/50">
                            <x-costume-artwork :costume="$costume" class="h-52" />
                            <div class="p-5">
                                <div class="flex items-start justify-between gap-4">
                                    <div class="min-w-0">
                                        <p class="text-xs font-extrabold uppercase tracking-[0.14em] text-violet-600">{{ $costume->category }} · {{ $costume->size }}</p>
                                        <h3 class="mt-2 truncate text-lg font-extrabold tracking-tight text-slate-950">{{ $costume->name }}</h3>
                                        <p class="mt-1 truncate text-sm text-slate-500">{{ $costume->character_name }}</p>
                                    </div>
                                    <span class="shrink-0 rounded-full px-2.5 py-1 text-[0.62rem] font-extrabold uppercase tracking-wider {{ $costume->is_published ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-600' }}">
                                        {{ $costume->is_published ? __('owner.costumes.published') : __('owner.costumes.unpublished') }}
                                    </span>
                                </div>

                                <p class="mt-4 line-clamp-2 min-h-10 text-sm leading-5 text-slate-500">{{ $costume->description }}</p>

                                <div class="mt-5 grid grid-cols-3 gap-2 rounded-2xl bg-slate-50 p-3 text-center">
                                    <div>
                                        <p class="text-sm font-extrabold text-slate-950">{{ $costume->stock }}</p>
                                        <p class="mt-0.5 text-[0.62rem] font-bold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.stock') }}</p>
                                    </div>
                                    <div class="border-x border-slate-200">
                                        <p class="text-sm font-extrabold text-slate-950">{{ $costume->rental_orders_count }}</p>
                                        <p class="mt-0.5 text-[0.62rem] font-bold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.orders') }}</p>
                                    </div>
                                    <div>
                                        <p class="text-sm font-extrabold text-slate-950">{{ \Number::currency($costume->price_per_day, in: 'IDR', locale: app()->getLocale()) }}</p>
                                        <p class="mt-0.5 text-[0.62rem] font-bold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.price') }}</p>
                                        @if ($costume->extra_price_per_day > 0)
                                            <p class="mt-0.5 text-[0.62rem] font-bold uppercase tracking-wider text-violet-600">
                                                +{{ \Number::currency($costume->extra_price_per_day, in: 'IDR', locale: app()->getLocale()) }} {{ __('owner.orders.extra_rate_short') }}
                                            </p>
                                        @endif
                                    </div>
                                </div>

                                <div class="mt-5 flex items-center gap-2">
                                    <a href="{{ route('cosrent-owner.costumes.edit', $costume) }}" class="inline-flex flex-1 items-center justify-center rounded-full border border-slate-200 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                                        {{ __('owner.costumes.edit') }}
                                    </a>
                                    <form
                                        method="POST"
                                        action="{{ route('cosrent-owner.costumes.destroy', $costume) }}"
                                        x-data="{ confirmation: @js(__('owner.costumes.delete_confirm')) }"
                                        x-on:submit="if (! window.confirm(confirmation)) $event.preventDefault()"
                                    >
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="inline-flex items-center justify-center rounded-full border border-rose-200 px-4 py-2.5 text-xs font-extrabold uppercase tracking-wider text-rose-700 transition hover:bg-rose-50">
                                            {{ __('owner.costumes.delete') }}
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </article>
                    @endforeach
                </div>

                <div class="mt-8">
                    {{ $costumes->links() }}
                </div>
            @endif
        </div>
    </div>
</x-app-layout>
