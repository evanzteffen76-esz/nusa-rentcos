<x-app-layout>
    <x-slot name="header">
        <a href="{{ route('dashboard') }}" class="inline-flex items-center gap-2 text-sm font-bold text-slate-500 transition hover:text-violet-700">
            <span aria-hidden="true">←</span>
            {{ __('customer.costume.back') }}
        </a>
        <p class="mt-3 text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('customer.dashboard.eyebrow') }}</p>
        <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ $availableCostume->name }}</h2>
        <p class="mt-2 text-sm text-slate-500">{{ $availableCostume->character_name }} · {{ $availableCostume->category }} · {{ $availableCostume->size }}</p>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(0,0.75fr)] xl:items-start">
                <div class="space-y-6">
                    @if ($gallery !== [])
                        <div class="space-y-4" x-data="{ active: 0, images: @js($gallery) }">
                            <div class="overflow-hidden rounded-[2rem] border border-white/80 bg-white shadow-xl shadow-slate-950/5">
                                <img
                                    src="{{ $gallery[0] }}"
                                    x-bind:src="images[active]"
                                    alt="{{ $availableCostume->character_name }} — {{ $availableCostume->name }}"
                                    class="h-72 w-full object-cover sm:h-[26rem]"
                                >
                            </div>

                            <div class="grid grid-cols-4 gap-3 sm:grid-cols-6">
                                @foreach ($gallery as $index => $image)
                                    <button
                                        type="button"
                                        x-on:click="active = {{ $index }}"
                                        x-bind:aria-current="active === {{ $index }} ? 'true' : 'false'"
                                        class="overflow-hidden rounded-2xl border-2 transition"
                                        x-bind:class="active === {{ $index }} ? 'border-violet-500' : 'border-transparent hover:border-violet-300'"
                                    >
                                        <img src="{{ $image }}" alt="" class="h-16 w-full object-cover sm:h-20" loading="lazy">
                                    </button>
                                @endforeach
                            </div>
                        </div>
                    @else
                        <x-costume-artwork :costume="$availableCostume" class="h-72 rounded-[2rem] sm:h-[26rem]" />
                    @endif

                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                        <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('customer.costume.description') }}</h3>
                        <p class="mt-3 text-sm leading-7 text-slate-500">{{ $availableCostume->description ?: __('customer.costume.description_empty') }}</p>

                        <dl class="mt-6 grid gap-3 sm:grid-cols-3">
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-[0.62rem] font-extrabold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.size') }}</dt>
                                <dd class="mt-1 text-sm font-extrabold text-slate-950">{{ $availableCostume->size }}</dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-[0.62rem] font-extrabold uppercase tracking-wider text-slate-400">{{ __('owner.costume_form.category') }}</dt>
                                <dd class="mt-1 text-sm font-extrabold text-slate-950">{{ $availableCostume->category }}</dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 p-4">
                                <dt class="text-[0.62rem] font-extrabold uppercase tracking-wider text-slate-400">{{ __('owner.costumes.stock') }}</dt>
                                <dd class="mt-1 text-sm font-extrabold text-slate-950">{{ $availableCostume->stock }}</dd>
                            </div>
                        </dl>
                    </section>

                    @if ($videos !== [])
                        <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                            <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('customer.costume.videos') }}</h3>
                            <div class="mt-4 grid gap-4 sm:grid-cols-2">
                                @foreach ($videos as $video)
                                    <video src="{{ $video }}" controls preload="metadata" playsinline class="w-full rounded-2xl bg-slate-950"></video>
                                @endforeach
                            </div>
                        </section>
                    @endif
                </div>

                <aside class="space-y-6 xl:sticky xl:top-6">
                    <section class="rounded-[2rem] bg-slate-950 p-6 text-white shadow-xl shadow-slate-950/15 sm:p-7">
                        <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.16em] text-violet-300">{{ __('owner.costume_form.price') }}</p>
                        <p class="mt-2 text-3xl font-extrabold tracking-tight">{{ \Number::currency($availableCostume->price_per_day, in: 'IDR', locale: app()->getLocale()) }}</p>
                        <p class="mt-2 text-xs leading-5 text-white/50">{{ __('customer.costume.price_note', ['days' => \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS]) }}</p>
                        @if ($availableCostume->extra_price_per_day > 0)
                            <p class="mt-2 text-xs font-bold leading-5 text-violet-300">
                                {{ __('customer.costume.extra_price_note', [
                                    'rate' => \Number::currency($availableCostume->extra_price_per_day, in: 'IDR', locale: app()->getLocale()),
                                    'days' => \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS,
                                ]) }}
                            </p>
                        @endif

                        <a
                            href="{{ route('dashboard.costumes.book.create', $availableCostume) }}"
                            class="mt-6 inline-flex w-full items-center justify-center gap-2 rounded-full bg-white px-6 py-3.5 text-sm font-extrabold text-slate-950 transition hover:bg-violet-100"
                        >
                            {{ __('customer.dashboard.book') }}
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>

                        <p class="mt-5 border-t border-white/10 pt-4 text-xs leading-5 text-white/45">{{ __('customer.booking.description') }}</p>
                    </section>

                    <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5">
                        <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.16em] text-slate-400">{{ __('customer.dashboard.owner') }}</p>
                        <p class="mt-2 text-lg font-extrabold text-slate-950">{{ $availableCostume->owner->name }}</p>
                        <p class="mt-3 text-xs leading-5 text-slate-500">{{ __('customer.costume.owner_note') }}</p>
                    </section>
                </aside>
            </div>
        </div>
    </div>
</x-app-layout>
