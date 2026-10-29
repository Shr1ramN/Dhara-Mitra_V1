import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart'
    show Value, Constant, OrderingTerm, BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/database.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import 'document_service.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key, this.refType, this.refId});
  final String? refType;
  final String? refId;
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  AudioPlayer? _player;
  late final _documents =
      (ref
              .read(databaseProvider)
              .select(ref.read(databaseProvider).storedDocuments)
            ..where(
              (d) =>
                  d.deleted.equals(false) &
                  (widget.refId == null
                      ? const Constant(true)
                      : d.refId.equals(widget.refId!)),
            )
            ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
          .watch();
  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l = context.l;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in {
              'camera': l.xCamera,
              'gallery': l.xGallery,
              'file': l.xFile,
              'voice': l.notes,
            }.entries)
              ListTile(
                title: Text(e.value),
                leading: Icon(
                  e.key == 'voice'
                      ? Icons.mic
                      : e.key == 'file'
                      ? Icons.attach_file
                      : Icons.photo_camera,
                ),
                onTap: () => Navigator.pop(context, e.key),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final service = DocumentService(ref.read(databaseProvider));
    await perform(context, () async {
      if (choice == 'voice') {
        final path = await showDialog<String>(
          context: context,
          builder: (_) => const _VoiceRecorder(),
        );
        if (path != null) {
          await service.store(
            File(path),
            title: l.notes,
            kind: 'voice',
            refType: widget.refType,
            refId: widget.refId,
          );
        }
      } else if (choice == 'file') {
        await service.pickFile(
          title: '',
          refType: widget.refType,
          refId: widget.refId,
        );
      } else {
        await service.photo(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          title: l.xPhoto,
          refType: widget.refType,
          refId: widget.refId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.xDocuments)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: Text(context.l.xAddDocument),
    ),
    body: StreamBuilder(
      stream: _documents,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(context.l.xError));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (snapshot.data!.isEmpty)
              EmptyState(icon: Icons.folder_open, text: context.l.xEmpty),
            for (final doc in snapshot.data!)
              Card(
                child: ListTile(
                  leading: Icon(
                    doc.kind == 'voice'
                        ? Icons.play_circle_outline
                        : Icons.description_outlined,
                  ),
                  title: Text(doc.title),
                  subtitle: Text(
                    '${doc.originalName}\n${context.fmt.date(doc.updatedAt)}',
                  ),
                  isThreeLine: true,
                  onTap: () => perform(context, () async {
                    final file = await DocumentService(
                      ref.read(databaseProvider),
                    ).resolve(doc.path);
                    if (!await file.exists()) {
                      throw const FileSystemException('Missing document');
                    }
                    if (doc.kind == 'voice') {
                      final player = _player ??= AudioPlayer();
                      await player.stop();
                      await player.play(DeviceFileSource(file.path));
                    } else {
                      await OpenFilex.open(file.path);
                    }
                  }),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => perform(context, () async {
                      if (action == 'share') {
                        final file = await DocumentService(
                          ref.read(databaseProvider),
                        ).resolve(doc.path);
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path)],
                            subject: doc.title,
                          ),
                        );
                      } else if (action == 'rename') {
                        await openEntryForm(
                          context,
                          title: context.l.edit,
                          fields: [
                            EntryField(
                              'title',
                              context.l.xTitle,
                              initial: doc.title,
                              required: true,
                            ),
                          ],
                          onSave: (v) async {
                            final db = ref.read(databaseProvider);
                            await (db.update(
                              db.storedDocuments,
                            )..where((d) => d.id.equals(doc.id))).write(
                              StoredDocumentsCompanion(
                                title: Value(v.text('title')),
                                updatedAt: Value(DateTime.now()),
                              ),
                            );
                          },
                        );
                      } else if (await confirm(
                        context,
                        title: context.l.confirmDelete,
                      )) {
                        final db = ref.read(databaseProvider);
                        await (db.update(
                          db.storedDocuments,
                        )..where((d) => d.id.equals(doc.id))).write(
                          StoredDocumentsCompanion(
                            deleted: const Value(true),
                            updatedAt: Value(DateTime.now()),
                          ),
                        );
                      }
                    }),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text(context.l.edit),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text(context.l.xShareStatement),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l.delete),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _VoiceRecorder extends StatefulWidget {
  const _VoiceRecorder();
  @override
  State<_VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<_VoiceRecorder> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  String? _error;
  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_recording) {
        final path = await _recorder.stop();
        if (mounted) Navigator.pop(context, path);
        return;
      }
      if (!await _recorder.hasPermission()) {
        if (mounted) setState(() => _error = context.l.xVoiceUnavailable);
        return;
      }
      final dir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: p.join(dir.path, '${newId()}.m4a'),
      );
      if (mounted) setState(() => _recording = true);
    } catch (error) {
      if (mounted) setState(() => _error = failureText(context, error));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l.notes),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_recording ? Icons.mic : Icons.mic_none, size: 48),
        if (_error != null) Text(_error!),
        if (_recording) Text(context.l.xListening),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      FilledButton(
        onPressed: _toggle,
        child: Text(_recording ? context.l.save : context.l.xContinue),
      ),
    ],
  );
}
