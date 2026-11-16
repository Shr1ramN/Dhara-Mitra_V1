import 'dart:io';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../calendar/date_note.dart';
import '../labour/data/labour_repository.dart';

/// An editable workbook of farm records. Use Backup and restore for a full copy.
class FarmExcelExport {
  FarmExcelExport(this.db);
  final AppDatabase db;

  Future<List<int>> bytes() async {
    final snapshot = await db.transaction(() async {
      final sheets = <String, List<List<Object?>>>{};
      void sheet(
        String name,
        List<String> headers,
        Iterable<List<Object?>> rows,
      ) {
        final data = rows.toList();
        if (data.isNotEmpty) sheets[name] = [headers, ...data];
      }

      final notes =
          await (db.select(db.reminders)
                ..where(
                  (r) => r.kind.equals('dateNote') & r.deleted.equals(false),
                )
                ..orderBy([
                  (r) => OrderingTerm.asc(r.dueOn),
                  (r) => OrderingTerm.asc(r.id),
                ]))
              .get();
      final activities = <List<Object?>>[];
      final harvests = <List<Object?>>[];
      final sales = <List<Object?>>[];
      final saleItems = <List<Object?>>[];
      final purchases = <List<Object?>>[];
      for (final note in notes) {
        final data = noteValues(note.notes);
        switch (data['labelSource'] == 'custom'
            ? ''
            : note.title.trim().toLowerCase()) {
          case 'harvest':
          case 'ಕೊಯ್ಲು':
            harvests.add([
              note.dueOn,
              data['crop'],
              data['quantity'],
              data['unit'],
              data['description'],
            ]);
          case 'sale':
            final storedItems = data['items'];
            final items = storedItems is List
                ? storedItems.whereType<Map<Object?, Object?>>().toList()
                : const <Map<Object?, Object?>>[];
            final number = sales.length + 1;
            final primary = items.length == 1 ? items.single : data;
            sales.add([
              number,
              note.dueOn,
              data['buyer'],
              items.length > 1 ? 'See Crops sold' : primary['crop'],
              items.length > 1 ? null : primary['quantity'],
              items.length > 1 ? null : primary['unit'],
              _rupees(data['incomePaise']),
              data['description'],
            ]);
            if (items.length > 1) {
              for (final item in items) {
                saleItems.add([
                  number,
                  item['crop'],
                  item['quantity'],
                  item['unit'],
                ]);
              }
            }
          case 'purchase':
            purchases.add([
              note.dueOn,
              data['item'],
              _rupees(data['costPaise']),
              data['description'],
            ]);
          default:
            activities.add([
              note.dueOn,
              note.title,
              data['crop'],
              data['description'],
            ]);
        }
      }

      final oldActivities =
          await (db.select(db.activities)
                ..where((a) => a.deleted.equals(false))
                ..orderBy([(a) => OrderingTerm.asc(a.date)]))
              .get();
      for (final a in oldActivities) {
        activities.add([a.date, a.title, a.crops.join(', '), a.notes]);
      }
      final oldLots = await (db.select(
        db.lots,
      )..where((l) => l.deleted.equals(false))).get();
      for (final lot in oldLots) {
        harvests.add([
          lot.harvestedOn,
          lot.crop.name,
          lot.quantityMode == 'bags' ? lot.freshBags : lot.freshKg,
          lot.quantityMode,
          lot.notes,
        ]);
      }
      final oldProduce = await (db.select(
        db.produceLots,
      )..where((l) => l.deleted.equals(false))).get();
      for (final lot in oldProduce) {
        harvests.add([
          lot.harvestedOn,
          lot.crop,
          lot.freshQuantity,
          lot.freshUnit,
          lot.notes,
        ]);
      }
      final pickups = await (db.select(
        db.arecaCollections,
      )..where((p) => p.deleted.equals(false) & p.lotId.isNull())).get();
      for (final p in pickups) {
        harvests.add([p.collectedOn, 'areca', p.quantity, p.unit, p.notes]);
      }
      const activityHeaders = ['Date', 'Work type', 'Crop', 'Notes'];
      const harvestHeaders = ['Date', 'Crop', 'Quantity', 'Unit', 'Notes'];
      int byDate(List<Object?> a, List<Object?> b) =>
          (a.first as DateTime).compareTo(b.first as DateTime);
      sheet('Farm work', activityHeaders, activities..sort(byDate));
      sheet('Harvests', harvestHeaders, harvests..sort(byDate));
      sheet('Sales', [
        'Sale no.',
        'Date',
        'Buyer',
        'Crop',
        'Quantity',
        'Unit',
        'Income received (₹)',
        'Notes',
      ], sales);
      sheet('Crops sold', ['Sale no.', 'Crop', 'Quantity', 'Unit'], saleItems);
      sheet('Purchases', ['Date', 'Item', 'Cost (₹)', 'Notes'], purchases);

      final workers =
          await (db.select(db.workers)..orderBy([
                (w) => OrderingTerm.asc(w.name),
                (w) => OrderingTerm.asc(w.id),
              ]))
              .get();
      final nameCounts = <String, int>{};
      for (final worker in workers) {
        nameCounts.update(worker.name, (count) => count + 1, ifAbsent: () => 1);
      }
      final nameOccurrences = <String, int>{};
      final names = {
        for (final worker in workers)
          worker.id: nameCounts[worker.name] == 1
              ? worker.name
              : '${worker.name} (${nameOccurrences.update(worker.name, (n) => n + 1, ifAbsent: () => 1)})',
      };
      final txns =
          await (db.select(db.workerTxns)
                ..where((t) => t.deleted.equals(false))
                ..orderBy([
                  (t) => OrderingTerm.asc(t.date),
                  (t) => OrderingTerm.asc(t.id),
                ]))
              .get();
      final loans =
          await (db.select(db.workerLoanEntries)
                ..where((t) => t.deleted.equals(false))
                ..orderBy([
                  (t) => OrderingTerm.asc(t.date),
                  (t) => OrderingTerm.asc(t.id),
                ]))
              .get();
      final settlements = await (db.select(
        db.workerSettlements,
      )..where((s) => s.deleted.equals(false))).get();
      final attendance =
          await (db.select(db.attendanceEntries)
                ..where((a) => a.deleted.equals(false))
                ..orderBy([
                  (a) => OrderingTerm.asc(a.date),
                  (a) => OrderingTerm.asc(a.id),
                ]))
              .get();

      final wagesDue = <String, int>{};
      for (final t in txns) {
        wagesDue.update(
          t.workerId,
          (amount) => amount + (t.kind == TxnKind.work ? t.amount : -t.amount),
          ifAbsent: () => t.kind == TxnKind.work ? t.amount : -t.amount,
        );
      }
      final loansDue = <String, int>{};
      for (final loan in loans) {
        final change = loan.kind == 'previous' || loan.kind == 'new'
            ? loan.amount
            : -loan.amount;
        loansDue.update(
          loan.workerId,
          (amount) => amount + change,
          ifAbsent: () => change,
        );
      }
      sheet(
        'Workers',
        [
          'Worker',
          'Status',
          'Full-day wage (₹)',
          'Half-day wage (₹)',
          'Wages due (₹)',
          'Loan balance (₹)',
        ],
        [
          for (final w in workers.where((w) => !w.deleted))
            [
              names[w.id],
              w.active ? 'Active' : 'Inactive',
              w.wageType == 'daily' ? _rupees(w.dayRate) : null,
              w.wageType == 'daily'
                  ? _rupees(w.halfDayRate ?? (w.dayRate / 2).round())
                  : null,
              _rupees(wagesDue[w.id] ?? 0),
              _rupees(loansDue[w.id] ?? 0),
            ],
        ],
      );
      sheet(
        'Attendance',
        ['Date', 'Worker', 'Attendance', 'Wages earned (₹)', 'Work'],
        [
          for (final a in attendance)
            [
              a.date,
              names[a.workerId],
              switch (a.status) {
                AttendanceStatus.present => 'Full day',
                AttendanceStatus.half => 'Half day',
                AttendanceStatus.absent => 'Absent',
              },
              _rupees(a.amount),
              a.work,
            ],
        ],
      );
      final attendanceIds = {for (final a in attendance) a.id};
      final settlementById = {for (final s in settlements) s.id: s};
      final wages = <List<Object?>>[];
      for (final t in txns) {
        if (t.refType == refAttendance && attendanceIds.contains(t.refId)) {
          continue;
        }
        final settlement = t.refType == 'settlement'
            ? settlementById[t.refId]
            : null;
        wages.add([
          t.date,
          names[t.workerId],
          switch (t.kind) {
            TxnKind.work => 'Other work',
            TxnKind.payment => 'Payment',
            TxnKind.advance => 'Advance',
          },
          t.kind == TxnKind.work ? _rupees(t.amount) : null,
          t.kind == TxnKind.work
              ? null
              : _rupees(settlement?.cashPaid ?? t.amount),
          _rupees(settlement?.loanDeduction),
          t.mode?.name,
          settlement?.periodStart,
          settlement?.periodEnd,
          settlement?.note ?? t.note,
        ]);
      }
      sheet('Wages and payments', [
        'Date',
        'Worker',
        'Type',
        'Other wages (₹)',
        'Paid to worker (₹)',
        'Loan deduction (₹)',
        'Payment method',
        'Period start',
        'Period end',
        'Notes',
      ], wages);
      sheet(
        'Worker loans',
        ['Date', 'Worker', 'Type', 'Amount (₹)', 'Notes'],
        [
          for (final loan in loans)
            [
              loan.date,
              names[loan.workerId],
              switch (loan.kind) {
                'previous' => 'Earlier loan',
                'new' => 'New loan',
                'repayment' => 'Repayment',
                'deduction' => 'Deducted from wages',
                _ => loan.kind,
              },
              _rupees(loan.amount),
              loan.note,
            ],
        ],
      );

      if (sheets.isEmpty) sheets['Farm work'] = [activityHeaders];
      return sheets;
    });
    return compute(encodeFarmExcel, snapshot);
  }

  Future<File> save(File file) async =>
      file.writeAsBytes(await bytes(), flush: true);
}

double? _rupees(Object? paise) => paise is num ? paise / 100 : null;

List<int> encodeFarmExcel(Map<String, List<List<Object?>>> sheets) {
  final book = Excel.createExcel();
  CellValue? value(Object? v) => switch (v) {
    null => null,
    final int n => IntCellValue(n),
    final double n => DoubleCellValue(n),
    final DateTime d => DateCellValue.fromDateTime(d),
    _ => TextCellValue(v.toString()),
  };
  for (final entry in sheets.entries) {
    final target = book[entry.key];
    for (final row in entry.value) {
      target.appendRow(row.map(value).toList());
    }
    final headers = entry.value.first.cast<String>();
    for (var i = 0; i < headers.length; i++) {
      final header = headers[i];
      target
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E7EFE4'),
      );
      target.setColumnWidth(i, header == 'Notes' || header == 'Work' ? 42 : 24);
      if (header.endsWith('(₹)')) {
        for (var row = 1; row < entry.value.length; row++) {
          final cell = target.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
          );
          if (cell.value != null) {
            cell.cellStyle = CellStyle(numberFormat: NumFormat.standard_2);
          }
        }
      }
    }
  }
  book.delete('Sheet1');
  book.setDefaultSheet(sheets.keys.first);
  return book.encode()!;
}
