import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusa_cosrent/data/api_client.dart';
import 'package:nusa_cosrent/data/cosrent_repository.dart';
import 'package:nusa_cosrent/features/auth/login_page.dart';
import 'package:nusa_cosrent/state/app_state.dart';
import 'package:nusa_cosrent/theme/app_theme.dart';

/// Real-world viewports the auth screens must survive.
const _devices = <String, Size>{
  'small phone (320x568)': Size(320, 568),
  'phone (390x844)': Size(390, 844),
  'large phone (430x932)': Size(430, 932),
  'landscape phone (844x390)': Size(844, 390),
  'foldable open (673x841)': Size(673, 841),
  'tablet portrait (600x960)': Size(600, 960),
  'tablet landscape (1024x768)': Size(1024, 768),
  'desktop (1280x800)': Size(1280, 800),
  'wide desktop (1920x1080)': Size(1920, 1080),
};

MockClient _unusedApi() => MockClient(
  (_) async => http.Response(
    jsonEncode({'message': 'unused'}),
    200,
    headers: {'content-type': 'application/json'},
  ),
);

AppState _state() {
  return AppState(
    CosrentRepository(
      ApiClient(
        baseUrl: 'http://localhost:8000/api/v1',
        httpClient: _unusedApi(),
        tokenStore: MemoryTokenStore(),
      ),
    ),
  )..isLoading = false;
}

Future<void> _pumpAuth(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    AppScope(
      notifier: _state(),
      child: MaterialApp(theme: AppTheme.light(), home: page),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpRegister(WidgetTester tester) async {
  await tester.pumpWidget(
    AppScope(
      notifier: _state(),
      child: MaterialApp(theme: AppTheme.light(), home: const RegisterPage()),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  for (final entry in _devices.entries) {
    testWidgets('login page adapts on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAuth(tester, const LoginPage());
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('register page adapts on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegister(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsNWidgets(5));
    });
  }

  testWidgets('login page respects a large system font scale', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: AppScope(
          notifier: _state(),
          child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('login page is fully reachable by scrolling on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpAuth(tester, const LoginPage());

    final registerLink = find.text('Belum punya akun? Daftar sekarang');
    expect(registerLink, findsOneWidget);

    // The call-to-action must not be stranded below the fold.
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
