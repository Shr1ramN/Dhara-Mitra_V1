import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/db/database.dart';
import '../../core/farm_profiles.dart';
import '../../core/validation.dart';
import 'backup_service.dart';

/// Bundles independently restorable farm backups. Import creates new profiles,
/// leaving every existing farm untouched even if an import fails midway.
class FarmBundle {
  FarmBundle(
    this.catalogue,
    this.temporary, {
    AppDatabase Function(String)? open,
  }) : open = open ?? ((id) => AppDatabase.onDevice(profileId: id));
  final FarmProfiles catalogue;
  final Directory temporary;
  final AppDatabase Function(String) open;
  Directory _documents(String id) => id == 'default'
      ? catalogue.root
      : Directory(p.join(catalogue.root.path, 'farms', id));

  Future<File> create(AppDatabase current) async {
    final ids = (await catalogue.read()).ids;
    final output = File(
      p.join(temporary.path, 'dhara-all-farms-${newId()}.zip'),
    );
    final encoder = ZipFileEncoder()..create(output.path);
    final copies = <File>[];
    final hashes = <String, String>{};
    try {
      for (final (index, id) in ids.indexed) {
        final db = id == current.profileId ? current : open(id);
        try {
          final copy = await BackupService(
            db,
            documentsDirectory: _documents(id),
            temporaryDirectory: temporary,
          ).create();
          copies.add(copy);
          final name = 'farm-$index.zip';
          hashes[name] = (await sha256.bind(copy.openRead()).first).toString();
          await encoder.addFile(copy, name);
        } finally {
          if (db != current) await db.close();
        }
      }
      final metadata = utf8.encode(
        jsonEncode({'format': 'dhara-farms-1', 'files': hashes}),
      );
      encoder.addArchiveFile(
        ArchiveFile('farms.json', metadata.length, metadata),
      );
      await encoder.close();
      return output;
    } catch (_) {
      await encoder.close();
      rethrow;
    } finally {
      for (final copy in copies) {
        if (await copy.exists()) await copy.delete();
      }
    }
  }

  Future<int> import(File file) async {
    require(await file.length() <= 512 * 1024 * 1024, 'backup');
    final stage = await Directory(
      p.join(temporary.path, 'farm-import-${newId()}'),
    ).create();
    final input = InputFileStream(file.path);
    final imported = <String>[];
    try {
      final archive = ZipDecoder().decodeBuffer(input, verify: true);
      final names = <String>{};
      var total = 0;
      for (final entry in archive) {
        require(
          entry.isFile && !entry.isSymbolicLink && names.add(entry.name),
          'backup',
        );
        require(
          entry.name == 'farms.json' ||
              RegExp(r'^farm-[0-9]+\.zip$').hasMatch(entry.name),
          'backup',
        );
        total += entry.size;
        require(total <= 512 * 1024 * 1024 && names.length <= 101, 'backup');
        final out = OutputFileStream(p.join(stage.path, entry.name));
        try {
          entry.writeContent(out);
        } finally {
          await out.close();
        }
      }
      final metadata = jsonDecode(
        await File(p.join(stage.path, 'farms.json')).readAsString(),
      ) as Map<String, dynamic>;
      require(metadata['format'] == 'dhara-farms-1', 'backup');
      final hashes = (metadata['files'] as Map<String, dynamic>)
          .cast<String, String>();
      require(hashes.isNotEmpty && hashes.length == names.length - 1, 'backup');
      var expanded = 0;
      // Validate every member before opening any destination database.
      for (final name in hashes.keys) {
        require(names.contains(name) && name != 'farms.json', 'backup');
        final member = File(p.join(stage.path, name));
        require(
          (await sha256.bind(member.openRead()).first).toString() ==
              hashes[name],
          'backup',
        );
        final stream = InputFileStream(member.path);
        try {
          final nested = ZipDecoder().decodeBuffer(stream);
          for (final entry in nested) {
            expanded += entry.size;
          }
          require(expanded <= 512 * 1024 * 1024, 'backup');
        } finally {
          await stream.close();
        }
      }
      for (final name in hashes.keys) {
        final id = newId();
        final db = open(id);
        try {
          await BackupService(
            db,
            documentsDirectory: _documents(id),
            temporaryDirectory: temporary,
          ).restore(File(p.join(stage.path, name)));
          imported.add(id);
        } finally {
          await db.close();
        }
      }
      await catalogue.register(imported);
      return imported.length;
    } finally {
      await input.close();
      await stage.delete(recursive: true);
    }
  }
}
