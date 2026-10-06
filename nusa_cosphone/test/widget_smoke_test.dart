import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nusa_cosrent/data/models.dart';
import 'package:nusa_cosrent/theme/app_theme.dart';
import 'package:nusa_cosrent/widgets/common_widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('costume artwork handles an unbounded card height', (
    tester,
  ) async {
    const costume = Costume(
      id: 1,
      ownerId: 1,
      name: 'Nebula Witch',
      category: 'Fantasy',
      size: 'M',
      color: 'Purple',
      description: 'A complete set.',
      price: 85000,
      extraPricePerDay: 25000,
      isAvailable: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: CostumeArtwork(
              costume: costume,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
