<?php

namespace App\Http\Requests\Owner;

use App\Models\Costume;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Arr;
use Illuminate\Validation\Validator;

class SaveCostumeRequest extends FormRequest
{
    /**
     * The maximum number of gallery images per costume.
     */
    public const MAX_IMAGES = 8;

    /**
     * The maximum number of gallery videos per costume.
     */
    public const MAX_VIDEOS = 2;

    /**
     * The maximum size of a single gallery image in kilobytes.
     */
    public const MAX_IMAGE_SIZE_KB = 5120;

    /**
     * The maximum size of a single gallery video in kilobytes.
     */
    public const MAX_VIDEO_SIZE_KB = 25600;

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $user = $this->user();
        $costume = $this->route('ownerCostume');

        if ($user === null) {
            return false;
        }

        return $costume instanceof Costume
            ? $user->can('update', $costume)
            : $user->can('create', Costume::class);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'character_name' => ['required', 'string', 'max:120'],
            'category' => ['required', 'string', 'max:80'],
            'size' => ['required', 'string', 'max:20'],
            'color' => ['nullable', 'string', 'max:80'],
            'description' => ['nullable', 'string', 'max:1000'],
            'images' => ['nullable', 'array', 'max:'.self::MAX_IMAGES],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:'.self::MAX_IMAGE_SIZE_KB],
            'videos' => ['nullable', 'array', 'max:'.self::MAX_VIDEOS],
            'videos.*' => [
                'mimetypes:video/mp4,video/quicktime,video/webm,video/x-msvideo,video/ogg,video/x-matroska',
                'max:'.self::MAX_VIDEO_SIZE_KB,
            ],
            'price_per_day' => ['required', 'integer', 'min:0', 'max:100000000'],
            'extra_price_per_day' => ['required', 'integer', 'min:0', 'max:100000000'],
            'stock' => ['required', 'integer', 'min:1', 'max:100'],
            'is_published' => ['sometimes', 'boolean'],
        ];
    }

    /**
     * Get the custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'images.max' => __('owner.costume_form.image_limit_error', ['max' => self::MAX_IMAGES]),
            'images.*.image' => __('owner.costume_form.image_invalid'),
            'images.*.mimes' => __('owner.costume_form.image_invalid'),
            'images.*.max' => __('owner.costume_form.image_too_large', ['max' => self::imageSizeMb()]),
            'videos.max' => __('owner.costume_form.video_limit_error', ['max' => self::MAX_VIDEOS]),
            'videos.*.mimetypes' => __('owner.costume_form.video_invalid'),
            'videos.*.max' => __('owner.costume_form.video_too_large', ['max' => self::videoSizeMb()]),
        ];
    }

    /**
     * Keep the saved gallery within the allowed size after removals and uploads.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $costume = $this->route('ownerCostume');

            $this->guardTotal(
                $validator,
                'images',
                self::MAX_IMAGES,
                $costume instanceof Costume ? $costume->images : [],
                Arr::wrap($this->input('remove_images')),
            );

            $this->guardTotal(
                $validator,
                'videos',
                self::MAX_VIDEOS,
                $costume instanceof Costume ? $costume->videos : [],
                Arr::wrap($this->input('remove_videos')),
            );
        });
    }

    /**
     * The maximum gallery image size in megabytes.
     */
    public static function imageSizeMb(): int
    {
        return (int) (self::MAX_IMAGE_SIZE_KB / 1024);
    }

    /**
     * The maximum gallery video size in megabytes.
     */
    public static function videoSizeMb(): int
    {
        return (int) (self::MAX_VIDEO_SIZE_KB / 1024);
    }

    /**
     * Add an error when the resulting gallery is larger than the limit.
     *
     * @param  array<int, mixed>|null  $current
     * @param  array<int, mixed>  $removals
     */
    private function guardTotal(
        Validator $validator,
        string $key,
        int $limit,
        ?array $current,
        array $removals,
    ): void {
        $stored = array_values(array_filter(
            Arr::wrap($current),
            static fn (mixed $path): bool => is_string($path) && filled($path),
        ));

        $flagged = array_values(array_intersect($stored, $removals));
        $total = (count($stored) - count($flagged)) + count(Arr::wrap($this->file($key)));

        if ($total > $limit) {
            $validator->errors()->add(
                $key,
                __("owner.costume_form.{$key}_limit_error", ['max' => $limit]),
            );
        }
    }
}
