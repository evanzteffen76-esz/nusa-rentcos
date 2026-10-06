<x-app-layout>
    <x-slot name="header">
        <a href="{{ route('cosrent-owner.costumes.index') }}" class="inline-flex items-center gap-2 text-sm font-bold text-slate-500 transition hover:text-violet-700">
            <span aria-hidden="true">←</span>
            {{ __('owner.costumes.title') }}
        </a>
        <h2 class="mt-3 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('owner.costume_form.edit_title') }}</h2>
        <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">{{ __('owner.costume_form.edit_description') }}</p>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            @include('owner.costumes._form', [
                'ownerCostume' => $ownerCostume,
                'submitRoute' => route('cosrent-owner.costumes.update', $ownerCostume),
                'method' => 'PATCH',
            ])
        </div>
    </div>
</x-app-layout>
