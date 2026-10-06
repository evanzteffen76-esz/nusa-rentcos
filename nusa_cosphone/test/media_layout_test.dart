// Layout smoke tests for the screens that were rebuilt for media and payments.
//
// These exist because a layout mistake like an `Expanded` inside an unbounded
// `Row` passes `flutter analyze` and only shows up as a blank screen on a
// device. Each test pumps the real widget inside a real scrollable and asserts
// that nothing threw.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/data/models.dart';
import 'package:nusa_cosrent/features/media/media_picker.dart';
import 'package:nusa_cosrent/features/payments/payment_method_picker.dart';
import 'package:nusa_cosrent/features/payments/payment_summary_panel.dart';
import 'package:nusa_cosrent/state/app_state.dart';
import 'package:nusa_cosrent/theme/app_theme.dart';

/// Wrap [child] in the minimum an app-level widget needs.
Widget _host(Widget child, {AppState? state}) {
  final notifier = state ?? _StubState();
  return AppScope(
    notifier: notifier,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

/// A state object that exists only to satisfy `AppState.of`.
///
/// These tests exercise layout, so any repository call means something went
/// wrong and would fail loudly rather than silently returning empty data.
class _StubState extends AppState {
  _StubState() : super(_layoutRepository()) {
    isLoading = false;
  }
}

/// A repository that answers every call with an empty JSON body.
CosrentRepository _layoutRepository() => CosrentRepository(
  ApiClient(
    baseUrl: 'http://localhost:8000/api/v1',
    httpClient: MockClient((_) async => http.Response('{}', 200)),
    tokenStore: MemoryTokenStore(),
  ),
);

Costume _galleryCostume({
  int images = 3,
  int videos = 1,
  String? cover,
}) => Costume.fromMap(<String, Object?>{
  'id': 1,
  'owner_id': 3,
  'name': 'Nebula Witch',
  'character_name': 'Luna',
  'category': 'Fantasy',
  'size': 'M',
  'color': 'Ungu',
  'description': 'Lengkap dengan mantle, tiara, dan wand.',
  'price_per_day': 85000,
  'stock': 3,
  'is_published': true,
  'is_available': true,
  'cover_image_url': cover,
  'image_urls': <String>[
    for (var i = 0; i < images; i++) 'https://cdn.test/storage/$i.png',
  ],
  'video_urls': <String>[
    for (var i = 0; i < videos; i++) 'https://cdn.test/storage/$i.mp4',
  ],
});

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  group('media gallery', () {
    testWidgets('the strip lays out inside a vertical scroll view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: CostumeGalleryStrip(costume: _galleryCostume()),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('3 foto · 1 video'), findsOneWidget);
    });

    testWidgets('the strip renders without a video count when there are none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: CostumeGalleryStrip(costume: _galleryCostume(videos: 0)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Galeri'), findsOneWidget);
    });

    testWidgets('the strip collapses when a costume has no media', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: CostumeGalleryStrip(
              costume: _galleryCostume(images: 0, videos: 0),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Galeri'), findsNothing);
    });

    testWidgets('the viewer opens and pages through the gallery', (
      tester,
    ) async {
      final costume = _galleryCostume();
      await tester.pumpWidget(
        _host(MediaGalleryViewer(costume: costume)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1 / 4'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2 / 4'), findsOneWidget);
    });
  });

  group('payment picker', () {
    testWidgets('offers cash and explains why transfer is unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: PaymentMethodPicker(bankDetails: BankDetails.empty),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Bayar di lokasi'), findsOneWidget);
      expect(find.text('Transfer bank'), findsOneWidget);
      expect(
        find.textContaining('belum mengisi data rekening'),
        findsOneWidget,
      );
    });

    testWidgets('shows the supplier account once transfer is chosen', (
      tester,
    ) async {
      const bank = BankDetails(
        bankName: 'Mandiri',
        accountNumber: '1050021051887',
        accountHolder: 'Nadia',
        isComplete: true,
      );
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(child: PaymentMethodPicker(bankDetails: bank)),
        ),
      );
      expect(tester.takeException(), isNull);
      // The account is only revealed after the customer commits to a transfer.
      expect(find.text('Mandiri'), findsNothing);

      await tester.tap(find.text('Transfer bank'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mandiri'), findsOneWidget);
      expect(find.text('1050 0210 5188 7'), findsOneWidget);
      expect(find.text('Nadia'), findsOneWidget);
      expect(find.text('Bukti transfer'), findsOneWidget);
    });

    testWidgets('a transfer stays unselectable without an account', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const PaymentMethodPicker(bankDetails: BankDetails.empty)),
      );
      await tester.tap(find.text('Transfer bank'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Still on cash: the receipt section must not appear.
      expect(find.text('Bukti transfer'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('defaults to paying at the owner', (tester) async {
      await tester.pumpWidget(
        _host(const PaymentMethodPicker(bankDetails: BankDetails.empty)),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byIcon(Icons.check_circle),
        findsOneWidget,
        reason: 'the cash option is the pre-selected one',
      );
    });
  });

  group('payment summary', () {
    RentalOrder buildOrder({
      String method = 'pay_at_owner',
      String? code,
      bool proof = false,
      String? filename,
      bool canView = false,
    }) => RentalOrder.fromMap(<String, Object?>{
      'id': 10,
      'owner_id': 3,
      'customer_id': 7,
      'costume_id': 1,
      'status': 'pending',
      'rental_start': '2026-10-10',
      'rental_end': '2026-10-12',
      'total_price': 255000,
      'payment_method': method,
      'payment_code': code,
      'has_payment_proof': proof,
      'payment_proof_filename': filename,
      'can_view_payment_proof': canView,
      'owner_bank': <String, Object?>{
        'bank_name': 'Mandiri',
        'account_number': '1050021051887',
        'account_holder': 'Nadia',
        'is_complete': true,
      },
    });

    testWidgets('a cash booking shows its payment code', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: PaymentSummaryPanel(
              order: buildOrder(code: 'COSPAY-ABCD-1234'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('COSPAY-ABCD-1234'), findsOneWidget);
      expect(find.text('Kode pembayaran'), findsOneWidget);
    });

    testWidgets('a transfer without a receipt says so', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: PaymentSummaryPanel(order: buildOrder(method: 'bank_transfer')),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('belum diunggah'), findsOneWidget);
      expect(find.text('Lihat bukti transfer'), findsNothing);
    });

    testWidgets('a stored receipt offers to open it', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: PaymentSummaryPanel(
              order: buildOrder(
                method: 'bank_transfer',
                proof: true,
                filename: 'transfer.pdf',
                canView: true,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('transfer.pdf'), findsOneWidget);
      expect(find.text('Mandiri'), findsOneWidget);
    });

    testWidgets('a receipt the viewer may not read stays hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: PaymentSummaryPanel(
              order: buildOrder(method: 'bank_transfer', proof: true),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Lihat bukti transfer'), findsNothing);
      expect(
        find.textContaining('tidak dapat dibuka'),
        findsOneWidget,
        reason: 'the server refuses this download, so no button is offered',
      );
    });
  });
}