import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../orders/order_detail_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  final AppUser user;
  final ValueChanged<int> onNavigate;

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  late Future<_OwnerData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OwnerData> _load() async {
    final repository = AppState.of(context).repository;
    final stats = await repository.getDashboardStats();
    final orders = (await repository.getOrders()).items;
    final costumes = (await repository.getCostumes()).items;
    final issues = await repository.getIssues();
    return _OwnerData(
      stats: stats,
      orders: orders,
      costumes: costumes,
      issues: issues,
    );
  }

  Future<void> _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      color: Theme.of(context).colorScheme.primary,
      child: FutureBuilder<_OwnerData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScrollableRefreshable(child: LoadingView());
          }
          if (snapshot.hasError) {
            return ScrollableRefreshable(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Gagal memuat dashboard',
                message: '${snapshot.error}',
                actionLabel: 'Coba lagi',
                onAction: _reload,
              ),
            );
          }
          final data = snapshot.data!;
          final pending = data.orders
              .where((order) => order.isPending)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.user.name.split(' ').first,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  SoftIcon(
                    icon: Icons.insights_rounded,
                    color: AppColors.secondary,
                    size: 50,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      AppColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan hari ini',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data.stats['pendingOrders'] ?? 0} pesanan\nmenunggu tindakan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 37,
                            child: FilledButton(
                              onPressed: () => widget.onNavigate(1),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                ),
                              ),
                              child: const Text('Kelola pesanan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.white,
                      size: 82,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 140,
                children: [
                  StatCard(
                    label: 'Total pesanan',
                    value: '${data.stats['totalOrders'] ?? 0}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    label: 'Kostum aktif',
                    value:
                        '${data.costumes.where((c) => c.isAvailable).length}',
                    icon: Icons.checkroom_outlined,
                    color: AppColors.success,
                  ),
                  StatCard(
                    label: 'Laporan terbuka',
                    value: '${data.stats['openIssues'] ?? 0}',
                    icon: Icons.report_problem_outlined,
                    color: AppColors.warning,
                  ),
                  StatCard(
                    label: 'Pelanggan',
                    value:
                        '${data.orders.map((order) => order.customerId).toSet().length}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 27),
              SectionTitle(
                title: 'Butuh ditinjau',
                actionLabel: pending.isEmpty ? null : 'Lihat semua',
                onAction: () => widget.onNavigate(1),
              ),
              const SizedBox(height: 11),
              if (pending.isEmpty)
                _OwnerEmpty(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Semua beres',
                  message: 'Tidak ada pesanan yang menunggu persetujuan.',
                  actionLabel: 'Kelola kostum',
                  onAction: () => widget.onNavigate(2),
                )
              else
                ...pending
                    .take(3)
                    .map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PendingOrderTile(
                          order: order,
                          onTap: () => _openOrder(order),
                        ),
                      ),
                    ),
              const SizedBox(height: 17),
              SectionTitle(
                title: 'Laporan terbaru',
                actionLabel: 'Lihat semua',
                onAction: () => widget.onNavigate(3),
              ),
              const SizedBox(height: 11),
              if (data.issues.isEmpty)
                const _OwnerEmpty(
                  icon: Icons.fact_check_outlined,
                  title: 'Belum ada laporan',
                  message: 'Laporan customer akan tampil di sini.',
                )
              else
                ...data.issues
                    .take(2)
                    .map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IssueMiniTile(issue: issue),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openOrder(RentalOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          orderId: order.id,
          user: widget.user,
          ownerView: true,
        ),
      ),
    );
    if (mounted) _reload();
  }
}

class _OwnerData {
  const _OwnerData({
    required this.stats,
    required this.orders,
    required this.costumes,
    required this.issues,
  });

  final Map<String, int> stats;
  final List<RentalOrder> orders;
  final List<Costume> costumes;
  final List<RentalIssue> issues;
}

class _PendingOrderTile extends StatelessWidget {
  const _PendingOrderTile({required this.order, required this.onTap});

  final RentalOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const SoftIcon(
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              size: 40,
            ),
            const SizedBox(width: 11),
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
                  const SizedBox(height: 4),
                  Text(
                    '${order.customerName ?? 'Customer'} • ${formatCompactDate(order.startDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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

class _IssueMiniTile extends StatelessWidget {
  const _IssueMiniTile({required this.issue});

  final RentalIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SoftIcon(
            icon: Icons.report_problem_outlined,
            color: statusColor(issue.type),
            size: 40,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${statusLabel(issue.type)} • ${issue.costumeName ?? 'Kostum'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.customerName ?? 'Customer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: issue.status, compact: true),
        ],
      ),
    );
  }
}

class _OwnerEmpty extends StatelessWidget {
  const _OwnerEmpty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
