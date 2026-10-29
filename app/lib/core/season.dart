import 'dates.dart';

/// A farming season, June to May by default (F1.4). Identified by the year it starts in.
class Season implements Comparable<Season> {
  const Season(this.startYear);

  factory Season.of(DateTime date, {int startMonth = 6}) =>
      Season(date.month >= startMonth ? date.year : date.year - 1);

  final int startYear;

  /// "2026–27"
  String get label => '$startYear–${_two(startYear + 1)}';

  /// "2627", used inside lot codes.
  String get code => '${_two(startYear)}${_two(startYear + 1)}';

  DateTime firstDay({int startMonth = 6}) => DateTime(startYear, startMonth);

  DateTime lastDay({int startMonth = 6}) =>
      addDays(DateTime(startYear + 1, startMonth), -1);

  bool contains(DateTime date, {int startMonth = 6}) =>
      Season.of(date, startMonth: startMonth) == this;

  Season get previous => Season(startYear - 1);

  static String _two(int year) => (year % 100).toString().padLeft(2, '0');

  @override
  int compareTo(Season other) => startYear.compareTo(other.startYear);

  @override
  bool operator ==(Object other) =>
      other is Season && other.startYear == startYear;

  @override
  int get hashCode => startYear.hashCode;

  @override
  String toString() => 'Season($label)';
}
