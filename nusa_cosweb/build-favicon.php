<?php

/**
 * One-off brand asset generator.
 *
 * Reads the master PNGs in public/images/icons and produces the derived
 * assets that need resizing or packing:
 *
 *   - public/favicon.ico                  multi-size tab icon (16/32/64/128/256)
 *   - public/apple-touch-icon.png         180x180, opaque (Apple ignores alpha)
 *
 * Run with:  php build-favicon.php
 */

$icons = __DIR__ . '/public/images/icons';

/* -------------------------------------------------------------------------
 | Favicon (.ico) — PNG-compressed entries, supported by every current browser.
 | ---------------------------------------------------------------------- */

// Ordered largest -> smallest; the browser picks the closest match.
$sizes = [256, 128, 64, 32, 16];

$images = [];
foreach ($sizes as $size) {
    $path = sprintf('%s/icon-light-%dx%d.png', $icons, $size, $size);

    if (! is_file($path)) {
        fwrite(STDERR, "Missing source icon: {$path}\n");
        exit(1);
    }

    $images[$size] = file_get_contents($path);
}

$entries = '';
$payload = '';

// ICONDIR: reserved(0), type(1 = icon), image count.
$header = pack('vvv', 0, 1, count($images));
$offset = strlen($header) + (16 * count($images));

foreach ($images as $size => $data) {
    // The dimension is a single byte, so 256 is encoded as 0.
    $dimension = $size >= 256 ? 0 : $size;

    // ICONDIRENTRY: width, height, palette, reserved, planes, bpp, bytes, offset.
    $entries .= pack(
        'CCCCvvVV',
        $dimension,
        $dimension,
        0,   // palette colours (0 = truecolour)
        0,   // reserved
        1,   // colour planes
        32,  // bits per pixel
        strlen($data),
        $offset
    );

    $payload .= $data;
    $offset += strlen($data);
}

$ico = __DIR__ . '/public/favicon.ico';
file_put_contents($ico, $header . $entries . $payload);
printf("Wrote %s (%d bytes, sizes: %s)\n", $ico, filesize($ico), implode(', ', $sizes));

/* -------------------------------------------------------------------------
 | Apple touch icon — 180x180, composited onto an opaque background because
 | iOS fills transparent pixels with black.
 | ---------------------------------------------------------------------- */

$apple = __DIR__ . '/public/apple-touch-icon.png';
$source = imagecreatefrompng($icons . '/icon-light-256x256.png');

if ($source === false) {
    fwrite(STDERR, "Could not read the 256x256 source icon.\n");
    exit(1);
}

$canvas = imagecreatetruecolor(180, 180);

// #0A0A12 — the light-theme background sampled from the source icon.
$background = imagecolorallocate($canvas, 0x0A, 0x0A, 0x12);
imagefilledrectangle($canvas, 0, 0, 180, 180, $background);

imagecopyresampled($canvas, $source, 0, 0, 0, 0, 180, 180, 256, 256);
imagepng($canvas, $apple, 9);

imagedestroy($canvas);
imagedestroy($source);

printf("Wrote %s (%d bytes, 180x180 opaque)\n", $apple, filesize($apple));
