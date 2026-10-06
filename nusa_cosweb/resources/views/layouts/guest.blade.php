<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ __('app.name') }}</title>

        <x-favicon />

        <!-- Fonts -->
        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=figtree:400,500,600&display=swap" rel="stylesheet" />

        <x-theme-init />

        <!-- Scripts -->
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    </head>
    <body class="font-sans text-gray-900 antialiased dark:bg-slate-950 dark:text-slate-100">
        <div class="flex min-h-screen flex-col items-center bg-gray-100 px-6 py-6 sm:justify-center sm:py-0 dark:bg-slate-950">
            <div class="w-full sm:max-w-md">
                <div class="flex items-center justify-between">
                    <a href="{{ url('/') }}" aria-label="{{ __('app.name') }}">
                        <x-brand-logo />
                    </a>
                    <x-language-switcher />
                </div>

                <div class="mt-6 w-full overflow-hidden bg-white px-6 py-4 shadow-md dark:bg-slate-900 sm:rounded-lg">
                    {{ $slot }}
                </div>
            </div>
        </div>
    </body>
</html>
