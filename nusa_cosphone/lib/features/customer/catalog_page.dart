import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'costume_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.user});

  final AppUser user;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  String _category = 'Semua';
  bool _availableOnly = false;
  late Future<List<Costume>> _future;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _categoriesFuture = AppState.of(context).repository.getCostumeCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Costume>> _load() async {
    final page = await AppState.of(context).repository.getCostumes(
      search: _searchController.text,
      category: _category,
      publishedOnly: true,
      availableOnly: _availableOnly,
    );
    return page.items;
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = AppState.of(context).repository
          .getCostumeCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                eyebrow: 'Koleksi kostum',
                title: 'Temukan character-mu',
                subtitle: 'Pilih kostum yang paling sesuai dengan cerita dan gaya-mu.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _reload(),
                onChanged: (_) {},
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kategori kostum',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Cari',
                    onPressed: _reload,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: FutureBuilder<List<String>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Row(
                        children: [
                          const Expanded(child: Text('Kategori gagal dimuat')),
                          TextButton(
                            onPressed: _reloadCategories,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      );
                    }
                    final categories = snapshot.data ?? ['Semua'];
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'Semua',
                          selected: _category == 'Semua',
                          onTap: () {
                            _category = 'Semua';
                            _reload();
                          },
                        ),
                        ...categories
                            .where((item) => item != 'Semua')
                            .map(
                              (item) => _CategoryChip(
                                label: item,
                                selected: _category == item,
                                onTap: () {
                                  _category = item;
                                  _reload();
                                },
                              ),
                            ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: const Text('Tersedia'),
                          avatar: Icon(
                            Icons.bolt_rounded,
                            size: 17,
                            color: _availableOnly
                                ? AppColors.success
                                : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                          ),
                          selected: _availableOnly,
                          onSelected: (value) {
                            _availableOnly = value;
                            _reload();
                          },
                        ),
                      ],
                    );
                  },
                ),
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
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Gagal memuat katalog',
                  message: '${snapshot.error}',
                  actionLabel: 'Coba lagi',
                  onAction: _reload,
                );
              }
              final costumes = snapshot.data ?? [];
              if (costumes.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Kostum tidak ditemukan',
                  message: 'Coba kata kunci atau kategori yang lain.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                      ? 3
                      : constraints.maxWidth >= 360
                      ? 2
                      : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      mainAxisExtent: columns == 1 ? 360 : 330,
                    ),
                    itemCount: costumes.length,
                    itemBuilder: (context, index) => _CatalogCard(
                      costume: costumes[index],
                      onTap: () => _openDetail(costumes[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(Costume costume) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CostumeDetailPage(costume: costume, user: widget.user),
      ),
    );
    if (mounted) _reload();
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.costume, required this.onTap});

  final Costume costume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CostumeArtwork(
                costume: costume,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          costume.characterName.isEmpty
                              ? costume.name
                              : costume.characterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (costume.isAvailable)
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.success,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatRupiah(costume.price)}/$kFreeRentalDays hari',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '+$kFreeRentalDays hari: '
                    '${formatRupiah(costume.extraPricePerDay)}/hari',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${costume.size}  •  ${costume.color}  •  Stok ${costume.stock}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
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
