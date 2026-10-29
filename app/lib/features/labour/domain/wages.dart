import '../../../core/enums.dart';

/// Wage for one day's attendance (F3.3). Half day defaults to half the day rate.
int attendanceWage(
  AttendanceStatus status, {
  required int dayRate,
  int? halfDayRate,
}) => switch (status) {
  AttendanceStatus.present => dayRate,
  AttendanceStatus.half => halfDayRate ?? (dayRate / 2).round(),
  AttendanceStatus.absent => 0,
};

/// A worker's account (F3.4): what they earned against what they were given.
class WorkerBalance {
  const WorkerBalance({this.earned = 0, this.paid = 0, this.advanced = 0});

  factory WorkerBalance.of(Iterable<(TxnKind, int)> txns) {
    var earned = 0, paid = 0, advanced = 0;
    for (final (kind, amount) in txns) {
      switch (kind) {
        case TxnKind.work:
          earned += amount;
        case TxnKind.payment:
          paid += amount;
        case TxnKind.advance:
          advanced += amount;
      }
    }
    return WorkerBalance(earned: earned, paid: paid, advanced: advanced);
  }

  final int earned;
  final int paid;
  final int advanced;

  /// Positive: we owe the worker. Negative: the worker holds an unearned advance.
  int get due => earned - paid - advanced;

  int get given => paid + advanced;
}

/// Balance after each entry, for entries sorted oldest first.
List<int> runningDue(Iterable<(TxnKind, int)> txnsOldestFirst) {
  var due = 0;
  return [
    for (final (kind, amount) in txnsOldestFirst)
      due += kind == TxnKind.work ? amount : -amount,
  ];
}
