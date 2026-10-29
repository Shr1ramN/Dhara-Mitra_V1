import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/diary/data/diary_repository.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:dhara_mitra/features/produce/produce_repository.dart';
import 'package:dhara_mitra/features/reports/report_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late String worker;
  final day = DateTime(2026, 10, 10);
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    worker = await LabourRepository(db).saveWorker(
      WorkersCompanion.insert(name: 'Ravi', dayRate: const Value(80001)),
    );
  });
  tearDown(() => db.close());
  Future<String> areca({List<LabourInput> labour = const []}) =>
      LotsRepository(db).createHarvestLot(
        crop: Crop.areca,
        harvestedOn: day,
        title: 'Areca',
        plotIds: [],
        labour: labour,
      );
  LabourInput daily(double qty) =>
      LabourInput(workerId: worker, qty: qty, unit: RateUnit.day, rate: 80001);
  Future<String> produce() => ProduceRepository(db).harvest(
    crop: 'coconut',
    on: day,
    quantity: 20,
    unit: 'nut',
    title: 'Coconut',
  );
  Future<int> due() async => (await LabourRepository(
    db,
  ).watchWorkerSummaries().first).single.balance.due;
  Future<int> costs([String? crop]) async => (await ReportRepository(
    db,
  ).build(season: const Season(2026), today: day, crop: crop)).costs;
  test('attendance first and lot first each book one wage, with additional piecework', () async {
    await LabourRepository(db).saveAttendance(day, {
      worker: const AttendanceMark(AttendanceStatus.present),
    });
    final id = await areca(
      labour: [
        daily(1),
        LabourInput(workerId: worker, qty: 10, unit: RateUnit.palm, rate: 200),
      ],
    );
    expect(await due(), 82001);
    expect((await LotsRepository(db).loadLotViews()).single.totalCost, 82001);
    await LabourRepository(db).saveAttendance(day, {
      worker: const AttendanceMark(AttendanceStatus.half),
    });
    expect(await due(), 42001);
    expect((await LotsRepository(db).loadLotViews()).single.totalCost, 42001);
    expect(await costs('areca'), 42001);
    await LotsRepository(db).deleteLot(id);
    expect(await due(), 40001); // manual attendance retained; piecework removed
  });
  test('two entry-first half-day crop jobs grow one wage; deletion releases only its share', () async {
    final lot = await areca(labour: [daily(.5)]);
    expect(await due(), 40001);
    final p = await produce();
    await ProduceRepository(db).labour(
      p,
      workerId: worker,
      on: day,
      work: 'Collect',
      quantity: .5,
      unit: 'day',
      rate: 80001,
    );
    expect(await due(), 80001);
    expect(await costs(), 80001);
    final arecaCost = (await LotsRepository(
      db,
    ).loadLotViews()).single.totalCost;
    final coconutCost = (await ProduceRepository(db).load()).single.cost;
    expect(arecaCost + coconutCost, 80001);
    expect(await costs('areca'), arecaCost);
    expect(await costs('coconut'), coconutCost);
    await LotsRepository(db).deleteLot(lot);
    expect(await due(), 40001);
    expect((await ProduceRepository(db).load()).single.cost, 40001);
    await ProduceRepository(db).delete(p);
    expect(await due(), 0);
  });
  test(
    'diary and two lots share a corrected attendance wage with exact paise',
    () async {
      await LabourRepository(db).saveAttendance(day, {
        worker: const AttendanceMark(AttendanceStatus.present),
      });
      await DiaryRepository(db).save(
        date: day,
        kind: 'weeding',
        title: 'Weed',
        crops: ['banana'],
        labour: [daily(.5)],
      );
      final lot = await areca(labour: [daily(.5)]);
      await expectLater(
        areca(labour: [daily(.5)]),
        throwsA(isA<FarmException>()),
      );
      expect((await LotsRepository(db).loadLotViews()).length, 1);
      expect(await due(), 80001);
      expect(await costs(), 80001);
      await LabourRepository(db).saveAttendance(day, {
        worker: const AttendanceMark(AttendanceStatus.half),
      });
      final total =
          (await DiaryRepository(db).load()).single.labourCost +
          (await LotsRepository(db).loadLotViews()).single.totalCost;
      expect(total, 40001);
      expect(await costs(), 40001);
      await LabourRepository(db).saveAttendance(day, {
        worker: const AttendanceMark(AttendanceStatus.absent),
      });
      expect(await due(), 0);
      expect(await costs(), 0);
      await LabourRepository(db).saveAttendance(day, {
        worker: const AttendanceMark(AttendanceStatus.present),
      });
      expect(await due(), 80001);
      expect(await costs(), 80001);
      await LotsRepository(db).deleteLot(lot);
      expect(await due(), 80001); // manual day stays
      expect(
        await costs(),
        80001,
      ); // released share remains an unallocated attendance cost
    },
  );
  test('produce first later manual attendance adopts the wage; removal preserves it', () async {
    final id = await produce();
    await ProduceRepository(db).labour(
      id,
      workerId: worker,
      on: day,
      work: 'Pick',
      quantity: 1,
      unit: 'day',
      rate: 80001,
    );
    await LabourRepository(db).saveAttendance(day, {
      worker: const AttendanceMark(AttendanceStatus.present),
    });
    expect(await due(), 80001);
    final line = (await ProduceRepository(db).load()).single.labour.single;
    await ProduceRepository(db).deleteLabour(line.id);
    expect(await due(), 80001);
    expect((await ProduceRepository(db).load()).single.cost, 0);
  });
  test('multi-day jobs reuse each attendance and reject invalid requests atomically', () async {
    final id = await areca(labour: [daily(1.5)]);
    expect(await due(), 120002);
    expect((await db.select(db.attendanceEntries).get()).length, 2);
    await expectLater(
      LotsRepository(db).addLabour(id, LotStage.harvest, day, [daily(.3)]),
      throwsA(isA<FarmException>()),
    );
    expect((await LotsRepository(db).loadLotViews()).single.labour.length, 1);
    await LotsRepository(db).deleteLot(id);
    expect(await due(), 0);
  });
  test('schema 3 upgrade reconciles duplicate day wages, retains source rows and actual payments', () async {
    final root = await Directory.systemTemp.createTemp('wage-upgrade-');
    final file = File('${root.path}/old.sqlite');
    var disk = AppDatabase(NativeDatabase(file));
    try {
      final w = await disk
          .into(disk.workers)
          .insertReturning(
            WorkersCompanion.insert(
              name: 'Old worker',
              dayRate: const Value(80000),
            ),
          );
      final lot = await disk
          .into(disk.lots)
          .insertReturning(
            LotsCompanion.insert(
              code: 'A-01',
              crop: Crop.areca,
              seasonStartYear: 2026,
              title: 'Old lot',
              harvestedOn: day,
            ),
          );
      final line = await disk
          .into(disk.lotLabour)
          .insertReturning(
            LotLabourCompanion.insert(
              lotId: lot.id,
              stage: LotStage.harvest,
              workerId: Value(w.id),
              date: day,
              qty: 1,
              unit: RateUnit.day,
              rate: 80000,
              amount: 80000,
            ),
          );
      await LabourRepository(disk).saveAttendance(day, {
        w.id: const AttendanceMark(AttendanceStatus.present, work: 'Manual'),
      });
      await syncWorkTxn(
        disk,
        workerId: w.id,
        date: day,
        amount: 80000,
        note: 'Duplicate',
        refType: refLotLabour,
        refId: line.id,
      );
      await LabourRepository(disk).addPayment(
        workerId: w.id,
        date: day,
        kind: TxnKind.payment,
        amount: 50000,
      );
      await disk.customStatement('DROP TABLE daily_work_allocations');
      await disk.customStatement('DROP TABLE IF EXISTS sale_receipts');
      await disk.customStatement('PRAGMA user_version = 3');
      await disk.close();
      disk = AppDatabase(NativeDatabase(file));
      final summary = (await LabourRepository(
        disk,
      ).watchWorkerSummaries().first).single;
      expect(summary.balance.earned, 80000);
      expect(summary.balance.given, 50000);
      expect(summary.balance.due, 30000);
      expect((await disk.select(disk.lotLabour).get()).single.id, line.id);
      final oldTxn = (await disk.select(disk.workerTxns).get()).singleWhere(
        (t) => t.refId == line.id,
      );
      expect(oldTxn.deleted, isTrue);
      expect(oldTxn.amount, 80000);
      expect(
        (await disk.select(disk.attendanceEntries).get()).single.work,
        'Manual',
      );
      expect(
        (await LotsRepository(disk).loadLotViews()).single.totalCost,
        80000,
      );
    } finally {
      await disk.close();
      await root.delete(recursive: true);
    }
  });
}
