import 'dart:io';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:dhara_mitra/features/backup/farm_bundle.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all-farm backup imports isolated records and attachments without replacing existing farms', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final root = await Directory.systemTemp.createTemp('farms-bundle-');
    final temp = await Directory('${root.path}/tmp').create();
    final catalogue = FarmProfiles(Directory('${root.path}/docs'));
    AppDatabase open(String id) => AppDatabase(
      NativeDatabase(File('${root.path}/$id.sqlite')),
      profileId: id,
    );
    final current = open('default');
    try {
      final secondId = await catalogue.add();
      await current
          .into(current.farms)
          .insert(FarmsCompanion.insert(name: 'Farm A', lat: const Value(13)));
      await current
          .into(current.workers)
          .insert(
            WorkersCompanion.insert(name: 'Ravi', dayRate: const Value(50000)),
          );
      final second = open(secondId);
      await second
          .into(second.farms)
          .insert(FarmsCompanion.insert(name: 'Farm B', lat: const Value(14)));
      await second
          .into(second.workers)
          .insert(
            WorkersCompanion.insert(name: 'Ravi', dayRate: const Value(60000)),
          );
      final attachment = File(
        '${catalogue.root.path}/farms/$secondId/attachments/test.txt',
      );
      await attachment.parent.create(recursive: true);
      await attachment.writeAsString('Farm B bill');
      await second
          .into(second.storedDocuments)
          .insert(
            StoredDocumentsCompanion.insert(
              title: 'Bill',
              kind: 'file',
              path: 'attachments/test.txt',
              originalName: 'test.txt',
            ),
          );
      await second.close();
      final service = FarmBundle(catalogue, temp, open: open);
      final archive = await service.create(current);
      expect(await service.import(archive), 2);
      final ids = (await catalogue.read()).ids;
      expect(ids.length, 4);
      expect((await catalogue.read()).active, 'default');
      final importedA = open(ids[2]), importedB = open(ids[3]);
      try {
        expect(
          (await importedA.select(importedA.workers).get()).single.dayRate,
          50000,
        );
        expect(
          (await importedB.select(importedB.workers).get()).single.dayRate,
          60000,
        );
        expect(
          await File(
            '${catalogue.root.path}/farms/${ids[3]}/attachments/test.txt',
          ).readAsString(),
          'Farm B bill',
        );
        expect(
          (await current.select(current.workers).get()).single.dayRate,
          50000,
        );
      } finally {
        await importedA.close();
        await importedB.close();
      }
    } finally {
      await current.close();
      await root.delete(recursive: true);
    }
  });
}
