<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">
        <meta name="description" content="{{ __('app.description') }}">

        <title>{{ __('app.name') }} — {{ __('site.auth.member_access') }}</title>

        <x-favicon />

        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=figtree:400,500,600,700,800" rel="stylesheet" />

        <x-theme-init />

        @vite(['resources/css/app.css', 'resources/js/app.js'])
    </head>
    <body class="min-h-screen overflow-x-hidden bg-[#f8f7f4] font-sans text-slate-900 antialiased dark:bg-slate-950">
        <div class="home-canvas relative flex min-h-screen flex-col overflow-hidden">
            <div aria-hidden="true" class="pointer-events-none absolute -left-40 -top-48 h-[34rem] w-[34rem] rounded-full bg-violet-200/45 blur-3xl"></div>
            <div aria-hidden="true" class="pointer-events-none absolute -right-44 top-48 h-[30rem] w-[30rem] rounded-full bg-rose-200/40 blur-3xl"></div>
            <div aria-hidden="true" class="pointer-events-none absolute bottom-[-18rem] left-1/3 h-[30rem] w-[30rem] rounded-full bg-amber-100/70 blur-3xl"></div>

            <header class="relative z-20 mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-5 py-6 sm:px-8 lg:px-10">
                <a href="{{ url('/') }}" aria-label="{{ __('app.name') }}">
                    <x-brand-logo />
                </a>

                <div class="flex items-center gap-2">
                    <x-language-switcher class="shrink-0" />

                    <a
                        href="{{ url('/') }}"
                        class="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-slate-200 bg-white/75 text-slate-700 shadow-sm transition hover:-translate-y-0.5 hover:border-violet-300 hover:bg-white hover:text-violet-700 dark:border-slate-700 dark:bg-slate-900/80 dark:text-slate-200 dark:hover:border-violet-500 dark:hover:bg-slate-800 dark:hover:text-violet-200"
                        aria-label="{{ __('site.nav.home') }}"
                        title="{{ __('site.nav.home') }}"
                    >
                        <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                            <path d="M3 10.5 12 3l9 7.5V19a2 2 0 0 1-2 2h-4v-6H9v6H5a2 2 0 0 1-2-2v-8.5Z" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        <span class="sr-only">{{ __('site.nav.home') }}</span>
                    </a>

                    <x-theme-toggle />
                </div>
            </header>

            <main class="relative z-10 mx-auto flex w-full max-w-2xl flex-1 flex-col justify-center px-5 pb-14 sm:px-8 lg:px-10">
                {{ $slot }}
            </main>

            <footer class="relative z-10 px-5 pb-8 sm:px-8 lg:px-10">
                <div class="mx-auto flex max-w-2xl flex-col items-center gap-2 text-center text-xs font-semibold text-slate-400 dark:text-slate-500 sm:flex-row sm:justify-between">
                    <span>© {{ date('Y') }} {{ __('app.name') }}</span>
                    <p>{{ __('site.footer.tagline') }}</p>
                </div>
            </footer>
        </div>
    </body>
</html>
