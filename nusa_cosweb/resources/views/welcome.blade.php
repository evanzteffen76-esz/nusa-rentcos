<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="{{ __('app.description') }}">

    <title>{{ __('app.name') }} — {{ __('site.nav.collection') }}</title>

    <x-favicon />

    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=figtree:400,500,600,700,800" rel="stylesheet" />

    <x-theme-init />

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body
    class="min-h-screen overflow-x-hidden bg-[#f8f7f4] font-sans text-slate-900 dark:text-slate-100 antialiased dark:bg-slate-950">
    <div x-data="{
        mobileMenuOpen: false
    }" class="home-canvas relative min-h-screen overflow-hidden">
        <div aria-hidden="true"
            class="pointer-events-none absolute -left-40 -top-48 h-[34rem] w-[34rem] rounded-full bg-violet-200/45 blur-3xl">
        </div>
        <div aria-hidden="true"
            class="pointer-events-none absolute -right-44 top-48 h-[30rem] w-[30rem] rounded-full bg-rose-200/40 blur-3xl">
        </div>
        <div aria-hidden="true"
            class="pointer-events-none absolute bottom-[-18rem] left-1/3 h-[30rem] w-[30rem] rounded-full bg-amber-100/70 blur-3xl">
        </div>

        <header class="relative z-20 mx-auto max-w-7xl px-5 py-6 sm:px-8 lg:px-10">
            <div class="flex items-center justify-between">
                <a href="{{ url('/') }}" aria-label="{{ __('app.name') }}">
                    <x-brand-logo />
                </a>

                <nav class="hidden items-center gap-8 text-sm font-semibold text-slate-500 dark:text-slate-400 lg:flex"
                    aria-label="Navigasi utama">
                    <a href="#koleksi"
                        class="transition hover:text-slate-950 dark:text-white">{{ __('site.nav.collection') }}</a>
                    <a href="#keunggulan"
                        class="transition hover:text-slate-950 dark:text-white">{{ __('site.nav.benefits') }}</a>
                    <a href="#cara-kerja"
                        class="transition hover:text-slate-950 dark:text-white">{{ __('site.nav.how_it_works') }}</a>
                </nav>

                <div class="flex items-center gap-2">
                    <x-language-switcher class="shrink-0" />

                    @auth
                        <a href="{{ route(Auth::user()->isCosrentOwner() ? 'cosrent-owner.dashboard' : 'dashboard') }}"
                            class="hidden rounded-full bg-slate-950 px-5 py-2.5 text-sm font-bold text-white shadow-lg shadow-slate-950/15 transition hover:-translate-y-0.5 hover:bg-violet-700 sm:inline-flex">
                            {{ __('nav.dashboard') }}
                        </a>
                    @else
                        <a href="{{ route('login') }}"
                            class="hidden rounded-full px-3.5 py-2.5 text-sm font-bold text-slate-600 dark:text-slate-300 transition hover:bg-white dark:hover:bg-slate-800 hover:text-slate-950 dark:text-white sm:inline-flex sm:px-4">
                            {{ __('common.login') }}
                        </a>
                        <a href="{{ route('register') }}"
                            class="hidden rounded-full bg-slate-950 px-4 py-2.5 text-sm font-bold text-white shadow-lg shadow-slate-950/15 transition hover:-translate-y-0.5 hover:bg-violet-700 sm:inline-flex sm:px-5">
                            {{ __('common.register') }}
                        </a>
                    @endauth

                    <x-theme-toggle />

                    <button type="button" @click="mobileMenuOpen = ! mobileMenuOpen"
                        class="inline-flex h-10 w-10 items-center justify-center rounded-full border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/70 text-slate-700 dark:text-slate-200 shadow-sm transition hover:border-slate-300 dark:hover:border-slate-600 hover:text-slate-950 dark:text-white lg:hidden"
                        :aria-expanded="mobileMenuOpen" aria-label="{{ __('site.nav.menu') }}">
                        <svg x-show="! mobileMenuOpen" viewBox="0 0 24 24" fill="none" class="h-5 w-5"
                            aria-hidden="true">
                            <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" stroke-width="1.8"
                                stroke-linecap="round" />
                        </svg>
                        <svg x-show="mobileMenuOpen" x-cloak viewBox="0 0 24 24" fill="none" class="h-5 w-5"
                            aria-hidden="true">
                            <path d="m6 6 12 12M18 6 6 18" stroke="currentColor" stroke-width="1.8"
                                stroke-linecap="round" />
                        </svg>
                    </button>
                </div>
            </div>

            <div x-show="mobileMenuOpen" x-cloak x-transition.origin.top
                class="absolute inset-x-5 top-[5.25rem] rounded-2xl border border-white/80 dark:border-slate-700 bg-white/95 dark:bg-slate-900/95 p-3 shadow-2xl shadow-slate-950/10 backdrop-blur-xl lg:hidden">
                <nav class="grid gap-1 text-sm font-semibold text-slate-600 dark:text-slate-300"
                    aria-label="Navigasi seluler">
                    <a href="#koleksi" @click="mobileMenuOpen = false"
                        class="rounded-xl px-4 py-3 transition hover:bg-violet-50 dark:hover:bg-violet-950/40 hover:text-violet-700 dark:hover:text-violet-300">{{ __('site.nav.collection') }}</a>
                    <a href="#keunggulan" @click="mobileMenuOpen = false"
                        class="rounded-xl px-4 py-3 transition hover:bg-violet-50 dark:hover:bg-violet-950/40 hover:text-violet-700 dark:hover:text-violet-300">{{ __('site.nav.benefits') }}</a>
                    <a href="#cara-kerja" @click="mobileMenuOpen = false"
                        class="rounded-xl px-4 py-3 transition hover:bg-violet-50 dark:hover:bg-violet-950/40 hover:text-violet-700 dark:hover:text-violet-300">{{ __('site.nav.how_it_works') }}</a>
                </nav>
                <div class="mt-2 border-t border-slate-100 dark:border-slate-800 pt-2">
                    @auth
                        <a href="{{ route(Auth::user()->isCosrentOwner() ? 'cosrent-owner.dashboard' : 'dashboard') }}"
                            @click="mobileMenuOpen = false"
                            class="block rounded-xl bg-slate-950 px-4 py-3 text-center text-sm font-bold text-white">{{ __('nav.dashboard') }}</a>
                    @else
                        <div class="grid grid-cols-2 gap-2">
                            <a href="{{ route('login') }}"
                                class="rounded-xl border border-slate-200 dark:border-slate-700 px-4 py-3 text-center text-sm font-bold text-slate-700 dark:text-slate-200 transition hover:border-violet-200 dark:hover:border-violet-500 hover:text-violet-700 dark:hover:text-violet-300">{{ __('common.login') }}</a>
                            <a href="{{ route('register') }}"
                                class="rounded-xl bg-slate-950 px-4 py-3 text-center text-sm font-bold text-white transition hover:bg-violet-700">{{ __('common.register') }}</a>
                        </div>
                    @endauth
                </div>
            </div>
        </header>

        <main
            class="relative z-10 mx-auto w-full max-w-4xl px-5 pb-16 pt-8 sm:px-8 sm:pt-12 lg:px-10 lg:pb-24 lg:pt-16">
            <section class="min-w-0">
                <div
                    class="inline-flex items-center gap-2 rounded-full border border-violet-200/80 dark:border-violet-500/40 bg-white/75 dark:bg-slate-900/75 px-3.5 py-2 text-xs font-extrabold uppercase tracking-[0.16em] text-violet-700 shadow-sm shadow-violet-200/30 backdrop-blur">
                    <span class="relative flex h-2 w-2">
                        <span
                            class="absolute inline-flex h-full w-full animate-ping rounded-full bg-violet-400 opacity-60"></span>
                        <span class="relative inline-flex h-2 w-2 rounded-full bg-violet-600"></span>
                    </span>
                    {{ __('site.hero.badge') }}
                </div>

                <h1
                    class="mt-7 max-w-2xl text-5xl font-extrabold leading-[0.98] tracking-[-0.065em] text-slate-950 dark:text-white sm:text-6xl lg:text-[5.25rem]">
                    {{ __('site.hero.title_first') }}
                    <span
                        class="mt-1 block bg-gradient-to-r from-violet-700 via-fuchsia-500 to-rose-500 bg-clip-text text-transparent">{{ __('site.hero.title_second') }}</span>
                </h1>

                <p
                    class="mt-7 w-full max-w-xl break-words text-base leading-8 text-slate-500 dark:text-slate-400 sm:text-lg">
                    {{ __('site.hero.description') }}
                </p>

                <div class="mt-9 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
                    <a href="#koleksi"
                        class="group inline-flex items-center justify-center gap-3 rounded-full bg-slate-950 px-6 py-3.5 text-sm font-bold text-white shadow-xl shadow-slate-950/15 transition hover:-translate-y-0.5 hover:bg-violet-700 hover:shadow-violet-500/25">
                        {{ __('site.hero.explore') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1"
                            aria-hidden="true">
                            <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8"
                                stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                    </a>
                    @guest
                        <a href="{{ route('register') }}"
                            class="group inline-flex items-center justify-center gap-3 rounded-full bg-violet-600 px-6 py-3.5 text-sm font-bold text-white shadow-xl shadow-violet-500/25 transition hover:-translate-y-0.5 hover:bg-violet-700">
                            {{ __('site.auth.register_button') }}
                            <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1"
                                aria-hidden="true">
                                <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8"
                                    stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                        </a>
                    @endguest
                    <a href="#cara-kerja"
                        class="group inline-flex items-center justify-center gap-3 rounded-full border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/70 px-6 py-3.5 text-sm font-bold text-slate-700 dark:text-slate-200 shadow-sm transition hover:-translate-y-0.5 hover:border-violet-200 dark:hover:border-violet-500 hover:text-violet-700 dark:hover:text-violet-300">
                        {{ __('site.hero.how') }}
                        <span class="text-xs font-extrabold text-violet-500">01</span>
                    </a>
                </div>

                <div
                    class="mt-10 grid w-full max-w-xl grid-cols-3 divide-x divide-slate-200/80 dark:divide-slate-800/80 border-y border-slate-200/80 dark:border-slate-800/80 py-5">
                    <div class="min-w-0 pr-4">
                        <p class="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">
                            120+</p>
                        <p class="mt-1 text-xs font-semibold leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.hero.stat_sets') }}</p>
                    </div>
                    <div class="min-w-0 px-4 sm:px-6">
                        <p class="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">
                            4.9<span class="text-violet-500">/5</span></p>
                        <p class="mt-1 text-xs font-semibold leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.hero.stat_rating') }}</p>
                    </div>
                    <div class="min-w-0 pl-4 sm:pl-6">
                        <p class="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">
                            24<span class="text-violet-500">h</span></p>
                        <p class="mt-1 text-xs font-semibold leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.hero.stat_support') }}</p>
                    </div>
                </div>

                <div class="relative mt-12 h-64 overflow-hidden rounded-[2rem] border border-white/80 dark:border-slate-700 bg-slate-900 shadow-2xl shadow-slate-950/15 sm:h-80"
                    role="img" aria-label="{{ __('site.hero.image_label') }}">
                    <div class="hero-photo absolute inset-0"></div>
                    <div class="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-transparent">
                    </div>
                    <div
                        class="absolute left-5 top-5 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-[0.65rem] font-extrabold uppercase tracking-[0.18em] text-white backdrop-blur-md">
                        <span class="h-1.5 w-1.5 rounded-full bg-rose-300"></span>
                        {{ __('site.hero.curated_drop') }}
                    </div>
                    <div
                        class="absolute right-5 top-5 h-20 w-16 overflow-hidden rounded-2xl border border-white/30 bg-slate-800 shadow-xl shadow-slate-950/30">
                        <div class="thumbnail-photo h-full w-full"></div>
                    </div>
                    <div class="absolute bottom-5 left-5 right-5 flex items-end justify-between gap-4 text-white">
                        <div>
                            <p class="text-[0.62rem] font-bold uppercase tracking-[0.2em] text-white/60">
                                {{ __('site.hero.editor_pick') }}</p>
                            <p class="mt-1 text-xl font-extrabold tracking-tight sm:text-2xl">Nebula Witch</p>
                            <p class="mt-1 text-xs font-medium text-white/65">{{ __('site.hero.complete_set') }}</p>
                        </div>
                        <span
                            class="shrink-0 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-bold backdrop-blur-md">Rp
                            75k</span>
                    </div>
                </div>
            </section>
        </main>

        <section id="koleksi"
            class="relative z-10 border-t border-slate-200/70 dark:border-slate-800/70 bg-white/35 dark:bg-slate-950/35 px-5 py-16 backdrop-blur-sm sm:px-8 lg:px-10 lg:py-20">
            <div class="mx-auto max-w-7xl">
                <div class="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
                    <div>
                        <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">
                            {{ __('site.collection.eyebrow') }}</p>
                        <h2
                            class="mt-3 max-w-xl text-3xl font-extrabold tracking-[-0.045em] text-slate-950 dark:text-white sm:text-4xl">
                            {{ __('site.collection.title') }}</h2>
                    </div>
                    <a href="{{ Auth::check() ? route(Auth::user()->isCosrentOwner() ? 'cosrent-owner.dashboard' : 'dashboard') : route('register') }}"
                        class="group inline-flex items-center gap-2 text-sm font-bold text-slate-600 dark:text-slate-300 transition hover:text-violet-700 dark:hover:text-violet-300">
                        {{ Auth::check() ? __('nav.dashboard') : __('site.collection.action') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1"
                            aria-hidden="true">
                            <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8"
                                stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                    </a>
                </div>

                <div class="mt-9 grid gap-4 md:grid-cols-3">
                    <article class="collection-card collection-card-violet group">
                        <div class="relative z-10 flex h-full flex-col justify-between">
                            <div class="flex items-center justify-between">
                                <span
                                    class="rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-[0.62rem] font-extrabold uppercase tracking-[0.18em] text-white/75">{{ __('site.collection.fantasy') }}</span>
                                <span
                                    class="text-4xl text-white/40 transition duration-500 group-hover:rotate-12 group-hover:scale-110">✦</span>
                            </div>
                            <div>
                                <h3 class="text-2xl font-extrabold tracking-tight text-white">Nightbloom</h3>
                                <p class="mt-2 text-sm text-white/65">{{ __('site.collection.fantasy_desc') }}</p>
                            </div>
                        </div>
                    </article>

                    <article class="collection-card collection-card-blue group">
                        <div class="relative z-10 flex h-full flex-col justify-between">
                            <div class="flex items-center justify-between">
                                <span
                                    class="rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-[0.62rem] font-extrabold uppercase tracking-[0.18em] text-white/75">{{ __('site.collection.heroic') }}</span>
                                <span
                                    class="text-4xl text-white/40 transition duration-500 group-hover:-rotate-12 group-hover:scale-110">✧</span>
                            </div>
                            <div>
                                <h3 class="text-2xl font-extrabold tracking-tight text-white">Astra Guard</h3>
                                <p class="mt-2 text-sm text-white/65">{{ __('site.collection.heroic_desc') }}</p>
                            </div>
                        </div>
                    </article>

                    <article class="collection-card collection-card-sunset group">
                        <div class="relative z-10 flex h-full flex-col justify-between">
                            <div class="flex items-center justify-between">
                                <span
                                    class="rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-[0.62rem] font-extrabold uppercase tracking-[0.18em] text-white/75">{{ __('site.collection.modern') }}</span>
                                <span
                                    class="text-4xl text-white/40 transition duration-500 group-hover:rotate-12 group-hover:scale-110">✺</span>
                            </div>
                            <div>
                                <h3 class="text-2xl font-extrabold tracking-tight text-white">City Muse</h3>
                                <p class="mt-2 text-sm text-white/65">{{ __('site.collection.modern_desc') }}</p>
                            </div>
                        </div>
                    </article>
                </div>
            </div>
        </section>

        <section id="keunggulan" class="relative z-10 px-5 py-16 sm:px-8 lg:px-10 lg:py-24">
            <div class="mx-auto grid max-w-7xl gap-10 lg:grid-cols-[0.8fr_1.2fr] lg:items-end lg:gap-20">
                <div>
                    <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">
                        {{ __('site.benefits.eyebrow') }}</p>
                    <h2
                        class="mt-3 text-3xl font-extrabold tracking-[-0.045em] text-slate-950 dark:text-white sm:text-4xl">
                        {{ __('site.benefits.title_line_1') }}<br>{{ __('site.benefits.title_line_2') }}</h2>
                </div>
                <div class="grid gap-4 sm:grid-cols-3">
                    <div
                        class="rounded-3xl border border-white/80 dark:border-slate-700 bg-white/70 dark:bg-slate-900/70 p-5 shadow-sm shadow-slate-950/5 backdrop-blur">
                        <span
                            class="flex h-10 w-10 items-center justify-center rounded-2xl bg-violet-100 dark:bg-violet-950 dark:text-violet-300 text-violet-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                                <path d="M12 3.75 14.3 8l4.7.7-3.4 3.3.8 4.7-4.4-2.3-4.4 2.3.8-4.7L5 8.7 9.7 8 12 3.75Z"
                                    stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" />
                            </svg>
                        </span>
                        <h3 class="mt-5 text-sm font-extrabold text-slate-950 dark:text-white">
                            {{ __('site.benefits.quality_title') }}</h3>
                        <p class="mt-2 text-xs leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.benefits.quality_desc') }}</p>
                    </div>
                    <div
                        class="rounded-3xl border border-white/80 dark:border-slate-700 bg-white/70 dark:bg-slate-900/70 p-5 shadow-sm shadow-slate-950/5 backdrop-blur">
                        <span
                            class="flex h-10 w-10 items-center justify-center rounded-2xl bg-rose-100 dark:bg-rose-950 dark:text-rose-300 text-rose-600">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                                <path d="M4 7.5h16v11H4v-11Zm0 1 8 5 8-5M8 4.5h8" stroke="currentColor"
                                    stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                        </span>
                        <h3 class="mt-5 text-sm font-extrabold text-slate-950 dark:text-white">
                            {{ __('site.benefits.booking_title') }}</h3>
                        <p class="mt-2 text-xs leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.benefits.booking_desc') }}</p>
                    </div>
                    <div
                        class="rounded-3xl border border-white/80 dark:border-slate-700 bg-white/70 dark:bg-slate-900/70 p-5 shadow-sm shadow-slate-950/5 backdrop-blur">
                        <span
                            class="flex h-10 w-10 items-center justify-center rounded-2xl bg-amber-100 dark:bg-amber-950 dark:text-amber-300 text-amber-700">
                            <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                                <path d="M12 4.25v7.1l4.25 2.5M19.25 12a7.25 7.25 0 1 1-14.5 0 7.25 7.25 0 0 1 14.5 0Z"
                                    stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
                            </svg>
                        </span>
                        <h3 class="mt-5 text-sm font-extrabold text-slate-950 dark:text-white">
                            {{ __('site.benefits.ready_title') }}</h3>
                        <p class="mt-2 text-xs leading-5 text-slate-500 dark:text-slate-400">
                            {{ __('site.benefits.ready_desc') }}</p>
                    </div>
                </div>
            </div>
        </section>

        <section id="cara-kerja"
            class="relative z-10 border-t border-slate-200/70 dark:border-slate-800/70 bg-white/35 dark:bg-slate-950/35 px-5 py-16 backdrop-blur-sm sm:px-8 lg:px-10 lg:py-20">
            <div class="mx-auto max-w-7xl">
                <div class="flex flex-col justify-between gap-5 sm:flex-row sm:items-end">
                    <div>
                        <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-violet-600">
                            {{ __('site.steps.eyebrow') }}</p>
                        <h2
                            class="mt-3 text-3xl font-extrabold tracking-[-0.045em] text-slate-950 dark:text-white sm:text-4xl">
                            {{ __('site.steps.title') }}</h2>
                    </div>
                    <a href="{{ Auth::check() ? route(Auth::user()->isCosrentOwner() ? 'cosrent-owner.dashboard' : 'dashboard') : route('register') }}"
                        class="group inline-flex items-center gap-2 text-sm font-bold text-slate-600 dark:text-slate-300 transition hover:text-violet-700 dark:hover:text-violet-300">
                        {{ Auth::check() ? __('nav.dashboard') : __('site.steps.action') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4 transition group-hover:translate-x-1"
                            aria-hidden="true">
                            <path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8"
                                stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                    </a>
                </div>

                <div class="mt-10 grid gap-4 md:grid-cols-3">
                    <div class="rounded-[1.75rem] bg-slate-950 p-6 text-white sm:p-7">
                        <span class="text-4xl font-extrabold text-violet-400">01</span>
                        <h3 class="mt-12 text-lg font-extrabold">{{ __('site.steps.choose_title') }}</h3>
                        <p class="mt-2 text-sm leading-6 text-white/55">{{ __('site.steps.choose_desc') }}</p>
                    </div>
                    <div
                        class="rounded-[1.75rem] border border-violet-100 dark:border-violet-500/30 bg-violet-50 dark:bg-violet-950/35 p-6 sm:p-7">
                        <span class="text-4xl font-extrabold text-violet-500">02</span>
                        <h3 class="mt-12 text-lg font-extrabold text-slate-950 dark:text-white">
                            {{ __('site.steps.schedule_title') }}</h3>
                        <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                            {{ __('site.steps.schedule_desc') }}</p>
                    </div>
                    <div
                        class="rounded-[1.75rem] border border-rose-100 dark:border-rose-500/30 bg-rose-50 dark:bg-rose-950/35 p-6 sm:p-7">
                        <span class="text-4xl font-extrabold text-rose-500">03</span>
                        <h3 class="mt-12 text-lg font-extrabold text-slate-950 dark:text-white">
                            {{ __('site.steps.scene_title') }}</h3>
                        <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                            {{ __('site.steps.scene_desc') }}</p>
                    </div>
                </div>
            </div>
        </section>

        <footer class="relative z-10 border-t border-slate-200/70 dark:border-slate-800/70 px-5 py-8 sm:px-8 lg:px-10">
            <div
                class="mx-auto flex max-w-7xl flex-col gap-4 text-xs font-semibold text-slate-400 dark:text-slate-500 sm:flex-row sm:items-center sm:justify-between">
                <div class="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                    <span class="flex h-7 w-7 items-center justify-center rounded-lg bg-slate-950 text-white">
                        <svg viewBox="0 0 32 32" fill="none" class="h-4 w-4" aria-hidden="true">
                            <path d="M7.5 21.5 16 7l8.5 14.5M10.2 21.5h11.6" stroke="currentColor" stroke-width="2.4"
                                stroke-linecap="round" stroke-linejoin="round" />
                        </svg>
                    </span>
                    <span>© {{ date('Y') }} CosplayNusa</span>
                </div>
                <p>{{ __('site.footer.tagline') }}</p>
            </div>
        </footer>
    </div>
</body>

</html>
