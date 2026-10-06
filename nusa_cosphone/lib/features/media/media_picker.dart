import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/cosrent_repository.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';

/// A media file the user picked but has not uploaded yet.
class PendingMedia {
  const PendingMedia({required this.path, required this.isVideo});

  factory PendingMedia.fromPath(String path) => PendingMedia(
    path: path,
    isVideo: _videoExtensions.contains(_extensionOf(path)),
  );

  final String path;
  final bool isVideo;

  String get fileName => path.split(RegExp(r'[/\\]')).last;

  static String _extensionOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    if (!name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  static const Set<String> _videoExtensions = <String>{
    'mp4',
    'mov',
    'webm',
    'avi',
    'ogg',
    'mkv',
  };

  /// Whether the server would accept this file, checked locally so the user
  /// is not made to wait for a round trip to learn the file is the wrong type.
  bool get isAcceptableType =>
      isVideo || _imageExtensions.contains(_extensionOf(path));

  static const Set<String> _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
  };
}

/// Pick gallery media, enforcing the server's limits before the upload.
///
/// The limits mirror `App\Http\Requests\Api\V1\SaveCostumeRequest`, so a form
/// that passes validation here is not rejected after a long upload.
class GalleryPicker {
  const GalleryPicker._();

  /// Returns the newly picked paths, or `null` when the user cancelled.
  ///
  /// [error] is filled with a user-facing reason when a pick fails or a limit
  /// would be exceeded.
  static Future<GalleryPickResult?> pick({
    required bool images,
    required int imageCount,
    required int videoCount,
    required int removedImageCount,
    required int removedVideoCount,
  }) async {
    final limit = images
        ? CosrentRepository.maxGalleryImages
        : CosrentRepository.maxGalleryVideos;
    final existing = images
        ? imageCount - removedImageCount
        : videoCount - removedVideoCount;
    final room = limit - existing;

    if (room <= 0) {
      return GalleryPickResult(
        paths: const <String>[],
        error: images
            ? 'Maksimal $limit foto per kostum. Hapus salah satu dulu.'
            : 'Maksimal $limit video per kostum. Hapus salah satu dulu.',
      );
    }

    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: images
            ? const ['jpg', 'jpeg', 'png', 'webp']
            : const ['mp4', 'mov', 'webm', 'avi', 'ogg', 'mkv'],
      );
    } on Object {
      return const GalleryPickResult(
        paths: <String>[],
        error: 'Gagal membuka pemilih berkas di perangkat ini.',
      );
    }

    if (picked.isEmpty) return null;

    final paths = <String>[];
    final oversize = <String>[];
    final wrongType = <String>[];
    var noPath = 0;

    for (final file in picked) {
      // A pick that yields no local path (a web blob, for example) cannot be
      // streamed as a multipart body, so it is reported rather than dropped.
      final path = file.path;
      if (path == null) {
        noPath++;
        continue;
      }
      final pending = PendingMedia.fromPath(path);
      if (!pending.isAcceptableType) {
        wrongType.add(pending.fileName);
        continue;
      }
      final maxSize = pending.isVideo
          ? CosrentRepository.maxVideoBytes
          : CosrentRepository.maxImageBytes;
      final size = file.lengthSync();
      if (size != null && size > maxSize) {
        oversize.add(pending.fileName);
        continue;
      }
      paths.add(path);
    }

    if (paths.length > room) {
      return GalleryPickResult(
        paths: paths.take(room).toList(),
        error:
            'Hanya $room slot tersisa, jadi ${paths.length - room} berkas '
            'diabaikan.',
      );
    }

    if (paths.isEmpty) {
      final String reason;
      if (noPath > 0) {
        reason =
            'Pilihan berkas tidak punya jalur lokal, jadi tidak bisa diunggah '
            'dari perangkat ini.';
      } else if (wrongType.isNotEmpty) {
        reason = 'Format tidak didukung: ${wrongType.take(3).join(', ')}.';
      } else if (oversize.isNotEmpty) {
        reason = 'Berkas terlalu besar: ${oversize.take(3).join(', ')}.';
      } else {
        reason = 'Berkas tidak dapat dibaca.';
      }
      return GalleryPickResult(paths: const <String>[], error: reason);
    }

    return GalleryPickResult(paths: paths);
  }
}

class GalleryPickResult {
  const GalleryPickResult({required this.paths, this.error});

  final List<String> paths;
  final String? error;
}

/// Full-screen gallery for a costume's photos and clips.
///
/// Videos get a play affordance rather than an inline player: bundling a media
/// player for at most two short clips per listing is not worth the binary size,
/// and the clip is still reachable in a browser from the listing.
class MediaGalleryViewer extends StatefulWidget {
  const MediaGalleryViewer({
    super.key,
    required this.costume,
    this.initialIndex = 0,
  });

  final Costume costume;
  final int initialIndex;

  @override
  State<MediaGalleryViewer> createState() => _MediaGalleryViewerState();
}

class _MediaGalleryViewerState extends State<MediaGalleryViewer> {
  late final PageController _controller;
  late int _index;

  List<String> get _images => widget.costume.imageUrls;
  List<String> get _videos => widget.costume.videoUrls;

  /// Images first, then clips, so the numbering matches [Costume.galleryUrls].
  List<String> get _all => <String>[..._images, ..._videos];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _all.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _all;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${items.length}'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada media.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: items.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      final url = items[index];
                      final isVideo = index >= _images.length;
                      return InteractiveViewer(
                        minScale: 0.7,
                        maxScale: 5,
                        child: Center(
                          child: isVideo
                              ? _VideoTile(url: url)
                              : Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  // A dead media URL must leave a placeholder
                                  // rather than a red error box or a crash.
                                  errorBuilder: (context, error, stack) =>
                                      const _MediaFallback(
                                        icon: Icons.broken_image_outlined,
                                        label: 'Gambar tidak tersedia',
                                      ),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26, top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _index ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The poster falls back to the placeholder when the clip cannot be
        // decoded as an image, which is the normal case for a video URL.
        Image.network(
          url,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              size: 74,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Klip video',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 46, color: Colors.white38),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

/// A gallery strip shown under a costume's cover image.
class CostumeGalleryStrip extends StatelessWidget {
  const CostumeGalleryStrip({
    super.key,
    required this.costume,
    this.onOpen,
  });

  final Costume costume;

  /// Called with the tapped index. When null the viewer is pushed instead.
  final void Function(int index)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (!costume.hasGallery) return const SizedBox.shrink();

    final images = costume.imageUrls;
    final videos = costume.videoUrls;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A plain Row rather than `SectionTitle`: that widget wraps its label
        // in an `Expanded`, which asserts when the surrounding Row is
        // unbounded, as it is inside a sliver list.
        Row(
          children: [
            Expanded(
              child: Text(
                'Galeri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (videos.isNotEmpty)
              Text(
                '${images.length} foto · ${videos.length} video',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isVideo = index >= images.length;
              final url = isVideo
                  ? videos[index - images.length]
                  : images[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (onOpen != null) {
                    onOpen!(index);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MediaGalleryViewer(
                        costume: costume,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: AppColors.muted.withValues(alpha: 0.25),
                            child: Icon(
                              isVideo
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.image_not_supported_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isVideo)
                          const Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white70,
                              size: 26,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}