import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  final AppUser user;
  final ValueChanged<int> onNavigate;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_AdminData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminData> _load() async {
    final repository = AppState.of(context).repository;
    final stats = await repository.getDashboardStats();
    final users = await repository.getUsers();
    final orders = (await repository.getOrders()).items;
    final issues = await repository.getIssues();
    return _AdminData(stats, users, orders, issues);
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
      child: FutureBuilder<_AdminData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScrollableRefreshable(child: LoadingView());
          }
          if (snapshot.hasError) {
            return ScrollableRefreshable(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Gagal memuat overview',
                message: '${snapshot.error}',
                actionLabel: 'Coba lagi',
                onAction: _reload,
              ),
            );
          }
          final data = snapshot.data!;
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
                          'Control center',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Halo, ${widget.user.name.split(' ').first}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  SoftIcon(
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ink, const Color(0xFF3D315C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COSPLAYNUSA PULSE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Platform tumbuh\ndengan momentum',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: _PulseMetric(
                            label: 'Pesanan',
                            value: '${data.stats['totalOrders'] ?? 0}',
                          ),
                        ),
                        Expanded(
                          child: _PulseMetric(
                            label: 'Pengguna',
                            value:
                                '${data.stats['totalUsers'] ?? data.users.length}',
                          ),
                        ),
                        Expanded(
                          child: _PulseMetric(
                            label: 'Kostum',
                            value: '${data.stats['availableCostumes'] ?? 0}',
                          ),
                        ),
                      ],
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
                mainAxisExtent: 150,
                children: [
                  StatCard(
                    label: 'Pending order',
                    value: '${data.stats['pendingOrders'] ?? 0}',
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.warning,
                    caption: 'perlu review',
                  ),
                  StatCard(
                    label: 'Laporan terbuka',
                    value: '${data.stats['openIssues'] ?? 0}',
                    icon: Icons.report_problem_outlined,
                    color: AppColors.danger,
                    caption: 'perlu action',
                  ),
                  StatCard(
                    label: 'Customer',
                    value:
                        '${data.stats['customerUsers'] ?? data.users.where((user) => user.isCustomer).length}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.info,
                  ),
                  StatCard(
                    label: 'Owner tim',
                    value:
                        '${data.stats['ownerUsers'] ?? data.users.where((user) => user.isOwner).length}',
                    icon: Icons.storefront_outlined,
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 27),
              const SectionTitle(title: 'Aksi cepat'),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.people_alt_outlined,
                      label: 'Kelola pengguna',
                      onTap: () => widget.onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.report_problem_outlined,
                      label: 'Lihat laporan',
                      onTap: () => widget.onNavigate(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 27),
              SectionTitle(
                title: 'Aktivitas terbaru',
                actionLabel: 'Lihat pesanan',
                onAction: () => widget.onNavigate(3),
              ),
              const SizedBox(height: 11),
              if (data.orders.isEmpty)
                const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Belum ada aktivitas',
                  message: 'Aktivitas pesanan akan tampil di sini.',
                )
              else
                ...data.orders
                    .take(4)
                    .map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActivityTile(order: order),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminData {
  const _AdminData(this.stats, this.users, this.orders, this.issues);
  final Map<String, int> stats;
  final List<AppUser> users;
  final List<RentalOrder> orders;
  final List<RentalIssue> issues;
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(
            icon: icon,
            color: Theme.of(context).colorScheme.primary,
            size: 39,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.order});
  final RentalOrder order;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
      ),
    ),
    child: Row(
      children: [
        SoftIcon(
          icon: order.isPending
              ? Icons.hourglass_top_rounded
              : Icons.check_circle_outline_rounded,
          color: statusColor(order.status),
          size: 38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.customerName ?? 'Customer'} memesan ${order.costumeName ?? 'kostum'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatCompactDate(order.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(status: order.status, compact: true),
      ],
    ),
  );
}
