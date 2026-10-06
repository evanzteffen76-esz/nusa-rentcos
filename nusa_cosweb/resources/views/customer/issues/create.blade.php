<x-app-layout>
    <x-slot name="header">
        <a href="{{ route('dashboard') }}" class="inline-flex items-center gap-2 text-sm font-bold text-slate-500 transition hover:text-violet-700">
            <span aria-hidden="true">←</span>
            {{ __('customer.dashboard.recent_orders') }}
        </a>
        <div class="mt-3 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
                <p class="text-xs font-extrabold uppercase tracking-[0.2em] text-rose-600">{{ __('owner.issues.issue_type_lost') }}</p>
                <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-950">{{ __('customer.issues.lost_title') }}</h2>
                <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">{{ __('customer.issues.lost_description') }}</p>
            </div>
            <span class="rounded-full bg-rose-100 px-3 py-1.5 text-xs font-extrabold text-rose-700">#{{ str_pad((string) $customerRentalOrder->id, 5, '0', STR_PAD_LEFT) }}</span>
        </div>
    </x-slot>

    <div class="bg-slate-100 py-8 sm:py-10">
        <div class="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            @if ($errors->any())
                <div class="mb-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-bold text-rose-700" role="alert">
                    {{ $errors->first() }}
                </div>
            @endif

            <div class="mb-6 rounded-3xl border border-rose-200 bg-rose-50 p-5 sm:p-6">
                <div class="flex items-start gap-4">
                    <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-700">
                        <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true"><path d="M12 4.25v7.1l4.25 2.5M19.25 12a7.25 7.25 0 1 1-14.5 0 7.25 7.25 0 0 1 14.5 0Z" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
                    </span>
                    <div>
                        <h3 class="font-extrabold text-rose-900">{{ __('customer.issues.replacement_required') }}</h3>
                        <p class="mt-1 text-sm leading-6 text-rose-700">{{ __('customer.issues.proof_hint') }}</p>
                    </div>
                </div>
            </div>

            <form method="POST" action="{{ route('dashboard.orders.loss-report.store', $customerRentalOrder) }}" enctype="multipart/form-data" class="space-y-6">
                @csrf
                <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-8">
                    <h3 class="text-lg font-extrabold tracking-tight text-slate-950">{{ $customerRentalOrder->costume->name }}</h3>
                    <p class="mt-1 text-sm text-slate-500">{{ $customerRentalOrder->costume->character_name }}</p>

                    <div class="mt-6">
                        <label for="description" class="text-sm font-extrabold text-slate-800">{{ __('customer.issues.description') }}</label>
                        <textarea id="description" name="description" rows="6" required maxlength="1000" placeholder="{{ __('customer.issues.description_placeholder') }}" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-rose-500 focus:ring-rose-500">{{ old('description') }}</textarea>
                        <x-input-error :messages="$errors->get('description')" class="mt-2" />
                    </div>

                    <div class="mt-6 grid gap-6 sm:grid-cols-2">
                        <div>
                            <label for="replacement_cost" class="text-sm font-extrabold text-slate-800">{{ __('customer.issues.replacement_cost') }}</label>
                            <div class="relative mt-2">
                                <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-sm font-bold text-slate-500">Rp</span>
                                <input id="replacement_cost" name="replacement_cost" type="number" min="1" max="100000000" step="1000" required value="{{ old('replacement_cost') }}" class="block w-full rounded-2xl border-slate-200 py-3 pl-11 pr-4 text-sm shadow-sm focus:border-rose-500 focus:ring-rose-500">
                            </div>
                            <x-input-error :messages="$errors->get('replacement_cost')" class="mt-2" />
                        </div>
                        <div>
                            <label for="replacement_proof" class="text-sm font-extrabold text-slate-800">{{ __('customer.issues.replacement_proof') }}</label>
                            <input id="replacement_proof" name="replacement_proof" type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" required class="mt-2 block w-full rounded-2xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm file:mr-3 file:rounded-full file:border-0 file:bg-rose-100 file:px-3 file:py-1.5 file:text-xs file:font-extrabold file:text-rose-700 hover:file:bg-rose-200 focus:border-rose-500 focus:ring-rose-500">
                            <x-input-error :messages="$errors->get('replacement_proof')" class="mt-2" />
                        </div>
                    </div>
                </section>

                <div class="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                    <a href="{{ route('dashboard') }}" class="inline-flex items-center justify-center rounded-full border border-slate-200 bg-white px-5 py-3 text-sm font-extrabold text-slate-700 transition hover:bg-slate-50">{{ __('common.cancel') }}</a>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-full bg-rose-600 px-5 py-3 text-sm font-extrabold text-white transition hover:bg-rose-700">
                        {{ __('customer.issues.submit') }}
                        <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="M3.75 10h12.5M11 4.75 16.25 10 11 15.25" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                    </button>
                </div>
            </form>
        </div>
    </div>
</x-app-layout>
