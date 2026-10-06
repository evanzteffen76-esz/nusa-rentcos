import 'package:flutter/material.dart';

/// The web build cannot read a local file, so a staged upload shows a
/// labelled placeholder. Uploading is not supported here either, since a
/// multipart body needs a path the browser does not expose.
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
    return errorBuilder?.call(context, 'Pratinjau tidak tersedia', null) ??
        const ColoredBox(color: Color(0x22000000));
  }
}