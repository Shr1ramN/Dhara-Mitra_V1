import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/features/labour/domain/wages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attendanceWage', () {
    test('present pays the day rate, absent nothing', () {
      expect(attendanceWage(AttendanceStatus.present, dayRate: 80000), 80000);
      expect(attendanceWage(AttendanceStatus.absent, dayRate: 80000), 0);
    });

    test('half day is half unless a half-day rate is set', () {
      expect(attendanceWage(AttendanceStatus.half, dayRate: 80000), 40000);
      expect(attendanceWage(AttendanceStatus.half, dayRate: 80001), 40001);
      expect(
        attendanceWage(
          AttendanceStatus.half,
          dayRate: 80000,
          halfDayRate: 45000,
        ),
        45000,
      );
    });
  });

  group('WorkerBalance', () {
    test('due = earned − paid − advance', () {
      final b = WorkerBalance.of([
        (TxnKind.work, 160000),
        (TxnKind.payment, 200000),
        (TxnKind.work, 160000),
        (TxnKind.advance, 50000),
      ]);
      expect(b.earned, 320000);
      expect(b.given, 250000);
      expect(b.due, 70000);
    });

    test('an advance before any work shows as negative due', () {
      expect(WorkerBalance.of([(TxnKind.advance, 200000)]).due, -200000);
    });
  });

  test('runningDue', () {
    expect(
      runningDue([
        (TxnKind.work, 100),
        (TxnKind.payment, 60),
        (TxnKind.advance, 10),
        (TxnKind.work, 50),
      ]),
      [100, 40, 30, 80],
    );
  });
}
