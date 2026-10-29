import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../common/forms.dart';
import '../security/security.dart';
import 'backup_service.dart';
import 'farm_bundle.dart';
import '../farm/ui/farms_screen.dart';

import 'package:path_provider/path_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _safety;
  Future<void> _bundle(bool importing) async {
    setState(() => _busy = true);
    await perform(context, () async {
      final service = FarmBundle(
        await ref.read(farmCatalogueProvider),
        await getTemporaryDirectory(),
      );
      if (importing) {
        final selected = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (selected?.path == null) return;
        await service.import(File(selected!.path!));
        ref.invalidate(profilesProvider);
        if (mounted) showSnack(context, context.l.fImported);
      } else {
        final file = await service.create(ref.read(databaseProvider));
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Dhara Mitra — all farms',
          ),
        );
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    await perform(context, () async {
      final file = await BackupService(ref.read(databaseProvider)).create();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Dhara Mitra backup'),
      );
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restore() async {
    if (!await confirm(
          context,
          title: context.l.xRestore,
          body: context.l.xRestoreWarning,
        ) ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip', 'sqlite'],
      );
      if (selected?.path == null) return;
      final db = ref.read(databaseProvider);
      final safety = await BackupService(db).restore(File(selected!.path!));
      final language = await db.setting('language') ?? 'en';
      await ref.read(localeProvider.notifier).set(language);
      await ref
          .read(appLockProvider.notifier)
          .set(await db.setting('app_lock') == 'true');
      _safety = safety.path;
      final farm = await ref.read(farmRepositoryProvider).getFarm();
      if (mounted) context.go(farm == null ? '/setup' : '/');
    } catch (error) {
      if (mounted) showSnack(context, failureText(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l.xBackup),
      leading: context.canPop()
          ? null
          : IconButton(
              tooltip: context.l.aBack,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(
                ref.read(farmProvider).value == null ? '/setup' : '/',
              ),
            ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l.aManualBackup),
          ),
        ),
        Text(context.l.xBackupHint),
        Text(context.l.fFarmBackup),
        FilledButton.icon(
          onPressed: _busy ? null : () => _bundle(false),
          icon: const Icon(Icons.backup_outlined),
          label: Text(context.l.fBackupAll),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _bundle(true),
          icon: const Icon(Icons.add_business_outlined),
          label: Text(context.l.fImportFarms),
        ),
        Text(context.l.fImportHint),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.ios_share),
          label: Text(context.l.xCreateBackup),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.restore),
          label: Text(context.l.xRestore),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_safety != null) Text('${context.l.xBackup}: $_safety'),
        const SizedBox(height: 24),

      ],
    ),
  );
}
