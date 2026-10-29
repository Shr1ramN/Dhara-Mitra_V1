import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/db/database.dart';
import '../../core/validation.dart';

class DocumentService {
  DocumentService(this.db);
  final AppDatabase db;

  Future<String?> pickFile({
    required String title,
    String kind = 'other',
    String? refType,
    String? refId,
  }) async {
    final result = await FilePicker.pickFile();
    final path = result?.path;
    if (path == null) return null;
    return store(
      File(path),
      title: title,
      kind: kind,
      refType: refType,
      refId: refId,
    );
  }

  Future<String?> photo({
    required ImageSource source,
    required String title,
    String? refType,
    String? refId,
  }) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 85,
    );
    if (image == null) return null;
    return store(
      File(image.path),
      title: title,
      kind: 'photo',
      refType: refType,
      refId: refId,
    );
  }

  Future<String> store(
    File input, {
    required String title,
    required String kind,
    String? refType,
    String? refId,
  }) async {
    require(await input.exists());
    final directory = Directory(
      p.join((await db.documentsDirectory()).path, 'attachments'),
    );
    await directory.create(recursive: true);
    final id = newId();
    final extension = p.extension(input.path).toLowerCase();
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : '.bin';
    final relativePath = p.join('attachments', '$id$safeExtension');
    final copy = await input.copy(p.join(directory.parent.path, relativePath));
    try {
      await db
          .into(db.storedDocuments)
          .insert(
            StoredDocumentsCompanion.insert(
              id: Value(id),
              title: title.trim().isEmpty
                  ? p.basename(input.path)
                  : title.trim(),
              kind: kind,
              path: relativePath,
              originalName: p.basename(input.path),
              refType: Value(refType),
              refId: Value(refId),
            ),
          );
    } catch (_) {
      await copy.delete();
      rethrow;
    }
    return id;
  }

  Future<File> resolve(String relativePath) async {
    final root = (await db.documentsDirectory()).path;
    final absolute = p.normalize(p.join(root, relativePath));
    require(p.isWithin(root, absolute));
    return File(absolute);
  }
}
