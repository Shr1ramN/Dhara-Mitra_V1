import 'package:dhara_mitra/features/labour/domain/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'selected date determines complete day, Monday week, month and year',
    () {
      final anchor = DateTime(2026, 11, 5, 18, 30);
      for (final (period, start, end) in [
        ('day', DateTime(2026, 11, 5), DateTime(2026, 11, 5)),
        ('week', DateTime(2026, 11, 2), DateTime(2026, 11, 8)),
        ('month', DateTime(2026, 11), DateTime(2026, 11, 30)),
        ('year', DateTime(2026), DateTime(2026, 12, 31)),
      ]) {
        final r = labourReportPeriod(anchor, period);
        expect(r.start, start);
        expect(r.end, end);
        expect(
          inReportPeriod(
            DateTime(end.year, end.month, end.day, 23, 59),
            r.start,
            r.end,
          ),
          isTrue,
        );
        expect(
          inReportPeriod(
            start.subtract(const Duration(seconds: 1)),
            r.start,
            r.end,
          ),
          isFalse,
        );
        expect(
          inReportPeriod(end.add(const Duration(days: 1)), r.start, r.end),
          isFalse,
        );
      }
    },
  );
  test(
    'leap years, cross-year weeks and navigation follow calendar boundaries',
    () {
      expect(
        labourReportPeriod(DateTime(2024, 2, 14), 'month').end,
        DateTime(2024, 2, 29),
      );
      final week = labourReportPeriod(DateTime(2027, 1, 1), 'week');
      expect(week.start, DateTime(2026, 12, 28));
      expect(week.end, DateTime(2027, 1, 3));
      expect(
        moveReportDate(DateTime(2026, 1, 31), 'month', 1),
        DateTime(2026, 2),
      );
      expect(moveReportDate(DateTime(2026, 1, 1), 'year', -1), DateTime(2025));
      expect(
        moveReportDate(DateTime(2026, 11, 5), 'week', -1),
        DateTime(2026, 10, 29),
      );
    },
  );
}
