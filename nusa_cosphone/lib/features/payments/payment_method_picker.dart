import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Let a customer choose how to settle a booking.
///
/// A cash booking is settled in person against a code the server mints; a bank
/// transfer needs the supplier's account and an uploaded receipt. When the
/// supplier has not filled in their bank details the transfer option is shown
/// disabled with the reason, rather than hidden, so the choice stays
/// self-explanatory.
class PaymentMethodPicker extends StatefulWidget {
  const PaymentMethodPicker({
    super.key,
    required this.bankDetails,
    this.initialMethod = PaymentMethod.payAtOwner,
  });

  final BankDetails bankDetails;
  final PaymentMethod initialMethod;

  @override
  State<PaymentMethodPicker> createState() => PaymentMethodPickerState();
}

class PaymentMethodPickerState extends State<PaymentMethodPicker> {
  late PaymentMethod _method = widget.initialMethod;
  String? _proofPath;
  String? _proofError;
  bool _picking = false;

  /// The selected method, read by the booking sheet before it submits.
  PaymentMethod get method => _method;

  /// The selected receipt, or `null` when the method does not need one.
  String? get proofPath => _method.isBankTransfer ? _proofPath : null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bank = widget.bankDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode pembayaran',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Transfer bank butuh data rekening pemilik kostum.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _MethodOption(
          selected: _method == PaymentMethod.payAtOwner,
          enabled: true,
          icon: Icons.payments_outlined,
          title: 'Bayar di lokasi',
          subtitle: 'Dapat kode COSPAY untuk dibayar langsung ke owner.',
          onTap: () => setState(() {
            _method = PaymentMethod.payAtOwner;
            _proofPath = null;
            _proofError = null;
          }),
        ),
        const SizedBox(height: 10),
        _MethodOption(
          selected: _method == PaymentMethod.bankTransfer,
          // A transfer can only be offered once the supplier has published an
          // account; until then the option stays visible but disabled, with the
          // reason attached, so the choice is never a dead end.
          enabled: bank.isComplete,
          icon: Icons.account_balance_outlined,
          title: 'Transfer bank',
          subtitle: bank.isComplete
              ? 'Unggah bukti transfer ke rekening owner.'
              : 'Pemilik kostum belum mengisi data rekening, jadi metode '
                    'transfer belum tersedia.',
          onTap: () => setState(() => _method = PaymentMethod.bankTransfer),
        ),
        if (_method == PaymentMethod.bankTransfer) ...[
          const SizedBox(height: 14),
          BankDetailsCard(details: bank),
          const SizedBox(height: 12),
          _ProofField(
            path: _proofPath,
            error: _proofError,
            busy: _picking,
            onPick: _pickProof,
            onClear: () => setState(() {
              _proofPath = null;
              _proofError = null;
            }),
          ),
        ],
      ],
    );
  }

  Future<void> _pickProof() async {
    setState(() {
      _picking = true;
      _proofError = null;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (!mounted) return;
      setState(() {
        _picking = false;
        if (picked != null && picked.path != null) _proofPath = picked.path;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _proofError =
            'Gagal membuka pemilih berkas: ${error.message ?? 'tidak diketahui'}.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _proofError = 'Gagal membuka pemilih berkas di perangkat ini.';
      });
    }
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: scheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the supplier's account so a transfer can be made from it.
class BankDetailsCard extends StatelessWidget {
  const BankDetailsCard({super.key, required this.details});

  final BankDetails details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!details.isComplete) {
      return Card(
        color: scheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Data rekening pemilik kostum belum lengkap. Pilih bayar di lokasi '
            'atau hubungi owner.',
          ),
        ),
      );
    }

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BankRow(label: 'Bank', value: details.bankName),
            const SizedBox(height: 8),
            _BankRow(
              label: 'Nomor rekening',
              value: details.maskedAccountNumber,
              copyable: details.accountNumber,
            ),
            const SizedBox(height: 8),
            _BankRow(label: 'Atas nama', value: details.accountHolder),
          ],
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({
    required this.label,
    required this.value,
    this.copyable,
  });

  final String label;
  final String value;
  final String? copyable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (copyable != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Salin $label',
            icon: const Icon(Icons.copy_rounded, size: 17),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyable!));
              if (!context.mounted) return;
              showAppSnack(context, '$label disalin.');
            },
          ),
      ],
    );
  }
}

class _ProofField extends StatelessWidget {
  const _ProofField({
    required this.path,
    required this.error,
    required this.busy,
    required this.onPick,
    required this.onClear,
  });

  final String? path;
  final String? error;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = path?.split(RegExp(r'[/\\]')).last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bukti transfer',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (name == null)
          OutlinedButton.icon(
            onPressed: busy ? null : onPick,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_rounded),
            label: const Text('Pilih foto atau PDF'),
          )
        else
          Card(
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}