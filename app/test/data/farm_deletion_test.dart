import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/farm_deletion.dart';
import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  test('deleting a farm clears linked records and attachments, preserving other farms and backups', () async {
    final root = await Directory.systemTemp.createTemp('farm-delete-');
    final catalogue = FarmProfiles(root);
    final id = await catalogue.add();
    final db = AppDatabase(NativeDatabase.memory(), profileId: id);
    final other = AppDatabase(NativeDatabase.memory());
    try {
      await db.into(db.farms).insert(FarmsCompanion.insert(name: 'Delete me'));
      await other
          .into(other.farms)
          .insert(FarmsCompanion.insert(name: 'Keep me'));
      final worker = newId();
      await db
          .into(db.workers)
          .insert(WorkersCompanion.insert(id: Value(worker), name: 'Worker'));
      await db
          .into(db.attendanceEntries)
          .insert(
            AttendanceEntriesCompanion.insert(
              workerId: worker,
              date: DateTime(2026, 10, 27),
              status: AttendanceStatus.present,
              amount: 50000,
            ),
          );
      final docs = Directory('${root.path}/farms/$id');
      final attachment = File('${docs.path}/attachments/bill.txt');
      await attachment.parent.create(recursive: true);
      await attachment.writeAsString('bill');
      final backup = File('${docs.path}/backups/export.zip');
      await backup.parent.create(recursive: true);
      await backup.writeAsString('export');
      await deleteFarmData(catalogue, db, documents: docs);
      expect((await catalogue.read()).ids, ['default']);
      for (final table in db.allTables) {
        expect(
          await db.select(table).get(),
          isEmpty,
          reason: table.actualTableName,
        );
      }
      expect(await attachment.exists(), isFalse);
      expect(await backup.exists(), isTrue);
      expect((await other.select(other.farms).get()).single.name, 'Keep me');
    } finally {
      await db.close();
      await other.close();
      await root.delete(recursive: true);
    }
  });

  test(
    'active farm cannot be deleted until a replacement is selected',
    () async {
      final root = await Directory.systemTemp.createTemp('farm-delete-active-');
      final catalogue = FarmProfiles(root);
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await db
            .into(db.farms)
            .insert(FarmsCompanion.insert(name: 'Only farm'));
        await expectLater(
          deleteFarmData(catalogue, db, documents: root),
          throwsStateError,
        );
        expect((await db.select(db.farms).get()).single.name, 'Only farm');
        final replacement = await catalogue.add();
        await catalogue.select(replacement);
        await deleteFarmData(catalogue, db, documents: root);
        expect((await catalogue.read()).ids, [replacement]);
        expect((await catalogue.read()).active, replacement);
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
}
