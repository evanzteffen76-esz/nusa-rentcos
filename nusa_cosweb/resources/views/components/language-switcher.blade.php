@props(['label' => null])

<div {{ $attributes->merge(['class' => 'relative']) }}>
    <form method="POST" action="{{ route('language.switch') }}">
        @csrf
        <input type="hidden" name="redirect" value="{{ request()->getRequestUri() }}">

        <label for="language-selector" class="sr-only">{{ $label ?? __('language.select') }}</label>
        <div class="relative">
            <span class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm" aria-hidden="true">
                {{ config('locales.supported.'.app()->getLocale().'.flag') }}
            </span>
            <select
                id="language-selector"
                name="locale"
                onchange="this.form.submit()"
                class="h-10 cursor-pointer appearance-none rounded-full border border-slate-200 bg-white/80 py-2 pl-9 pr-8 text-xs font-bold text-slate-700 shadow-sm outline-none transition hover:border-violet-200 hover:text-violet-700 focus:border-violet-400 focus:ring-4 focus:ring-violet-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:border-violet-500 dark:hover:text-violet-200"
                aria-label="{{ $label ?? __('language.select') }}"
            >
                @foreach (config('locales.supported', []) as $code => $locale)
                    <option value="{{ $code }}" @selected(app()->getLocale() === $code)>
                        {{ $locale['native_name'] }}
                    </option>
                @endforeach
            </select>
            <svg viewBox="0 0 20 20" fill="none" class="pointer-events-none absolute right-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-slate-400 dark:text-slate-500" aria-hidden="true">
                <path d="m5 7.5 5 5 5-5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
        </div>
    </form>
</div>
