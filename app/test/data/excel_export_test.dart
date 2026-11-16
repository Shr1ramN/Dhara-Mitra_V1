import 'dart:convert';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/backup/excel_export.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:dhara_mitra/features/calendar/date_note.dart';
import 'package:dhara_mitra/features/farm/data/farm_crops.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/labour/data/payroll_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Excel exports readable, reconciled records without raw or duplicated data',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final w = await db
          .into(db.workers)
          .insertReturning(
            WorkersCompanion.insert(
              name: 'ರಾಮು',
              phone: const Value('09876543210'),
              dayRate: const Value(70000),
            ),
          );
      await db
          .into(db.workers)
          .insert(
            WorkersCompanion.insert(
              name: '=SUM(1,2)',
              wageType: const Value('other'),
            ),
          );
      final day = DateTime(2026, 10, 26),
          labour = LabourRepository(db),
          payroll = PayrollRepository(db);
      await labour.saveAttendance(day, {
        w.id: const AttendanceMark(AttendanceStatus.present),
      });
      await labour.saveAttendance(DateTime(2026, 10, 27), {
        w.id: const AttendanceMark(AttendanceStatus.half),
      });
      await labour.addPayment(
        workerId: w.id,
        date: day,
        kind: TxnKind.advance,
        amount: 10001,
      );
      await payroll.loan(
        workerId: w.id,
        date: day,
        kind: 'previous',
        amount: 50000,
      );
      await payroll.settle(
        workerId: w.id,
        date: DateTime(2026, 10, 28),
        start: day,
        end: DateTime(2026, 10, 28),
        cashPaid: 40000,
        deduction: 10000,
      );
      await payroll.loan(
        workerId: w.id,
        date: DateTime(2026, 10, 28),
        kind: 'repayment',
        amount: 10000,
      );
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              title: 'ಕೊಯ್ಲು',
              dueOn: day,
              kind: const Value('dateNote'),
              done: const Value(true),
              notes: Value(
                notePrefix +
                    jsonEncode({
                      'description': 'ಹಣ್ಣು ಕೊಯ್ಲು',
                      'crop': 'Mango',
                      'quantity': 12.5,
                      'unit': 'bags',
                    }),
              ),
            ),
          );
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              title: 'sale',
              dueOn: day,
              kind: const Value('dateNote'),
              done: const Value(true),
              notes: Value(
                notePrefix +
                    jsonEncode({
                      'crop': 'Mango',
                      'buyer': '=Buyer',
                      'quantity': 2.5,
                      'unit': 'kg',
                      'incomePaise': 123456,
                    }),
              ),
            ),
          );
      for (final (title, data, deleted) in [
        ('purchase', {'item': 'Seed bags', 'costPaise': 12345}, false),
        ('purchase', {'item': 'Deleted item', 'costPaise': 200}, true),
        (
          'sale',
          {'labelSource': 'custom', 'description': 'Custom work'},
          false,
        ),
      ]) {
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: title,
                dueOn: day,
                kind: const Value('dateNote'),
                notes: Value(notePrefix + jsonEncode(data)),
                deleted: Value(deleted),
              ),
            );
      }
      final before = (await labour.watchWorkerSummaries().first)
          .firstWhere((e) => e.worker.id == w.id)
          .balance
          .due;
      final book = Excel.decodeBytes(await FarmExcelExport(db).bytes());
      final sale = book['Sales'].rows[1];
      expect(sale[2]!.value.toString(), '=Buyer');
      expect(sale[2]!.value, isA<TextCellValue>());
      expect((sale[6]!.value as DoubleCellValue).value, 1234.56);
      expect(book.getDefaultSheet(), 'Farm work');
      expect(book.tables.keys, [
        'Farm work',
        'Harvests',
        'Sales',
        'Purchases',
        'Workers',
        'Attendance',
        'Wages and payments',
        'Worker loans',
      ]);
      final workerRows = book['Workers'].rows;
      final workerRow = workerRows.singleWhere(
        (row) => row[0]!.value.toString() == 'ರಾಮು',
      );
      expect((workerRow[4]!.value as DoubleCellValue).value, 449.99);
      expect(num.parse(workerRow[5]!.value.toString()), 300);
      final formulaName = workerRows.singleWhere(
        (row) => row[0]!.value.toString() == '=SUM(1,2)',
      );
      expect(formulaName[0]!.value, isA<TextCellValue>());
      expect(book['Attendance'].rows[1][0]!.value, isA<DateCellValue>());
      expect(book['Attendance'].rows[2][2]!.value.toString(), 'Half day');
      final wages = book['Wages and payments'].rows;
      expect(wages.length, 3);
      expect(num.parse(wages.last[4]!.value.toString()), 400);
      expect(num.parse(wages.last[5]!.value.toString()), 100);
      expect(wages.last[7]!.value, isA<DateCellValue>());
      expect(book['Harvests'].rows[1][1]!.value.toString(), 'Mango');
      expect(
        (book['Harvests'].rows[1][2]!.value as DoubleCellValue).value,
        12.5,
      );
      expect(book['Harvests'].rows[1][3]!.value.toString(), 'bags');
      expect(book['Purchases'].rows.length, 2);
      expect(
        (book['Purchases'].rows[1][2]!.value as DoubleCellValue).value,
        123.45,
      );
      expect(book['Farm work'].rows[1][3]!.value.toString(), 'Custom work');
      book['Workers']
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Edited offline',
      );
      expect((await labour.getWorker(w.id))!.name, 'ರಾಮು');
      expect(
        (await labour.watchWorkerSummaries().first)
            .firstWhere((e) => e.worker.id == w.id)
            .balance
            .due,
        before,
      );
    },
  );
  test(
    'crop edits keep old counts and historical activity crops intact',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final plot = await db
          .into(db.plots)
          .insertReturning(
            PlotsCompanion.insert(
              name: 'Old plot',
              arecaPalms: const Value(60),
            ),
          );
      final id = await db
          .into(db.activities)
          .insertReturning(
            ActivitiesCompanion.insert(
              date: DateTime(2026, 10, 1),
              kind: 'irrigation',
              title: 'Watered',
              crops: const Value(['areca']),
            ),
          );
      expect(await loadFarmCrops(db), ['Arecanut']);
      await saveFarmCrops(db, ['Mango', 'ಅವಕಾಡೊ']);
      expect(await loadFarmCrops(db), ['Mango', 'ಅವಕಾಡೊ']);
      expect(
        (await db.select(db.plots).getSingle()).arecaPalms,
        plot.arecaPalms,
      );
      expect((await db.select(db.activities).getSingle()).crops, id.crops);
      await saveFarmCrops(db, []);
      expect(await loadFarmCrops(db), isEmpty);
    },
  );
  test(
    'removed sales stay in storage and leave the calendar interface',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final buyer = await db
          .into(db.buyers)
          .insertReturning(BuyersCompanion.insert(name: 'Old buyer'));
      await db
          .into(db.sales)
          .insert(
            SalesCompanion.insert(
              date: DateTime(2026, 10, 1),
              buyerId: buyer.id,
            ),
          );
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(calendarRecordsProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        (await CalendarRepository(db).load()).any((r) => r.category == 'sale'),
        isTrue,
      );
      expect(
        (await container.read(calendarRecordsProvider.future))
            .any((r) => r.category == 'sale'),
        isFalse,
      );
      expect((await db.select(db.sales).get()).length, 1);
    },
  );
}
