<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('admin.header.eyebrow') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('admin.header.title') }}</h2>
            </div>
            <span class="inline-flex w-fit items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3.5 py-2 text-xs font-extrabold uppercase tracking-[0.14em] text-emerald-700">
                <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
                {{ __('common.secure_area') }}
            </span>
        </div>
    </x-slot>

    <div class="bg-slate-100 py-10 sm:py-12">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="grid gap-6 lg:grid-cols-[minmax(0,1.45fr)_minmax(280px,0.55fr)]">
                <section class="relative overflow-hidden rounded-[2rem] bg-slate-950 p-7 text-white shadow-2xl shadow-slate-950/15 sm:p-9">
                    <div aria-hidden="true" class="absolute -right-20 -top-24 h-72 w-72 rounded-full bg-violet-500/30 blur-3xl"></div>
                    <div aria-hidden="true" class="absolute -bottom-28 left-1/3 h-64 w-64 rounded-full bg-rose-500/20 blur-3xl"></div>
                    <div class="relative">
                        <div class="flex items-center justify-between gap-4">
                            <span class="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-white/10 text-violet-200">
                                <svg viewBox="0 0 24 24" fill="none" class="h-6 w-6" aria-hidden="true">
                                    <path d="M12 3.5 14.3 8l4.7.7-3.4 3.3.8 4.7-4.4-2.3-4.4 2.3.8-4.7L5 8.7 9.7 8 12 3.5Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                                </svg>
                            </span>
                            <span class="rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-[0.62rem] font-extrabold uppercase tracking-[0.18em] text-white/65">{{ __('common.live_overview') }}</span>
                        </div>
                        <p class="mt-10 text-xs font-extrabold uppercase tracking-[0.2em] text-violet-300">{{ __('admin.hero.welcome') }}</p>
                        <h3 class="mt-3 max-w-xl text-3xl font-extrabold tracking-[-0.045em] sm:text-4xl">{{ __('admin.hero.greeting', ['name' => $admin->name]) }}</h3>
                        <p class="mt-4 max-w-xl text-sm leading-7 text-white/60 sm:text-base">{{ __('admin.hero.description') }}</p>
                        <div class="mt-8 flex flex-wrap gap-3">
                            <a href="{{ route('profile.edit') }}" class="inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-extrabold text-slate-950 transition hover:-translate-y-0.5 hover:bg-violet-100">
                                {{ __('admin.hero.profile') }}
                                <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                            </a>
                            <a href="{{ url('/') }}" class="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-sm font-extrabold text-white transition hover:-translate-y-0.5 hover:bg-white/15">
                                {{ __('admin.hero.landing') }}
                            </a>
                        </div>
                    </div>
                </section>

                <aside class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-7">
                    <div class="flex items-start justify-between gap-4">
                        <div>
                            <p class="text-[0.65rem] font-extrabold uppercase tracking-[0.2em] text-violet-600">{{ __('admin.quick.eyebrow') }}</p>
                            <h3 class="mt-2 text-xl font-extrabold tracking-tight text-slate-950">{{ __('admin.quick.title') }}</h3>
                        </div>
                        <span class="flex h-10 w-10 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M12 4v16M4 12h16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>
                        </span>
                    </div>

                    <div class="mt-6 grid gap-3">
                        <a href="{{ route('profile.edit') }}" class="group flex items-center justify-between rounded-2xl border border-slate-200 px-4 py-3.5 text-sm font-bold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                            <span>{{ __('admin.quick.account') }}</span>
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>
                        <a href="{{ route('dashboard') }}" class="group flex items-center justify-between rounded-2xl border border-slate-200 px-4 py-3.5 text-sm font-bold text-slate-700 transition hover:border-violet-200 hover:bg-violet-50 hover:text-violet-700">
                            <span>{{ __('admin.quick.dashboard') }}</span>
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </a>
                    </div>

                    <div class="mt-6 rounded-2xl bg-slate-50 p-4">
                        <div class="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.16em] text-slate-500">
                            <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
                            {{ __('common.database_connection') }}
                        </div>
                        <div class="mt-3 flex items-center justify-between gap-3">
                            <span class="text-sm font-bold text-slate-950">{{ strtoupper($databaseConnection) }}</span>
                            <span class="rounded-full bg-emerald-100 px-2.5 py-1 text-[0.65rem] font-extrabold text-emerald-700">{{ __('common.connected') }}</span>
                        </div>
                    </div>
                </aside>
            </div>

            <div class="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <div class="rounded-3xl border border-white/80 bg-white p-6 shadow-lg shadow-slate-950/5">
                    <div class="flex items-center justify-between">
                        <span class="text-sm font-bold text-slate-500">{{ __('admin.stats.users') }}</span>
                        <span class="flex h-10 w-10 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M16 19v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 17.5V19m6-8a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm6-7.5a3 3 0 0 1 0 5.8M19.5 19v-1.2a3 3 0 0 0-1.8-2.75" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </span>
                    </div>
                    <p class="mt-5 text-3xl font-extrabold tracking-tight text-slate-950">{{ $totalUsers }}</p>
                    <p class="mt-1 text-xs font-semibold text-slate-500">{{ __('admin.stats.users_desc') }}</p>
                </div>

                <div class="rounded-3xl border border-white/80 bg-white p-6 shadow-lg shadow-slate-950/5">
                    <div class="flex items-center justify-between">
                        <span class="text-sm font-bold text-slate-500">{{ __('admin.stats.admin_access') }}</span>
                        <span class="flex h-10 w-10 items-center justify-center rounded-2xl bg-amber-100 text-amber-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M12 3.5 14.3 8l4.7.7-3.4 3.3.8 4.7-4.4-2.3-4.4 2.3.8-4.7L5 8.7 9.7 8 12 3.5Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>
                        </span>
                    </div>
                    <p class="mt-5 text-3xl font-extrabold tracking-tight text-slate-950">{{ $adminCount }}</p>
                    <p class="mt-1 text-xs font-semibold text-slate-500">{{ __('admin.stats.admin_desc') }}</p>
                </div>

                <div class="rounded-3xl border border-white/80 bg-white p-6 shadow-lg shadow-slate-950/5">
                    <div class="flex items-center justify-between">
                        <span class="text-sm font-bold text-slate-500">{{ __('admin.stats.owner_access') }}</span>
                        <span class="flex h-10 w-10 items-center justify-center rounded-2xl bg-cyan-100 text-cyan-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="m4 7.5 8 4.5 8-4.5M12 12v9" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>
                        </span>
                    </div>
                    <p class="mt-5 text-3xl font-extrabold tracking-tight text-slate-950">{{ $ownerCount }}</p>
                    <p class="mt-1 text-xs font-semibold text-slate-500">{{ __('admin.stats.owner_desc') }}</p>
                </div>

                <div class="rounded-3xl border border-white/80 bg-white p-6 shadow-lg shadow-slate-950/5">
                    <div class="flex items-center justify-between">
                        <span class="text-sm font-bold text-slate-500">{{ __('admin.stats.regular') }}</span>
                        <span class="flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-100 text-emerald-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M5 12.5 9.5 17 19 7.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        </span>
                    </div>
                    <p class="mt-5 text-3xl font-extrabold tracking-tight text-slate-950">{{ $regularUserCount }}</p>
                    <p class="mt-1 text-xs font-semibold text-slate-500">{{ __('admin.stats.regular_desc') }}</p>
                </div>
            </div>

            <section class="mt-6 rounded-[2rem] border border-violet-100 bg-violet-50 p-6 sm:p-8">
                <div class="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-start gap-4">
                        <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-white text-violet-700 shadow-sm">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M12 3.5 14.3 8l4.7.7-3.4 3.3.8 4.7-4.4-2.3-4.4 2.3.8-4.7L5 8.7 9.7 8 12 3.5Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>
                        </span>
                        <div>
                            <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ __('admin.foundation.title') }}</h3>
                            <p class="mt-1 max-w-2xl text-sm leading-6 text-slate-600">{{ __('admin.foundation.description') }}</p>
                        </div>
                    </div>
                    <span class="w-fit rounded-full bg-white px-3.5 py-2 text-xs font-extrabold text-violet-700 shadow-sm">{{ __('admin.foundation.badge') }}</span>
                </div>
            </section>
        </div>
    </div>
</x-app-layout>
