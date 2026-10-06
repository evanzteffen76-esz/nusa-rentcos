<?php

namespace App\Http\Requests\Api\V1;

use App\Http\Requests\Owner\SaveCostumeRequest as WebSaveCostumeRequest;
use App\Models\Costume;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Arr;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * Validate a costume listing written by the mobile client.
 *
 * The scalar rules mirror the web form and the gallery rules are reused from
 * it, so an upload accepted by one surface is accepted by the other. Unlike
 * the web request the route parameter differs per role (`ownerCostume` for an
 * owner, `costume` for an administrator), so the target is resolved from
 * whichever one is present.
 */
class SaveCostumeRequest extends FormRequest
{
    /**
     * The maximum number of gallery images per costume.
     */
    public const MAX_IMAGES = WebSaveCostumeRequest::MAX_IMAGES;

    /**
     * The maximum number of gallery videos per costume.
     */
    public const MAX_VIDEOS = WebSaveCostumeRequest::MAX_VIDEOS;

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $user = $this->user();

        if ($user === null) {
            return false;
        }

        return $this->costume() instanceof Costume
            ? $user->can('update', $this->costume())
            : $user->can('create', Costume::class) || $user->isAdmin();
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            // Only an administrator may reassign a listing; the value is read
            // separately by the controller and ignored on an owner request.
            'owner_id' => ['sometimes', 'nullable', 'integer', Rule::exists('users', 'id')],
            'name' => ['required', 'string', 'max:120'],
            'character_name' => ['required', 'string', 'max:120'],
            'category' => ['required', 'string', 'max:80'],
            'size' => ['required', 'string', 'max:20'],
            'color' => ['nullable', 'string', 'max:80'],
            'description' => ['nullable', 'string', 'max:1000'],
            'image_url' => ['nullable', 'url:http,https', 'max:2048'],
            'images' => ['nullable', 'array', 'max:'.self::MAX_IMAGES],
            'images.*' => [
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:'.WebSaveCostumeRequest::MAX_IMAGE_SIZE_KB,
            ],
            'videos' => ['nullable', 'array', 'max:'.self::MAX_VIDEOS],
            'videos.*' => [
                'mimetypes:video/mp4,video/quicktime,video/webm,video/x-msvideo,video/ogg,video/x-matroska',
                'max:'.WebSaveCostumeRequest::MAX_VIDEO_SIZE_KB,
            ],
            // Stored paths of media the client wants dropped. Only paths the
            // costume actually holds are honoured, so a crafted request cannot
            // delete an unrelated file.
            'remove_images' => ['nullable', 'array'],
            'remove_images.*' => ['string'],
            'remove_videos' => ['nullable', 'array'],
            'remove_videos.*' => ['string'],
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
            'images.*.max' => __('owner.costume_form.image_too_large', ['max' => WebSaveCostumeRequest::imageSizeMb()]),
            'videos.max' => __('owner.costume_form.video_limit_error', ['max' => self::MAX_VIDEOS]),
            'videos.*.mimetypes' => __('owner.costume_form.video_invalid'),
            'videos.*.max' => __('owner.costume_form.video_too_large', ['max' => WebSaveCostumeRequest::videoSizeMb()]),
        ];
    }

    /**
     * Normalize boolean-shaped input before validation.
     *
     * A multipart body has no types, so a client may send `true`, `false`,
     * `on`, `yes` or a number. Laravel's `boolean` rule only understands the
     * last two, which would reject a perfectly reasonable upload with a
     * confusing message about the publication flag.
     */
    protected function prepareForValidation(): void
    {
        $published = $this->input('is_published');

        if ($published === null || is_bool($published)) {
            return;
        }

        $this->merge([
            'is_published' => filter_var(
                $published,
                FILTER_VALIDATE_BOOL,
                FILTER_NULL_ON_FAILURE,
            ),
        ]);
    }
    /**
     * Keep the saved gallery within the allowed size after removals and uploads.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $costume = $this->costume();
            $current = $costume instanceof Costume;

            $this->guardTotal(
                $validator,
                'images',
                self::MAX_IMAGES,
                $current ? $costume->images : [],
                Arr::wrap($this->input('remove_images')),
            );

            $this->guardTotal(
                $validator,
                'videos',
                self::MAX_VIDEOS,
                $current ? $costume->videos : [],
                Arr::wrap($this->input('remove_videos')),
            );
        });
    }

    /**
     * Resolve the costume this request targets, if any.
     */
    public function costume(): ?Costume
    {
        $route = $this->route();

        if ($route === null) {
            return null;
        }

        foreach (['ownerCostume', 'costume'] as $key) {
            $value = $route->parameter($key);

            if ($value instanceof Costume) {
                return $value;
            }
        }

        return null;
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

        $flagged = array_values(array_intersect($stored, array_filter($removals, 'is_string')));
        $total = (count($stored) - count($flagged)) + count(Arr::wrap($this->file($key)));

        if ($total > $limit) {
            $validator->errors()->add(
                $key,
                __("owner.costume_form.{$key}_limit_error", ['max' => $limit]),
            );
        }
    }
}