import 'dart:io';

import 'package:path/path.dart' as p;

import 'db/database.dart';
import 'farm_profiles.dart';

/// The caller must stop the farm's services and close any other connection first.
Future<void> deleteFarmData(
  FarmProfiles catalogue,
  AppDatabase db, {
  Directory? documents,
}) async {
  final state = await catalogue.read();
  if (!state.ids.contains(db.profileId) || state.active == db.profileId) {
    throw StateError('Switch farms before deleting');
  }
  await db.transaction(() async {
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final table in db.allTables) {
      await db.customStatement('DELETE FROM "${table.actualTableName}"');
    }
  });
  final root = documents ?? await db.documentsDirectory();
  final attachments = Directory(p.join(root.path, 'attachments'));
  if (await attachments.exists()) await attachments.delete(recursive: true);
  await catalogue.remove(db.profileId);
}
