import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/db/database.dart';
import '../../core/validation.dart';

Future<void> packBackup(
  String output,
  List<(String, String)> files,
  int schema,
) async {
  final checksums = <String, String>{};
  final encoder = ZipFileEncoder()..create(output);
  try {
    for (final file in files) {
      final input = File(file.$1);
      checksums[file.$2] = (await sha256.bind(input.openRead()).first)
          .toString();
      await encoder.addFile(input, file.$2);
    }
    final manifest = utf8.encode(
      jsonEncode({
        'format': 1,
        'app': 'in.dharamitra.app',
        'schema': schema,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'files': checksums,
      }),
    );
    encoder.addArchiveFile(
      ArchiveFile('manifest.json', manifest.length, manifest),
    );
  } finally {
    await encoder.close();
  }
}

/// Extracts only the app's allowlisted files, with byte, path and checksum checks.
/// This runs outside the UI isolate and never follows links from an archive.
Future<void> unpackBackup(String input, String destination) async {
  final stream = InputFileStream(input);
  try {
    final archive = ZipDecoder().decodeBuffer(stream, verify: true);
    final names = <String>{};
    var total = 0;
    for (final file in archive) {
      require(!file.isSymbolicLink);
      if (!file.isFile) continue;
      final name = file.name;
      require(
        !name.contains('\\') &&
            !name.contains(':') &&
            !p.posix.isAbsolute(name) &&
            !name.split('/').contains('..') &&
            (name == 'manifest.json' ||
                name == 'app.sqlite' ||
                RegExp(r'^attachments/[a-zA-Z0-9._-]+$').hasMatch(name)),
      );
      require(names.add(name));
      total += file.size;
      require(file.size >= 0 && total <= 512 * 1024 * 1024);
      final path = p.joinAll([destination, ...name.split('/')]);
      require(p.isWithin(destination, path));
      await Directory(p.dirname(path)).create(recursive: true);
      final output = OutputFileStream(path);
      try {
        file.writeContent(output);
      } finally {
        await output.close();
      }
    }
    require(names.contains('manifest.json') && names.contains('app.sqlite'));
    final manifest = jsonDecode(
      await File(p.join(destination, 'manifest.json')).readAsString(),
    ) as Map<String, dynamic>;
    require(manifest['format'] == 1 && manifest['app'] == 'in.dharamitra.app');
    final hashes = manifest['files'] as Map<String, dynamic>;
    require(hashes.length == names.length - 1);
    for (final name in names.where((n) => n != 'manifest.json')) {
      final file = File(p.joinAll([destination, ...name.split('/')]));
      require(
        (await sha256.bind(file.openRead()).first).toString() == hashes[name],
      );
    }
  } finally {
    await stream.close();
  }
}

Future<void> _packInIsolate(
  String output,
  List<(String, String)> files,
  int schema,
) => Isolate.run(() => packBackup(output, files, schema));
Future<void> _unpackInIsolate(String input, String destination) =>
    Isolate.run(() => unpackBackup(input, destination));

class _BackupDatabase extends AppDatabase {
  _BackupDatabase(super.e);
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => throw const FarmException('backup'),
    onUpgrade: super.migration.onUpgrade,
    beforeOpen: super.migration.beforeOpen,
  );
}

class BackupService {
  BackupService(
    this.db, {
    Directory? documentsDirectory,
    Directory? temporaryDirectory,
  }) : _documents = documentsDirectory,
       _temporary = temporaryDirectory;
  final AppDatabase db;
  final Directory? _documents, _temporary;
  Future<File> create({bool safety = false}) async {
    final root = _documents ?? await db.documentsDirectory();
    final temporary = _temporary ?? await getTemporaryDirectory();
    final stamp = '${DateTime.now().microsecondsSinceEpoch}-${newId()}';
    final copy = File(p.join(temporary.path, '$stamp.sqlite'));
    await db.exportTo(copy.path);
    final snapshot = AppDatabase(NativeDatabase(copy));
    final documents = await (snapshot.select(
      snapshot.storedDocuments,
    )..where((d) => d.deleted.equals(false))).get();
    await snapshot.close();
    final files = <(String, String)>[(copy.path, 'app.sqlite')];
    for (final document in documents) {
      final relative = document.path.replaceAll('\\', '/');
      require(
        RegExp(r'^attachments/[a-zA-Z0-9._-]+$').hasMatch(relative),
        'backup',
      );
      final file = File(p.joinAll([root.path, ...relative.split('/')]));
      require(await file.exists(), 'backup');
      files.add((file.path, document.path.replaceAll('\\', '/')));
    }
    final outputDirectory = safety
        ? Directory(p.join(root.path, 'backups'))
        : temporary;
    await outputDirectory.create(recursive: true);
    final output = File(p.join(outputDirectory.path, 'dhara-mitra-$stamp.zip'));
    try {
      final schema = db.schemaVersion;
      await _packInIsolate(output.path, files, schema);
      return output;
    } finally {
      if (await copy.exists()) await copy.delete();
    }
  }

  Future<File> restore(File selected) async {
    final temporary = _temporary ?? await getTemporaryDirectory();
    final root = _documents ?? await db.documentsDirectory();
    final stage = await Directory(p.join(temporary.path, 'restore-${newId()}'))
        .create();
    AppDatabase? incoming;
    Directory? oldAttachments;
    var swapped = false;
    var committed = false;
    final currentAttachments = Directory(p.join(root.path, 'attachments'));
    try {
      require(await selected.length() <= 512 * 1024 * 1024, 'backup');
      if (p.extension(selected.path).toLowerCase() == '.sqlite') {
        await selected.copy(p.join(stage.path, 'app.sqlite'));
      } else {
        await _unpackInIsolate(selected.path, stage.path);
      }
      incoming = _BackupDatabase(
        NativeDatabase(File(p.join(stage.path, 'app.sqlite'))),
      );
      final integrity = await incoming
          .customSelect('PRAGMA integrity_check')
          .getSingle();
      require(integrity.data.values.single == 'ok', 'backup');
      require(
        (await incoming.customSelect('PRAGMA foreign_key_check').get()).isEmpty,
        'backup',
      );
      for (final table in incoming.allTables) {
        await incoming.select(table).get();
      }
      final documents = await (incoming.select(
        incoming.storedDocuments,
      )..where((d) => d.deleted.equals(false))).get();
      for (final doc in documents) {
        final relative = doc.path.replaceAll('\\', '/');
        require(
          RegExp(r'^attachments/[a-zA-Z0-9._-]+$').hasMatch(relative),
          'backup',
        );
        require(
          await File(p.joinAll([stage.path, ...relative.split('/')])).exists(),
          'backup',
        );
      }
      final snapshot = <String, List<Map<String, Object?>>>{};
      for (final table in incoming.allTables) {
        final columns = table.$columns.map((c) => '"${c.$name}"').join(',');
        final rows = await incoming
            .customSelect('SELECT $columns FROM "${table.actualTableName}"')
            .get();
        snapshot[table.actualTableName] = [
          for (final row in rows) Map<String, Object?>.from(row.data),
        ];
      }
      await incoming.close();
      incoming = null;
      final safety = await create(safety: true);
      if (await currentAttachments.exists()) {
        oldAttachments = Directory(
          p.join(root.path, 'attachments-before-${newId()}'),
        );
        await currentAttachments.rename(oldAttachments.path);
      }
      final staged = Directory(p.join(stage.path, 'attachments'));
      swapped = true;
      if (await staged.exists()) {
        await staged.rename(currentAttachments.path);
      } else {
        await currentAttachments.create();
      }
      await db.transaction(() async {
        await db.customStatement('PRAGMA defer_foreign_keys = ON');
        for (final table in db.allTables) {
          await db.customStatement('DELETE FROM "${table.actualTableName}"');
        }
        for (final table in db.allTables) {
          for (final row in snapshot[table.actualTableName]!) {
            final columns = row.keys.map((c) => '"$c"').join(',');
            await db.customStatement(
              'INSERT INTO "${table.actualTableName}" ($columns) VALUES (${List.filled(row.length, '?').join(',')})',
              row.values.toList(),
            );
          }
        }
        require(
          (await db.customSelect('PRAGMA foreign_key_check').get()).isEmpty,
          'backup',
        );
        await db.customStatement(
          "DELETE FROM app_settings WHERE key LIKE 'scheduled.%' OR key LIKE 'alert.%'",
        );
      });
      committed = true;
      db.notifyUpdates({
        for (final table in db.allTables) TableUpdate(table.actualTableName),
      });
      if (oldAttachments != null && await oldAttachments.exists()) {
        await oldAttachments.delete(recursive: true);
      }
      return safety;
    } catch (_) {
      if (!committed && swapped && await currentAttachments.exists()) {
        await currentAttachments.delete(recursive: true);
      }
      if (!committed &&
          oldAttachments != null &&
          await oldAttachments.exists()) {
        await oldAttachments.rename(currentAttachments.path);
      }
      rethrow;
    } finally {
      await incoming?.close();
      if (await stage.exists()) await stage.delete(recursive: true);
    }
  }
}
