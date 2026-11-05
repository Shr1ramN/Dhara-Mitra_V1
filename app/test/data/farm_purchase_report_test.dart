import 'dart:convert';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:dhara_mitra/features/calendar/date_note.dart';
import 'package:dhara_mitra/features/reports/report_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('purchases, sales and labour reconcile after edit and delete', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final date = DateTime(2026, 11, 5, 17);
    String purchase(int amount) =>
        notePrefix + jsonEncode({'item': 'Fertiliser', 'costPaise': amount});
    final bought = await db
        .into(db.reminders)
        .insertReturning(
          RemindersCompanion.insert(
            title: 'purchase',
            dueOn: date,
            kind: const Value('dateNote'),
            notes: Value(purchase(12345)),
            done: const Value(true),
          ),
        );
    await db
        .into(db.reminders)
        .insert(
          RemindersCompanion.insert(
            title: 'sale',
            dueOn: date,
            kind: const Value('dateNote'),
            notes: Value(
              notePrefix +
                  jsonEncode({
                    'buyer': 'Ramesh',
                    'incomePaise': 50000,
                    'items': [
                      {'crop': 'Areca', 'quantity': 5, 'unit': 'kg'},
                    ],
                  }),
            ),
          ),
        );
    final worker = await db
        .into(db.workers)
        .insertReturning(WorkersCompanion.insert(name: 'Worker'));
    await db
        .into(db.workerTxns)
        .insert(
          WorkerTxnsCompanion.insert(
            workerId: worker.id,
            date: date,
            kind: TxnKind.work,
            amount: 20000,
          ),
        );
    await db
        .into(db.workerTxns)
        .insert(
          WorkerTxnsCompanion.insert(
            workerId: worker.id,
            date: date,
            kind: TxnKind.payment,
            amount: 10000,
          ),
        );
    // This future purchase must not affect today's total.
    await db
        .into(db.reminders)
        .insert(
          RemindersCompanion.insert(
            title: 'purchase',
            dueOn: DateTime(2026, 11, 6),
            kind: const Value('dateNote'),
            notes: Value(purchase(99999)),
          ),
        );
    Future<FarmReport> report() => ReportRepository(db).build(
      season: Season(2026),
      today: DateTime(2026, 11, 5),
      rangeStart: DateTime(1900),
      rangeEnd: DateTime(2026, 11, 5),
    );
    var r = await report();
    expect(r.income, 50000);
    expect(r.costs, 32345); // wages counted once; paying wages adds no cost.
    final records = await CalendarRepository(db).load();
    final record = records.singleWhere((e) => e.id == bought.id);
    expect(calendarCategoryMatches(record, 'expense'), isTrue);
    expect(record.notes, contains('Fertiliser'));
    expect(RecordQuery('fertiliser').matches(record), isTrue);
    await (db.update(db.reminders)..where((e) => e.id.equals(bought.id))).write(
      RemindersCompanion(notes: Value(purchase(6000))),
    );
    r = await report();
    expect(r.costs, 26000);
    await (db.update(db.reminders)..where((e) => e.id.equals(bought.id))).write(
      const RemindersCompanion(deleted: Value(true)),
    );
    expect((await report()).costs, 20000);
    expect(
      (await CalendarRepository(db).load()).where((e) => e.id == bought.id),
      isEmpty,
    );
  });
}
