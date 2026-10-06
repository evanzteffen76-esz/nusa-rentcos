<button
    type="button"
    data-theme-toggle
    class="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-slate-200 bg-white/75 text-slate-700 shadow-sm transition hover:-translate-y-0.5 hover:border-violet-300 hover:bg-white hover:text-violet-700 dark:border-slate-700 dark:bg-slate-900/80 dark:text-slate-200 dark:hover:border-violet-500 dark:hover:bg-slate-800 dark:hover:text-violet-200"
    aria-label="{{ __('common.toggle_theme') }}"
    aria-pressed="false"
    title="{{ __('common.toggle_theme') }}"
>
    <svg data-theme-icon="light" viewBox="0 0 24 24" fill="none" class="hidden h-5 w-5 dark:block" aria-hidden="true">
        <circle cx="12" cy="12" r="3.5" stroke="currentColor" stroke-width="1.7"/>
        <path d="M12 2.75v2M12 19.25v2M21.25 12h-2M4.75 12h-2M18.54 5.46 17.13 6.87M6.87 17.13l-1.41 1.41M18.54 18.54l-1.41-1.41M6.87 6.87 5.46 5.46" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>
    </svg>
    <svg data-theme-icon="dark" viewBox="0 0 24 24" fill="none" class="h-5 w-5 dark:hidden" aria-hidden="true">
        <path d="M20.2 15.2A8.5 8.5 0 0 1 8.8 3.8 8.5 8.5 0 1 0 20.2 15.2Z" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    <span class="sr-only">{{ __('common.toggle_theme') }}</span>
</button>
