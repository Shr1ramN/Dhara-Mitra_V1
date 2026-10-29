import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/money.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/farm/data/farm_repository.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:dhara_mitra/features/lots/domain/lot_view.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FarmRepository farm;
  late LabourRepository labour;
  late LotsRepository lots;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    farm = FarmRepository(db);
    labour = LabourRepository(db);
    lots = LotsRepository(db);
  });

  tearDown(() => db.close());

  Future<String> addWorker(
    String name, {
    int dayRate = 80000,
    int? pieceRate,
    RateUnit? unit,
  }) => labour.saveWorker(
    WorkersCompanion.insert(
      name: name,
      dayRate: Value(dayRate),
      pieceRate: Value(pieceRate),
      pieceUnit: Value(unit),
    ),
  );

  Future<int> dueOf(String workerId) async =>
      (await labour.watchWorkerSummaries().first)
          .firstWhere((s) => s.worker.id == workerId)
          .balance
          .due;

  group('farm', () {
    test('saves the farm and plots', () async {
      final id = await farm.saveFarm(name: 'Bhat Thota', village: 'Kemminje');
      await farm.savePlot(
        PlotsCompanion.insert(
          name: 'Upper plot',
          acres: const Value(1.5),
          arecaPalms: const Value(750),
        ),
      );
      expect((await farm.getFarm())!.id, id);
      final plots = await farm.watchPlots().first;
      expect(plots.single.arecaPalms, 750);
      await farm.deletePlot(plots.single.id);
      expect(await farm.watchPlots().first, isEmpty);
    });

    test('settings round-trip', () async {
      expect(await db.setting('language'), isNull);
      await db.putSetting('language', 'kn');
      await db.putSetting('language', 'en');
      expect(await db.setting('language'), 'en');
    });
  });

  group('labour', () {
    test('attendance books wages, re-saving does not double count', () async {
      final abdul = await addWorker('Abdul', dayRate: rupees(800));
      final mohan = await addWorker('Mohan', dayRate: rupees(800));
      final day = DateTime(2026, 10, 21);

      await labour.saveAttendance(day, {
        abdul: const AttendanceMark(
          AttendanceStatus.present,
          work: 'Fertiliser',
        ),
        mohan: const AttendanceMark(AttendanceStatus.half),
      });
      expect(await dueOf(abdul), rupees(800));
      expect(await dueOf(mohan), rupees(400));

      await labour.saveAttendance(day, {
        abdul: const AttendanceMark(
          AttendanceStatus.present,
          work: 'Fertiliser',
        ),
        mohan: const AttendanceMark(AttendanceStatus.absent),
      });
      expect(await dueOf(abdul), rupees(800));
      expect(await dueOf(mohan), 0);

      final marks = await labour.watchAttendance(day).first;
      expect(marks[abdul]!.status, AttendanceStatus.present);
      expect(marks[mohan]!.status, AttendanceStatus.absent);
    });

    test('payments and advances reduce what is due; ledger keeps a running balance', () async {
      final w = await addWorker('Shekhar', dayRate: rupees(1300));
      await labour.saveAttendance(DateTime(2026, 10, 5), {
        w: const AttendanceMark(AttendanceStatus.present),
      });
      await labour.saveAttendance(DateTime(2026, 10, 6), {
        w: const AttendanceMark(AttendanceStatus.present),
      });
      await labour.addPayment(
        workerId: w,
        date: DateTime(2026, 10, 7),
        kind: TxnKind.payment,
        amount: rupees(2000),
      );
      await labour.addPayment(
        workerId: w,
        date: DateTime(2026, 10, 8),
        kind: TxnKind.advance,
        amount: rupees(500),
        mode: PayMode.upi,
      );

      expect(await dueOf(w), rupees(100));
      final ledger = await labour.watchLedger(w).first;
      expect(ledger.map((l) => l.dueAfter), [
        rupees(1300),
        rupees(2600),
        rupees(600),
        rupees(100),
      ]);

      await labour.deleteTxn(ledger.last.txn.id);
      expect(await dueOf(w), rupees(600));

      await labour.deleteTxn(ledger.first.txn.id);
      expect(
        await dueOf(w),
        rupees(600),
        reason: 'work entries are not deleted from the ledger screen',
      );
    });
  });

  group('lots', () {
    test(
      'the full chali journey, with costs, partial sales and profit',
      () async {
        final ramesh = await addWorker(
          'Ramesh',
          pieceRate: rupees(8),
          unit: RateUnit.palm,
        );
        final lakshmi = await addWorker(
          'Lakshmi',
          pieceRate: rupees(7),
          unit: RateUnit.kg,
        );
        final plot = await farm.savePlot(
          PlotsCompanion.insert(name: 'Upper plot'),
        );

        final id = await lots.createHarvestLot(
          crop: Crop.areca,
          harvestedOn: DateTime(2026, 1, 12),
          title: 'Harvest round 3',
          plotIds: [plot],
          palmsClimbed: 820,
          labour: [
            LabourInput(
              workerId: ramesh,
              qty: 820,
              unit: RateUnit.palm,
              rate: rupees(8),
            ),
          ],
        );

        Future<LotView> view() async => (await lots.loadLotViews()).single;

        var v = await view();
        expect(v.lot.code, 'A-2526-01');
        expect(v.stage, LotStage.harvest);
        expect(v.plots.single.name, 'Upper plot');
        expect(await dueOf(ramesh), rupees(6560));

        await lots.startDrying(
          id,
          on: DateTime(2026, 1, 13),
          yard: 'Main yard',
        );
        await lots.addEvent(id, LotEventKind.cover);
        v = await view();
        expect(v.stage, LotStage.drying);
        expect(v.dryingDayOn(DateTime(2026, 1, 22)), 10);
        expect(v.count(LotEventKind.cover), 1);

        await lots.finishDrying(id, on: DateTime(2026, 2, 24), driedKg: 1460);
        expect((await view()).stage, LotStage.peeling);

        await lots.recordPeeling(
          id,
          on: DateTime(2026, 3, 1),
          chaliKg: 1080,
          peelers: [
            LabourInput(
              workerId: lakshmi,
              qty: 540,
              unit: RateUnit.kg,
              rate: rupees(7),
            ),
          ],
        );
        v = await view();
        expect(v.stage, LotStage.grading);
        expect(v.outTurn, closeTo(73.97, 0.01));
        expect(v.labourCost(LotStage.peeling), rupees(3780));

        await lots.setGrades(id, {
          ArecaGrade.chali: 940,
          ArecaGrade.patora: 90,
          ArecaGrade.koka: 50,
        });
        await lots.store(
          id,
          on: DateTime(2026, 3, 2),
          place: 'Attic',
          bags: 14,
          pricePerKg: rupees(445),
        );
        v = await view();
        expect(v.stage, LotStage.storage);
        expect(v.gradedKg, 1080);

        final campco = await lots.saveBuyer(
          name: 'CAMPCO Puttur',
          kind: BuyerKind.campco,
        );
        await lots.recordSale(
          lotId: id,
          buyerId: campco,
          date: DateTime(2026, 9, 10),
          lines: [
            SaleLineInput(grade: ArecaGrade.chali, kg: 500, rate: rupees(480)),
          ],
          deductions: rupees(1200),
          received: rupees(200000),
        );
        v = await view();
        expect(v.stage, LotStage.storage);
        expect(v.remaining[ArecaGrade.chali], 440);
        expect(v.saleNet, rupees(238800));
        expect(v.pending, rupees(38800));

        await lots.recordSale(
          lotId: id,
          buyerId: campco,
          date: DateTime(2026, 10, 1),
          lines: [
            SaleLineInput(grade: ArecaGrade.chali, kg: 440, rate: rupees(490)),
            SaleLineInput(grade: ArecaGrade.patora, kg: 90, rate: rupees(300)),
            SaleLineInput(grade: ArecaGrade.koka, kg: 50, rate: rupees(150)),
          ],
          received: rupees(250100),
        );
        v = await view();
        expect(v.stage, LotStage.sold);
        expect(v.remainingKg, 0);
        expect(v.totalCost, rupees(6560 + 3780));
        expect(v.profit, v.saleNet - rupees(10340));

        await expectLater(
          lots.setGrades(id, {ArecaGrade.chali: 940, ArecaGrade.patora: 90}),
          throwsA(isA<FarmException>()),
        );
        expect(
          (await view()).gradedKg,
          1080,
          reason: 'sold stock cannot be removed from the grade ledger',
        );
      },
    );

    test('codes run per crop and season', () async {
      Future<String> harvest(DateTime d) => lots.createHarvestLot(
        crop: Crop.areca,
        harvestedOn: d,
        title: 'x',
        plotIds: [],
      );
      await harvest(DateTime(2026, 10, 1));
      await harvest(DateTime(2026, 11, 1));
      await harvest(DateTime(2026, 5, 1));
      final codes = (await lots.loadLotViews()).map((v) => v.lot.code).toSet();
      expect(codes, {'A-2627-01', 'A-2627-02', 'A-2526-01'});
    });

    test('deleting labour or a lot removes the ledger entries', () async {
      final ramesh = await addWorker('Ramesh');
      final id = await lots.createHarvestLot(
        crop: Crop.areca,
        harvestedOn: DateTime(2026, 10, 1),
        title: 'Round 1',
        plotIds: [],
        labour: [
          LabourInput(
            workerId: ramesh,
            qty: 620,
            unit: RateUnit.palm,
            rate: rupees(8),
          ),
          LabourInput(
            workerId: ramesh,
            qty: 2,
            unit: RateUnit.day,
            rate: rupees(800),
          ),
        ],
      );
      expect(await dueOf(ramesh), rupees(4960 + 1600));

      final palms = (await lots.loadLotViews()).single.labour.firstWhere(
        (l) => l.entry.unit == RateUnit.palm,
      );
      await lots.deleteLabour(palms.entry.id);
      expect(await dueOf(ramesh), rupees(1600));

      await lots.deleteLot(id);
      expect(await lots.loadLotViews(), isEmpty);
      expect(await dueOf(ramesh), 0);
    });
  });
}
