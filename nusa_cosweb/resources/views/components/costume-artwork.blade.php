@props(['costume'])

@php
    $gradientClasses = match (strtolower($costume->category)) {
        'fantasy' => 'from-violet-950 via-purple-900 to-fuchsia-600',
        'heroic' => 'from-slate-950 via-blue-950 to-cyan-500',
        'modern' => 'from-rose-950 via-orange-700 to-amber-400',
        default => 'from-slate-950 via-indigo-900 to-violet-600',
    };

    $initials = mb_strtoupper(mb_substr(trim($costume->character_name), 0, 2));
    $cover = $costume->image_url ?: $costume->coverImageUrl();
@endphp

<div {{ $attributes->merge(['class' => 'relative isolate overflow-hidden bg-slate-950']) }}>
    @if (filled($cover))
        <img
            src="{{ $cover }}"
            alt="{{ $costume->character_name }} — {{ $costume->name }}"
            class="h-full w-full object-cover"
            loading="lazy"
        >
        @if ($costume->videoCount() > 0)
            <span class="absolute bottom-3 right-3 inline-flex items-center gap-1.5 rounded-full bg-slate-950/80 px-2.5 py-1 text-[0.62rem] font-extrabold text-white backdrop-blur">
                <svg viewBox="0 0 24 24" fill="none" class="h-3.5 w-3.5" aria-hidden="true">
                    <path d="M3.5 6.5h17v11h-17v-11Zm4 0v11m9-11v11m-13-5.5h17" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                {{ $costume->videoCount() }}
                <span class="sr-only">{{ __('owner.costume_form.videos') }}</span>
            </span>
        @endif
    @else
        <div class="absolute inset-0 bg-gradient-to-br {{ $gradientClasses }}"></div>
        <div aria-hidden="true" class="absolute -right-12 -top-12 h-40 w-40 rounded-full border border-white/20 bg-white/10"></div>
        <div aria-hidden="true" class="absolute -bottom-16 -left-10 h-44 w-44 rounded-full bg-black/20 blur-2xl"></div>
        <div class="absolute inset-0 flex items-center justify-center">
            <span class="text-5xl font-black tracking-[-0.08em] text-white/85 drop-shadow-2xl sm:text-6xl">{{ $initials }}</span>
        </div>
    @endif
</div>
