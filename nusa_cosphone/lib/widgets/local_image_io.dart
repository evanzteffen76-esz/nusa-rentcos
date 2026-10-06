import 'dart:io';

import 'package:flutter/material.dart';

/// A square thumbnail of a file already on disk.
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    // A path that no longer resolves (a cache the OS reclaimed, a file the
    // user deleted) must render the fallback, not throw inside the image
    // decoder.
    if (!file.existsSync()) {
      return errorBuilder?.call(context, 'File tidak ditemukan', null) ??
          const SizedBox.shrink();
    }
    return Image.file(
      file,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder:
          errorBuilder ??
          (context, error, stack) => const SizedBox.shrink(),
    );
  }
}