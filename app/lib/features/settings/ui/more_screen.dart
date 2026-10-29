import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';


class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final file = File(p.join(dir.path, '$databaseName-$stamp.sqlite'));
      if (file.existsSync()) file.deleteSync();
      await ref.read(databaseProvider).exportTo(file.path);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: '${l.appName} $stamp'),
      );
    } on Exception catch (e) {
      if (context.mounted) showSnack(context, l.exportFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final farm = ref.watch(farmProvider).value;
    final plots = ref.watch(plotsProvider).value ?? const [];
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          PaddedCard(
            onTap: () => context.push('/farm'),
            child: Row(
              children: [
                const RoundIcon(
                  Icons.agriculture_outlined,
                  color: AppColors.accent,
                  background: AppColors.accentSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm?.name ?? l.farm,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        [
                          if ((farm?.village ?? '').isNotEmpty) farm!.village,
                          '${plots.length} · ${l.plotsTitle}',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
          SectionTitle(l.language),
          for (final entry in <(String, IconData, String)>[
            (l.fFarms, Icons.agriculture_outlined, '/farms'),
            (l.navHarvest, Icons.eco_outlined, '/lots'),
            (l.navLabour, Icons.groups_outlined, '/labour'),
            (l.fCollections, Icons.shopping_basket_outlined, '/collections'),
            (l.xDiary, Icons.menu_book_outlined, '/diary'),
            (l.xSales, Icons.receipt_long_outlined, '/sales'),
            (l.xExpenses, Icons.payments_outlined, '/expenses'),
            (l.xProduce, Icons.eco_outlined, '/produce'),
            (l.xReports, Icons.bar_chart_outlined, '/reports'),
            (l.xCalendar, Icons.calendar_month_outlined, '/calendar'),
            (l.xBackup, Icons.backup_outlined, '/backup'),
            (l.xSecurity, Icons.lock_outlined, '/security'),
          ])
            ListTile(
              leading: Icon(entry.$2),
              title: Text(entry.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(entry.$3),
            ),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l.english)),
              ButtonSegment(value: 'kn', label: Text(l.kannada)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (v) =>
                ref.read(localeProvider.notifier).set(v.first),
          ),
          SectionTitle(l.exportDb),
          PaddedCard(
            onTap: () => _export(context, ref),
            child: Row(
              children: [
                const RoundIcon(Icons.ios_share),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.exportDb,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l.exportDbSub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.dataOnPhone,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),

        ],
      ),
    );
  }
}
