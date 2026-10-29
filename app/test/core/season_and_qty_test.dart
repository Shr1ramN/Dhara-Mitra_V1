import 'package:dhara_mitra/core/dates.dart';
import 'package:dhara_mitra/core/quantity.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Season', () {
    test('June to May by default', () {
      expect(Season.of(DateTime(2026, 6, 1)), const Season(2026));
      expect(Season.of(DateTime(2026, 5, 31)), const Season(2025));
      expect(Season.of(DateTime(2027, 1, 12)), const Season(2026));
    });

    test('custom start month', () {
      expect(
        Season.of(DateTime(2026, 3, 1), startMonth: 4),
        const Season(2025),
      );
      expect(
        Season.of(DateTime(2026, 4, 1), startMonth: 4),
        const Season(2026),
      );
    });

    test('label, code and bounds', () {
      const s = Season(2026);
      expect(s.label, '2026–27');
      expect(s.code, '2627');
      expect(const Season(1999).code, '9900');
      expect(s.firstDay(), DateTime(2026, 6));
      expect(s.lastDay(), DateTime(2027, 5, 31));
      expect(s.contains(DateTime(2027, 5, 31)), isTrue);
      expect(s.contains(DateTime(2027, 6, 1)), isFalse);
    });
  });

  group('dates', () {
    test('daysBetween counts calendar days', () {
      expect(daysBetween(DateTime(2026, 10, 2), DateTime(2026, 10, 23)), 21);
      expect(
        daysBetween(DateTime(2026, 10, 2, 23, 59), DateTime(2026, 10, 3, 0, 1)),
        1,
      );
      expect(daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
    });

    test('addDays crosses month ends', () {
      expect(addDays(DateTime(2026, 10, 2), 39), DateTime(2026, 11, 10));
    });
  });

  group('quantities', () {
    test('formatQty', () {
      expect(formatQty(1850), '1,850');
      expect(formatQty(2.5), '2.5');
      expect(formatQty(2.25), '2.25');
      expect(formatQty(1234567.891), '12,34,567.89');
    });

    test('parseQty', () {
      expect(parseQty('1,850'), 1850);
      expect(parseQty('2.5'), 2.5);
      expect(parseQty('x'), isNull);
    });

    test('acres and guntas', () {
      expect(toAcresGuntas(2.7), (2, 28));
      expect(toAcresGuntas(0.8), (0, 32));
      expect(fromAcresGuntas(2, 28), closeTo(2.7, 1e-9));
    });
  });
}
