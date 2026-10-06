@use('App\Http\Requests\Owner\SaveCostumeRequest')
@use('App\Models\Costume')

@php
    $editing = isset($ownerCostume);
    $costume = $ownerCostume ?? new Costume;
@endphp

<form method="POST" action="{{ $submitRoute }}" enctype="multipart/form-data" class="space-y-8">
    @csrf
    @if ($method !== 'POST')
        @method($method)
    @endif

    <div class="grid gap-8 xl:grid-cols-[minmax(0,1.35fr)_minmax(300px,0.65fr)]">
        <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5 sm:p-8">
            <div class="grid gap-6 sm:grid-cols-2">
                <div class="sm:col-span-2">
                    <label for="name" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.name') }}</label>
                    <input id="name" name="name" type="text" value="{{ old('name', $costume->name) }}" required maxlength="120" autocomplete="off" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    <x-input-error :messages="$errors->get('name')" class="mt-2" />
                </div>

                <div>
                    <label for="character_name" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.character') }}</label>
                    <input id="character_name" name="character_name" type="text" value="{{ old('character_name', $costume->character_name) }}" required maxlength="120" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    <x-input-error :messages="$errors->get('character_name')" class="mt-2" />
                </div>

                <div>
                    <label for="category" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.category') }}</label>
                    <input id="category" name="category" type="text" value="{{ old('category', $costume->category) }}" required maxlength="80" list="costume-categories" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    <datalist id="costume-categories">
                        <option value="Fantasy"></option>
                        <option value="Heroic"></option>
                        <option value="Modern"></option>
                        <option value="Anime"></option>
                    </datalist>
                    <x-input-error :messages="$errors->get('category')" class="mt-2" />
                </div>

                <div>
                    <label for="size" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.size') }}</label>
                    <input id="size" name="size" type="text" value="{{ old('size', $costume->size) }}" required maxlength="20" placeholder="M / XL" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    <x-input-error :messages="$errors->get('size')" class="mt-2" />
                </div>

                <div>
                    <label for="price_per_day" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.price') }}</label>
                    <div class="relative mt-2">
                        <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-sm font-bold text-slate-500">Rp</span>
                        <input id="price_per_day" name="price_per_day" type="number" value="{{ old('price_per_day', $costume->price_per_day) }}" required min="0" max="100000000" step="1000" class="block w-full rounded-2xl border-slate-200 py-3 pl-11 pr-4 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    </div>
                    <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('owner.costume_form.price_hint') }}</p>
                    <x-input-error :messages="$errors->get('price_per_day')" class="mt-2" />
                </div>

                <div>
                    <label for="extra_price_per_day" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.extra_price') }}</label>
                    <div class="relative mt-2">
                        <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-sm font-bold text-slate-500">Rp</span>
                        <input id="extra_price_per_day" name="extra_price_per_day" type="number" value="{{ old('extra_price_per_day', $costume->extra_price_per_day) }}" required min="0" max="100000000" step="1000" class="block w-full rounded-2xl border-slate-200 py-3 pl-11 pr-4 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                    </div>
                    <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('owner.costume_form.extra_price_hint', ['days' => \App\Models\RentalOrder::INCLUDED_RENTAL_DAYS]) }}</p>
                    <x-input-error :messages="$errors->get('extra_price_per_day')" class="mt-2" />
                </div>

                <div class="sm:col-span-2">
                    <label for="description" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.description') }}</label>
                    <textarea id="description" name="description" rows="5" maxlength="1000" placeholder="{{ __('owner.costume_form.description_placeholder') }}" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">{{ old('description', $costume->description) }}</textarea>
                    <x-input-error :messages="$errors->get('description')" class="mt-2" />
                </div>

                <div class="sm:col-span-2 space-y-6 rounded-3xl border border-slate-200 bg-slate-50/70 p-5 sm:p-6">
                    @include('owner.costumes._media_picker', [
                        'type' => 'images',
                        'kind' => 'image',
                        'label' => __('owner.costume_form.images'),
                        'hint' => __('owner.costume_form.images_hint', ['max' => SaveCostumeRequest::MAX_IMAGES]),
                        'max' => SaveCostumeRequest::MAX_IMAGES,
                        'maxSizeMb' => SaveCostumeRequest::imageSizeMb(),
                        'existing' => $costume->images ?? [],
                    ])

                    <div class="border-t border-slate-200 pt-6">
                        @include('owner.costumes._media_picker', [
                            'type' => 'videos',
                            'kind' => 'video',
                            'label' => __('owner.costume_form.videos'),
                            'hint' => __('owner.costume_form.videos_hint', ['max' => SaveCostumeRequest::MAX_VIDEOS]),
                            'max' => SaveCostumeRequest::MAX_VIDEOS,
                            'maxSizeMb' => SaveCostumeRequest::videoSizeMb(),
                            'existing' => $costume->videos ?? [],
                        ])
                    </div>
                </div>
            </div>
        </section>

        <aside class="space-y-5">
            <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5">
                <label for="stock" class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.stock') }}</label>
                <input id="stock" name="stock" type="number" value="{{ old('stock', $costume->stock ?? 1) }}" required min="1" max="100" class="mt-2 block w-full rounded-2xl border-slate-200 px-4 py-3 text-sm shadow-sm focus:border-violet-500 focus:ring-violet-500">
                <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('owner.costume_form.stock_hint') }}</p>
                <x-input-error :messages="$errors->get('stock')" class="mt-2" />
            </section>

            <section class="rounded-[2rem] border border-white/80 bg-white p-6 shadow-xl shadow-slate-950/5">
                <p class="text-sm font-extrabold text-slate-800">{{ __('owner.costume_form.publication') }}</p>
                <p class="mt-2 text-xs leading-5 text-slate-500">{{ __('owner.costume_form.publication_hint') }}</p>
                <label class="mt-5 flex cursor-pointer items-center justify-between gap-4 rounded-2xl bg-slate-50 p-4">
                    <span class="text-sm font-bold text-slate-700">{{ $costume->is_published || old('is_published') ? __('owner.costumes.published') : __('owner.costumes.unpublished') }}</span>
                    <span class="relative inline-flex h-6 w-11 shrink-0 rounded-full transition {{ ($costume->is_published || old('is_published')) ? 'bg-violet-600' : 'bg-slate-300' }}">
                        <input type="checkbox" name="is_published" value="1" @checked(old('is_published', $costume->is_published)) class="peer sr-only">
                        <span class="absolute left-1 top-1 h-4 w-4 rounded-full bg-white shadow transition peer-checked:translate-x-5"></span>
                    </span>
                </label>
                <x-input-error :messages="$errors->get('is_published')" class="mt-2" />
            </section>

            <div class="rounded-[2rem] bg-slate-950 p-6 text-white shadow-xl shadow-slate-950/15">
                <button type="submit" class="inline-flex w-full items-center justify-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-extrabold text-slate-950 transition hover:bg-violet-100">
                    {{ __('owner.costume_form.save') }}
                    <svg viewBox="0 0 20 20" fill="none" class="h-4 w-4" aria-hidden="true"><path d="m4 10 4 4 8-8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
                </button>
                <a href="{{ route('cosrent-owner.costumes.index') }}" class="mt-3 inline-flex w-full items-center justify-center rounded-full border border-white/15 px-5 py-3 text-sm font-extrabold text-white/75 transition hover:bg-white/10 hover:text-white">
                    {{ __('common.cancel') }}
                </a>
            </div>
        </aside>
    </div>
</form>
