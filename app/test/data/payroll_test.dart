import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/labour/data/payroll_repository.dart';
import 'package:dhara_mitra/features/backup/backup_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'backdated repayments cannot consume money already repaid later',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final w = await db
          .into(db.workers)
          .insertReturning(WorkersCompanion.insert(name: 'Worker'));
      final repo = PayrollRepository(db);
      await repo.loan(
        workerId: w.id,
        date: DateTime(2026, 10, 1),
        kind: 'new',
        amount: 10000,
      );
      await repo.loan(
        workerId: w.id,
        date: DateTime(2026, 10, 10),
        kind: 'repayment',
        amount: 10000,
      );
      await repo.loan(
        workerId: w.id,
        date: DateTime(2026, 10, 20),
        kind: 'new',
        amount: 10000,
      );
      await expectLater(
        repo.loan(
          workerId: w.id,
          date: DateTime(2026, 10, 5),
          kind: 'repayment',
          amount: 10000,
        ),
        throwsException,
      );
      expect(await repo.loanBalance(w.id), 10000);
      expect((await db.select(db.workerLoanEntries).get()).length, 3);
    },
  );
  test(
    'backup and restore retain settlements and both sides of loan deductions',
    () async {
      final root = await Directory.systemTemp.createTemp('payroll-backup');
      final docs = await Directory('${root.path}/docs').create();
      final temp = await Directory('${root.path}/temp').create();
      final db = AppDatabase(NativeDatabase(File('${root.path}/farm.sqlite')));
      try {
        final w = await db
            .into(db.workers)
            .insertReturning(
              WorkersCompanion.insert(
                name: 'Worker',
                dayRate: const Value(70000),
              ),
            );
        final day = DateTime(2026, 10, 26), repo = PayrollRepository(db);
        await LabourRepository(db).saveAttendance(day, {
          w.id: const AttendanceMark(AttendanceStatus.half),
        });
        await repo.loan(
          workerId: w.id,
          date: day,
          kind: 'previous',
          amount: 10000,
        );
        await repo.settle(
          workerId: w.id,
          date: day,
          start: day,
          end: day,
          cashPaid: 20000,
          deduction: 5000,
        );
        final backup = BackupService(
          db,
          documentsDirectory: docs,
          temporaryDirectory: temp,
        );
        final file = await backup.create();
        await repo.loan(workerId: w.id, date: day, kind: 'new', amount: 10000);
        await backup.restore(file);
        expect(await repo.loanBalance(w.id), 5000);
        expect(
          (await db.select(db.workerSettlements).getSingle()).loanDeduction,
          5000,
        );
        expect(
          (await LabourRepository(
            db,
          ).watchWorkerSummaries().first).single.balance.due,
          10000,
        );
        expect(
          (await db.customSelect('PRAGMA foreign_key_check').get()),
          isEmpty,
        );
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
  test('upgrade retains workers, half days, piece rates, credits and exact balances', () async {
    final dir = await Directory.systemTemp.createTemp('payroll-upgrade');
    final file = File('${dir.path}/farm.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    try {
      await db
          .into(db.farms)
          .insert(FarmsCompanion.insert(name: 'Upgrade test farm'));
      final w = await db
          .into(db.workers)
          .insertReturning(
            WorkersCompanion.insert(
              name: 'Existing',
              dayRate: const Value(70101),
              halfDayRate: const Value(35051),
              pieceRate: const Value(12345),
              pieceUnit: const Value(RateUnit.kg),
            ),
          );
      final other = await db
          .into(db.workers)
          .insertReturning(WorkersCompanion.insert(name: 'Variable'));
      await LabourRepository(db).saveAttendance(DateTime(2026, 10, 25), {
        w.id: const AttendanceMark(
          AttendanceStatus.half,
          work: 'Historical work',
        ),
      });
      await LabourRepository(db).addPayment(
        workerId: w.id,
        date: DateTime(2026, 10, 26),
        kind: TxnKind.advance,
        amount: 10001,
      );
      await LabourRepository(db).addPayment(
        workerId: w.id,
        date: DateTime(2026, 10, 27),
        kind: TxnKind.payment,
        amount: 10000,
      );
      final before = (await LabourRepository(db).watchWorkerSummaries().first)
          .firstWhere((s) => s.worker.id == w.id)
          .balance
          .due;
      final ids = (await db.select(db.workerTxns).get())
          .map((e) => e.id)
          .toSet();
      await db.customStatement('DROP TABLE worker_loan_entries');
      await db.customStatement('DROP TABLE worker_settlements');
      await db.customStatement('ALTER TABLE workers DROP COLUMN wage_type');
      await db.customStatement('PRAGMA user_version = 5');
      await db.close();
      if (const bool.fromEnvironment('PAYROLL_FIXTURE')) {
        final target = await Directory('build/upgrade-fixture')
            .create(recursive: true);
        await file.copy('${target.path}/schema5.sqlite');
      }
      db = AppDatabase(NativeDatabase(file));
      expect(
        (await LabourRepository(db).watchWorkerSummaries().first)
            .firstWhere((s) => s.worker.id == w.id)
            .balance
            .due,
        before,
      );
      expect(
        (await db.select(db.workerTxns).get()).map((e) => e.id).toSet(),
        ids,
      );
      expect((await LabourRepository(db).getWorker(w.id))!.pieceRate, 12345);
      expect(
        (await LabourRepository(db).getWorker(other.id))!.wageType,
        'other',
      );
      expect((await db.select(db.attendanceEntries).getSingle()).amount, 35051);
      expect(
        (await db.select(db.attendanceEntries).getSingle()).work,
        'Historical work',
      );
      expect(await PayrollRepository(db).loanBalance(w.id), 0);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect((await db.select(db.workers).get()).length, 2);
      expect(
        (await LabourRepository(db).watchWorkerSummaries().first)
            .firstWhere((s) => s.worker.id == w.id)
            .balance
            .due,
        before,
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
  test('partial weekly settlements and explicit loan deductions balance atomically', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final w = await db
        .into(db.workers)
        .insertReturning(
          WorkersCompanion.insert(name: 'Worker', dayRate: const Value(70000)),
        );
    final labour = LabourRepository(db),
        payroll = PayrollRepository(db),
        day = DateTime(2026, 10, 26);
    await labour.saveAttendance(day, {
      w.id: const AttendanceMark(AttendanceStatus.present),
    });
    await labour.saveAttendance(DateTime(2026, 10, 27), {
      w.id: const AttendanceMark(AttendanceStatus.half),
    });
    await payroll.loan(
      workerId: w.id,
      date: day,
      kind: 'previous',
      amount: 20000,
    );
    await payroll.loan(workerId: w.id, date: day, kind: 'new', amount: 10000);
    expect(
      (await labour.watchWorkerSummaries().first).single.balance.due,
      105000,
    );
    final settlementId = await payroll.settle(
      workerId: w.id,
      date: DateTime(2026, 10, 31),
      start: day,
      end: DateTime(2026, 10, 31),
      cashPaid: 40000,
      deduction: 10000,
    );
    expect(
      (await labour.watchWorkerSummaries().first).single.balance.due,
      55000,
    );
    expect(await payroll.loanBalance(w.id), 20000);
    await payroll.loan(
      workerId: w.id,
      date: DateTime(2026, 10, 31),
      kind: 'repayment',
      amount: 5000,
    );
    expect(await payroll.loanBalance(w.id), 15000);
    expect(
      (await labour.watchWorkerSummaries().first).single.balance.due,
      55000,
    );
    final old = (await db.select(db.workerSettlements).get()).length;
    await expectLater(
      payroll.settle(
        workerId: w.id,
        date: DateTime(2026, 10, 31),
        start: day,
        end: DateTime(2026, 10, 31),
        cashPaid: 100,
        deduction: 20000,
      ),
      throwsException,
    );
    expect((await db.select(db.workerSettlements).get()).length, old);
    expect(await payroll.loanBalance(w.id), 15000);
    await payroll.cancelSettlement(settlementId);
    expect(
      (await labour.watchWorkerSummaries().first).single.balance.due,
      105000,
    );
    expect(await payroll.loanBalance(w.id), 25000);
    expect((await db.select(db.workerSettlements).getSingle()).deleted, isTrue);
    await expectLater(payroll.cancelSettlement(settlementId), throwsException);
  });
  test(
    'reopening an old week cannot pay it twice using later earnings',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final w = await db
          .into(db.workers)
          .insertReturning(
            WorkersCompanion.insert(
              name: 'Worker',
              dayRate: const Value(70000),
            ),
          );
      final labour = LabourRepository(db),
          repo = PayrollRepository(db),
          day = DateTime(2026, 10, 20);
      await labour.saveAttendance(day, {
        w.id: const AttendanceMark(AttendanceStatus.present),
      });
      await repo.settle(
        workerId: w.id,
        date: DateTime(2026, 10, 27),
        start: day,
        end: day,
        cashPaid: 70000,
      );
      await labour.saveAttendance(DateTime(2026, 10, 28), {
        w.id: const AttendanceMark(AttendanceStatus.present),
      });
      await expectLater(
        repo.settle(
          workerId: w.id,
          date: DateTime(2026, 10, 29),
          start: day,
          end: day,
          cashPaid: 70000,
        ),
        throwsException,
      );
      expect(
        (await labour.watchWorkerSummaries().first).single.balance.due,
        70000,
      );
      expect((await db.select(db.workerSettlements).get()).length, 1);
    },
  );
  test('attendance corrections update one wage; variable half day keeps actual amount', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final w = await db
        .into(db.workers)
        .insertReturning(
          WorkersCompanion.insert(
            name: 'Other',
            wageType: const Value('other'),
          ),
        );
    final repo = LabourRepository(db), day = DateTime(2026, 10, 26);
    await repo.saveAttendance(day, {
      w.id: const AttendanceMark(AttendanceStatus.half, rate: 66666),
    });
    await repo.saveAttendance(day, {
      w.id: const AttendanceMark(AttendanceStatus.half, rate: 66666),
    });
    expect((await db.select(db.attendanceEntries).getSingle()).amount, 33333);
    expect((await db.select(db.workerTxns).get()).length, 1);
    await repo.saveAttendance(day, {
      w.id: const AttendanceMark(AttendanceStatus.absent),
    });
    expect((await repo.watchWorkerSummaries().first).single.balance.due, 0);
  });
}
