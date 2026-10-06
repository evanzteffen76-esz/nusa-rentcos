import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../payments/payment_summary_panel.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.user,
    this.ownerView = false,
    this.adminView = false,
  });

  final int orderId;
  final AppUser user;
  final bool ownerView;
  final bool adminView;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _RentalDaysController extends ChangeNotifier {
  /// The length the owner grants on approval, shared between the picker and
  /// the approve request so the confirmed total always matches the picker.
  int _days = kMinRentalDays;

  int get days => _days;

  void decrease() {
    if (_days <= kMinRentalDays) return;
    _days -= 1;
    notifyListeners();
  }

  void increase() {
    if (_days >= kMaxRentalDays) return;
    _days += 1;
    notifyListeners();
  }
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<RentalOrder?> _future;
  bool _busy = false;
  final _rentalDays = _RentalDaysController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _rentalDays.dispose();
    super.dispose();
  }

  Future<RentalOrder?> _load() =>
      AppState.of(context).repository.getOrder(widget.orderId);

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  Future<void> _changeStatus(
    RentalOrder order,
    String status, {
    String? note,
    int? rentalDays,
  }) async {
    final label = status == 'approved'
        ? 'setujui'
        : status == 'rejected'
        ? 'tolak'
        : 'perbarui';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${label[0].toUpperCase()}${label.substring(1)} pesanan?'),
        content: Text(
          'Pesanan ${order.costumeName ?? 'ini'} akan berubah menjadi ${statusLabel(status).toLowerCase()}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, lanjutkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    String? actionNote = note;
    if (!widget.adminView &&
        (status == 'approved' ||
            status == 'rejected' ||
            status == 'returned')) {
      final controller = TextEditingController(text: note ?? '');
      final prompted = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            status == 'returned' ? 'Catatan pengembalian' : 'Catatan owner',
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: status == 'returned'
                  ? 'Catatan (opsional)'
                  : 'Alasan / catatan (opsional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
      if (prompted == null || !mounted) return;
      actionNote = prompted;
    }
    setState(() => _busy = true);
    final repository = AppState.of(context).repository;
    try {
      await repository.updateOrderStatus(
        order.id,
        status,
        notes: actionNote,
        // Only the owner approval endpoint accepts a length; sending it on any
        // other transition would be rejected as an unknown field.
        rentalDays: rentalDays,
      );
      if (mounted) {
        _reload();
        showAppSnack(context, 'Status pesanan berhasil diperbarui.');
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          'Gagal memperbarui status: $error',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reportIssue(
    RentalOrder order, {
    String initialType = 'lost',
  }) async {
    final typeController = TextEditingController(text: initialType);
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Laporkan masalah'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Jenis masalah'),
                  items: const [
                    DropdownMenuItem(
                      value: 'lost',
                      child: Text('Hilang / replacement'),
                    ),
                    DropdownMenuItem(
                      value: 'stain',
                      child: Text('Noda / stain'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(
                    () => typeController.text = value ?? 'stain',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ceritakan masalahnya',
                    hintText: 'Ceritakan detail yang membantu owner menangani.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: typeController.text == 'lost'
                        ? 'Biaya replacement (opsional)'
                        : 'Denda / biaya (opsional)',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'type': typeController.text,
                'description': descriptionController.text,
                'amount': amountController.text,
              }),
              child: const Text('Kirim laporan'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      typeController.dispose();
      descriptionController.dispose();
      amountController.dispose();
    });
    if (result == null || result['description']!.trim().isEmpty || !mounted) {
      return;
    }
    String? evidencePath;
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      evidencePath = picked?.path;
    } catch (_) {
      // A device may not expose a local file path; ask the user to retry.
    }
    if (!mounted) return;
    if (evidencePath == null || evidencePath.isEmpty) {
      showAppSnack(
        context,
        'Lampirkan bukti foto atau PDF sebelum mengirim laporan.',
        isError: true,
      );
      return;
    }
    final repository = AppState.of(context).repository;
    final amount =
        double.tryParse(
          result['amount']?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
        ) ??
        0;
    if (amount < 1) {
      showAppSnack(
        context,
        result['type'] == 'lost'
            ? 'Masukkan biaya replacement terlebih dahulu.'
            : 'Masukkan jumlah denda terlebih dahulu.',
        isError: true,
      );
      return;
    }
    try {
      await repository.createIssue(
        orderId: order.id,
        reportedBy: widget.user.id,
        type: result['type']!,
        description: result['description']!,
        fineAmount: result['type'] == 'stain' ? amount : 0,
        replacementCost: result['type'] == 'lost' ? amount : null,
        evidencePath: evidencePath,
      );
      if (mounted) {
        showAppSnack(
          context,
          'Laporan tersimpan. Owner akan segera menindaklanjuti.',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Gagal mengirim laporan: $error', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail pesanan')),
      body: FutureBuilder<RentalOrder?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Pesanan tidak ditemukan',
              message: 'Data pesanan sudah tidak tersedia.',
            );
          }
          final order = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor(order.status).withValues(alpha: 0.18),
                      statusColor(order.status).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.costumeName ?? 'Kostum',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order #NC-${order.id.toString().padLeft(4, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${formatDate(order.startDate)} — ${formatDate(order.endDate)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(order: order),
              const SizedBox(height: 20),
              PaymentSummaryPanel(order: order),
              const SizedBox(height: 20),
              Text(
                'Riwayat pesanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _Timeline(status: order.status),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Catatan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(order.notes),
                ),
              ],
              if (order.ownerNote.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Catatan owner',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Text(order.ownerNote),
              ],
              const SizedBox(height: 24),
              if (widget.ownerView || widget.adminView) ...[
                Text(
                  widget.adminView ? 'Aksi admin' : 'Aksi owner',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 11),
                if (order.isPending &&
                    (widget.adminView ||
                        order.canApprove ||
                        order.canReject)) ...[
                  // The owner sets the final length, because the extra days are
                  // what the customer's own rate will be billed for.
                  if (!widget.adminView && order.canApprove) ...[
                    _RentalDaysPicker(controller: _rentalDays, order: order),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _changeStatus(order, 'rejected'),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _changeStatus(
                                  order,
                                  'approved',
                                  rentalDays: _rentalDays.days,
                                ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.isReturned &&
                    (widget.adminView
                        ? !order.hasOpenIssue
                        : (order.canReportStain || order.canComplete))) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : widget.ownerView
                              ? () => _reportIssue(order, initialType: 'stain')
                              : null,
                          icon: const Icon(Icons.report_problem_outlined),
                          label: Text(
                            widget.ownerView
                                ? 'Laporkan noda'
                                : 'Laporan noda owner',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : (widget.adminView
                                    ? order.hasOpenIssue
                                    : !order.canComplete)
                              ? null
                              : () => _changeStatus(order, 'completed'),
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('Selesaikan'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.isApproved) ...[
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: AppColors.info,
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menunggu kostum dikembalikan oleh customer.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (order.isPending) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _confirmCancel(order),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan pesanan'),
                  ),
                ),
              ] else if (order.isApproved &&
                  (order.canReturn || order.canReportLost)) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy || !order.canReportLost
                            ? null
                            : () => _reportIssue(order),
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Laporkan hilang'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy
                            ? null
                            : order.canReturn
                            ? () => _changeStatus(order, 'returned')
                            : null,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Kembalikan'),
                      ),
                    ),
                  ],
                ),
              ] else if (order.isApproved) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        order.hasIssue
                            ? Icons.report_problem_outlined
                            : Icons.schedule_rounded,
                        color: order.hasIssue
                            ? AppColors.warning
                            : AppColors.info,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.hasIssue
                              ? 'Ada laporan pada pesanan ini. Tunggu owner menindaklanjuti.'
                              : 'Pengembalian dapat dilakukan setelah tanggal sewa selesai.',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (order.isReturned) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kostum sudah dikembalikan. Menunggu penyelesaian owner.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.isRejected &&
                  !widget.ownerView &&
                  !widget.adminView) ...[
                const SizedBox(height: 12),
                Text(
                  'Pesanan ini ditolak. Silakan pilih kostum atau tanggal lain.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(RentalOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final repository = AppState.of(context).repository;
    try {
      await repository.deleteOrder(order.id);
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(
          context,
          'Gagal membatalkan pesanan: $error',
          isError: true,
        );
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.order});

  final RentalOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            _Row(
              label: 'Pelanggan',
              value: order.customerName ?? '-',
              icon: Icons.person_outline_rounded,
            ),
            const Divider(height: 22),
            _Row(
              label: 'Email',
              value: order.customerEmail ?? '-',
              icon: Icons.alternate_email_rounded,
            ),
            const Divider(height: 22),
            _Row(
              label: 'Jumlah',
              value: '${order.quantity} kostum',
              icon: Icons.layers_outlined,
            ),
            const Divider(height: 22),
            _Row(
              label: 'Durasi',
              value: '${order.durationInDays} hari',
              icon: Icons.timelapse_outlined,
            ),
            if (order.extraDays > 0) ...[
              const Divider(height: 22),
              _Row(
                label: 'Hari tambahan',
                value:
                    '${order.extraDays} hari × '
                    '${formatRupiah(order.extraPricePerDay)}',
                icon: Icons.more_time_outlined,
              ),
              const Divider(height: 22),
              _Row(
                label: 'Biaya tambahan',
                value: formatRupiah(order.extraFeeTotal),
                icon: Icons.add_chart_outlined,
              ),
            ],
            const Divider(height: 22),
            _Row(
              label: 'Total',
              value: formatRupiah(order.totalPrice),
              icon: Icons.payments_outlined,
            ),
            if (order.returnedAt != null) ...[
              const Divider(height: 22),
              _Row(
                label: 'Dikembalikan',
                value: formatDate(order.returnedAt),
                icon: Icons.assignment_turned_in_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lets the owner set the final rental length while approving.
///
/// The first [kFreeRentalDays] days are covered by the order's base price, so
/// only the days past that add the owner's extra rate.
class _RentalDaysPicker extends StatelessWidget {
  const _RentalDaysPicker({
    required this.controller,
    required this.order,
  });

  final _RentalDaysController controller;
  final RentalOrder order;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final days = controller.days;
    final extra = extraDaysFor(days);
    final extraFee =
        order.extraPricePerDay * extra * (order.quantity < 1 ? 1 : order.quantity);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lama sewa',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$kFreeRentalDays hari sudah termasuk dalam harga dasar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: days > kMinRentalDays
                    ? controller.decrease
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Text(
                  '$days',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: days < kMaxRentalDays
                    ? controller.increase
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (extra > 0) ...[
            const SizedBox(height: 10),
            Text(
              '$extra hari tambahan × ${formatRupiah(order.extraPricePerDay)} '
              '= ${formatRupiah(extraFee)}',
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isApproved =
        normalized == 'approved' ||
        normalized == 'returned' ||
        normalized == 'completed';
    final isReturned = normalized == 'returned' || normalized == 'completed';
    final isRejected = normalized == 'rejected' || normalized == 'cancelled';
    final steps = <(String, bool)>[
      ('Pesanan dibuat', true),
      ('Menunggu persetujuan', normalized != 'pending'),
      if (isRejected)
        (normalized == 'cancelled' ? 'Dibatalkan' : 'Ditolak', true)
      else
        ('Disetujui owner', isApproved),
      if (!isRejected) ('Selesai dikembalikan', isReturned),
    ];
    return Column(
      children: List.generate(steps.length, (index) {
        final active = steps[index].$2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.success
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    active ? Icons.check_rounded : Icons.circle_outlined,
                    size: 15,
                    color: active
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: active && steps[index + 1].$2
                        ? AppColors.success.withValues(alpha: 0.5)
                        : Theme.of(context).dividerColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                steps[index].$1,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
