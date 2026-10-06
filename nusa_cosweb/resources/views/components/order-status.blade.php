@props(['status'])

@php
    $statusValue = $status instanceof \App\Enums\RentalOrderStatus
        ? $status->value
        : (string) $status;

    $statusClasses = match ($statusValue) {
        'approved' => 'border-emerald-200 bg-emerald-50 text-emerald-700',
        'returned' => 'border-sky-200 bg-sky-50 text-sky-700',
        'completed' => 'border-slate-200 bg-slate-100 text-slate-700',
        'rejected' => 'border-rose-200 bg-rose-50 text-rose-700',
        default => 'border-amber-200 bg-amber-50 text-amber-700',
    };

    $dotClasses = match ($statusValue) {
        'approved' => 'bg-emerald-500',
        'returned' => 'bg-sky-500',
        'completed' => 'bg-slate-500',
        'rejected' => 'bg-rose-500',
        default => 'bg-amber-500',
    };
@endphp

<span {{ $attributes->merge(['class' => "inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-[0.65rem] font-extrabold uppercase tracking-[0.12em] {$statusClasses}"]) }}>
    <span class="h-1.5 w-1.5 rounded-full {{ $dotClasses }}"></span>
    {{ __("owner.orders.{$statusValue}") }}
</span>
