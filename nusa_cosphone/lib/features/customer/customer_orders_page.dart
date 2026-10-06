import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../orders/order_detail_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key, required this.user});

  final AppUser user;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
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
              const PageIntro(
                eyebrow: 'Riwayat sewa',
                title: 'Pesanan saya',
                subtitle: 'Pantau status booking dan pengembalian kostum.',
              ),
              const SizedBox(height: 19),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _filter == 'all',
                      onTap: () {
                        _filter = 'all';
                        _reload();
                      },
                    ),
                    _FilterChip(
                      label: 'Menunggu',
                      selected: _filter == 'pending',
                      onTap: () {
                        _filter = 'pending';
                        _reload();
                      },
                    ),
                    _FilterChip(
                      label: 'Disetujui',
                      selected: _filter == 'approved',
                      onTap: () {
                        _filter = 'approved';
                        _reload();
                      },
                    ),
                    _FilterChip(
                      label: 'Selesai',
                      selected: _filter == 'completed',
                      onTap: () {
                        _filter = 'completed';
                        _reload();
                      },
                    ),
                    _FilterChip(
                      label: 'Dikembalikan',
                      selected: _filter == 'returned',
                      onTap: () {
                        _filter = 'returned';
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
          child: RefreshIndicator(
            onRefresh: _reload,
            // Wrapping the whole builder keeps pull-to-refresh alive on the
            // loading, error and empty states, not only when rows exist.
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
                  return const ScrollableRefreshable(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada pesanan',
                      message: 'Booking kostum pertamamu akan muncul di sini.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _OrderCard(
                    order: orders[index],
                    onTap: () => _openOrder(orders[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openOrder(RentalOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: order.id, user: widget.user),
      ),
    );
    if (mounted) _reload();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final RentalOrder order;
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor(order.status).withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.13),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: statusColor(order.status),
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          'Order #NC-${order.id.toString().padLeft(4, '0')}',
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
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${formatCompactDate(order.startDate)} — '
                      '${formatCompactDate(order.endDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      formatRupiah(order.totalPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
