import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:dhara_mitra/features/produce/produce_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'schema 4 received balances migrate once without changing totals',
    () async {
      final dir = await Directory.systemTemp.createTemp('v1-receipt-migration');
      final file = File('${dir.path}/farm.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      final repo = ProduceRepository(db);
      final lot = await repo.harvest(
        crop: 'coconut',
        on: DateTime(2026, 1, 1),
        quantity: 20,
        unit: 'nut',
        title: 'Coconut',
      );
      final buyer = await db
          .into(db.buyers)
          .insertReturning(BuyersCompanion.insert(name: 'Buyer'));
      await repo.sale(
        lot,
        buyerId: buyer.id,
        on: DateTime(2026, 1, 2),
        quantity: 10,
        rate: 1000,
        received: 3000,
      );
      await db.customStatement('DROP TABLE sale_receipts');
      await db.customStatement('PRAGMA user_version = 4');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect((await db.select(db.saleReceipts).getSingle()).amount, 3000);
      expect((await db.select(db.produceSales).getSingle()).received, 3000);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect((await db.select(db.saleReceipts).get()).length, 1);
      await db.close();
      await dir.delete(recursive: true);
    },
  );

  test(
    'calendar searches actual farm records and receipts retain dates',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.activities)
          .insert(
            ActivitiesCompanion.insert(
              date: DateTime(2026, 1, 2),
              kind: 'manure',
              title: 'Organic manure',
            ),
          );
      await db
          .into(db.activities)
          .insert(
            ActivitiesCompanion.insert(
              date: DateTime(2026, 2, 2),
              kind: 'spray',
              title: 'Treatment',
            ),
          );
      final records = await CalendarRepository(db).load();
      expect(records.length, 2);
      final query = RecordQuery('when did I last put manure');
      expect(query.latest, isTrue);
      expect(records.where(query.matches).single.date, DateTime(2026, 1, 2));
      expect(RecordQuery('ಗೊಬ್ಬರ').matches(records.last), isTrue);
      expect(records.where(RecordQuery('unknown').matches), isEmpty);
      final repo = ProduceRepository(db);
      final lot = await repo.harvest(
        crop: 'coconut',
        on: DateTime(2026, 3, 1),
        quantity: 100,
        unit: 'nut',
        title: 'Coconut',
      );
      final buyer = await db
          .into(db.buyers)
          .insertReturning(BuyersCompanion.insert(name: 'Buyer'));
      await repo.sale(
        lot,
        buyerId: buyer.id,
        on: DateTime(2026, 3, 2),
        quantity: 10,
        rate: 2000,
      );
      final sale = await db.select(db.produceSales).getSingle();
      await repo.receive(
        sale.id,
        5000,
        date: DateTime(2026, 3, 4),
        notes: 'Cash',
      );
      expect(
        (await db.select(db.saleReceipts).getSingle()).date,
        DateTime(2026, 3, 4),
      );
      expect(
        (await CalendarRepository(
          db,
        ).load()).where((r) => r.category == 'payment').single.notes,
        'Cash',
      );
      await expectLater(repo.receive(sale.id, 999999), throwsA(anything));
      expect((await db.select(db.produceSales).getSingle()).received, 5000);
      expect((await db.select(db.saleReceipts).get()).length, 1);
    },
  );
}
