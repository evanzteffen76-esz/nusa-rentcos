<?php

namespace App\Actions;

use App\Models\Costume;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Throwable;

class SyncCostumeMedia
{
    /**
     * Store the newly uploaded costume media and drop the files flagged for removal.
     *
     * @param  array<int, UploadedFile>  $uploadedImages
     * @param  array<int, UploadedFile>  $uploadedVideos
     * @param  array<int, string>  $removedImages
     * @param  array<int, string>  $removedVideos
     */
    public function handle(
        Costume $costume,
        array $uploadedImages = [],
        array $uploadedVideos = [],
        array $removedImages = [],
        array $removedVideos = [],
    ): void {
        $added = [];
        $removed = [];

        try {
            $images = $this->sync(
                $costume,
                'images',
                $uploadedImages,
                $removedImages,
                $added,
                $removed,
            );

            $videos = $this->sync(
                $costume,
                'videos',
                $uploadedVideos,
                $removedVideos,
                $added,
                $removed,
            );

            $costume->forceFill([
                'images' => $images,
                'videos' => $videos,
            ])->save();
        } catch (Throwable $exception) {
            $this->deletePaths($added);

            throw $exception;
        }

        $this->deletePaths($removed);
    }

    /**
     * Merge the current paths with the new uploads for a single media type.
     *
     * @param  array<int, UploadedFile>  $uploads
     * @param  array<int, string>  $removals
     * @param  array<int, string>  $added
     * @param  array<int, string>  $removed
     * @return array<int, string>
     */
    private function sync(
        Costume $costume,
        string $type,
        array $uploads,
        array $removals,
        array &$added,
        array &$removed,
    ): array {
        $current = $this->currentPaths($costume, $type);
        $removals = array_values(array_intersect($current, $this->sanitizePaths($removals)));
        $kept = array_values(array_diff($current, $removals));
        $stored = [];

        foreach ($uploads as $upload) {
            if (! $upload instanceof UploadedFile || ! $upload->isValid()) {
                continue;
            }

            $stored[] = $upload->storeAs(
                $costume->mediaDirectory($type),
                $upload->hashName(),
                Costume::MEDIA_DISK,
            );
        }

        $added = array_merge($added, $stored);
        $removed = array_merge($removed, $removals);

        return array_values(array_merge($kept, $stored));
    }

    /**
     * Get the stored paths for a media type.
     *
     * @return array<int, string>
     */
    private function currentPaths(Costume $costume, string $type): array
    {
        return $this->sanitizePaths($costume->{$type} ?? []);
    }

    /**
     * Keep only usable path strings.
     *
     * @param  array<int, mixed>  $paths
     * @return array<int, string>
     */
    private function sanitizePaths(array $paths): array
    {
        return array_values(array_filter(
            $paths,
            static fn (mixed $path): bool => is_string($path) && filled($path),
        ));
    }

    /**
     * Delete the given paths from the media disk.
     *
     * @param  array<int, string>  $paths
     */
    private function deletePaths(array $paths): void
    {
        if ($paths === []) {
            return;
        }

        Storage::disk(Costume::MEDIA_DISK)->delete($paths);
    }
}
