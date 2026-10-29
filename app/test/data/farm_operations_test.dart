import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/diary/data/diary_repository.dart';
import 'package:dhara_mitra/features/finance/finance_repository.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/loans/data/loans_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:dhara_mitra/features/stock/data/stock_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StockRepository stock;
  late DiaryRepository diary;
  final day = DateTime(2026, 10, 10);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    stock = StockRepository(db);
    diary = DiaryRepository(db);
  });
  tearDown(() => db.close());
  Future<String> item({double quantity = 100, int cost = 10000}) async {
    final id = await stock.saveItem(name: 'Urea', unit: 'kg', minimum: 10);
    await stock.purchase(itemId: id, date: day, quantity: quantity, cost: cost);
    return id;
  }

  Future<String> worker() async => LabourRepository(db).saveWorker(
    WorkersCompanion.insert(name: 'Test worker', dayRate: const Value(80000)),
  );
  test(
    'diary commits inventory, purchase cost and worker ledger together',
    () async {
      final input = await item();
      final w = await worker();
      await diary.save(
        date: day,
        days: 2,
        kind: 'fertiliser',
        title: 'Fertiliser',
        inputs: [InputUse(input, 10)],
        labour: [
          LabourInput(workerId: w, qty: 2, unit: RateUnit.day, rate: 80000),
        ],
      );
      final balance = (await stock.balances()).single;
      expect(balance.quantity, 90);
      expect(balance.value, 9000);
      final activity = (await diary.load()).single;
      expect(activity.inputCost, 1000);
      expect(activity.labourCost, 160000);
      expect(
        (await LabourRepository(
          db,
        ).watchWorkerSummaries().first).single.balance.due,
        160000,
      );
    },
  );
  test('insufficient stock rolls back the entire entry', () async {
    final input = await item();
    final w = await worker();
    await expectLater(
      diary.save(
        date: day,
        kind: 'spray',
        title: 'Spray',
        inputs: [InputUse(input, 101)],
        labour: [
          LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
        ],
      ),
      throwsA(isA<FarmException>()),
    );
    expect(await diary.load(), isEmpty);
    expect((await stock.balances()).single.quantity, 100);
    expect(await db.select(db.workerTxns).get(), isEmpty);
  });
  test('editing replaces links; deleting restores stock and clears linked wages/reminder', () async {
    final input = await item();
    final w = await worker();
    final id = await diary.save(
      date: day,
      kind: 'fertiliser',
      title: 'First',
      remindOn: DateTime(2026, 11, 20),
      inputs: [InputUse(input, 10)],
      labour: [
        LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
      ],
    );
    await diary.save(
      id: id,
      date: day,
      kind: 'fertiliser',
      title: 'Edited',
      inputs: [InputUse(input, 5)],
      labour: [
        LabourInput(workerId: w, qty: 0.5, unit: RateUnit.day, rate: 80000),
      ],
    );
    expect((await stock.balances()).single.quantity, 95);
    expect(
      (await LabourRepository(
        db,
      ).watchWorkerSummaries().first).single.balance.due,
      40000,
    );
    await diary.delete(id);
    expect((await stock.balances()).single.quantity, 100);
    expect(
      (await LabourRepository(
        db,
      ).watchWorkerSummaries().first).single.balance.due,
      0,
    );
    expect(
      await (db.select(
        db.reminders,
      )..where((r) => r.deleted.equals(false))).get(),
      isEmpty,
    );
  });
  test('failed edit retains the original entry and stock', () async {
    final input = await item();
    final id = await diary.save(
      date: day,
      kind: 'spray',
      title: 'Original',
      inputs: [InputUse(input, 5)],
    );
    await expectLater(
      diary.save(
        id: id,
        date: day,
        kind: 'spray',
        title: 'Bad edit',
        inputs: [InputUse(input, 1000)],
      ),
      throwsA(isA<FarmException>()),
    );
    expect((await diary.load()).single.activity.title, 'Original');
    expect((await stock.balances()).single.quantity, 95);
  });
  test('duplicate input lines cannot overspend stock and average purchase cost is preserved', () async {
    final input = await item(quantity: 3, cost: 100);
    await diary.save(
      date: day,
      kind: 'spray',
      title: 'Two uses',
      inputs: [InputUse(input, 1), InputUse(input, 1)],
    );
    expect((await diary.load()).single.inputCost, 67);
    expect((await stock.balances()).single.value, 33);
    await diary.save(
      date: day,
      kind: 'spray',
      title: 'Last use',
      inputs: [InputUse(input, 1)],
    );
    expect((await stock.balances()).single.value, 0);
    expect((await stock.balances()).single.quantity, 0);
  });
  test('stock units cannot be changed once purchases exist', () async {
    final input = await item();
    await expectLater(
      stock.saveItem(id: input, name: 'Urea', unit: 'bag'),
      throwsA(isA<FarmException>()),
    );
  });
  test('loan disbursement is distinct from the sanctioned limit; overpayment rolls back', () async {
    final repo = LoansRepository(db);
    final id = await repo.create(
      lender: 'PACS',
      lenderKind: 'society',
      kind: 'crop_kcc',
      sanctioned: 10000000,
      sanctionedOn: day,
      annualRate: 10,
      withdrawn: 5000000,
    );
    expect((await repo.load(day)).single.balance.principal, 5000000);
    await expectLater(
      repo.addTransaction(
        loanId: id,
        date: day,
        kind: 'principal',
        amount: 6000000,
      ),
      throwsA(isA<FarmException>()),
    );
    expect((await repo.load(day)).single.transactions.length, 1);
    await repo.addTransaction(
      loanId: id,
      date: day,
      kind: 'principal',
      amount: 5000000,
    );
    await repo.close(id, day);
    expect((await repo.load(day)).single.loan.status, 'closed');
    expect((await db.select(db.reminders).get()).single.done, isTrue);
  });
  test(
    'insurance receipts cannot exceed the claim and require a receipt date',
    () async {
      final finance = FinanceRepository(db);
      final policy = await finance.policy(
        scheme: 'Test policy',
        crop: 'areca',
        season: 2026,
        acres: 1,
        premium: 10000,
        paidOn: day,
        number: 'P-1',
      );
      await expectLater(
        finance.claim(
          policyId: policy,
          lossOn: day,
          claimed: 10000,
          received: 20000,
          receivedOn: day,
        ),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        finance.claim(
          policyId: policy,
          lossOn: day,
          claimed: 10000,
          received: 100,
        ),
        throwsA(isA<FarmException>()),
      );
      expect(await db.select(db.insuranceClaims).get(), isEmpty);
    },
  );
  test(
    'v1 to current migration retains existing farm, worker and lot data',
    () async {
      final dir = await Directory.systemTemp.createTemp('dhara-migration-');
      final file = File('${dir.path}/old.sqlite');
      var disk = AppDatabase(NativeDatabase(file));
      try {
        await disk
            .into(disk.farms)
            .insert(FarmsCompanion.insert(name: 'Existing farm'));
        await disk
            .into(disk.workers)
            .insert(WorkersCompanion.insert(name: 'Existing worker'));
        await disk
            .into(disk.lots)
            .insert(
              LotsCompanion.insert(
                code: 'A-2627-01',
                crop: Crop.areca,
                seasonStartYear: 2026,
                title: 'Existing lot',
                harvestedOn: day,
              ),
            );
        final originalTables = {
          'app_settings',
          'farms',
          'plots',
          'workers',
          'attendance_entries',
          'worker_txns',
          'lots',
          'lot_events',
          'lot_labour',
          'lot_grades',
          'buyers',
          'sales',
          'sale_lines',
        };
        for (final table in disk.allTables.toList().reversed) {
          if (!originalTables.contains(table.actualTableName)) {
            await disk.customStatement('DROP TABLE "${table.actualTableName}"');
          }
        }
        await disk.customStatement(
          'ALTER TABLE attendance_entries DROP COLUMN rate',
        );
        await disk.customStatement(
          'ALTER TABLE attendance_entries DROP COLUMN source_activity_id',
        );
        await disk.customStatement('DROP TABLE IF EXISTS sale_receipts');
        await disk.customStatement('PRAGMA user_version = 1');
        for (final column in ['telephone', 'custom_roles']) {
          await disk.customStatement('ALTER TABLE workers DROP COLUMN $column');
        }
        for (final column in ['quantity_mode', 'fresh_bags', 'dried_bags']) {
          await disk.customStatement('ALTER TABLE lots DROP COLUMN $column');
        }
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        expect(
          (await disk.select(disk.farms).get()).single.name,
          'Existing farm',
        );
        expect(
          (await disk.select(disk.workers).get()).single.name,
          'Existing worker',
        );
        expect(
          (await disk.select(disk.lots).get()).single.title,
          'Existing lot',
        );
        expect(await disk.select(disk.activities).get(), isEmpty);
        expect(await disk.select(disk.insurancePolicies).get(), isEmpty);
      } finally {
        await disk.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
