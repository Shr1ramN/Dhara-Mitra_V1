import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:dhara_mitra/core/indian_phone.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/lots/data/collections_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CollectionsRepository collections;
  final day = DateTime(2026, 10, 10);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    collections = CollectionsRepository(db);
  });
  tearDown(() => db.close());
  Future<String> pickup(double? q, {String unit = 'bags'}) async {
    await collections.save(on: day, plotIds: [], unit: unit, quantity: q);
    return (await db.select(db.arecaCollections).get()).last.id;
  }

  test(
    'daily pickups combine once, retain provenance and never invent kg',
    () async {
      final a = await pickup(3), b = await pickup(2.5);
      final lotId = await collections.dryTogether(
        {a, b},
        on: day,
        title: 'Week 1',
      );
      final lot = (await db.select(db.lots).get()).single;
      expect(lot.freshBags, 5.5);
      expect(lot.freshKg, isNull);
      expect(
        (await collections.watch().first).map((c) => c.lotId),
        everyElement(lotId),
      );
      await expectLater(
        collections.dryTogether({a}, on: day, title: 'Duplicate'),
        throwsA(isA<FarmException>()),
      );
      expect((await db.select(db.lots).get()).length, 1);
      await LotsRepository(db).finishDrying(lotId, on: day, driedBags: 2);
      await LotsRepository(db)
          .recordPeeling(lotId, on: day, chaliKg: 45, driedBags: 2);
      final result = (await db.select(db.lots).get()).single;
      expect(result.driedBags, 2);
      expect(result.driedKg, isNull);
      expect(result.chaliKg, 45);
    },
  );
  test('pickups may be dried separately', () async {
    final a = await pickup(2), b = await pickup(3);
    final first = await collections.dryTogether({a}, on: day, title: 'A');
    final second = await collections.dryTogether({b}, on: day, title: 'B');
    expect(first, isNot(second));
    expect((await db.select(db.lots).get()).length, 2);
  });
  test(
    'late measurements update the same lot; outturn requires measured kg',
    () async {
      final a = await pickup(null), b = await pickup(2);
      final id = await collections.dryTogether(
        {a, b},
        on: day,
        title: 'Measure later',
      );
      await collections.save(
        id: a,
        on: day,
        plotIds: [],
        unit: 'bags',
        quantity: 3,
      );
      final repo = LotsRepository(db);
      expect((await repo.loadLotViews()).single.lot.freshBags, 5);
      await repo.recordPeeling(id, on: day, chaliKg: 80, driedBags: 4);
      expect((await repo.loadLotViews()).single.outTurn, isNull);
      await repo.recordPeeling(
        id,
        on: day,
        chaliKg: 80,
        driedBags: 4,
        driedKg: 100,
      );
      final view = (await repo.loadLotViews()).single;
      expect(view.outTurn, 80);
      expect(view.lot.driedBags, 4);
      expect((await collections.watch().first).length, 2);
    },
  );
  test(
    'mixed units and premature dates roll back; unknown is not zero',
    () async {
      final bags = await pickup(3), kg = await pickup(15, unit: 'kg');
      await expectLater(
        collections.dryTogether({bags, kg}, on: day, title: 'Mixed'),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        collections.dryTogether(
          {bags},
          on: day.subtract(const Duration(days: 1)),
          title: 'Early',
        ),
        throwsA(isA<FarmException>()),
      );
      expect(await db.select(db.lots).get(), isEmpty);
      final unknown = await pickup(null);
      final id = await collections.dryTogether(
        {bags, unknown},
        on: day,
        title: 'Unknown',
      );
      expect((await db.select(db.lots).get()).single.freshBags, isNull);
      await LotsRepository(db).deleteLot(id);
      expect(
        (await collections.watch().first).every((c) => c.lotId == null),
        isTrue,
      );
    },
  );
  test('collection correction and deletion protect assigned pickups', () async {
    final id = await pickup(3);
    await collections.save(
      id: id,
      on: day,
      plotIds: [],
      unit: 'bags',
      quantity: 4,
    );
    expect((await collections.watch().first).single.quantity, 4);
    await collections.dryTogether({id}, on: day, title: 'Dry');
    await expectLater(collections.remove(id), throwsA(isA<FarmException>()));
    await expectLater(
      collections.save(
        id: id,
        on: day,
        plotIds: [],
        unit: 'bags',
        quantity: -1,
      ),
      throwsA(isA<FarmException>()),
    );
  });
  test(
    'individual work survives attendance edits without double wages',
    () async {
      final repo = LabourRepository(db);
      final a = await repo.saveWorker(
        WorkersCompanion.insert(
          name: 'A',
          dayRate: const Value(50000),
          customRoles: const Value(['Irrigation']),
        ),
      );
      final b = await repo.saveWorker(
        WorkersCompanion.insert(name: 'B', dayRate: const Value(60000)),
      );
      final marks = {
        a: const AttendanceMark(AttendanceStatus.present, work: 'Watering'),
        b: const AttendanceMark(AttendanceStatus.present, work: 'Collecting'),
      };
      await repo.saveAttendance(day, marks);
      await repo.saveAttendance(day, marks);
      final entries = await repo.watchAttendance(day).first;
      expect(entries[a]!.work, 'Watering');
      expect(entries[b]!.work, 'Collecting');
      expect(
        (await repo.watchWorkerSummaries().first).fold(
          0,
          (s, w) => s + w.balance.due,
        ),
        110000,
      );
      expect((await repo.getWorker(a))!.customRoles, ['Irrigation']);
    },
  );
  test('Indian numbers normalize and reject wrong type country or length', () {
    expect(indianPhone('9876543210'), '+919876543210');
    expect(indianPhone('+91 98765 43210'), '+919876543210');
    expect(indianPhone('0824 2345678', landline: true), '+918242345678');
    for (final invalid in [
      '12345',
      '98765432100',
      '+1 2025550123',
      'abcdef',
      '08242345678',
    ]) {
      expect(indianPhone(invalid), isNull);
    }
    expect(indianPhone('9876543210', landline: true), isNull);
  });
  test('profile catalogue preserves default and validates selection', () async {
    final dir = await Directory.systemTemp.createTemp('farm-profile-test-');
    try {
      final catalog = FarmProfiles(dir);
      final id = await catalog.add();
      await catalog.select(id);
      expect((await catalog.read()).ids, ['default', id]);
      expect((await catalog.read()).active, id);
      await expectLater(catalog.select('../escape'), throwsArgumentError);
      expect(FarmProfiles.validId('../escape'), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('v2 migration keeps kilograms roles and money intact', () async {
    final dir = await Directory.systemTemp.createTemp('farm-v2-test-');
    var disk = AppDatabase(NativeDatabase(File('${dir.path}/v2.sqlite')));
    try {
      await disk
          .into(disk.workers)
          .insert(
            WorkersCompanion.insert(
              name: 'Worker',
              dayRate: const Value(45000),
              roles: const Value([WorkerRole.climber]),
            ),
          );
      await disk
          .into(disk.lots)
          .insert(
            LotsCompanion.insert(
              code: 'A-01',
              crop: Crop.areca,
              seasonStartYear: 2026,
              title: 'Old',
              harvestedOn: day,
              freshKg: const Value(120),
            ),
          );
      await disk.customStatement('DROP TABLE daily_work_allocations');
      await disk.customStatement('DROP TABLE areca_collections');
      for (final c in ['telephone', 'custom_roles']) {
        await disk.customStatement('ALTER TABLE workers DROP COLUMN $c');
      }
      for (final c in ['quantity_mode', 'fresh_bags', 'dried_bags']) {
        await disk.customStatement('ALTER TABLE lots DROP COLUMN $c');
      }
      await disk.customStatement('DROP TABLE IF EXISTS sale_receipts');
      await disk.customStatement('PRAGMA user_version = 2');
      await disk.close();
      disk = AppDatabase(NativeDatabase(File('${dir.path}/v2.sqlite')));
      final lot = (await disk.select(disk.lots).get()).single;
      expect(lot.quantityMode, 'kg');
      expect(lot.freshKg, 120);
      expect(lot.freshBags, isNull);
      final worker = (await disk.select(disk.workers).get()).single;
      expect(worker.roles, [WorkerRole.climber]);
      expect(worker.dayRate, 45000);
      expect(worker.customRoles, isEmpty);
    } finally {
      await disk.close();
      await dir.delete(recursive: true);
    }
  });
}
