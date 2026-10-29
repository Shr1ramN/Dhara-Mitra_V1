import '../../../core/validation.dart';

class LoanEvent {
  const LoanEvent(this.date, this.kind, this.amount);
  final DateTime date;
  final String kind;
  final int amount;
}

class LoanBalance {
  const LoanBalance(this.principal, this.interest, this.interestPaid);
  final int principal;
  final int interest;
  final int interestPaid;
  int get total => principal + interest;
}

DateTime addMonthsClamped(DateTime date, int months) {
  final first = DateTime(date.year, date.month + months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, date.day > last ? last : date.day);
}

/// Actual/365, accrual exclusive of the withdrawal day and inclusive of the
/// elapsed interval. Compound interest is capitalised only on anniversaries
/// of the selected interval, not on each transaction or whenever a screen opens.
LoanBalance loanBalance({
  required DateTime openedOn,
  required double annualRate,
  required String method,
  required int compoundingMonths,
  required List<LoanEvent> events,
  required DateTime asOf,
  int? sanctioned,
}) {
  require(annualRate.isFinite && annualRate >= 0 && annualRate <= 1000);
  require(['simple', 'compound'].contains(method));
  require([1, 3, 6, 12].contains(compoundingMonths));
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  int days(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  final until = day(asOf);
  if (until.isBefore(day(openedOn))) return const LoanBalance(0, 0, 0);
  final ordered = events.where((e) => !day(e.date).isAfter(until)).toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0
          ? c
          : (a.kind == 'withdrawal' ? 0 : 1).compareTo(
              b.kind == 'withdrawal' ? 0 : 1,
            );
    });
  double principal = 0, interest = 0, capitalised = 0;
  int paid = 0;
  var cursor = day(openedOn);
  var period = 1;
  var boundary = addMonthsClamped(day(openedOn), compoundingMonths);
  void accrueTo(DateTime target) {
    while (method == 'compound' && !boundary.isAfter(target)) {
      interest +=
          (principal + capitalised) *
          annualRate /
          100 *
          days(cursor, boundary) /
          365;
      capitalised = interest;
      cursor = boundary;
      boundary = addMonthsClamped(day(openedOn), ++period * compoundingMonths);
    }
    interest +=
        (principal + (method == 'compound' ? capitalised : 0)) *
        annualRate /
        100 *
        days(cursor, target) /
        365;
    cursor = target;
  }

  for (final event in ordered) {
    positive(event.amount);
    final on = day(event.date);
    require(!on.isBefore(day(openedOn)), 'dates');
    accrueTo(on);
    switch (event.kind) {
      case 'withdrawal':
        principal += event.amount;
        require(sanctioned == null || principal <= sanctioned + 0.5, 'balance');
      case 'principal':
        require(event.amount <= principal + 0.5, 'balance');
        principal -= event.amount;
      case 'interest':
        require(event.amount <= interest.round(), 'balance');
        interest -= event.amount;
        paid += event.amount;
        if (interest < 0) interest = 0;
        if (capitalised > interest) capitalised = interest;
      case 'charge':
        interest += event.amount;
      default:
        throw const FarmException('invalid');
    }
  }
  accrueTo(until);
  return LoanBalance(principal.round(), interest.round(), paid);
}
