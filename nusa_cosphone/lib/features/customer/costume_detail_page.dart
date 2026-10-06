import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../media/media_picker.dart';
import '../payments/payment_method_picker.dart';

class CostumeDetailPage extends StatefulWidget {
  const CostumeDetailPage({
    super.key,
    required this.costume,
    required this.user,
  });

  final Costume costume;
  final AppUser user;

  @override
  State<CostumeDetailPage> createState() => _CostumeDetailPageState();
}

class _CostumeDetailPageState extends State<CostumeDetailPage> {
  final _notesController = TextEditingController();
  DateTime? _startDate;
  int _quantity = 1;
  int _days = kMinRentalDays;
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'Pilih tanggal mulai sewa',
      cancelText: 'Batal',
      confirmText: 'Gunakan tanggal',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _changeDays(int delta) {
    final next = _days + delta;
    // Never shorter than the free period, and never longer than the picker
    // horizon so the derived end date stays in range.
    setState(() => _days = next.clamp(kMinRentalDays, kMaxRentalDays));
  }

  /// The last day covered by the current duration choice.
  DateTime? get _periodEnd {
    final start = _startDate;
    return start == null ? null : rentalPeriodEnd(start, _days);
  }

  /// Days beyond the included period, which cost the owner's extra rate.
  int get _billableDays => widget.costume.billableDays(_days);

  /// The part of the estimate covered by the included period.
  double get _includedFee => widget.costume.price * _quantity;

  /// The part owed for the days beyond the included period.
  double get _extraFee =>
      widget.costume.extraPricePerDay * _billableDays * _quantity;

  double get _total => _includedFee + _extraFee;

  Future<void> _book() async {
    if (_startDate == null) {
      await _pickStartDate();
      return;
    }
    setState(() => _isBooking = true);
    final repository = AppState.of(context).repository;
    try {
      final current = await repository.getCostume(widget.costume.id);
      if (current == null || !current.isAvailable) {
        if (mounted) {
          showAppSnack(
            context,
            'Kostum sudah tidak tersedia. Silakan pilih kostum lain.',
            isError: true,
          );
        }
        return;
      }
      // The listing lookup above awaited, so confirm the page is still around
      // before presenting anything from its context.
      if (!mounted) return;

      // The payment method is confirmed in a sheet so a cash booking and a
      // transfer can each ask for what they need without cluttering this page.
      final payment = await showModalBottomSheet<_BookingPayment>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _PaymentSheet(bankDetails: current.ownerBank),
      );
      // The sheet may outlive this page, so re-check before touching state.
      if (!mounted) return;
      if (payment == null) {
        setState(() => _isBooking = false);
        return;
      }

      final order = await repository.createOrder(
        costumeId: current.id,
        startDate: _startDate!,
        days: _days,
        notes: _notesController.text,
        quantity: _quantity,
        paymentMethod: payment.method,
        paymentProofPath: payment.proofPath,
      );
      if (!mounted) return;
      final code = order?.paymentCode;
      showAppSnack(
        context,
        code == null || code.isEmpty
            ? 'Booking berhasil dibuat. Tunggu konfirmasi owner ya!'
            : 'Booking berhasil dibuat. Kode pembayaran: $code',
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Booking gagal: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = widget.costume.isAvailable;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail kostum'),
        actions: [
          IconButton(
            onPressed: () =>
                showAppSnack(context, 'Kostum disimpan ke favorit.'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CostumeArtwork(
                    costume: widget.costume,
                    height: 285,
                    borderRadius: 28,
                  ),
                  const SizedBox(height: 18),
                  CostumeGalleryStrip(costume: widget.costume),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.costume.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (widget.costume.characterName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Character: ${widget.costume.characterName}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(
                      status: available ? 'available' : 'unavailable',
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatRupiah(widget.costume.price),
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      ' / $kFreeRentalDays hari',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Text(
                  widget.costume.extraPricePerDay > 0
                      ? 'Hari ke-$kFreeRentalDays dan seterusnya '
                            '${formatRupiah(widget.costume.extraPricePerDay)}/hari.'
                      : 'Perpanjangan melewati $kFreeRentalDays hari tidak '
                            'dikenakan biaya.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _Spec(
                        icon: Icons.category_outlined,
                        label: 'Kategori',
                        value: widget.costume.category,
                      ),
                    ),
                    Expanded(
                      child: _Spec(
                        icon: Icons.straighten_rounded,
                        label: 'Ukuran',
                        value: widget.costume.size,
                      ),
                    ),
                    Expanded(
                      child: _Spec(
                        icon: Icons.palette_outlined,
                        label: 'Warna',
                        value: widget.costume.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Tentang kostum',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  widget.costume.description,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Text(
                  'Pilih tanggal mulai sewa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga sudah termasuk $kFreeRentalDays hari. Tambahkan hari '
                  'untuk biaya harian owner.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: available ? _pickStartDate : null,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? 'Pilih tanggal mulai sewa'
                                : '${formatDate(_startDate!)}  —  ${formatDate(_periodEnd!)}',
                            style: TextStyle(
                              color: _startDate == null
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SoftIcon(
                      icon: Icons.timelapse_rounded,
                      color: AppColors.primary,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Durasi sewa',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _billableDays == 0
                                ? 'Masih dalam $kFreeRentalDays hari termasuk'
                                : '$_billableDays hari tambahan',
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
                    IconButton.filledTonal(
                      onPressed: _days > kMinRentalDays
                          ? () => _changeDays(-1)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        '$_days',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _days < kMaxRentalDays
                          ? () => _changeDays(1)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SoftIcon(
                      icon: Icons.layers_outlined,
                      color: AppColors.primary,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jumlah kostum',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Maksimal sesuai stok yang tersedia',
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
                    IconButton.filledTonal(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _quantity < widget.costume.stock
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan untuk owner (opsional)',
                    hintText: 'Contoh: event, jam ambil, atau request khusus',
                  ),
                ),
                if (_startDate != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EstimateRow(
                          label:
                              '$kFreeRentalDays hari × $_quantity unit '
                              '(termasuk dalam harga)',
                          value: formatRupiah(_includedFee),
                        ),
                        if (_billableDays > 0) ...[
                          const SizedBox(height: 6),
                          _EstimateRow(
                            label:
                                '$_billableDays hari tambahan × '
                                '${formatRupiah(widget.costume.extraPricePerDay)}',
                            value: formatRupiah(_extraFee),
                            emphasis: true,
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Total sewa',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              formatRupiah(_total),
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: FilledButton.icon(
          onPressed: !available || _isBooking ? null : _book,
          icon: _isBooking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.event_available_rounded),
          label: Text(
            !available
                ? 'Kostum sedang dipesan'
                : (_startDate == null
                      ? 'Pilih tanggal dulu'
                      : 'Pesan kostum • ${formatRupiah(_total)}'),
          ),
        ),
      ),
    );
  }
}

/// One line of the price breakdown shown above the total.
class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: emphasis ? scheme.primary : AppColors.success,
            fontWeight: FontWeight.w800,
            fontSize: emphasis ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.label, required this.value});


  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SoftIcon(icon: icon, color: AppColors.primary, size: 38),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }
}

/// What the payment sheet returned to the booking flow.
class _BookingPayment {
  const _BookingPayment({required this.method, this.proofPath});

  final PaymentMethod method;
  final String? proofPath;
}

/// Confirm how the customer will pay before the booking request is sent.
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.bankDetails});

  final BankDetails bankDetails;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _pickerKey = GlobalKey<PaymentMethodPickerState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PaymentMethodPicker(
              key: _pickerKey,
              bankDetails: widget.bankDetails,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Konfirmasi pembayaran'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final picker = _pickerKey.currentState;
    if (picker == null) return;
    Navigator.of(context).pop(
      _BookingPayment(method: picker.method, proofPath: picker.proofPath),
    );
  }
}
