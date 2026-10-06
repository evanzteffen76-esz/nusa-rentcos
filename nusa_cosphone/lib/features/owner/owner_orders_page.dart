import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../orders/order_detail_page.dart';

class OwnerOrdersPage extends StatefulWidget {
  const OwnerOrdersPage({
    super.key,
    required this.user,
    this.adminScope = false,
  });

  final AppUser user;
  final bool adminScope;

  @override
  State<OwnerOrdersPage> createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends State<OwnerOrdersPage> {
  String _filter = 'all';
  late Future<List<RentalOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RentalOrder>> _load() async =>
      (await AppState.of(context).repository.getOrders(status: _filter)).items;

  Future<void> _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
    return future;
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
              PageIntro(
                eyebrow: widget.adminScope ? 'Moderasi' : 'Operasional',
                title: widget.adminScope ? 'Semua pesanan' : 'Kelola pesanan',
                subtitle: widget.adminScope
                    ? 'Pantau dan moderasi seluruh pesanan CosplayNusa.'
                    : 'Tinjau, setujui, dan selesaikan sewa kostum.',
              ),
              const SizedBox(height: 19),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Filter(
                      label: 'Semua',
                      selected: _filter == 'all',
                      onTap: () {
                        _filter = 'all';
                        _reload();
                      },
                    ),
                    _Filter(
                      label: 'Menunggu',
                      selected: _filter == 'pending',
                      onTap: () {
                        _filter = 'pending';
                        _reload();
                      },
                    ),
                    _Filter(
                      label: 'Disetujui',
                      selected: _filter == 'approved',
                      onTap: () {
                        _filter = 'approved';
                        _reload();
                      },
                    ),
                    _Filter(
                      label: 'Selesai',
                      selected: _filter == 'completed',
                      onTap: () {
                        _filter = 'completed';
                        _reload();
                      },
                    ),
                    _Filter(
                      label: 'Returned',
                      selected: _filter == 'returned',
                      onTap: () {
                        _filter = 'returned';
                        _reload();
                      },
                    ),
                    _Filter(
                      label: 'Ditolak',
                      selected: _filter == 'rejected',
                      onTap: () {
                        _filter = 'rejected';
                        _reload();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<RentalOrder>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ScrollableRefreshable(child: LoadingView());
              }
              if (snapshot.hasError) {
                return ScrollableRefreshable(
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Gagal memuat pesanan',
                    message: '${snapshot.error}',
                    actionLabel: 'Coba lagi',
                    onAction: _reload,
                  ),
                );
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return ScrollableRefreshable(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada pesanan',
                    message: widget.adminScope
                        ? 'Pesanan dari seluruh owner akan muncul di sini.'
                        : 'Pesanan customer akan muncul di sini.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _OwnerOrderCard(
                    order: orders[index],
                    adminScope: widget.adminScope,
                    onTap: () => _open(orders[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _open(RentalOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          orderId: order.id,
          user: widget.user,
          ownerView: !widget.adminScope,
          adminView: widget.adminScope,
        ),
      ),
    );
    if (mounted) _reload();
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _OwnerOrderCard extends StatelessWidget {
  const _OwnerOrderCard({
    required this.order,
    required this.adminScope,
    required this.onTap,
  });

  final RentalOrder order;
  final bool adminScope;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                        const SizedBox(height: 3),
                        Text(
                          '${order.customerName ?? '-'} • #NC-${order.id.toString().padLeft(4, '0')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${formatCompactDate(order.startDate)} — ${formatCompactDate(order.endDate)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(order.totalPrice),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (order.isPending) ...[
                const SizedBox(height: 13),
                const Divider(height: 1),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        adminScope
                            ? 'Menunggu keputusan admin'
                            : 'Menunggu keputusan owner',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(onPressed: onTap, child: const Text('Tinjau')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
