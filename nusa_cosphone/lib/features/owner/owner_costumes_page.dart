import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/cosrent_repository.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/local_image.dart';
import '../media/media_picker.dart';

/// What the costume form hands back to the page that opened it.
///
/// A gallery is never part of the model: the stored paths live on the server,
/// so an edit carries the new uploads and the removals alongside the fields.
class CostumeFormResult {
  const CostumeFormResult({
    required this.costume,
    this.newImagePaths = const <String>[],
    this.newVideoPaths = const <String>[],
    this.removedImageUrls = const <String>[],
    this.removedVideoUrls = const <String>[],
  });

  final Costume costume;
  final List<String> newImagePaths;
  final List<String> newVideoPaths;
  final List<String> removedImageUrls;
  final List<String> removedVideoUrls;

  bool get hasMediaChanges =>
      newImagePaths.isNotEmpty ||
      newVideoPaths.isNotEmpty ||
      removedImageUrls.isNotEmpty ||
      removedVideoUrls.isNotEmpty;
}

class OwnerCostumesPage extends StatefulWidget {
  const OwnerCostumesPage({
    super.key,
    required this.user,
    this.adminScope = false,
  });

  final AppUser user;

  /// When true the page lists every listing and can reassign one to a
  /// different owner, which is what the administration console needs.
  final bool adminScope;

  @override
  State<OwnerCostumesPage> createState() => _OwnerCostumesPageState();
}

class _OwnerCostumesPageState extends State<OwnerCostumesPage> {
  final _search = TextEditingController();
  String _filter = 'all';
  late Future<List<Costume>> _future;

  /// Owners an administrator may assign a listing to. Empty for an owner,
  /// who can only ever own their own listings.
  List<AppUser> owners = const <AppUser>[];

  @override
  void initState() {
    super.initState();
    _future = _load();
    if (widget.adminScope) _loadOwners();
  }

  Future<void> _loadOwners() async {
    try {
      final users = await AppState.of(
        context,
      ).repository.getUsers();
      final owners = users.where((user) => user.isOwner).toList();
      if (!mounted) return;
      setState(() => this.owners = owners);
    } on Object {
      // A failed lookup only costs the admin the owner picker; the page still
      // works, it just cannot reassign a listing.
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Costume>> _load() async {
    final page = await AppState.of(context).repository
        .getCostumes(search: _search.text);
    if (_filter == 'all') return page.items;
    return page.items
        .where(
          (item) =>
              _filter == 'available' ? item.isAvailable : !item.isAvailable,
        )
        .toList();
  }

  Future<void> _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _openForm([Costume? costume]) async {
    final result = await showModalBottomSheet<CostumeFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CostumeFormSheet(
        costume: costume,
        ownerId: widget.user.id,
        allowOwnerChange: widget.adminScope,
        owners: widget.adminScope ? owners : const <AppUser>[],
      ),
    );
    if (result == null || !mounted) return;
    final repository = AppState.of(context).repository;
    try {
      if (costume == null) {
        await repository.createCostume(
          result.costume,
          imagePaths: result.newImagePaths,
          videoPaths: result.newVideoPaths,
        );
        if (!mounted) return;
        showAppSnack(context, 'Kostum baru berhasil ditambahkan.');
      } else {
        await repository.updateCostume(
          result.costume,
          imagePaths: result.newImagePaths,
          videoPaths: result.newVideoPaths,
          removeImageUrls: result.removedImageUrls,
          removeVideoUrls: result.removedVideoUrls,
        );
        if (!mounted) return;
        showAppSnack(context, 'Perubahan kostum berhasil disimpan.');
      }
      _reload();
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Gagal menyimpan kostum: $error', isError: true);
      }
    }
  }

  Future<void> _delete(Costume costume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${costume.name}?'),
        content: const Text(
          'Kostum yang sudah memiliki pesanan tidak bisa dihapus, tetapi dapat dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppState.of(context).repository.deleteCostume(costume.id);
      if (mounted) {
        showAppSnack(context, 'Kostum berhasil dihapus.');
        _reload();
      }
    } catch (error) {
      if (mounted) showAppSnack(context, '$error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: PageIntro(
                        eyebrow: 'Katalog rental',
                        title: 'Kelola kostum',
                        subtitle:
                            'Atur koleksi, harga, dan ketersediaan kostum.',
                      ),
                    ),
                    SoftIcon(
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.secondary,
                      size: 50,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    hintText: 'Cari kostum',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Filter(
                      label: 'Semua',
                      selected: _filter == 'all',
                      onTap: () {
                        _filter = 'all';
                        _reload();
                      },
                    ),
                    const SizedBox(width: 8),
                    _Filter(
                      label: 'Tersedia',
                      selected: _filter == 'available',
                      onTap: () {
                        _filter = 'available';
                        _reload();
                      },
                    ),
                    const SizedBox(width: 8),
                    _Filter(
                      label: 'Nonaktif',
                      selected: _filter == 'unavailable',
                      onTap: () {
                        _filter = 'unavailable';
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Costume>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ScrollableRefreshable(child: LoadingView());
                }
                if (snapshot.hasError) {
                  return ScrollableRefreshable(
                    child: EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Gagal memuat kostum',
                      message: '${snapshot.error}',
                      actionLabel: 'Coba lagi',
                      onAction: _reload,
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return ScrollableRefreshable(
                    child: EmptyState(
                      icon: Icons.checkroom_outlined,
                      title: 'Katalog masih kosong',
                      message: 'Tambahkan kostum pertama untuk mulai menerima booking.',
                      actionLabel: 'Tambah kostum',
                      onAction: _openForm,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ManageCostumeCard(
                      costume: items[index],
                      onEdit: () => _openForm(items[index]),
                      onDelete: () => _delete(items[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah kostum'),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _ManageCostumeCard extends StatelessWidget {
  const _ManageCostumeCard({
    required this.costume,
    required this.onEdit,
    required this.onDelete,
  });

  final Costume costume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: CostumeArtwork(
                costume: costume,
                height: 105,
                borderRadius: 17,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          costume.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${costume.characterName.isEmpty ? costume.name : costume.characterName} • ${costume.category} • UK ${costume.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 9),
                  // The price row carries four parts, so it wraps to a second
                  // line rather than overflowing a narrow tile.
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatRupiah(costume.extraPricePerDay),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: '/hari',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '$kFreeRentalDays hari termasuk',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'Stok ${costume.stock}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  StatusBadge(
                    status: costume.isAvailable ? 'available' : 'unavailable',
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostumeFormSheet extends StatefulWidget {
  const _CostumeFormSheet({
    required this.ownerId,
    this.costume,
    this.allowOwnerChange = false,
    this.owners = const <AppUser>[],
  });

  final int ownerId;
  final Costume? costume;

  /// Whether the form offers an owner picker, which only an administrator has.
  final bool allowOwnerChange;
  final List<AppUser> owners;

  @override
  State<_CostumeFormSheet> createState() => _CostumeFormSheetState();
}

class _CostumeFormSheetState extends State<_CostumeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _characterName;
  late final TextEditingController _category;
  late final TextEditingController _size;
  late final TextEditingController _color;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _extraPrice;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late bool _published;
  late int _ownerId;

  /// Media staged for upload, and the stored URLs this edit will drop.
  final List<String> _newImagePaths = <String>[];
  final List<String> _newVideoPaths = <String>[];
  final List<String> _removedImageUrls = <String>[];
  final List<String> _removedVideoUrls = <String>[];
  String? _mediaError;

  @override
  void initState() {
    super.initState();
    final item = widget.costume;
    _ownerId = item?.ownerId ?? widget.ownerId;
    _name = TextEditingController(text: item?.name ?? '');
    _characterName = TextEditingController(text: item?.characterName ?? '');
    _category = TextEditingController(text: item?.category ?? 'Fantasy');
    _size = TextEditingController(text: item?.size ?? 'M');
    _color = TextEditingController(text: item?.color ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _price = TextEditingController(
      text: item == null ? '' : item.price.toStringAsFixed(0),
    );
    _extraPrice = TextEditingController(
      text: item == null ? '' : item.extraPricePerDay.toStringAsFixed(0),
    );
    _stock = TextEditingController(
      text: item == null ? '1' : item.stock.toString(),
    );
    _imageUrl = TextEditingController(text: item?.imageUrl ?? '');
    _published = item?.isPublished ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _characterName.dispose();
    _category.dispose();
    _size.dispose();
    _color.dispose();
    _description.dispose();
    _price.dispose();
    _extraPrice.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  double? _parsePrice(String value) {
    var raw = value.trim().replaceAll(' ', '');
    if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(raw)) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.costume;
    final price = _parsePrice(_price.text);
    final extraPrice = _parsePrice(_extraPrice.text);
    final stock = int.tryParse(_stock.text.trim());
    if (price == null ||
        price <= 0 ||
        extraPrice == null ||
        extraPrice < 0 ||
        stock == null ||
        stock < 1) {
      return;
    }
    Navigator.of(context).pop(
      CostumeFormResult(
        costume: Costume(
          id: existing?.id ?? 0,
          ownerId: _ownerId,
          name: _name.text.trim(),
          characterName: _characterName.text.trim(),
          category: _category.text.trim(),
          size: _size.text.trim(),
          color: _color.text.trim(),
          description: _description.text.trim(),
          price: price,
          extraPricePerDay: extraPrice,
          stock: stock,
          isPublished: _published,
          isAvailable: _published && stock > 0,
          imageUrl: _imageUrl.text.trim().isEmpty
              ? null
              : _imageUrl.text.trim(),
          coverImageUrl: existing?.coverImageUrl,
          imageUrls: existing?.imageUrls ?? const <String>[],
          videoUrls: existing?.videoUrls ?? const <String>[],
          createdAt: existing?.createdAt,
        ),
        newImagePaths: List<String>.of(_newImagePaths),
        newVideoPaths: List<String>.of(_newVideoPaths),
        removedImageUrls: List<String>.of(_removedImageUrls),
        removedVideoUrls: List<String>.of(_removedVideoUrls),
      ),
    );
  }

  /// The stored gallery that survives this edit.
  List<String> get _keptImages {
    final removed = _removedImageUrls.toSet();
    final existing = widget.costume?.imageUrls ?? const <String>[];
    return existing.where((url) => !removed.contains(url)).toList();
  }

  List<String> get _keptVideos {
    final removed = _removedVideoUrls.toSet();
    final existing = widget.costume?.videoUrls ?? const <String>[];
    return existing.where((url) => !removed.contains(url)).toList();
  }

  Future<void> _pickMedia({required bool images}) async {
    final result = await GalleryPicker.pick(
      images: images,
      imageCount: _keptImages.length,
      videoCount: _keptVideos.length,
      removedImageCount: _removedImageUrls.length,
      removedVideoCount: _removedVideoUrls.length,
    );
    if (!mounted || result == null) return;
    setState(() {
      _mediaError = result.error;
      if (images) {
        _newImagePaths.addAll(result.paths);
      } else {
        _newVideoPaths.addAll(result.paths);
      }
    });
  }

  /// The gallery section of the form: counts, add buttons, and the removable
  /// thumbnails for both what is already stored and what is staged.
  Widget _galleryEditor() {
    final scheme = Theme.of(context).colorScheme;
    final images = _keptImages;
    final videos = _keptVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Galeri',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          'Maksimal ${CosrentRepository.maxGalleryImages} foto dan '
          '${CosrentRepository.maxGalleryVideos} video per kostum.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickMedia(images: true),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text('Foto (${images.length + _newImagePaths.length})'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickMedia(images: false),
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: Text('Video (${videos.length + _newVideoPaths.length})'),
            ),
          ],
        ),
        if (_mediaError != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: AppColors.danger,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _mediaError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          _GalleryRow(
            label: 'Foto tersimpan',
            entries: [
              for (final url in images)
                _GalleryEntry(url: url, onRemove: () {
                  setState(() => _removedImageUrls.add(url));
                }),
            ],
          ),
        ],
        if (_newImagePaths.isNotEmpty) ...[
          const SizedBox(height: 10),
          _GalleryRow(
            label: 'Foto baru',
            entries: [
              for (final path in _newImagePaths)
                _GalleryEntry(
                  localPath: path,
                  isVideo: false,
                  onRemove: () => setState(() => _newImagePaths.remove(path)),
                ),
            ],
          ),
        ],
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 10),
          _GalleryRow(
            label: 'Video tersimpan',
            entries: [
              for (final url in videos)
                _GalleryEntry(
                  url: url,
                  isVideo: true,
                  onRemove: () => setState(() => _removedVideoUrls.add(url)),
                ),
            ],
          ),
        ],
        if (_newVideoPaths.isNotEmpty) ...[
          const SizedBox(height: 10),
          _GalleryRow(
            label: 'Video baru',
            entries: [
              for (final path in _newVideoPaths)
                _GalleryEntry(
                  localPath: path,
                  isVideo: true,
                  onRemove: () => setState(() => _newVideoPaths.remove(path)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.costume == null ? 'Tambah kostum' : 'Edit kostum',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'Lengkapi informasi agar customer dapat menemukan kostum yang tepat.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama kostum',
                  prefixIcon: Icon(Icons.checkroom_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _characterName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama karakter',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama karakter wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _category,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _size,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Ukuran'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _color,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Warna'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga sewa',
                        helperText: 'Untuk 3 hari pertama',
                      ),
                      validator: (v) =>
                          (_parsePrice(v ?? '') == null ||
                              _parsePrice(v ?? '')! <= 0)
                          ? 'Masukkan angka lebih dari 0'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _extraPrice,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Biaya hari tambahan',
                  prefixText: 'Rp ',
                  helperText:
                      'Dikenakan per hari setelah $kFreeRentalDays hari yang '
                      'sudah termasuk. Isi 0 untuk perpanjangan gratis.',
                ),
                validator: (v) =>
                    (_parsePrice(v ?? '') == null || _parsePrice(v ?? '')! < 0)
                    ? 'Masukkan angka 0 atau lebih'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null || int.parse(v!) < 1
                          ? 'Minimal 1'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrl,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return null;
                        final uri = Uri.tryParse(value);
                        return uri == null ||
                                !{'http', 'https'}.contains(uri.scheme)
                            ? 'URL harus diawali http:// atau https://'
                            : null;
                      },
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL gambar (opsional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Detail bahan, aksesori, dan karakter kostum',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 8),
              if (widget.allowOwnerChange && widget.owners.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _ownerId,
                  decoration: const InputDecoration(
                    labelText: 'Owner kostum',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  items: [
                    for (final owner in widget.owners)
                      DropdownMenuItem<int>(
                        value: owner.id,
                        child: Text(owner.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _ownerId = value ?? _ownerId),
                ),
                const SizedBox(height: 8),
              ],
              _galleryEditor(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Publikasikan kostum',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Kostum hanya tampil di katalog jika dipublikasikan.',
                ),
                value: _published,
                onChanged: (value) => setState(() => _published = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    widget.costume == null
                        ? 'Simpan kostum'
                        : 'Simpan perubahan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled row of gallery thumbnails, each removable.
class _GalleryRow extends StatelessWidget {
  const _GalleryRow({required this.label, required this.entries});

  final String label;
  final List<_GalleryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries,
        ),
      ],
    );
  }
}

/// One removable thumbnail, backed either by a stored URL or a local file.
class _GalleryEntry extends StatelessWidget {
  const _GalleryEntry({
    this.url,
    this.localPath,
    this.isVideo = false,
    required this.onRemove,
  });

  final String? url;
  final String? localPath;
  final bool isVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 72,
            height: 72,
            child: _thumbnail(scheme),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: scheme.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close_rounded, size: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnail(ColorScheme scheme) {
    final source = url ?? localPath;
    if (source == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          LocalImage(
            path: localPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (isVideo)
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }
}
