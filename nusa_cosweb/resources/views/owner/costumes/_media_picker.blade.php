@use('App\Models\Costume')

@php
    /**
     * @var string $type      Field name suffix: "images" or "videos".
     * @var string $kind      Media kind used for client-side checks: "image" or "video".
     * @var string $label     Section label.
     * @var string $hint      Helper text under the label.
     * @var int    $max       Maximum number of files.
     * @var int    $maxSizeMb Maximum size of a single file in megabytes.
     * @var array<int, string> $existing Stored media paths.
     */
    $picker = [
        'maxFiles' => $max,
        'maxSizeMb' => $maxSizeMb,
        'kind' => $kind,
        'initialCount' => count($existing),
        'labels' => [
            'remaining' => __('owner.costume_form.remaining_count', ['count' => ':count']),
            'remove' => __('owner.costume_form.remove_media'),
            'limitReached' => __('owner.costume_form.limit_reached', ['max' => $max]),
            'tooLarge' => __('owner.costume_form.file_too_large'),
            'invalidType' => __('owner.costume_form.file_invalid_type'),
        ],
    ];

    $accept = $kind === 'video'
        ? 'video/mp4,video/quicktime,video/webm,video/x-msvideo'
        : 'image/jpeg,image/png,image/webp';

    $mediaErrors = collect($errors->getBag('default')->getMessages())
        ->filter(fn (array $messages, string $key): bool => $key === $type || str_starts_with($key, $type.'.'))
        ->flatten()
        ->values()
        ->all();
@endphp

<div class="space-y-4" x-data="mediaPicker(@js($picker))">
    <div class="flex items-start justify-between gap-3">
        <div>
            <p class="text-sm font-extrabold text-slate-800">{{ $label }}</p>
            <p class="mt-1 text-xs leading-5 text-slate-500" id="{{ $type }}-hint">{{ $hint }}</p>
        </div>
        <span class="shrink-0 rounded-full bg-violet-100 px-3 py-1 text-xs font-extrabold text-violet-700" x-text="`${total}/${maxFiles}`"></span>
    </div>

    @if ($existing !== [])
        <div class="rounded-2xl border border-slate-200 bg-white p-4">
            <div class="flex flex-wrap items-center justify-between gap-2">
                <p class="text-xs font-extrabold uppercase tracking-wider text-slate-500">{{ __('owner.costume_form.saved_media') }}</p>
                <p class="text-[0.68rem] leading-4 text-slate-400">{{ __('owner.costume_form.remove_media_hint') }}</p>
            </div>

            <div class="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-4">
                @foreach ($existing as $path)
                    <label class="group relative block cursor-pointer overflow-hidden rounded-2xl border border-slate-200 bg-slate-50 has-[:checked]:border-rose-400 has-[:checked]:ring-2 has-[:checked]:ring-rose-200">
                        @if ($kind === 'image')
                            <img src="{{ Costume::mediaUrl($path) }}" alt="{{ $label }}" class="h-24 w-full object-cover" loading="lazy">
                        @else
                            <video src="{{ Costume::mediaUrl($path) }}" class="h-24 w-full bg-slate-950 object-cover" muted playsinline></video>
                        @endif

                        <input type="checkbox" name="remove_{{ $type }}[]" value="{{ $path }}" class="peer sr-only">
                        <span class="absolute inset-x-0 bottom-0 flex items-center justify-center gap-1.5 bg-slate-950/85 px-2 py-1.5 text-[0.65rem] font-extrabold text-white opacity-0 transition group-hover:opacity-100 peer-checked:opacity-100">
                            <svg viewBox="0 0 24 24" fill="none" class="h-3.5 w-3.5" aria-hidden="true">
                                <path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                            </svg>
                            {{ __('owner.costume_form.remove_media') }}
                        </span>
                    </label>
                @endforeach
            </div>
        </div>
    @endif

    <button
        type="button"
        x-on:click="open"
        x-on:dragover.prevent="dragging = true"
        x-on:dragleave.prevent="dragging = false"
        x-on:drop.prevent="drop($event)"
        aria-describedby="{{ $type }}-hint"
        class="flex w-full flex-col items-center justify-center rounded-2xl border-2 border-dashed px-5 py-7 text-center transition"
        x-bind:class="{
            'border-violet-400 bg-violet-50': dragging,
            'border-slate-300 bg-slate-50 hover:border-violet-300': ! dragging && ! isFull,
            'border-slate-200 bg-slate-50 opacity-60': isFull,
        }"
    >
        <span class="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-100 text-violet-700">
            @if ($kind === 'video')
                <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                    <path d="M3.5 6.5h17v11h-17v-11Zm4 0v11m9-11v11m-13-5.5h17" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
            @else
                <svg viewBox="0 0 24 24" fill="none" class="h-5 w-5" aria-hidden="true">
                    <path d="M4 6.75h16v10.5H4V6.75Zm.75.75L12 13l7.25-5.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
            @endif
        </span>

        <span class="mt-3 text-sm font-bold text-slate-700">{{ __('owner.costume_form.drop_hint') }}</span>
        <span class="mt-1 text-xs font-semibold text-slate-500" x-show="! isFull" x-text="labels.remaining.replace(':count', String(remaining))"></span>
        <span class="mt-1 text-xs font-bold text-amber-700" x-show="isFull" x-text="labels.limitReached"></span>
    </button>

    <input
        x-ref="input"
        type="file"
        name="{{ $type }}[]"
        multiple
        accept="{{ $accept }}"
        class="sr-only"
        x-on:change="add($event.target.files)"
    >

    <p x-show="notice" x-text="notice" class="text-xs font-bold text-amber-700" role="status"></p>

    <div class="grid grid-cols-2 gap-3 sm:grid-cols-4" x-show="hasFiles" x-cloak>
        <template x-for="(file, index) in files" x-bind:key="file.name + index">
            <div class="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white">
                <template x-if="kind === 'image'">
                    <img x-bind:src="file.url" x-bind:alt="file.name" class="h-24 w-full object-cover">
                </template>
                <template x-if="kind !== 'image'">
                    <video x-bind:src="file.url" class="h-24 w-full bg-slate-950 object-cover" muted playsinline></video>
                </template>

                <button
                    type="button"
                    x-on:click="remove(index)"
                    class="absolute right-1.5 top-1.5 inline-flex h-6 w-6 items-center justify-center rounded-full bg-slate-950/80 text-white transition hover:bg-rose-600"
                    x-bind:aria-label="labels.remove"
                >
                    <svg viewBox="0 0 24 24" fill="none" class="h-3.5 w-3.5" aria-hidden="true">
                        <path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </button>

                <p class="truncate px-2 pt-2 text-[0.65rem] font-bold text-slate-600" x-text="file.name"></p>
                <p class="px-2 pb-2 text-[0.6rem] text-slate-400" x-text="file.size"></p>
            </div>
        </template>
    </div>

    <x-input-error :messages="$mediaErrors" class="mt-2" />
</div>
