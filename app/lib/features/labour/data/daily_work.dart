import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/dates.dart';
import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/validation.dart';
import 'labour_repository.dart';

/// One attendance wage per worker/date, shared explicitly by diary/lot work.
/// Fractional day requests reserve part of that wage; piecework has no links.
class DailyWork {
  DailyWork(this.db);
  final AppDatabase db;
  static String key(String type, String id) => '$type:$id';
  static double days(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 1,
    AttendanceStatus.half => .5,
    _ => 0,
  };

  Future<void> book({
    required String type,
    required String id,
    required String owner,
    required String worker,
    required DateTime on,
    required double quantity,
    required int rate,
    required String note,
    bool migrating = false,
  }) async {
    require(
      quantity.isFinite &&
          quantity > 0 &&
          quantity <= 366 &&
          quantity * 2 == (quantity * 2).roundToDouble(),
      'attendance',
    );
    final touched = <String>{};
    for (var index = 0; index < quantity.ceil(); index++) {
      final requested = math.min(1.0, quantity - index);
      final date = addDays(dateOnly(on), index);
      var attendance =
          await (db.select(db.attendanceEntries)
                ..where((a) => a.workerId.equals(worker) & a.date.equals(date)))
              .getSingleOrNull();
      if (attendance == null || (attendance.deleted && !migrating)) {
        await LabourRepository(db).saveAttendance(date, {
          worker: AttendanceMark(
            requested == 1 ? AttendanceStatus.present : AttendanceStatus.half,
            work: note,
            rate: rate,
          ),
        }, sourceActivityId: owner);
        attendance =
            await (db.select(db.attendanceEntries)..where(
                  (a) => a.workerId.equals(worker) & a.date.equals(date),
                ))
                .getSingle();
      }
      await _attach(type, id, attendance, requested, migrating: migrating);
      touched.add(attendance.id);
    }
    await refresh(attendanceIds: touched);
    // Old independent source wages are replaced by the canonical attendance.
    await (db.update(
      db.workerTxns,
    )..where((t) => t.refType.equals(type) & t.refId.equals(id))).write(
      WorkerTxnsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _attach(
    String type,
    String id,
    AttendanceEntry attendance,
    double quantity, {
    bool migrating = false,
  }) async {
    final existing =
        await (db.select(db.dailyWorkAllocations)..where(
              (a) =>
                  a.attendanceId.equals(attendance.id) &
                  a.deleted.equals(false),
            ))
            .get();
    final used = existing.fold(0.0, (s, a) => s + a.quantity);
    var current = attendance;
    if (!current.deleted &&
        current.sourceActivityId != null &&
        current.status == AttendanceStatus.half &&
        used + quantity > .5 &&
        (migrating || used + quantity <= 1.000001)) {
      await LabourRepository(db).saveAttendance(current.date, {
        current.workerId: AttendanceMark(
          AttendanceStatus.present,
          work: current.work,
          rate: current.rate,
        ),
      }, sourceActivityId: current.sourceActivityId);
      current = await (db.select(
        db.attendanceEntries,
      )..where((a) => a.id.equals(attendance.id))).getSingle();
    }
    if (!migrating) {
      final capacity = days(current.status);
      // A whole-day request may reuse an existing half-day wage, but it cannot
      // allocate the same attendance a second time to another full-day task.
      require(
        !current.deleted &&
            capacity > 0 &&
            used + math.min(quantity, capacity) <= capacity + .000001,
        'attendance',
      );
    }
    await db
        .into(db.dailyWorkAllocations)
        .insert(
          DailyWorkAllocationsCompanion.insert(
            attendanceId: attendance.id,
            sourceType: type,
            sourceId: id,
            quantity: quantity,
          ),
        );
  }

  Future<void> refresh({Set<String>? attendanceIds}) async {
    final links =
        await (db.select(db.dailyWorkAllocations)
              ..where(
                (a) =>
                    a.deleted.equals(false) &
                    (attendanceIds == null
                        ? const Constant(true)
                        : a.attendanceId.isIn(attendanceIds)),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.id)]))
            .get();
    final attendance = {
      for (final a in await db.select(db.attendanceEntries).get()) a.id: a,
    };
    final sources = <String, (String, String)>{};
    final groups = <String, List<DailyWorkAllocation>>{};
    for (final link in links) {
      groups.putIfAbsent(link.attendanceId, () => []).add(link);
    }
    for (final group in groups.entries) {
      final rows = group.value;
      final entry = attendance[group.key];
      final capacity = entry == null || entry.deleted
          ? 0.0
          : days(entry.status);
      final total = rows.fold(0.0, (s, l) => s + l.quantity);
      final denominator = math.max(capacity, total);
      var prefix = 0.0, allocated = 0;
      for (final row in rows) {
        prefix += row.quantity;
        final cumulative = capacity == 0
            ? 0
            : (prefix * entry!.amount / denominator).round();
        await (db.update(
          db.dailyWorkAllocations,
        )..where((a) => a.id.equals(row.id))).write(
          DailyWorkAllocationsCompanion(
            amount: Value(cumulative - allocated),
            updatedAt: Value(DateTime.now()),
          ),
        );
        allocated = cumulative;
        sources[key(row.sourceType, row.sourceId)] = (
          row.sourceType,
          row.sourceId,
        );
      }
    }
    for (final source in sources.values) {
      await _updateSource(source.$1, source.$2);
    }
  }

  Future<void> _updateSource(String type, String id) async {
    final rows =
        await (db.select(db.dailyWorkAllocations)..where(
              (a) =>
                  a.sourceType.equals(type) &
                  a.sourceId.equals(id) &
                  a.deleted.equals(false),
            ))
            .get();
    final amount = rows.fold(0, (s, a) => s + a.amount);
    final now = DateTime.now();
    switch (type) {
      case 'activityLabour':
        await (db.update(
          db.activityLabour,
        )..where((l) => l.id.equals(id))).write(
          ActivityLabourCompanion(
            amount: Value(amount),
            attendanceIds: Value(rows.map((r) => r.attendanceId).toList()),
            updatedAt: Value(now),
          ),
        );
      case 'lot_labour':
        await (db.update(db.lotLabour)..where((l) => l.id.equals(id))).write(
          LotLabourCompanion(amount: Value(amount), updatedAt: Value(now)),
        );
      case 'produceLabour':
        await (db.update(
          db.produceLabour,
        )..where((l) => l.id.equals(id))).write(
          ProduceLabourCompanion(amount: Value(amount), updatedAt: Value(now)),
        );
    }
  }

  Future<Map<String, double>> quantities() async {
    final links = await (db.select(
      db.dailyWorkAllocations,
    )..where((a) => a.deleted.equals(false))).get();
    final attendance = {
      for (final a in await db.select(db.attendanceEntries).get()) a.id: a,
    };
    final result = <String, double>{};
    final totals = <String, double>{};
    for (final row in links) {
      totals.update(
        row.attendanceId,
        (q) => q + row.quantity,
        ifAbsent: () => row.quantity,
      );
    }
    for (final row in links) {
      final entry = attendance[row.attendanceId];
      final capacity = entry == null || entry.deleted
          ? 0.0
          : days(entry.status);
      final total = totals[row.attendanceId]!;
      final quantity = row.quantity * math.min(1.0, capacity / total);
      result.update(
        key(row.sourceType, row.sourceId),
        (q) => q + quantity,
        ifAbsent: () => quantity,
      );
    }
    return result;
  }

  Future<void> release(String type, String id) async {
    final links =
        await (db.select(db.dailyWorkAllocations)..where(
              (a) =>
                  a.sourceType.equals(type) &
                  a.sourceId.equals(id) &
                  a.deleted.equals(false),
            ))
            .get();
    await (db.update(
      db.dailyWorkAllocations,
    )..where((a) => a.sourceType.equals(type) & a.sourceId.equals(id))).write(
      DailyWorkAllocationsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    for (final attendanceId in links.map((l) => l.attendanceId).toSet()) {
      final remaining =
          await (db.select(db.dailyWorkAllocations)..where(
                (a) =>
                    a.attendanceId.equals(attendanceId) &
                    a.deleted.equals(false),
              ))
              .get();
      final entry = await (db.select(
        db.attendanceEntries,
      )..where((a) => a.id.equals(attendanceId))).getSingle();
      if (remaining.isEmpty && entry.sourceActivityId != null) {
        await (db.update(
          db.attendanceEntries,
        )..where((a) => a.id.equals(attendanceId))).write(
          AttendanceEntriesCompanion(
            deleted: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await syncWorkTxn(
          db,
          workerId: entry.workerId,
          date: entry.date,
          amount: 0,
          note: entry.work,
          refType: refAttendance,
          refId: attendanceId,
        );
      } else if (entry.sourceActivityId != null && remaining.isNotEmpty) {
        final requested = remaining.fold(0.0, (s, a) => s + a.quantity);
        await LabourRepository(db).saveAttendance(entry.date, {
          entry.workerId: AttendanceMark(
            requested <= .5 ? AttendanceStatus.half : AttendanceStatus.present,
            work: entry.work,
            rate: entry.rate,
          ),
        }, sourceActivityId: entry.sourceActivityId);
      }
    }
    await refresh(attendanceIds: links.map((l) => l.attendanceId).toSet());
  }

  /// Keep source records, payments and manual attendance. Reconcile legacy day
  /// ledger duplicates into attendance and retain per-source allocation history.
  Future<void> migrate() async {
    for (final line in await (db.select(
      db.activityLabour,
    )..where((l) => l.deleted.equals(false) & l.unit.equals('day'))).get()) {
      if (line.attendanceIds.isNotEmpty) {
        var remaining = line.quantity;
        for (final id in line.attendanceIds) {
          final entry = await (db.select(
            db.attendanceEntries,
          )..where((a) => a.id.equals(id))).getSingleOrNull();
          if (entry != null) {
            await _attach(
              'activityLabour',
              line.id,
              entry,
              math.min(1.0, math.max(.5, remaining)),
              migrating: true,
            );
          }
          remaining -= 1;
        }
      }
    }
    for (final line
        in await (db.select(db.lotLabour)..where(
              (l) =>
                  l.deleted.equals(false) &
                  l.unit.equalsValue(RateUnit.day) &
                  l.workerId.isNotNull(),
            ))
            .get()) {
      if (_validLegacy(line.qty, line.rate)) {
        await book(
          type: 'lot_labour',
          id: line.id,
          owner: key('lot_labour', line.id),
          worker: line.workerId!,
          on: line.date,
          quantity: line.qty,
          rate: line.rate,
          note: line.note,
          migrating: true,
        );
      }
    }
    for (final line in await (db.select(
      db.produceLabour,
    )..where((l) => l.deleted.equals(false) & l.unit.equals('day'))).get()) {
      if (_validLegacy(line.quantity, line.rate)) {
        await book(
          type: 'produceLabour',
          id: line.id,
          owner: key('produceLabour', line.id),
          worker: line.workerId,
          on: line.date,
          quantity: line.quantity,
          rate: line.rate,
          note: line.work,
          migrating: true,
        );
      }
    }
    await refresh();
  }

  bool _validLegacy(double q, int rate) =>
      q.isFinite &&
      q > 0 &&
      q <= 366 &&
      q * 2 == (q * 2).roundToDouble() &&
      rate > 0;
}
