import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/validation.dart';
import 'labour_repository.dart';

class PayrollRepository {
  PayrollRepository(this.db);
  final AppDatabase db;

  Future<void> cancelSettlement(String id) => db.transaction(() async {
    final settlement =
        await (db.select(db.workerSettlements)
              ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
            .getSingleOrNull();
    require(settlement != null);
    final now = DateTime.now();
    await (db.update(
      db.workerTxns,
    )..where((t) => t.refType.equals('settlement') & t.refId.equals(id))).write(
      WorkerTxnsCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (db.update(
      db.workerLoanEntries,
    )..where((t) => t.settlementId.equals(id))).write(
      WorkerLoanEntriesCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await (db.update(
      db.workerSettlements,
    )..where((t) => t.id.equals(id))).write(
      WorkerSettlementsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  });

  /// A backdated repayment must also leave every later day's balance valid.
  Future<int> repayable(String workerId, DateTime date) async {
    final rows =
        await (db.select(db.workerLoanEntries)..where(
              (t) => t.workerId.equals(workerId) & t.deleted.equals(false),
            ))
            .get();
    final days = <DateTime, int>{};
    for (final row in rows) {
      days.update(
        row.date,
        (v) =>
            v +
            (['previous', 'new'].contains(row.kind) ? row.amount : -row.amount),
        ifAbsent: () =>
            ['previous', 'new'].contains(row.kind) ? row.amount : -row.amount,
      );
    }
    var balance = 0;
    int? minimum;
    final target = dateOnly(date);
    for (final d in {...days.keys, target}.toList()..sort()) {
      balance += days[d] ?? 0;
      if (!d.isBefore(target) && (minimum == null || balance < minimum)) {
        minimum = balance;
      }
    }
    return minimum ?? 0;
  }

  Future<int> loanBalance(String workerId, {DateTime? through}) async {
    final rows =
        await (db.select(db.workerLoanEntries)..where(
              (t) => t.workerId.equals(workerId) & t.deleted.equals(false),
            ))
            .get();
    return rows
        .where((e) => through == null || !e.date.isAfter(dateOnly(through)))
        .fold<int>(
          0,
          (s, e) =>
              s +
              (e.kind == 'previous' || e.kind == 'new' ? e.amount : -e.amount),
        );
  }

  Future<void> loan({
    required String workerId,
    required DateTime date,
    required String kind,
    required int amount,
    String note = '',
  }) => db.transaction(() async {
    require(['previous', 'new', 'repayment'].contains(kind));
    require(amount > 0, 'positive');
    require(!dateOnly(date).isAfter(dateOnly(DateTime.now())), 'dates');
    final worker = await LabourRepository(db).getWorker(workerId);
    require(worker != null && !worker.deleted);
    if (kind == 'repayment') {
      require(amount <= await repayable(workerId, date), 'balance');
      require(amount <= await loanBalance(workerId, through: date), 'balance');
      require(amount <= await loanBalance(workerId), 'balance');
    }
    await db
        .into(db.workerLoanEntries)
        .insert(
          WorkerLoanEntriesCompanion.insert(
            workerId: workerId,
            date: dateOnly(date),
            kind: kind,
            amount: amount,
            note: Value(note),
          ),
        );
  });

  Future<String> settle({
    required String workerId,
    required DateTime date,
    required DateTime start,
    required DateTime end,
    required int cashPaid,
    int deduction = 0,
    PayMode mode = PayMode.cash,
    String note = '',
  }) => db.transaction(() async {
    require(
      cashPaid >= 0 && deduction >= 0 && cashPaid + deduction > 0,
      'positive',
    );
    require(
      !dateOnly(end).isBefore(dateOnly(start)) &&
          !dateOnly(date).isBefore(dateOnly(end)) &&
          !dateOnly(date).isAfter(dateOnly(DateTime.now())),
      'dates',
    );
    final worker = await LabourRepository(db).getWorker(workerId);
    require(worker != null && !worker.deleted);
    final txns =
        await (db.select(db.workerTxns)..where(
              (t) => t.workerId.equals(workerId) & t.deleted.equals(false),
            ))
            .get();
    int due(Iterable<WorkerTxn> rows) => rows.fold(
      0,
      (s, t) => s + (t.kind == TxnKind.work ? t.amount : -t.amount),
    );
    // Payments settle oldest earnings first, even when paid after this period.
    // Subtract every payment so reopening a paid week cannot pay it twice.
    final availableThroughEnd = txns.fold<int>(
      0,
      (sum, txn) =>
          sum +
          (txn.kind == TxnKind.work
              ? (txn.date.isAfter(dateOnly(end)) ? 0 : txn.amount)
              : -txn.amount),
    );
    require(
      cashPaid + deduction <= availableThroughEnd &&
          cashPaid + deduction <= due(txns),
      'balance',
    );
    require(
      deduction <= await repayable(workerId, date) &&
          deduction <= await loanBalance(workerId, through: date) &&
          deduction <= await loanBalance(workerId),
      'balance',
    );
    final id = newId();
    await db
        .into(db.workerSettlements)
        .insert(
          WorkerSettlementsCompanion.insert(
            id: Value(id),
            workerId: workerId,
            date: dateOnly(date),
            periodStart: dateOnly(start),
            periodEnd: dateOnly(end),
            cashPaid: cashPaid,
            loanDeduction: Value(deduction),
            note: Value(note),
          ),
        );
    await db
        .into(db.workerTxns)
        .insert(
          WorkerTxnsCompanion.insert(
            workerId: workerId,
            date: dateOnly(date),
            kind: TxnKind.payment,
            amount: cashPaid + deduction,
            mode: Value(mode),
            note: Value(note),
            refType: const Value('settlement'),
            refId: Value(id),
          ),
        );
    if (deduction > 0) {
      await db
          .into(db.workerLoanEntries)
          .insert(
            WorkerLoanEntriesCompanion.insert(
              workerId: workerId,
              date: dateOnly(date),
              kind: 'deduction',
              amount: deduction,
              settlementId: Value(id),
              note: Value(note),
            ),
          );
    }
    return id;
  });
}
