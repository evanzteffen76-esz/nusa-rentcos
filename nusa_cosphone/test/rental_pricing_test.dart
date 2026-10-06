import 'package:flutter_test/flutter_test.dart';
import 'package:nusa_cosrent/data/models.dart';

/// The pricing rule has to stay byte-for-byte compatible with the server's
/// `RentalOrder::priceFor`, because the client only ever shows an estimate and
/// the server recomputes the authoritative total.
void main() {
  group('rental period arithmetic', () {
    test('a period is counted inclusively and never below one day', () {
      expect(daysBetween(DateTime(2026, 10, 1), DateTime(2026, 10, 1)), 1);
      expect(daysBetween(DateTime(2026, 10, 1), DateTime(2026, 10, 3)), 3);
      expect(daysBetween(DateTime(2026, 10, 1), DateTime(2026, 10, 4)), 4);
      // An end date before the start can only come from bad input; the server
      // clamps to one day and so must the client.
      expect(daysBetween(DateTime(2026, 10, 3), DateTime(2026, 10, 1)), 1);
    });

    test('the period end is the day before the anniversary of the last day', () {
      final start = DateTime(2026, 10, 1, 13, 45);
      expect(rentalPeriodEnd(start, 3), DateTime(2026, 10, 3));
      expect(rentalPeriodEnd(start, 4), DateTime(2026, 10, 4));
      expect(rentalPeriodEnd(start, 30), DateTime(2026, 10, 30));
    });

    test('a period shorter than the minimum is stretched, not shortened', () {
      final start = DateTime(2026, 10, 1);
      expect(rentalPeriodEnd(start, 1), DateTime(2026, 10, 3));
      expect(rentalPeriodEnd(start, 0), DateTime(2026, 10, 3));
      expect(rentalPeriodEnd(start, -5), DateTime(2026, 10, 3));
    });

    test('the time of day never leaks into the period end', () {
      final end = rentalPeriodEnd(DateTime(2026, 10, 1, 23, 59), 3);
      expect(end.hour, 0);
      expect(end.minute, 0);
      expect(end.day, 3);
    });
  });

  group('extra days', () {
    test('the included period costs nothing extra', () {
      expect(extraDaysFor(1), 0);
      expect(extraDaysFor(2), 0);
      expect(extraDaysFor(kFreeRentalDays), 0);
    });

    test('every day past the included period is billable', () {
      expect(extraDaysFor(4), 1);
      expect(extraDaysFor(9), 6);
      expect(extraDaysFor(kMaxRentalDays), kMaxRentalDays - kFreeRentalDays);
    });
  });

  group('priceFor mirrors the server', () {
    test('the base price covers the included period on its own', () {
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 20000,
          days: 1,
        ),
        100000,
      );
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 20000,
          days: 3,
        ),
        100000,
      );
    });

    test('days past the included period add the extra rate', () {
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 20000,
          days: 4,
        ),
        120000,
      );
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 20000,
          days: 6,
        ),
        160000,
      );
    });

    test('the whole amount scales with the quantity', () {
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 20000,
          days: 5,
          quantity: 2,
        ),
        280000,
      );
    });

    test('a costume with no extra rate never charges beyond the included period', () {
      expect(
        RentalOrder.priceFor(
          basePrice: 100000,
          extraRate: 0,
          days: kMaxRentalDays,
          quantity: 2,
        ),
        200000,
      );
    });
  });

  group('Costume estimates', () {
    const costume = Costume(
      id: 1,
      ownerId: 1,
      name: 'Nebula Witch',
      category: 'Fantasy',
      size: 'M',
      color: 'Ungu',
      description: '',
      price: 100000,
      extraPricePerDay: 20000,
      isAvailable: true,
    );

    test('the estimate agrees with the server rule', () {
      expect(costume.estimateTotal(days: 3), 100000);
      expect(costume.estimateTotal(days: 4), 120000);
      expect(costume.estimateTotal(days: 5, quantity: 2), 280000);
    });

    test('billable days match the free helpers', () {
      expect(costume.billableDays(3), extraDaysFor(3));
      expect(costume.billableDays(7), extraDaysFor(7));
    });
  });

  group('Costume parsing', () {
    test('the extra rate falls back to the base price until the API sends it', () {
      final costume = Costume.fromMap(<String, Object?>{
        'id': 1,
        'name': 'Nebula Witch',
        'price_per_day': 85000,
      });
      expect(costume.price, 85000);
      expect(costume.extraPricePerDay, 85000);
    });

    test('an explicit extra rate wins, including zero', () {
      final costume = Costume.fromMap(<String, Object?>{
        'id': 1,
        'name': 'Nebula Witch',
        'price_per_day': 85000,
        'extra_price_per_day': 0,
      });
      expect(costume.extraPricePerDay, 0);
    });
  });

  group('RentalOrder breakdown parsing', () {
    test('the server breakdown is read as sent', () {
      final order = RentalOrder.fromMap(<String, Object?>{
        'id': 1,
        'costume_id': 1,
        'customer_id': 1,
        'owner_id': 2,
        'status': 'approved',
        'rental_start': '2026-10-01',
        'rental_end': '2026-10-05',
        'quantity': 2,
        'duration_in_days': 5,
        'price_per_day': 100000,
        'extra_price_per_day': 20000,
        'extra_days': 2,
        'included_fee_total': 200000,
        'extra_fee_total': 80000,
        'included_rental_days': 3,
        'total_price': 280000,
      });
      expect(order.durationInDays, 5);
      expect(order.extraDays, 2);
      expect(order.includedFeeTotal, 200000);
      expect(order.extraFeeTotal, 80000);
      expect(order.includedRentalDays, 3);
      expect(order.totalPrice, 280000);
    });

    test('a trimmed payload falls back to what the dates imply', () {
      final order = RentalOrder.fromMap(<String, Object?>{
        'id': 1,
        'costume_id': 1,
        'customer_id': 1,
        'owner_id': 2,
        'status': 'approved',
        'rental_start': '2026-10-01',
        'rental_end': '2026-10-06',
        'quantity': 2,
        'price_per_day': 100000,
        'extra_price_per_day': 20000,
        'total_price': 320000,
      });
      expect(order.durationInDays, 6);
      expect(order.extraDays, 3);
      expect(order.includedFeeTotal, 200000);
      expect(order.extraFeeTotal, 120000);
      expect(order.includedRentalDays, kFreeRentalDays);
    });
  });
}
