import 'package:drift/drift.dart';

import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/db/database.dart';
import '../../../core/validation.dart';
import '../../labour/data/labour_repository.dart';
import '../../labour/data/daily_work.dart';
import '../../lots/data/lots_repository.dart';
import '../../stock/data/stock_repository.dart';

const activityKinds = [
  'manure',
  'fertiliser',
  'spray',
  'irrigation',
  'weeding',
  'mulching',
  'harvest',
  'cropCare',
  'other',
];

class InputUse {
  const InputUse(this.itemId, this.quantity);
  final String itemId;
  final double quantity;
}

class ActivityView {
  const ActivityView(this.activity, this.inputs, this.labour);
  final Activity activity;
  final List<ActivityInput> inputs;
  final List<ActivityLabourData> labour;
  int get inputCost => inputs.fold(0, (s, i) => s + i.cost);
  int get labourCost => labour.fold(0, (s, l) => s + l.amount);
  int get total => inputCost + labourCost;
}

class DiaryRepository {
  DiaryRepository(this.db);
  final AppDatabase db;

  Stream<List<ActivityView>> watchAll() => db.watchAll([
    db.activities,
    db.activityInputs,
    db.activityLabour,
    db.attendanceEntries,
  ], load);

  Future<List<ActivityView>> load() async {
    final entries =
        await (db.select(db.activities)
              ..where((a) => a.deleted.equals(false))
              ..orderBy([
                (a) => OrderingTerm.desc(a.date),
                (a) => OrderingTerm.desc(a.updatedAt),
              ]))
            .get();
    final inputs = await (db.select(
      db.activityInputs,
    )..where((a) => a.deleted.equals(false))).get();
    final labour = await (db.select(
      db.activityLabour,
    )..where((a) => a.deleted.equals(false))).get();
    final quantities = await DailyWork(db).quantities();
    final resolved = [
      for (final line in labour)
        line.copyWith(
          quantity:
              quantities[DailyWork.key('activityLabour', line.id)] ??
              line.quantity,
        ),
    ];
    return [
      for (final a in entries)
        ActivityView(
          a,
          inputs.where((i) => i.activityId == a.id).toList(),
          resolved.where((l) => l.activityId == a.id).toList(),
        ),
    ];
  }

  Future<String> save({
    String? id,
    required DateTime date,
    required String kind,
    required String title,
    int days = 1,
    List<String> crops = const [],
    List<String> plotIds = const [],
    String notes = '',
    DateTime? remindOn,
    List<InputUse> inputs = const [],
    List<LabourInput> labour = const [],
  }) => db.transaction(() async {
    require(title.trim().isNotEmpty && activityKinds.contains(kind));
    require(days > 0 && days <= 366);
    if (remindOn != null) {
      require(!dateOnly(remindOn).isBefore(dateOnly(date)), 'dates');
    }
    if (id != null) await _removeLinks(id);
    final activityId = id ?? newId();
    final row = ActivitiesCompanion.insert(
      id: Value(activityId),
      date: dateOnly(date),
      kind: kind,
      title: title.trim(),
      days: Value(days),
      crops: Value(crops),
      plotIds: Value(plotIds),
      notes: Value(notes.trim()),
      remindOn: Value(remindOn == null ? null : dateOnly(remindOn)),
      updatedAt: Value(DateTime.now()),
    );
    await db.into(db.activities).insertOnConflictUpdate(row);
    final grouped = <String, double>{};
    for (final input in inputs) {
      positive(input.quantity);
      grouped.update(
        input.itemId,
        (q) => q + input.quantity,
        ifAbsent: () => input.quantity,
      );
    }
    final balances = await StockRepository(db).balances();
    for (final e in grouped.entries) {
      final balance = balances.where((s) => s.item.id == e.key).firstOrNull;
      require(
        balance != null && e.value <= balance.quantity + 0.000001,
        'stock',
      );
      final cost = balance!.quantity - e.value < 0.000001
          ? balance.value
          : (e.value * balance.value / balance.quantity).round();
      final input = await db
          .into(db.activityInputs)
          .insertReturning(
            ActivityInputsCompanion.insert(
              activityId: activityId,
              itemId: e.key,
              quantity: e.value,
              cost: cost,
            ),
          );
      await db
          .into(db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              itemId: e.key,
              date: dateOnly(date),
              kind: 'usage',
              quantity: -e.value,
              cost: -cost,
              refId: Value(input.id),
              note: Value(title.trim()),
            ),
          );
    }
    for (final line in labour) {
      require(line.workerId != null);
      positive(line.qty);
      positive(line.rate);
      final entry = await db
          .into(db.activityLabour)
          .insertReturning(
            ActivityLabourCompanion.insert(
              activityId: activityId,
              workerId: line.workerId!,
              quantity: line.qty,
              unit: line.unit.name,
              rate: line.rate,
              amount: line.amount,
            ),
          );
      if (line.unit == RateUnit.day) {
        require(line.qty <= days, 'attendance');
        await DailyWork(db).book(
          type: 'activityLabour',
          id: entry.id,
          owner: activityId,
          worker: line.workerId!,
          on: date,
          quantity: line.qty,
          rate: line.rate,
          note: title.trim(),
        );
      } else {
        await syncWorkTxn(
          db,
          workerId: line.workerId!,
          date: dateOnly(date),
          amount: line.amount,
          note: title.trim(),
          refType: 'activityLabour',
          refId: entry.id,
        );
      }
    }
    final oldReminders =
        await (db.select(db.reminders)..where(
              (r) => r.kind.equals('activity') & r.refId.equals(activityId),
            ))
            .get();
    for (final r in oldReminders) {
      await (db.update(db.reminders)..where((t) => t.id.equals(r.id))).write(
        RemindersCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    if (remindOn != null) {
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              title: title.trim(),
              dueOn: dateOnly(remindOn),
              kind: const Value('activity'),
              refId: Value(activityId),
            ),
          );
    }
    return activityId;
  });

  Future<void> _removeLinks(String id) async {
    final now = DateTime.now();
    final inputs = await (db.select(
      db.activityInputs,
    )..where((i) => i.activityId.equals(id) & i.deleted.equals(false))).get();
    for (final i in inputs) {
      await (db.update(
        db.stockMovements,
      )..where((m) => m.refId.equals(i.id) & m.kind.equals('usage'))).write(
        StockMovementsCompanion(
          deleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    final labour = await (db.select(
      db.activityLabour,
    )..where((l) => l.activityId.equals(id) & l.deleted.equals(false))).get();
    for (final l in labour) {
      await DailyWork(db).release('activityLabour', l.id);
      await (db.update(db.workerTxns)..where(
            (t) => t.refType.equals('activityLabour') & t.refId.equals(l.id),
          ))
          .write(
            WorkerTxnsCompanion(
              deleted: const Value(true),
              updatedAt: Value(now),
            ),
          );
    }
    await (db.update(
      db.activityInputs,
    )..where((i) => i.activityId.equals(id))).write(
      ActivityInputsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await (db.update(
      db.activityLabour,
    )..where((l) => l.activityId.equals(id))).write(
      ActivityLabourCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> delete(String id) => db.transaction(() async {
    await _removeLinks(id);
    await (db.update(db.activities)..where((a) => a.id.equals(id))).write(
      ActivitiesCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (db.update(
      db.reminders,
    )..where((r) => r.kind.equals('activity') & r.refId.equals(id))).write(
      RemindersCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
}
