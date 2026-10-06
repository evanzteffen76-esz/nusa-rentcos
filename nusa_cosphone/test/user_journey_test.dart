// End-to-end walkthrough of every user-facing activity in the app:
// daftar akun -> login -> ajukan pesanan -> login owner -> setujui pesanan
// -> update akun -> logout -> hapus akun.
//
// Order *submission* is driven through the repository rather than by tapping
// the Material date-range picker, which is not reliably driveable from a
// widget test. Everything else is driven through the real widgets.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/features/profile/profile_page.dart';
import 'package:nusa_cosrent/main.dart';
import 'package:nusa_cosrent/state/app_state.dart';

/// Minimal stateful stand-in for the Laravel API.
class _FakeBackend {
  _FakeBackend() {
    final owner = _addUser(
      name: 'Nadia Cosrent',
      username: 'owner',
      email: 'owner@cosplaynusa.test',
      isOwner: true,
    );
    costumes.add({
      'id': 7,
      'owner_id': owner['id'],
      'name': 'Nebula Witch Signature Set',
      'character_name': 'Luna Starweaver',
      'category': 'Fantasy',
      'size': 'M',
      'color': 'Ungu / emas',
      'description': 'Lengkap dengan mantle, tiara, dan wand.',
      'image_url': null,
      'price_per_day': 85000,
      'stock': 3,
      'is_published': true,
      'is_available': true,
    });
  }

  final List<Map<String, Object?>> users = [];
  final List<Map<String, Object?>> orders = [];
  final List<Map<String, Object?>> costumes = [];
  final Map<String, int> tokenToUser = {};
  var _nextUserId = 1;
  var _nextOrderId = 1;
  var _nextToken = 1;

  Map<String, Object?> _addUser({
    required String name,
    required String username,
    required String email,
    bool isOwner = false,
    bool isAdmin = false,
  }) {
    final user = <String, Object?>{
      'id': _nextUserId++,
      'name': name,
      'username': username,
      'email': email,
      'password': 'password',
      'is_admin': isAdmin,
      'is_cosrent_owner': isOwner,
    };
    users.add(user);
    return user;
  }

  Map<String, Object?>? _userForToken(String? token) {
    if (token == null) return null;
    final id = tokenToUser[token];
    if (id == null) return null;
    return users.firstWhere((u) => u['id'] == id);
  }

  /// Mirrors App\Http\Resources\UserResource.
  Map<String, Object?> _userPayload(Map<String, Object?> u) => {
    'id': u['id'],
    'name': u['name'],
    'username': u['username'],
    'email': u['email'],
    'role': u['is_admin'] == true
        ? 'admin'
        : (u['is_cosrent_owner'] == true ? 'owner' : 'customer'),
    'is_admin': u['is_admin'],
    'is_cosrent_owner': u['is_cosrent_owner'],
    'created_at': '2026-09-01T00:00:00.000000Z',
  };

  /// Mirrors App\Http\Resources\RentalOrderResource.
  Map<String, Object?> _orderPayload(Map<String, Object?> o) => {
    ...o,
    'duration_in_days': o['duration_in_days'] ?? 3,
    'can_approve': o['status'] == 'pending',
    'can_reject': o['status'] == 'pending',
    'can_return': false,
    'can_report_lost': o['status'] == 'approved',
    'can_complete': o['status'] == 'returned',
    'can_report_stain': false,
    'is_return_overdue': false,
    'price_per_day': 100000,
    'extra_price_per_day': 20000,
    'extra_days': o['extra_days'] ?? 0,
    'included_fee_total': o['included_fee_total'] ?? 100000,
    'extra_fee_total': o['extra_fee_total'] ?? 0,
    'included_rental_days': 3,
    'issue': null,
    'owner': _userPayload(users.firstWhere((u) => u['id'] == o['owner_id'])),
    'customer': _userPayload(
      users.firstWhere((u) => u['id'] == o['customer_id']),
    ),
    'costume': costumes.firstWhere((c) => c['id'] == o['costume_id']),
  };

  /// The length the last approval sent, so a test can assert what the picker
  /// asked the server for.
  int? lastApprovedDays;

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  MockClient get client => MockClient((request) async => _route(request));

  Future<http.Response> _route(http.Request request) async {
    final path = request.url.path;
    final method = request.method;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    final auth = request.headers['authorization']?.replaceFirst('Bearer ', '');
    final me = _userForToken(auth);

    http.Response ok(Object payload) => _json({'data': payload});
    http.Response fail(
      String message,
      int status, [
      String field = 'message',
    ]) => _json({
      'message': message,
      'errors': {
        field: [message],
      },
    }, status);

    if (method == 'GET' && path.endsWith('/health')) {
      return _json({'status': 'ok', 'database': 'mysql'});
    }

    // --- public auth ---
    if (path.endsWith('/auth/register')) {
      if (users.any((u) => u['email'] == body['email'])) {
        return fail('Email sudah digunakan.', 422, 'email');
      }
      final user = _addUser(
        name: body['name'] as String,
        username: (body['username'] as String?) ?? 'user',
        email: body['email'] as String,
        isOwner: body['account_type'] == 'cosrent_owner',
      );
      final token = 'tok-${_nextToken++}';
      tokenToUser[token] = user['id']! as int;
      return _json({
        'token': token,
        'token_type': 'Bearer',
        'user': _userPayload(user),
      }, 201);
    }

    if (path.endsWith('/auth/login')) {
      final login = (body['login'] ?? '').toString();
      final user = users.cast<Map<String, Object?>?>().firstWhere(
        (u) => u!['email'] == login || u['username'] == login,
        orElse: () => null,
      );
      if (user == null || user['password'] != body['password']) {
        return fail('Email atau password salah.', 422, 'login');
      }
      final token = 'tok-${_nextToken++}';
      tokenToUser[token] = user['id']! as int;
      return _json({
        'token': token,
        'token_type': 'Bearer',
        'user': _userPayload(user),
      });
    }

    if (me == null) return fail('Unauthenticated.', 401);

    // --- authenticated ---
    if (path.endsWith('/auth/me')) return ok(_userPayload(me));

    if (path.endsWith('/auth/logout')) {
      tokenToUser.remove(auth);
      return _json({'message': 'Token revoked successfully.'});
    }

    if (path.endsWith('/auth/profile') && method == 'PATCH') {
      final name = body['name'];
      final email = body['email'];
      final username = body['username'];
      if (email != null &&
          users.any((u) => u['email'] == email && u['id'] != me['id'])) {
        return fail('Email sudah digunakan.', 422, 'email');
      }
      if (username != null &&
          username.isNotEmpty &&
          users.any((u) => u['username'] == username && u['id'] != me['id'])) {
        return fail('Username sudah digunakan.', 422, 'username');
      }
      if (name != null) me['name'] = name;
      if (email != null) me['email'] = email;
      if (username != null && username.isNotEmpty) me['username'] = username;
      if ((body['password'] ?? '') != '') {
        if (body['current_password'] != me['password']) {
          return fail('Password saat ini salah.', 422, 'current_password');
        }
        me['password'] = body['password'];
      }
      return ok(_userPayload(me));
    }

    if (path.endsWith('/auth/account') && method == 'DELETE') {
      if (body['password'] != me['password']) {
        return fail('Password salah.', 422, 'password');
      }
      final active = orders.where(
        (o) =>
            (o['owner_id'] == me['id'] || o['customer_id'] == me['id']) &&
            (o['status'] == 'pending' || o['status'] == 'approved'),
      );
      if (active.isNotEmpty) {
        return fail(
          'Selesaikan proses sewa yang sedang berjalan sebelum menghapus akun.',
          422,
          'account',
        );
      }
      users.removeWhere((u) => u['id'] == me['id']);
      return _json({'message': 'Account deleted successfully.'});
    }

    if (path.endsWith('/dashboard') || path.endsWith('/admin/dashboard')) {
      return ok({'totalOrders': orders.length, 'pendingOrders': 0});
    }

    if (path.endsWith('/costumes/categories')) {
      return ok({
        'data': ['Fantasy'],
      });
    }

    if (path.endsWith('/costumes') ||
        path.endsWith('/owner/costumes') ||
        path.endsWith('/admin/costumes')) {
      return _json({'data': costumes});
    }

    final costumeMatch = RegExp(r'/costumes/(\d+)$').firstMatch(path);
    if (costumeMatch != null) {
      final id = int.parse(costumeMatch.group(1)!);
      final costume = costumes.cast<Map<String, Object?>?>().firstWhere(
        (c) => c!['id'] == id,
        orElse: () => null,
      );
      return costume == null ? fail('Not found.', 404) : ok(costume);
    }

    // create order
    final createMatch = RegExp(r'/customer/costumes/(\d+)/orders$')
        .firstMatch(path);
    if (createMatch != null && method == 'POST') {
      final costumeId = int.parse(createMatch.group(1)!);
      final costume = costumes.firstWhere((c) => c['id'] == costumeId);
      final order = <String, Object?>{
        'id': _nextOrderId++,
        'owner_id': costume['owner_id'],
        'customer_id': me['id'],
        'costume_id': costumeId,
        'status': 'pending',
        'quantity': body['quantity'] ?? 1,
        'rental_start': body['rental_start'],
        'rental_end': body['rental_end'],
        'requested_rental_start': body['rental_start'],
        'requested_rental_end': body['rental_end'],
        'total_price': 255000,
        'customer_note': body['customer_note'] ?? '',
        'owner_note': '',
      };
      orders.add(order);
      return _json({'data': _orderPayload(order)}, 201);
    }

    if (path.endsWith('/orders') ||
        path.endsWith('/customer/orders') ||
        path.endsWith('/owner/orders') ||
        path.endsWith('/admin/orders')) {
      final mine = orders
          .where(
            (o) => me['is_cosrent_owner'] == true || me['is_admin'] == true
                ? true
                : o['customer_id'] == me['id'],
          )
          .toList();
      return _json({'data': mine.map(_orderPayload).toList()});
    }

    if (path.contains('/issues')) return _json({'data': <Object>[]});
    if (path.endsWith('/users')) {
      return _json({'data': users.map(_userPayload).toList()});
    }

    // approve / reject / complete
    final decision = RegExp(r'/orders/(\d+)/(approve|reject|complete)$')
        .firstMatch(path);
    if (decision != null) {
      final order = orders.firstWhere(
        (o) => o['id'] == int.parse(decision.group(1)!),
      );
      order['status'] = switch (decision.group(2)) {
        'approve' => 'approved',
        'reject' => 'rejected',
        _ => 'completed',
      };
      if ((body['owner_note'] ?? '') != '') {
        order['owner_note'] = body['owner_note'];
      }
      // Approving may carry the length the owner granted; the mock prices the
      // order with the same rule the real server uses.
      final grantedDays = body['rental_days'];
      if (decision.group(2) == 'approve' && grantedDays != null) {
        final days = int.parse('$grantedDays');
        lastApprovedDays = days;
        final start = DateTime.now();
        order['rental_start'] = _dateOnly(start);
        order['rental_end'] = _dateOnly(
          start.add(Duration(days: days - 1)),
        );
        order['quantity'] = days > 3 ? 2 : 1;
        order['duration_in_days'] = days;
        order['extra_days'] = days > 3 ? days - 3 : 0;
        order['extra_fee_total'] = (days > 3 ? (days - 3) * 20000 : 0) *
            (order['quantity'] as int);
        order['included_fee_total'] = 100000 * (order['quantity'] as int);
        order['total_price'] =
            (order['included_fee_total'] as int) +
                (order['extra_fee_total'] as int);
      }
      return ok(_orderPayload(order));
    }

    final showMatch = RegExp(r'/orders/(\d+)$').firstMatch(path);
    if (showMatch != null) {
      final order = orders.firstWhere(
        (o) => o['id'] == int.parse(showMatch.group(1)!),
      );
      return ok(_orderPayload(order));
    }

    return fail('Not found.', 404);
  }

  static http.Response _json(Object payload, [int status = 200]) =>
      http.Response(
        jsonEncode(payload),
        status,
        headers: {'content-type': 'application/json'},
      );
}

AppState _stateFor(_FakeBackend backend) {
  return AppState(
    CosrentRepository(
      ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: backend.client,
        tokenStore: MemoryTokenStore(),
      ),
    ),
  )..isLoading = false;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Pins the test to a phone-sized viewport. The default 800x600 test surface
/// crosses the 760px rail breakpoint in MainShell and would swap the bottom
/// NavigationBar for a NavigationRail.
void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Scrolls the profile list until [label] is built. The list is lazy, so the
/// action rows near the bottom do not exist in the tree until scrolled to.
Future<void> _scrollTo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    250,
    scrollable: find
        .descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await _settle(tester);
}

/// Scrolls any visible list until [label] is on screen.
Future<void> _scrollToIn(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await _settle(tester);
}

/// Lets a SnackBar time out so it stops covering the bottom-row actions.
Future<void> _waitForSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('full customer and owner journey across every activity', (
    tester,
  ) async {
    _usePhone(tester);

    final backend = _FakeBackend();
    final state = _stateFor(backend);

    await tester.pumpWidget(CosplayNusaApp(state: state));
    await _settle(tester);

    // 1. Landing page is the login screen.
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.text('Masuk ke CosplayNusa'), findsOneWidget);

    // 2. Daftar akun -> RegisterPage.
    final registerLink = find.text('Belum punya akun? Daftar sekarang');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await _settle(tester);
    expect(find.text('Buat akun'), findsOneWidget);
    expect(find.text('Mulai petualanganmu'), findsOneWidget);

    // Fill the registration form.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama lengkap'),
      'Raka Pradana',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'raka',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'raka@cosplaynusa.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi password'),
      'password',
    );
    await _settle(tester);

    final submit = find.text('Daftar sekarang');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await _settle(tester);

    // Registration creates the account and signs it straight in, so the gate
    // swaps to the customer shell without a second login.
    expect(
      backend.users.any((u) => u['email'] == 'raka@cosplaynusa.test'),
      isTrue,
    );
    expect(find.textContaining('Hai, Raka'), findsOneWidget);

    // 3. Logout returns to the login screen.
    await _waitForSnackBar(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await _settle(tester);
    await _scrollTo(tester, 'Keluar dari akun');
    await tester.tap(find.text('Keluar dari akun'));
    await _settle(tester);
    await tester.tap(find.text('Keluar'));
    await _settle(tester);
    expect(find.text('Selamat datang kembali'), findsOneWidget);

    // 4. Login again using the newly created username (not the email).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email atau username'),
      'raka',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );
    await _settle(tester);

    await tester.tap(find.text('Masuk ke CosplayNusa'));
    await tester.pumpAndSettle();
    await _settle(tester);

    // Lands on the customer home page.
    expect(find.textContaining('Hai, Raka'), findsOneWidget);

    // 5. Navigate to the catalog, then into a costume detail page.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Jelajah'),
      ),
    );
    await _settle(tester);
    expect(find.text('Luna Starweaver'), findsOneWidget);

    await tester.tap(find.text('Luna Starweaver'));
    await _settle(tester);
    expect(find.text('Detail kostum'), findsOneWidget);
    // The booking button starts disabled until a date range is chosen.
    expect(find.text('Pilih tanggal dulu'), findsOneWidget);

    // 5. Mengajukan pesanan. The date-range picker that fronts this form is
    // not reliably driveable from a widget test, so the booking call itself
    // goes through the repository; the UI above proves the route is reachable.
    // Tap the back button by type rather than `pageBack()`: the helper looks
    // the tooltip up by its English text, and this app localizes to Indonesian
    // where it reads "Kembali".
    await tester.tap(find.byType(BackButton).first);
    await _settle(tester);
    await state.repository.createOrder(
      costumeId: 7,
      startDate: DateTime.now(),
      days: 3,
      notes: 'Event cosplay',
    );
    expect(backend.orders, hasLength(1));
    expect(backend.orders.single['status'], 'pending');
    expect(backend.orders.single['customer_note'], 'Event cosplay');

    // The new order shows up on the customer's order list page once the list
    // is refreshed (the page was built before the booking existed).
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pesanan'),
      ),
    );
    await _settle(tester);
    await tester.fling(
      find.byType(RefreshIndicator).last,
      const Offset(0, 320),
      1000,
    );
    await _settle(tester);
    expect(find.text('Order #NC-0001'), findsOneWidget);
    expect(find.text('Menunggu'), findsWidgets);
  });
  testWidgets('owner can approve a submitted order', (tester) async {
    _usePhone(tester);
    final backend = _FakeBackend();
    // Seed a pending customer order for the owner to act on.
    final customer = backend.users.first;
    backend.orders.add({
      'id': 1,
      'owner_id': backend.users.last['id'],
      'customer_id': customer['id'],
      'costume_id': 7,
      'status': 'pending',
      'quantity': 1,
      'rental_start': '2026-10-01',
      'rental_end': '2026-10-03',
      'requested_rental_start': '2026-10-01',
      'requested_rental_end': '2026-10-03',
      'total_price': 255000,
      'customer_note': 'Event cosplay',
      'owner_note': '',
    });

    final state = _stateFor(backend);
    await state.login('owner', 'password');
    expect(state.currentUser!.isOwner, isTrue);

    await tester.pumpWidget(CosplayNusaApp(state: state));
    await _settle(tester);

    // Owner lands straight on the owner dashboard.
    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pesanan'),
      ),
    );
    await _settle(tester);
    expect(find.text('Nebula Witch Signature Set'), findsWidgets);

    // "Tinjau" opens the order detail screen with the owner actions.
    await tester.tap(find.text('Tinjau').first);
    await _settle(tester);
    await _scrollToIn(tester, 'Setujui');
    expect(find.text('Aksi owner'), findsOneWidget);

    // The owner can grant more than the included period; the extra days show
    // up as a charge before anything is approved.
    expect(find.text('Lama sewa'), findsOneWidget);
    expect(
      find.text('3 hari sudah termasuk dalam harga dasar'),
      findsOneWidget,
    );
    await _scrollToIn(tester, 'Lama sewa');
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await _settle(tester);
    expect(backend.lastApprovedDays, isNull);
    expect(find.textContaining('1 hari tambahan'), findsOneWidget);

    await tester.tap(find.text('Setujui'));
    await _settle(tester);

    // Approve is a two-step flow: confirm, then optionally attach a note.
    expect(find.text('Ya, lanjutkan'), findsOneWidget);
    await tester.tap(find.text('Ya, lanjutkan'));
    await _settle(tester);
    expect(find.text('Catatan owner'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    await _settle(tester);

    expect(backend.orders.first['status'], 'approved');
    // The granted length reached the server and priced the extra day.
    expect(backend.lastApprovedDays, 4);
    expect(backend.orders.first['extra_days'], 1);
    expect(backend.orders.first['extra_fee_total'], 20000);
    expect(backend.orders.first['total_price'], 220000);
  });

  testWidgets('user can update their profile from the profile page', (
    tester,
  ) async {
    _usePhone(tester);
    final backend = _FakeBackend();
    final state = _stateFor(backend);
    await state.login('owner', 'password');

    await tester.pumpWidget(CosplayNusaApp(state: state));
    await _settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await _settle(tester);
    expect(find.text('Profil'), findsWidgets);

    // The edit button now opens a real form.
    await tester.tap(find.byTooltip('Edit profil'));
    await _settle(tester);
    expect(find.text('Edit profil'), findsOneWidget);
    expect(find.text('Informasi akun'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama lengkap'),
      'Nadia_updated',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'nadia.baru@cosplaynusa.test',
    );
    await _settle(tester);

    final save = find.text('Simpan perubahan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _settle(tester);

    expect(backend.users.last['name'], 'Nadia_updated');
    expect(backend.users.last['email'], 'nadia.baru@cosplaynusa.test');
    expect(state.currentUser!.name, 'Nadia_updated');
    expect(find.text('Nadia_updated'), findsWidgets);
  });

  testWidgets('user can log out and lands back on the login page', (
    tester,
  ) async {
    _usePhone(tester);
    final backend = _FakeBackend();
    final state = _stateFor(backend);
    await state.login('owner', 'password');

    await tester.pumpWidget(CosplayNusaApp(state: state));
    await _settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await _settle(tester);
    await _scrollTo(tester, 'Keluar dari akun');
    await tester.tap(find.text('Keluar dari akun'));
    await _settle(tester);
    await tester.tap(find.text('Keluar'));
    await _settle(tester);

    expect(state.currentUser, isNull);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });

  testWidgets('user can delete their account and lands back on login', (
    tester,
  ) async {
    _usePhone(tester);
    final backend = _FakeBackend();
    final state = _stateFor(backend);
    await state.login('owner', 'password');
    final emailBefore = state.currentUser!.email;

    await tester.pumpWidget(CosplayNusaApp(state: state));
    await _settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await _settle(tester);

    await _scrollTo(tester, 'Hapus akun');
    await tester.tap(find.text('Hapus akun'));
    await _settle(tester);

    // The dialog must spell out the cascade before it can be confirmed.
    expect(find.text('Hapus akun permanen?'), findsOneWidget);
    final confirmButton = find.widgetWithText(FilledButton, 'Hapus permanen');
    expect(
      tester.widget<FilledButton>(confirmButton).onPressed,
      isNull,
      reason: 'confirm stays disabled until a password is typed',
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Password akun'),
      'password',
    );
    await _settle(tester);
    await tester.tap(confirmButton);
    await _settle(tester);

    expect(backend.users.any((u) => u['email'] == emailBefore), isFalse);
    expect(state.currentUser, isNull);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });
}
