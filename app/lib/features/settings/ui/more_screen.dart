import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/appearance.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../backup/excel_export.dart';
import '../../common/forms.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});
  @override
  ConsumerState<MoreScreen> createState() => _MoreState();
}

class _MoreState extends ConsumerState<MoreScreen> {
  bool exporting = false;
  Future<void> export(bool excel) async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      if (!mounted) return;
      final db = ref.read(databaseProvider),
          title = excel ? context.l.exportExcel : context.l.exportDb;
      final file = File(
        p.join(
          dir.path,
          'dhara-mitra-${DateTime.now().microsecondsSinceEpoch}.${excel ? 'xlsx' : 'sqlite'}',
        ),
      );
      if (excel) {
        await FarmExcelExport(db).save(file);
      } else {
        await db.exportTo(file.path);
      }
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: title),
      );
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          for (final item in <(String, IconData, String)>[
            (l.farm, Icons.agriculture_outlined, '/farm'),
            (l.fFarms, Icons.swap_horiz, '/farms'),
            (l.xBackup, Icons.backup_outlined, '/backup'),
            (l.xSecurity, Icons.lock_outlined, '/security'),
          ])
            ListTile(
              leading: Icon(item.$2),
              title: Text(item.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(item.$3),
            ),
          SectionTitle(l.appearance),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(l.lightTheme)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.darkTheme)),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l.systemTheme),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (v) => perform(
              context,
              () => ref.read(themeModeProvider.notifier).set(v.first),
            ),
          ),
          SectionTitle(l.language),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l.english)),
              ButtonSegment(value: 'kn', label: Text(l.kannada)),
            ],
            selected: {ref.watch(localeProvider).languageCode},
            onSelectionChanged: (v) =>
                ref.read(localeProvider.notifier).set(v.first),
          ),
          SectionTitle(l.exportDb),
          ListTile(
            enabled: !exporting,
            leading: const Icon(Icons.storage_outlined),
            title: Text(l.exportDb),
            subtitle: Text(l.exportDbSub),
            onTap: () => export(false),
          ),
          ListTile(
            enabled: !exporting,
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l.exportExcel),
            subtitle: Text(l.excelSnapshotHelp),
            onTap: () => export(true),
          ),
          if (exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Text(l.dataOnPhone),
        ],
      ),
    );
  }
}
