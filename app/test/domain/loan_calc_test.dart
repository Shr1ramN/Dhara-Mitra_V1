import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/loans/domain/loan_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2025, 1, 1);
  LoanBalance calculate(
    List<LoanEvent> events,
    DateTime until, {
    String method = 'simple',
    int months = 12,
  }) => loanBalance(
    openedOn: start,
    annualRate: 10,
    method: method,
    compoundingMonths: months,
    events: events,
    asOf: until,
  );
  test('simple annual interest uses paise and elapsed days', () {
    final b = calculate([
      LoanEvent(start, 'withdrawal', 10000000),
    ], DateTime(2026, 1, 1));
    expect(b.principal, 10000000);
    expect(b.interest, 1000000);
  });
  test('interest follows changing principal and ignores future entries', () {
    final events = [
      LoanEvent(start, 'withdrawal', 10000000),
      LoanEvent(DateTime(2025, 7, 1), 'principal', 5000000),
      LoanEvent(DateTime(2027, 1, 1), 'withdrawal', 10000000),
    ];
    final b = calculate(events, DateTime(2026, 1, 1));
    expect(b.principal, 5000000);
    expect(
      b.interest,
      (10000000 * .1 * 181 / 365 + 5000000 * .1 * 184 / 365).round(),
    );
  });
  test('annual compounding capitalises only at anniversaries', () {
    final b = calculate(
      [LoanEvent(start, 'withdrawal', 10000000)],
      DateTime(2027, 1, 1),
      method: 'compound',
    );
    expect(b.principal, 10000000);
    expect(b.interest, 2100000);
  });
  test(
    'interest payments reduce capitalised interest instead of principal',
    () {
      final b = calculate(
        [
          LoanEvent(start, 'withdrawal', 10000000),
          LoanEvent(DateTime(2026, 1, 1), 'interest', 1000000),
        ],
        DateTime(2027, 1, 1),
        method: 'compound',
      );
      expect(b.interest, 1000000);
      expect(b.interestPaid, 1000000);
    },
  );
  test('month arithmetic clamps the original day without drift', () {
    expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonthsClamped(DateTime(2026, 1, 31), 2), DateTime(2026, 3, 31));
    expect(addMonthsClamped(DateTime(2024, 2, 29), 12), DateTime(2025, 2, 28));
  });
  test('rejects repayment before borrowing and invalid interest settings', () {
    expect(
      () => calculate([LoanEvent(start, 'principal', 1)], start),
      throwsA(isA<FarmException>()),
    );
    expect(
      () => calculate([], start, months: 0),
      throwsA(isA<FarmException>()),
    );
    expect(
      () =>
          calculate([LoanEvent(DateTime(2024, 1, 1), 'withdrawal', 1)], start),
      throwsA(isA<FarmException>()),
    );
  });
}
