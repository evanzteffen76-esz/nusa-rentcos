import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/features/auth/login_page.dart';
import 'package:nusa_cosrent/features/customer/catalog_page.dart';
import 'package:nusa_cosrent/features/customer/costume_detail_page.dart';
import 'package:nusa_cosrent/features/orders/order_detail_page.dart';
import 'package:nusa_cosrent/features/shell/main_shell.dart';
import 'package:nusa_cosrent/state/app_state.dart';
import 'package:nusa_cosrent/theme/app_theme.dart';

const _owner = {
  'id': 2,
  'name': 'Nadia Cosrent',
  'username': 'owner',
  'email': 'owner@cosplaynusa.test',
  'role': 'owner',
  'is_admin': false,
  'is_cosrent_owner': true,
};

const _customer = {
  'id': 1,
  'name': 'Raka Pradana',
  'username': 'customer',
  'email': 'customer@cosplaynusa.test',
  'role': 'customer',
  'is_admin': false,
  'is_cosrent_owner': false,
};

const _admin = {
  'id': 3,
  'name': 'Admin CosplayNusa',
  'username': 'admin',
  'email': 'admin@cosplaynusa.test',
  'role': 'admin',
  'is_admin': true,
  'is_cosrent_owner': false,
};

const _costume = {
  'id': 7,
  'owner_id': 2,
  'name': 'Nebula Witch Signature Set',
  'character_name': 'Luna Starweaver',
  'category': 'Fantasy',
  'size': 'M',
  'color': 'Ungu / emas',
  'description': 'Lengkap dengan mantle, tiara, wand, dan clutch karakter.',
  'image_url': null,
  'price_per_day': 85000,
  'stock': 3,
  'is_published': true,
  'is_available': true,
};

const _order = {
  'id': 10,
  'owner_id': 2,
  'customer_id': 1,
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
  'can_approve': true,
  'can_reject': true,
  'can_return': false,
  'can_report_lost': true,
  'can_complete': false,
  'can_report_stain': false,
  'customer': _customer,
  'owner': _owner,
  'costume': _costume,
  'issue': null,
};

const _stats = {
  'totalOrders': 1,
  'activeOrders': 1,
  'pendingOrders': 1,
  'availableCostumes': 1,
  'openIssues': 0,
  'totalUsers': 3,
  'customerUsers': 1,
  'ownerUsers': 1,
};

http.Response _json(Object payload, [int status = 200]) => http.Response(
  jsonEncode(payload),
  status,
  headers: {'content-type': 'application/json'},
);

MockClient _api() => MockClient((request) async {
  final path = request.url.path;
  if (path.endsWith('/auth/login')) {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final login = body['login'].toString();
    final user = switch (login) {
      'owner' => _owner,
      'admin' => _admin,
      _ => _customer,
    };
    return _json({'token': 'token-$login', 'user': user});
  }
  if (path.endsWith('/dashboard')) {
    return _json({'data': _stats});
  }
  if (path.endsWith('/costumes/categories')) {
    return _json({
      'data': ['Fantasy', 'School'],
    });
  }
  if (path.endsWith('/costumes') ||
      path.endsWith('/admin/costumes') ||
      path.endsWith('/owner/costumes')) {
    return _json({
      'data': [_costume],
    });
  }
  if (path.contains('/issues')) {
    return _json({'data': <Object>[]});
  }
  if (path.endsWith('/users')) {
    return _json({
      'data': [_customer, _owner, _admin],
    });
  }
  if (path.endsWith('/orders') ||
      path.endsWith('/customer/orders') ||
      path.endsWith('/owner/orders') ||
      path.endsWith('/admin/orders')) {
    return _json({
      'data': [_order],
    });
  }
  if (path.contains('/orders/')) {
    return _json({'data': _order});
  }
  if (path.contains('/costumes/')) {
    return _json({'data': _costume});
  }
  return _json({}, 404);
});

Future<void> _pumpRole(
  WidgetTester tester,
  String login, {
  bool desktop = false,
}) async {
  tester.view.physicalSize = desktop
      ? const Size(1280, 800)
      : const Size(1170, 2532);
  tester.view.devicePixelRatio = desktop ? 1 : 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final repository = CosrentRepository(
    ApiClient(
      baseUrl: 'http://localhost:8000/api/v1',
      httpClient: _api(),
      tokenStore: MemoryTokenStore(),
    ),
  );
  await repository.initialize();
  final user = await repository.authenticate(login, 'password');
  final state = AppState(repository)
    ..currentUser = user
    ..isLoading = false;

  await tester.pumpWidget(
    AppScope(
      notifier: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MainShell(user: user!),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('customer pages render without exceptions', (tester) async {
    await _pumpRole(tester, 'customer');
  });

  testWidgets('owner pages render without exceptions', (tester) async {
    await _pumpRole(tester, 'owner');
  });

  testWidgets('admin pages render without exceptions', (tester) async {
    await _pumpRole(tester, 'admin');
  });

  testWidgets('login and registration pages render without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final state = AppState(
      CosrentRepository(
        ApiClient(
          baseUrl: 'http://localhost:8000/api/v1',
          httpClient: _api(),
          tokenStore: MemoryTokenStore(),
        ),
      ),
    )..isLoading = false;

    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    final registerLink = find.text('Belum punya akun? Daftar sekarang');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Buat akun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer order and costume detail screens open cleanly', (
    tester,
  ) async {
    await _pumpRole(tester, 'customer');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pesanan'),
      ),
    );
    await _settle(tester);
    final orderId = find.text('Order #NC-0010', skipOffstage: false);
    expect(orderId, findsOneWidget);
    await tester.tap(orderId);
    await _settle(tester);
    expect(find.byType(OrderDetailPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Jelajah'),
      ),
    );
    await _settle(tester);
    final costumeName = find.descendant(
      of: find.byType(CatalogPage),
      matching: find.text('Luna Starweaver'),
    );
    expect(costumeName, findsOneWidget);
    await tester.tap(costumeName);
    await _settle(tester);
    expect(find.byType(CostumeDetailPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner costume form opens cleanly', (tester) async {
    await _pumpRole(tester, 'owner');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Kostum'),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Tambah kostum'));
    await _settle(tester);
    expect(
      find.text(
        'Lengkapi informasi agar customer dapat menemukan kostum yang tepat.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin user form opens cleanly', (tester) async {
    await _pumpRole(tester, 'admin');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Pengguna'),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Tambah pengguna'));
    await _settle(tester);
    expect(
      find.text('Atur informasi dan role akses pengguna.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final login in ['customer', 'owner', 'admin']) {
    testWidgets('$login pages render on desktop without exceptions', (
      tester,
    ) async {
      await _pumpRole(tester, login, desktop: true);
    });
  }
}
