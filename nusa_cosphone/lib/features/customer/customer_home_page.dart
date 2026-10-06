import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'costume_detail_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    super.key,
    required this.user,
    required this.onBrowse,
    required this.onOrders,
  });

  final AppUser user;
  final VoidCallback onBrowse;
  final VoidCallback onOrders;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final repository = AppState.of(context).repository;
    // Each future is awaited under its own name instead of combining them in a
    // `Future.wait` and casting by position: the list endpoints return a page,
    // and a positional cast would only surface the mismatch at runtime.
    final stats = await repository.getDashboardStats();
    final orders = (await repository.getOrders()).items;
    final costumes = (await repository.getCostumes(publishedOnly: true)).items;
    return _HomeData(
      stats: stats,
      orders: orders,
      costumes: costumes,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Theme.of(context).colorScheme.primary,
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScrollableRefreshable(child: LoadingView());
          }
          if (snapshot.hasError) {
            return ScrollableRefreshable(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Gagal memuat data',
                message: '${snapshot.error}',
                actionLabel: 'Coba lagi',
                onAction: _refresh,
              ),
            );
          }
          final data = snapshot.data!;
          final activeOrders = data.orders
              .where((order) => order.isPending || order.isApproved)
              .toList();
          final recommendations = data.costumes
              .where((costume) => costume.isAvailable)
              .take(5)
              .toList();
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, ${widget.user.name.split(' ').first}!',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Siap jadi\nkarakter favoritmu?',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _HeroCard(onBrowse: widget.onBrowse),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760
                          ? 3
                          : constraints.maxWidth >= 420
                          ? 2
                          : 1;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: columns == 1 ? 165 : 160,
                        children: [
                          StatCard(
                            label: 'Pesanan aktif',
                            value: '${data.stats['activeOrders'] ?? 0}',
                            icon: Icons.event_available_rounded,
                            color: AppColors.primary,
                            caption: 'dalam proses',
                          ),
                          StatCard(
                            label: 'Menunggu',
                            value: '${data.stats['pendingOrders'] ?? 0}',
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.warning,
                            caption: 'perlu ditinjau',
                          ),
                          StatCard(
                            label: 'Tersedia',
                            value: '${data.stats['availableCostumes'] ?? 0}',
                            icon: Icons.checkroom_rounded,
                            color: AppColors.success,
                            caption: 'kostum siap',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Booking kamu',
                    actionLabel: activeOrders.isEmpty ? null : 'Lihat semua',
                    onAction: widget.onOrders,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: activeOrders.isEmpty
                      ? _NoBookingCard(onBrowse: widget.onBrowse)
                      : _ActiveBookingCard(
                          order: activeOrders.first,
                          onTap: widget.onOrders,
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionTitle(
                    title: 'Rekomendasi untukmu',
                    actionLabel: 'Lihat katalog',
                    onAction: widget.onBrowse,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 235,
                  child: recommendations.isEmpty
                      ? const EmptyState(
                          icon: Icons.checkroom_outlined,
                          title: 'Belum ada kostum',
                          message: 'Cek kembali koleksiku ya.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) => _RecommendationCard(
                            costume: recommendations[index],
                            onTap: () => _openCostume(recommendations[index]),
                          ),
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCostume(Costume costume) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CostumeDetailPage(costume: costume, user: widget.user),
      ),
    );
    if (mounted) _refresh();
  }
}

class _HomeData {
  const _HomeData({
    required this.stats,
    required this.orders,
    required this.costumes,
  });

  final Map<String, int> stats;
  final List<RentalOrder> orders;
  final List<Costume> costumes;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 205,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            const Color(0xFF8B72F7),
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -32,
            child: Icon(
              Icons.auto_awesome,
              size: 150,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'KOSTUM BARU SETIAP MINGGU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Costume up,\nmake it memorable.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: onBrowse,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                  child: const Text('Mulai jelajah'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.costume, required this.onTap});

  final Costume costume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CostumeArtwork(costume: costume, height: 145, borderRadius: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      costume.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({required this.order, required this.onTap});

  final RentalOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.secondary.withValues(alpha: 0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.costumeName ?? 'Kostum',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatCompactDate(order.startDate)} — ${formatCompactDate(order.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: order.status, compact: true),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _NoBookingCard extends StatelessWidget {
  const _NoBookingCard({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBrowse,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            const SoftIcon(
              icon: Icons.add_shopping_cart_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada booking aktif. Yuk temukan kostum untuk acara berikutnya!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
