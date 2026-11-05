import '../../../core/dates.dart';

/// Local calendar boundaries, inclusive of both complete days.
({DateTime start, DateTime end}) labourReportPeriod(
  DateTime selected,
  String period,
) {
  final day = dateOnly(selected);
  final start = switch (period) {
    'day' => day,
    'month' => DateTime(day.year, day.month),
    'year' => DateTime(day.year),
    _ => addDays(day, 1 - day.weekday),
  };
  final end = switch (period) {
    'day' => day,
    'month' => DateTime(day.year, day.month + 1, 0),
    'year' => DateTime(day.year, 12, 31),
    _ => addDays(start, 6),
  };
  return (start: start, end: end);
}

bool inReportPeriod(DateTime date, DateTime start, DateTime end) =>
    !dateOnly(date).isBefore(dateOnly(start)) &&
    !dateOnly(date).isAfter(dateOnly(end));

DateTime moveReportDate(DateTime date, String period, int step) =>
    switch (period) {
      'day' => addDays(date, step),
      'month' => DateTime(date.year, date.month + step),
      'year' => DateTime(date.year + step, 1, 1),
      _ => addDays(date, step * 7),
    };
