import 'package:flutter/foundation.dart';

import 'dart:io';

import 'package:excel/excel.dart';

import '../../core/db/database.dart';
import '../calendar/date_note.dart';

/// A portable, typed snapshot. Editing it never writes back to the database.
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
        sheets[name] = [headers, ...rows];
      }

      sheet(
        'Guide',
        ['Dhara Mitra V3', 'Details'],
        [
          ['Exported at', DateTime.now().toIso8601String()],
          ['Database schema', db.schemaVersion],
          [
            'Multi-crop sales',
            'Income contains one total per sale. SaleItems contains crop quantities; join sale_record_id to Income.record_id. Do not sum a sale total once per crop.',
          ],
          ['Farm profile ID', db.profileId],
          [
            'Purpose',
            'Editable Excel snapshot for analysis. Editing this workbook does not change app data.',
          ],
          [
            'Money',
            'Primary sheets show rupees and exact integer paise. Raw sheets retain SQLite integers.',
          ],
          [
            'Dates',
            'Primary sheets use Excel dates. Raw SQLite date/time columns are Unix timestamps in seconds.',
          ],
          [
            'Record IDs',
            'Use stable worker_id and record_id columns to join sheets; names are not unique identifiers.',
          ],
          [
            'Old advances',
            'Historical advance credits retain their original effect on wages. New worker loans are separate.',
          ],
          [
            'Legacy data',
            'Raw_* sheets include every stored table, including removed features and soft-deleted history. Filter deleted=0 for current records.',
          ],
          [
            'ಭಾಷೆ',
            'ಮೂಲ ಹೆಸರುಗಳು ಮತ್ತು ಕನ್ನಡ ಪಠ್ಯ ಹಾಗೆಯೇ ಉಳಿಯುತ್ತವೆ. Excel ಬದಲಾವಣೆಗಳು ಆ್ಯಪ್‌ನ ದತ್ತಾಂಶವನ್ನು ಬದಲಾಯಿಸುವುದಿಲ್ಲ.',
          ],
        ],
      );
      final workers = await db.select(db.workers).get();
      final names = {for (final w in workers) w.id: w.name};
      final txns = (await db.select(db.workerTxns).get())
          .where((e) => !e.deleted)
          .toList();
      final loans = (await db.select(db.workerLoanEntries).get())
          .where((e) => !e.deleted)
          .toList();
      final settlements = (await db.select(db.workerSettlements).get())
          .where((e) => !e.deleted)
          .toList();
      sheet(
        'Workers',
        [
          'worker_id',
          'name',
          'phone',
          'village',
          'wage_type',
          'daily_wage_rupees',
          'daily_wage_paise',
          'half_day_wage_rupees',
          'active',
          'wages_due_rupees',
          'wages_due_paise',
          'loan_outstanding_rupees',
          'loan_outstanding_paise',
        ],
        [
          for (final w in workers.where((w) => !w.deleted))
            [
              w.id,
              w.name,
              w.phone,
              w.village,
              w.wageType,
              w.dayRate / 100,
              w.dayRate,
              w.halfDayRate == null ? null : w.halfDayRate! / 100,
              w.active,
              txns
                      .where((t) => t.workerId == w.id)
                      .fold<int>(
                        0,
                        (s, t) =>
                            s + (t.kind.name == 'work' ? t.amount : -t.amount),
                      ) /
                  100,
              txns
                  .where((t) => t.workerId == w.id)
                  .fold<int>(
                    0,
                    (s, t) =>
                        s + (t.kind.name == 'work' ? t.amount : -t.amount),
                  ),
              loans
                      .where((t) => t.workerId == w.id)
                      .fold<int>(
                        0,
                        (s, t) =>
                            s +
                            (['previous', 'new'].contains(t.kind)
                                ? t.amount
                                : -t.amount),
                      ) /
                  100,
              loans
                  .where((t) => t.workerId == w.id)
                  .fold<int>(
                    0,
                    (s, t) =>
                        s +
                        (['previous', 'new'].contains(t.kind)
                            ? t.amount
                            : -t.amount),
                  ),
            ],
        ],
      );
      final attendance = (await db.select(db.attendanceEntries).get()).where(
        (e) => !e.deleted,
      );
      sheet(
        'Attendance',
        [
          'record_id',
          'worker_id',
          'worker_name',
          'date',
          'status',
          'wage_rupees',
          'wage_paise',
          'work',
        ],
        [
          for (final a in attendance)
            [
              a.id,
              a.workerId,
              names[a.workerId],
              a.date,
              a.status.name,
              a.amount / 100,
              a.amount,
              a.work,
            ],
        ],
      );
      final settlementById = {for (final s in settlements) s.id: s};
      sheet(
        'Wages',
        [
          'record_id',
          'worker_id',
          'worker_name',
          'date',
          'kind',
          'ledger_rupees',
          'ledger_paise',
          'cash_paid_rupees',
          'loan_deduction_rupees',
          'mode',
          'note',
          'source_type',
          'source_id',
        ],
        [
          for (final t in txns)
            [
              t.id,
              t.workerId,
              names[t.workerId],
              t.date,
              t.kind.name,
              t.amount / 100,
              t.amount,
              t.kind.name == 'work'
                  ? null
                  : (settlementById[t.refId]?.cashPaid ?? t.amount) / 100,
              (settlementById[t.refId]?.loanDeduction ?? 0) / 100,
              t.mode?.name,
              t.note,
              t.refType,
              t.refId,
            ],
        ],
      );
      sheet(
        'Settlements',
        [
          'record_id',
          'worker_id',
          'worker_name',
          'payment_date',
          'period_start',
          'period_end',
          'paid_rupees',
          'paid_paise',
          'loan_deduction_rupees',
          'loan_deduction_paise',
          'note',
        ],
        [
          for (final s in settlements)
            [
              s.id,
              s.workerId,
              names[s.workerId],
              s.date,
              s.periodStart,
              s.periodEnd,
              s.cashPaid / 100,
              s.cashPaid,
              s.loanDeduction / 100,
              s.loanDeduction,
              s.note,
            ],
        ],
      );
      sheet(
        'WorkerLoans',
        [
          'record_id',
          'worker_id',
          'worker_name',
          'date',
          'kind',
          'amount_rupees',
          'amount_paise',
          'settlement_id',
          'note',
        ],
        [
          for (final l in loans)
            [
              l.id,
              l.workerId,
              names[l.workerId],
              l.date,
              l.kind,
              l.amount / 100,
              l.amount,
              l.settlementId,
              l.note,
            ],
        ],
      );
      final notes = (await db.select(db.reminders).get()).where(
        (e) => !e.deleted && e.kind == 'dateNote',
      );
      sheet(
        'FarmActivities',
        ['record_id', 'date', 'label', 'description', 'crop', 'source'],
        [
          for (final n in notes.where(
            (n) => ![
              'harvest',
              'ಕೊಯ್ಲು',
              'sale',
            ].contains(n.title.trim().toLowerCase()),
          ))
            [
              n.id,
              n.dueOn,
              n.title,
              noteValues(n.notes)['description'],
              noteValues(n.notes)['crop'],
              'date_note',
            ],
          for (final a in (await db.select(db.activities).get()).where(
            (a) => !a.deleted,
          ))
            [
              a.id,
              a.date,
              a.title,
              a.notes,
              a.crops.join(', '),
              'legacy_activity',
            ],
        ],
      );
      sheet(
        'Income',
        [
          'record_id',
          'date',
          'crop',
          'buyer',
          'quantity',
          'unit',
          'income_rupees',
          'income_paise',
          'description',
          'harvest_record_id',
        ],
        [
          for (final n in notes.where((n) => n.title == 'sale'))
            [
              n.id,
              n.dueOn,
              noteValues(n.notes)['crop'],
              noteValues(n.notes)['buyer'],
              noteValues(n.notes)['quantity'],
              noteValues(n.notes)['unit'],
              (noteValues(n.notes)['incomePaise'] as int) / 100,
              noteValues(n.notes)['incomePaise'],
              noteValues(n.notes)['description'],
              noteValues(n.notes)['harvestId'],
            ],
        ],
      );
      sheet(
        'SaleItems',
        ['sale_record_id', 'crop', 'quantity', 'unit'],
        [
          for (final n in notes.where((n) => n.title == 'sale'))
            if (noteValues(n.notes)['items'] is List)
              for (final item
                  in (noteValues(n.notes)['items'] as List)
                      .whereType<Map<Object?, Object?>>()
                      .map((e) => e.cast<String, dynamic>()))
                [n.id, item['crop'], item['quantity'], item['unit']]
            else
              [
                n.id,
                noteValues(n.notes)['crop'],
                noteValues(n.notes)['quantity'],
                noteValues(n.notes)['unit'],
              ],
        ],
      );
      sheet(
        'Harvests',
        [
          'record_id',
          'date',
          'crop',
          'quantity',
          'unit',
          'description',
          'source',
        ],
        [
          for (final n in notes.where(
            (n) => ['harvest', 'ಕೊಯ್ಲು'].contains(n.title.trim().toLowerCase()),
          ))
            [
              n.id,
              n.dueOn,
              noteValues(n.notes)['crop'],
              noteValues(n.notes)['quantity'],
              noteValues(n.notes)['unit'],
              noteValues(n.notes)['description'],
              'date_note',
            ],
          for (final l in (await db.select(db.lots).get()).where(
            (l) => !l.deleted,
          ))
            [
              l.id,
              l.harvestedOn,
              l.crop.name,
              l.quantityMode == 'bags' ? l.freshBags : l.freshKg,
              l.quantityMode,
              l.notes,
              'legacy_lot',
            ],
          for (final l in (await db.select(db.produceLots).get()).where(
            (l) => !l.deleted,
          ))
            [
              l.id,
              l.harvestedOn,
              l.crop,
              l.freshQuantity,
              l.freshUnit,
              l.notes,
              'legacy_produce',
            ],
          for (final l in (await db.select(db.arecaCollections).get()).where(
            (l) => !l.deleted && l.lotId == null,
          ))
            [
              l.id,
              l.collectedOn,
              'areca',
              l.quantity,
              l.unit,
              l.notes,
              'legacy_collection',
            ],
        ],
      );
      // Raw sheets preserve all old fields and soft-deleted records for technical users.
      for (final table in db.allTables) {
        final rows = await db
            .customSelect('SELECT * FROM "${table.actualTableName}"')
            .get();
        final columns = table.$columns.map((c) => c.$name).toList();
        final name = 'Raw_${table.actualTableName}';
        sheet(name.length > 31 ? name.substring(0, 31) : name, columns, [
          for (final row in rows)
            [for (final column in columns) row.data[column]],
        ]);
      }
      return sheets;
    });
    return compute(encodeFarmExcel, snapshot);
  }

  Future<File> save(File file) async =>
      file.writeAsBytes(await bytes(), flush: true);
}

List<int> encodeFarmExcel(Map<String, List<List<Object?>>> sheets) {
  final book = Excel.createExcel();
  CellValue value(Object? v) => switch (v) {
    null => TextCellValue(''),
    final int n => IntCellValue(n),
    final double n => DoubleCellValue(n),
    final bool b => BoolCellValue(b),
    final DateTime d => DateCellValue.fromDateTime(d),
    _ => TextCellValue(v.toString()),
  };
  for (final entry in sheets.entries) {
    final target = book[entry.key];
    for (final row in entry.value) {
      target.appendRow(row.map(value).toList());
    }
    for (var i = 0; i < entry.value.first.length; i++) {
      final header = entry.value.first[i].toString();
      target
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E7EFE4'),
        textWrapping: TextWrapping.WrapText,
      );
      target.setColumnWidth(
        i,
        header.contains('note') || header.contains('description') ? 40 : 22,
      );
    }
  }
  book.delete('Sheet1');
  book.setDefaultSheet('Guide');
  return book.encode()!;
}
