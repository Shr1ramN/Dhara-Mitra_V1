import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/backup/backup_service.dart';
import 'package:dhara_mitra/features/diary/data/diary_repository.dart';
import 'package:dhara_mitra/features/finance/finance_repository.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/loans/data/loans_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:dhara_mitra/features/prices/prices_repository.dart';
import 'package:dhara_mitra/features/produce/produce_repository.dart';
import 'package:dhara_mitra/features/reports/report_repository.dart';
import 'package:dhara_mitra/features/stock/data/stock_repository.dart';
import 'package:dhara_mitra/features/weather/weather_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  final day = DateTime(2026, 10, 10);
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());
  Future<String> worker() async => LabourRepository(db).saveWorker(
    WorkersCompanion.insert(name: 'Test worker', dayRate: const Value(80000)),
  );
  test(
    'attendance first: diary reuses wages and follows attendance corrections',
    () async {
      final w = await worker();
      final labour = LabourRepository(db);
      final diary = DiaryRepository(db);
      await labour.saveAttendance(day, {
        w: const AttendanceMark(AttendanceStatus.present),
      });
      final id = await diary.save(
        date: day,
        kind: 'weeding',
        title: 'Work',
        crops: ['areca'],
        labour: [
          LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
        ],
      );
      expect(
        (await labour.watchWorkerSummaries().first).single.balance.earned,
        80000,
      );
      expect((await diary.load()).single.labourCost, 80000);
      expect((await db.select(db.workerTxns).get()).length, 1);
      await labour.saveAttendance(day, {
        w: const AttendanceMark(AttendanceStatus.half),
      });
      expect((await diary.load()).single.labourCost, 40000);
      final report = await ReportRepository(db)
          .build(season: const Season(2026), today: day, crop: 'areca');
      expect(report.costs, 40000);
      await diary.delete(id);
      expect(
        (await labour.watchWorkerSummaries().first).single.balance.earned,
        40000,
      );
    },
  );
  test('diary first: later attendance cannot book the same wage twice; piecework is additional', () async {
    final w = await worker();
    final labour = LabourRepository(db);
    final diary = DiaryRepository(db);
    await diary.save(
      date: day,
      kind: 'harvest',
      title: 'Harvest',
      labour: [
        LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
        LabourInput(workerId: w, qty: 100, unit: RateUnit.palm, rate: 800),
      ],
    );
    await labour.saveAttendance(day, {
      w: const AttendanceMark(AttendanceStatus.present),
    });
    expect(
      (await labour.watchWorkerSummaries().first).single.balance.earned,
      160000,
    );
    await expectLater(
      diary.save(
        date: day,
        kind: 'weeding',
        title: 'Duplicate daily wage',
        labour: [
          LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
        ],
      ),
      throwsA(isA<FarmException>()),
    );
    expect((await diary.load()).length, 1);
  });
  test(
    'pepper full journey with stock limit, partial sales and linked labour',
    () async {
      final repo = ProduceRepository(db);
      final w = await worker();
      final id = await repo.harvest(
        crop: 'pepper',
        on: day,
        quantity: 100,
        unit: 'kg',
        title: 'Pepper round',
      );
      await repo.processing(id, 'threshing', day);
      await repo.startDrying(id, day);
      await repo.finish(
        id,
        on: DateTime(2026, 10, 15),
        quantity: 35,
        unit: 'kg',
      );
      await repo.store(id, on: DateTime(2026, 10, 15), place: 'Store');
      await repo.labour(
        id,
        workerId: w,
        on: day,
        work: 'Threshing',
        quantity: 1,
        unit: 'day',
        rate: 80000,
      );
      final buyer = await LotsRepository(db)
          .saveBuyer(name: 'Trader', kind: BuyerKind.trader);
      await repo.sale(
        id,
        buyerId: buyer,
        on: DateTime(2026, 10, 16),
        quantity: 10,
        rate: 60000,
        received: 500000,
      );
      var view = (await repo.load()).single;
      expect(view.remaining, 25);
      expect(view.pending, 100000);
      expect(view.cost, 80000);
      await expectLater(
        repo.sale(
          id,
          buyerId: buyer,
          on: DateTime(2026, 10, 16),
          quantity: 26,
          rate: 60000,
        ),
        throwsA(isA<FarmException>()),
      );
      await repo.receive(view.sales.single.id, 100000);
      expect((await repo.load()).single.pending, 0);
      await repo.sale(
        id,
        buyerId: buyer,
        on: DateTime(2026, 10, 16),
        quantity: 25,
        rate: 60000,
      );
      view = (await repo.load()).single;
      expect(view.stage, 'sold');
      await repo.delete(id);
      expect(
        (await LabourRepository(
          db,
        ).watchWorkerSummaries().first).single.balance.due,
        0,
      );
    },
  );
  test(
    'coconut cannot change nuts into copra after a partial nut sale',
    () async {
      final repo = ProduceRepository(db);
      final id = await repo.harvest(
        crop: 'coconut',
        on: day,
        quantity: 100,
        unit: 'nut',
        title: 'Coconuts',
      );
      final buyer = await LotsRepository(db)
          .saveBuyer(name: 'Buyer', kind: BuyerKind.trader);
      await repo.sale(id, buyerId: buyer, on: day, quantity: 10, rate: 2500);
      await expectLater(
        repo.processing(id, 'dehusking', day),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        repo.sale(id, buyerId: buyer, on: day, quantity: .5, rate: 2500),
        throwsA(isA<FarmException>()),
      );
    },
  );
  test('banana bunches may be weighed into kg before any sale', () async {
    final repo = ProduceRepository(db);
    final id = await repo.harvest(
      crop: 'banana',
      on: day,
      quantity: 10,
      unit: 'bunch',
      title: 'Banana',
    );
    await repo.finish(id, on: day, quantity: 250, unit: 'kg');
    expect((await repo.load()).single.remaining, 250);
  });
  test('accrual report counts wages and inputs once; payment and purchase cash are not duplicated', () async {
    final w = await worker();
    final stock = StockRepository(db);
    final item = await stock.saveItem(name: 'Fertiliser', unit: 'kg');
    await stock.purchase(itemId: item, date: day, quantity: 100, cost: 100000);
    await DiaryRepository(db).save(
      date: day,
      kind: 'fertiliser',
      title: 'Fertiliser',
      crops: ['areca'],
      inputs: [InputUse(item, 10)],
      labour: [
        LabourInput(workerId: w, qty: 1, unit: RateUnit.day, rate: 80000),
      ],
    );
    await LabourRepository(
      db,
    ).addPayment(workerId: w, date: day, kind: TxnKind.payment, amount: 60000);
    final lots = LotsRepository(db);
    final lot = await lots.createHarvestLot(
      crop: Crop.areca,
      harvestedOn: day,
      title: 'Lot',
      plotIds: [],
    );
    await lots.recordPeeling(lot, on: day, chaliKg: 10);
    final buyer = await lots.saveBuyer(name: 'Buyer', kind: BuyerKind.trader);
    await lots.recordSale(
      lotId: lot,
      buyerId: buyer,
      date: day,
      lines: [
        const SaleLineInput(grade: ArecaGrade.chali, kg: 10, rate: 45000),
      ],
      deductions: 10000,
    );
    final finance = FinanceRepository(db);
    await finance.expense(
      date: day,
      category: 'repairs',
      amount: 10000,
      crop: 'areca',
    );
    await finance.policy(
      scheme: 'Policy',
      crop: 'areca',
      season: 2026,
      acres: 1,
      premium: 10000,
      paidOn: day,
      number: 'P-1',
    );
    final loan = await LoansRepository(db).create(
      lender: 'Bank',
      lenderKind: 'bank',
      kind: 'term',
      sanctioned: 1000000,
      sanctionedOn: DateTime(2026, 1, 1),
      annualRate: 10,
      withdrawn: 1000000,
    );
    await LoansRepository(
      db,
    ).addTransaction(loanId: loan, date: day, kind: 'interest', amount: 5000);
    final report = await ReportRepository(db)
        .build(season: const Season(2026), today: day);
    expect(report.income, 440000);
    expect(report.costs, 115000);
    expect(report.profit, 325000);
    final areca = await ReportRepository(db)
        .build(season: const Season(2026), today: day, crop: 'areca');
    expect(areca.costs, 110000);
  });
  test('shared crop/plot amounts retain every paise', () {
    final line = ReportLine(
      date: day,
      label: 'Shared',
      category: 'expense',
      amount: 101,
      income: false,
      crops: ['pepper', 'areca'],
      plots: ['b', 'a'],
    );
    expect(line.allocated(crop: 'areca') + line.allocated(crop: 'pepper'), 101);
    expect(line.allocated(plot: 'a') + line.allocated(plot: 'b'), 101);
    expect(line.allocated(crop: 'areca', plot: 'a'), 26);
  });
  test(
    'quintal prices are converted to canonical kg; invalid ranges are rejected',
    () async {
      final prices = PricesRepository(db);
      await prices.save(
        date: day,
        source: 'Manual',
        market: 'Puttur',
        crop: 'areca',
        grade: 'chali',
        unit: 'quintal',
        modal: 4500000,
      );
      final price = (await prices.watch().first).single;
      expect(price.modal, 45000);
      expect(price.unit, 'kg');
      await expectLater(
        prices.save(
          date: day,
          source: 'Manual',
          market: 'Puttur',
          crop: 'areca',
          grade: 'chali',
          unit: 'kg',
          modal: 10,
          minimum: 20,
        ),
        throwsA(isA<FarmException>()),
      );
    },
  );
  final weather = jsonEncode({
    'daily': {
      'time': ['2026-10-10'],
      'temperature_2m_min': [22],
      'temperature_2m_max': [30],
      'precipitation_sum': [2.5],
      'precipitation_probability_max': [70],
    },
    'hourly': {
      'time': ['2026-10-10T12:00'],
      'precipitation': [.5],
      'precipitation_probability': [70],
    },
  });
  test('weather keeps its cached forecast after a failed refresh', () async {
    await WeatherRepository(
      db,
      client: MockClient((_) async => http.Response(weather, 200)),
    ).refresh(12, 75);
    await expectLater(
      WeatherRepository(
        db,
        client: MockClient((_) async => http.Response('Unavailable', 503)),
      ).refresh(12, 75),
      throwsA(isA<FarmException>()),
    );
    final cached = (await db.select(db.weatherCaches).get()).single;
    expect(Forecast.parse(cached.payload).days.single.chance, 70);
  });
  test('full backup restores records and attachments, and preserves a safety backup', () async {
    final dir = await Directory.systemTemp.createTemp('dhara-backup-');
    final root = await Directory('${dir.path}/documents').create();
    final temp = await Directory('${dir.path}/temp').create();
    final attachments = await Directory('${root.path}/attachments').create();
    try {
      final file = await File('${attachments.path}/test.jpg')
          .writeAsBytes([1, 2, 3]);
      await db
          .into(db.storedDocuments)
          .insert(
            StoredDocumentsCompanion.insert(
              title: 'Photo',
              kind: 'photo',
              path: 'attachments/test.jpg',
              originalName: 'test.jpg',
            ),
          );
      final farmId = await db
          .into(db.farms)
          .insertReturning(FarmsCompanion.insert(name: 'Original farm'));
      await db.putSetting('scheduled.reminder:test', 'old-phone');
      final service = BackupService(
        db,
        documentsDirectory: root,
        temporaryDirectory: temp,
      );
      final backup = await service.create();
      await (db.update(db.farms)..where((f) => f.id.equals(farmId.id))).write(
        const FarmsCompanion(name: Value('Changed farm')),
      );
      await file.writeAsBytes([9]);
      final safety = await service.restore(backup);
      expect(await safety.exists(), isTrue);
      expect((await db.select(db.farms).get()).single.name, 'Original farm');
      expect(await file.readAsBytes(), [1, 2, 3]);
      expect(await db.setting('scheduled.reminder:test'), isNull);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('archive traversal and arbitrary SQLite files cannot overwrite current data', () async {
    final dir = await Directory.systemTemp.createTemp('dhara-invalid-');
    final root = await Directory('${dir.path}/documents').create();
    final temp = await Directory('${dir.path}/temp').create();
    try {
      await db.into(db.farms).insert(FarmsCompanion.insert(name: 'Keep me'));
      final archive = Archive()
        ..addFile(ArchiveFile('../escape', 3, [1, 2, 3]));
      final zip = await File('${dir.path}/bad.zip')
          .writeAsBytes(ZipEncoder().encode(archive)!);
      final service = BackupService(
        db,
        documentsDirectory: root,
        temporaryDirectory: temp,
      );
      await expectLater(service.restore(zip), throwsA(anything));
      expect((await db.select(db.farms).get()).single.name, 'Keep me');
      final empty = File('${dir.path}/empty.sqlite');
      final emptyDb = NativeDatabase(empty);
      final fake = AppDatabase(emptyDb);
      await fake.customSelect('SELECT 1').get();
      await fake.customStatement('PRAGMA user_version = 0');
      await fake.close();
      await expectLater(service.restore(empty), throwsA(anything));
      expect((await db.select(db.farms).get()).single.name, 'Keep me');
      expect(await File('${temp.path}/escape').exists(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
