import 'package:drift/drift.dart';

import '../../../core/dates.dart';
import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../domain/wages.dart';
import 'daily_work.dart';

const refAttendance = 'attendance';
const refLotLabour = 'lot_labour';

class WorkerSummary {
  const WorkerSummary(this.worker, this.balance);

  final Worker worker;
  final WorkerBalance balance;
}

class LedgerLine {
  const LedgerLine(this.txn, this.dueAfter);

  final WorkerTxn txn;

  /// What we owe the worker after this entry.
  final int dueAfter;
}

/// One worker's attendance for a day, as chosen on the attendance screen.
class AttendanceMark {
  const AttendanceMark(this.status, {this.work = '', this.rate});

  final AttendanceStatus status;
  final String work;
  final int? rate;
}

class LabourRepository {
  LabourRepository(this._db);

  final AppDatabase _db;

  Stream<List<WorkerSummary>> watchWorkerSummaries() {
    final t = _db.workerTxns;
    final w = _db.workers;
    final earned = t.amount.sum(filter: t.kind.equalsValue(TxnKind.work));
    final paid = t.amount.sum(filter: t.kind.equalsValue(TxnKind.payment));
    final advanced = t.amount.sum(filter: t.kind.equalsValue(TxnKind.advance));
    final query =
        _db.select(w).join([
            leftOuterJoin(
              t,
              t.workerId.equalsExp(w.id) & t.deleted.equals(false),
            ),
          ])
          ..where(w.deleted.equals(false))
          ..addColumns([earned, paid, advanced])
          ..groupBy([w.id])
          ..orderBy([OrderingTerm.desc(w.active), OrderingTerm.asc(w.name)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          WorkerSummary(
            row.readTable(w),
            WorkerBalance(
              earned: row.read(earned) ?? 0,
              paid: row.read(paid) ?? 0,
              advanced: row.read(advanced) ?? 0,
            ),
          ),
      ],
    );
  }

  Future<Worker?> getWorker(String id) => (_db.select(
    _db.workers,
  )..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<String> saveWorker(WorkersCompanion worker) async {
    final row = worker.copyWith(updatedAt: Value(DateTime.now()));
    if (!row.id.present) {
      return (await _db.into(_db.workers).insertReturning(row)).id;
    }
    await (_db.update(
      _db.workers,
    )..where((w) => w.id.equals(row.id.value))).write(row);
    return row.id.value;
  }

  /// Oldest first, each with the balance after it (F3.4).
  Stream<List<LedgerLine>> watchLedger(String workerId) =>
      (_db.select(_db.workerTxns)
            ..where(
              (t) => t.workerId.equals(workerId) & t.deleted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.date),
              (t) => OrderingTerm.asc(t.updatedAt),
            ]))
          .watch()
          .map((txns) {
            final due = runningDue(txns.map((t) => (t.kind, t.amount)));
            return [
              for (var i = 0; i < txns.length; i++) LedgerLine(txns[i], due[i]),
            ];
          });

  Stream<Map<String, AttendanceEntry>> watchAttendance(DateTime day) =>
      (_db.select(_db.attendanceEntries)..where(
            (a) => a.date.equals(dateOnly(day)) & a.deleted.equals(false),
          ))
          .watch()
          .map((rows) => {for (final a in rows) a.workerId: a});

  /// Saves the day's attendance; each present / half day becomes a work entry
  /// in that worker's ledger at their day rate (F3.3 → F3.4).
  Future<void> saveAttendance(
    DateTime day,
    Map<String, AttendanceMark> marks, {
    String? sourceActivityId,
  }) => _db.transaction(() async {
    final date = dateOnly(day);
    final touched = <String>{};
    final now = DateTime.now();
    for (final MapEntry(key: workerId, value: mark) in marks.entries) {
      final worker = await getWorker(workerId);
      if (worker == null) continue;
      final existing =
          await (_db.select(_db.attendanceEntries)..where(
                (a) => a.workerId.equals(workerId) & a.date.equals(date),
              ))
              .getSingleOrNull();
      final customRate = mark.rate ?? existing?.rate;
      final amount = attendanceWage(
        mark.status,
        dayRate: customRate ?? worker.dayRate,
        halfDayRate: customRate == null ? worker.halfDayRate : null,
      );
      final String attendanceId;
      if (existing == null) {
        attendanceId =
            (await _db
                    .into(_db.attendanceEntries)
                    .insertReturning(
                      AttendanceEntriesCompanion.insert(
                        workerId: workerId,
                        date: date,
                        status: mark.status,
                        work: Value(mark.work),
                        amount: amount,
                        rate: Value(customRate),
                        sourceActivityId: Value(sourceActivityId),
                      ),
                    ))
                .id;
      } else {
        attendanceId = existing.id;
        await (_db.update(
          _db.attendanceEntries,
        )..where((a) => a.id.equals(existing.id))).write(
          AttendanceEntriesCompanion(
            status: Value(mark.status),
            work: Value(mark.work),
            amount: Value(amount),
            rate: Value(customRate),
            sourceActivityId: Value(sourceActivityId),
            deleted: const Value(false),
            updatedAt: Value(now),
          ),
        );
      }
      touched.add(attendanceId);
      await syncWorkTxn(
        _db,
        workerId: workerId,
        date: date,
        amount: amount,
        note: mark.work,
        refType: refAttendance,
        refId: attendanceId,
      );
    }
    await DailyWork(_db).refresh(attendanceIds: touched);
  });

  Future<void> addPayment({
    required String workerId,
    required DateTime date,
    required TxnKind kind,
    required int amount,
    PayMode mode = PayMode.cash,
    String note = '',
  }) {
    assert(
      kind != TxnKind.work,
      'Work entries come from attendance or lot labour',
    );
    return _db
        .into(_db.workerTxns)
        .insert(
          WorkerTxnsCompanion.insert(
            workerId: workerId,
            date: dateOnly(date),
            kind: kind,
            amount: amount,
            mode: Value(mode),
            note: Value(note),
          ),
        );
  }

  /// Only payments and advances can be removed here; work entries are removed
  /// from the attendance or lot they came from.
  Future<void> deleteTxn(String id) =>
      (_db.update(
        _db.workerTxns,
      )..where((t) => t.id.equals(id) & t.refType.isNull())).write(
        WorkerTxnsCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

/// Keeps the single work entry for a source row (attendance, lot labour) in
/// step with it. A zero [amount] removes the entry.
Future<void> syncWorkTxn(
  AppDatabase db, {
  required String workerId,
  required DateTime date,
  required int amount,
  required String note,
  required String refType,
  required String refId,
}) async {
  final existing =
      await (db.select(db.workerTxns)
            ..where((t) => t.refType.equals(refType) & t.refId.equals(refId)))
          .getSingleOrNull();
  final now = DateTime.now();
  if (existing == null) {
    if (amount == 0) return;
    await db
        .into(db.workerTxns)
        .insert(
          WorkerTxnsCompanion.insert(
            workerId: workerId,
            date: date,
            kind: TxnKind.work,
            amount: amount,
            note: Value(note),
            refType: Value(refType),
            refId: Value(refId),
          ),
        );
    return;
  }
  await (db.update(
    db.workerTxns,
  )..where((t) => t.id.equals(existing.id))).write(
    WorkerTxnsCompanion(
      workerId: Value(workerId),
      date: Value(date),
      amount: Value(amount),
      note: Value(note),
      deleted: Value(amount == 0),
      updatedAt: Value(now),
    ),
  );
}
