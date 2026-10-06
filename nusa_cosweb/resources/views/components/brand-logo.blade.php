@props(['compact' => false])

<span {{ $attributes->merge(['class' => 'group inline-flex items-center gap-3']) }}>
    <span @class([
        'flex shrink-0 items-center justify-center bg-slate-950 text-white shadow-xl shadow-violet-500/20 transition duration-300 group-hover:-rotate-6 group-hover:shadow-violet-500/40',
        'h-9 w-9 rounded-xl' => $compact,
        'h-11 w-11 rounded-2xl' => ! $compact,
    ])>
        <svg viewBox="0 0 32 32" fill="none" class="{{ $compact ? 'h-5 w-5' : 'h-6 w-6' }}" aria-hidden="true">
            <path d="M7.5 21.5 16 7l8.5 14.5" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M10.2 21.5h11.6M12.5 17h7" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>
            <path d="m23.4 6.8.65 1.65 1.65.65-1.65.65-.65 1.65-.65-1.65-1.65-.65 1.65-.65.65-1.65Z" fill="currentColor"/>
        </svg>
    </span>

    <span class="leading-none">
        <span class="block text-sm font-extrabold tracking-[0.22em] text-slate-950 dark:text-white">COSPLAY</span>
        <span class="mt-1 block text-[0.62rem] font-bold tracking-[0.34em] text-violet-600">NUSA</span>
    </span>
</span>
