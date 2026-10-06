import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'payment_method_picker.dart';

/// Shows how an order is being paid, and opens the receipt when there is one.
///
/// Both the customer and the owner can open the receipt: the download endpoint
/// is role-scoped on the server and this panel only appears when the server
/// says the signed-in account may read it.
class PaymentSummaryPanel extends StatefulWidget {
  const PaymentSummaryPanel({
    super.key,
    required this.order,
    this.onProofLoaded,
  });

  final RentalOrder order;

  /// Called after a receipt is fetched, so the caller can surface a failure.
  final VoidCallback? onProofLoaded;

  @override
  State<PaymentSummaryPanel> createState() => _PaymentSummaryPanelState();
}

class _PaymentSummaryPanelState extends State<PaymentSummaryPanel> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SoftIcon(
                  icon: order.isPaidAtOwner
                      ? Icons.payments_outlined
                      : Icons.account_balance_outlined,
                  color: order.isPaidAtOwner ? AppColors.success : AppColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        order.isPaidAtOwner
                            ? 'Bayar di lokasi owner'
                            : 'Transfer bank',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (order.isPaidAtOwner && order.paymentCode != null)
              _PaymentCodeCard(code: order.paymentCode!)
            else if (order.isPaidByTransfer) ...[
              BankDetailsCard(details: order.ownerBank),
              const SizedBox(height: 12),
              if (order.hasPaymentProof && order.canShowPaymentProof)
                OutlinedButton.icon(
                  onPressed: _loading ? null : _openProof,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined),
                  label: Text(
                    order.paymentProofFilename == null
                        ? 'Lihat bukti transfer'
                        : 'Bukti: ${order.paymentProofFilename}',
                  ),
                )
              else if (order.hasPaymentProof)
                Text(
                  'Bukti transfer sudah diunggah tetapi tidak dapat dibuka '
                  'dari akun ini.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                )
              else
                Text(
                  'Bukti transfer belum diunggah. Hubungi owner bila sudah '
                  'melakukan transfer.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ] else
              Text(
                'Metode pembayaran belum ditentukan.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProof() async {
    setState(() => _loading = true);
    try {
      final repository = AppState.of(context).repository;
      final file = await repository.getPaymentProof(widget.order.id);
      if (!mounted) return;
      await showApiFileViewer(context, file);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.message, isError: true);
    } on Object {
      if (!mounted) return;
      showAppSnack(
        context,
        'Bukti transfer tidak dapat diunduh. Periksa koneksi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      widget.onProofLoaded?.call();
    }
  }
}

/// A large, selectable payment code, so it can be read aloud or copied.
class _PaymentCodeCard extends StatelessWidget {
  const _PaymentCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kode pembayaran',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Salin kode',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  showAppSnack(context, 'Kode pembayaran disalin.');
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tunjukkan kode ini ke owner saat membayar di lokasi.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Present a file fetched from an authenticated endpoint.
///
/// Images render inline. Anything else (a PDF receipt, for example) cannot be
/// rendered without bundling a document viewer, so the file is saved to the
/// device's temporary directory and its location is reported instead of
/// silently showing nothing.
Future<void> showApiFileViewer(BuildContext context, ApiFile file) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ApiFileViewerPage(file: file),
    ),
  );
}

class _ApiFileViewerPage extends StatelessWidget {
  const _ApiFileViewerPage({required this.file});

  final ApiFile file;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(file.filename, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: file.isImage
            ? InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    file.bytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    // A corrupt payload must not take the screen down.
                    errorBuilder: (context, error, stack) => _Unreadable(
                      message: 'Gambar tidak dapat ditampilkan.',
                      color: scheme.error,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        file.filename,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berkas ${_formatBytes(file.bytes.length)} berhasil '
                        'diunduh. Pratinjau dokumen tidak tersedia di dalam '
                        'aplikasi; buka lewat browser atau aplikasi berkas.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _Unreadable extends StatelessWidget {
  const _Unreadable({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 42, color: color),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Render a byte count the way a person would read it.
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
