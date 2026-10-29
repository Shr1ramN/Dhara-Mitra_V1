import '../../../core/v1.dart';
import '../../calendar/calendar_records.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../lots/domain/lot_calc.dart';
import '../../lots/domain/lot_view.dart';
import '../../lots/ui/lots_screen.dart';
import '../../sales/sales_screen.dart';

final monthlyCostsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(todayProvider);
  return db.watchAll([db.expenses, db.workerTxns], () async {
    final expenses = await db.select(db.expenses).get();
    final wages = await db.select(db.workerTxns).get();
    bool inMonth(DateTime d) =>
        d.year == today.year && d.month == today.month && !d.isAfter(today);
    return expenses
            .where((e) => !e.deleted && inMonth(e.date))
            .fold(0, (s, e) => s + e.amount) +
        wages
            .where(
              (w) => !w.deleted && w.kind == TxnKind.work && inMonth(w.date),
            )
            .fold(0, (s, w) => s + w.amount);
  });
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final today = ref.watch(todayProvider);
    final lots = ref.watch(lotViewsProvider).value ?? const <LotView>[];
    final workers = ref.watch(workerSummariesProvider).value ?? const [];

    final drying = lots
        .where((v) => v.stage == LotStage.drying && v.lot.dryingEndedOn == null)
        .toList();
    final waiting = lots
        .where(
          (v) =>
              v.stage == LotStage.harvest ||
              v.stage == LotStage.peeling ||
              (v.stage == LotStage.drying && v.lot.dryingEndedOn != null),
        )
        .toList();
    final stored = lots
        .where(
          (v) => v.stage == LotStage.storage || v.stage == LotStage.grading,
        )
        .toList();
    final toPay = workers.fold(
      0,
      (s, w) => s + (w.balance.due > 0 ? w.balance.due : 0),
    );
    final toReceive =
        (ref.watch(receivablesProvider).value ?? const <Receivable>[]).fold(
          0,
          (s, v) => s + v.pending,
        );
    final spent = ref.watch(monthlyCostsProvider).value ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Text(
              fmt.weekdayDate(today),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text('${l.namaskara} 🙏', style: display(26)),
            OutlinedButton.icon(
              onPressed: () => context.push('/farms'),
              icon: const Icon(Icons.swap_horiz),
              label: Text(l.fFarms),
            ),
            const SizedBox(height: 6),
            if ((ref.watch(calendarRecordsProvider).value ?? [])
                .isNotEmpty) ...[
              SectionTitle(
                v1Text(context, 'Recent records', 'ಇತ್ತೀಚಿನ ದಾಖಲೆಗಳು'),
              ),
              for (final record
                  in (ref.watch(calendarRecordsProvider).value ?? []).take(3))
                ListTile(
                  title: Text(record.title),
                  subtitle: Text(fmt.date(record.date)),
                  onTap: () => context.go('/calendar'),
                ),
            ],
            if (drying.isNotEmpty) ...[
              SectionTitle(l.dryingNow),
              for (final v in drying) ...[
                _DryingCard(v),
                const SizedBox(height: 10),
              ],
            ],
            if (waiting.isNotEmpty) ...[
              SectionTitle(l.waitingForYou),
              for (final v in waiting) ...[
                LotCard(v),
                const SizedBox(height: 10),
              ],
            ],
            if (stored.isNotEmpty) ...[
              SectionTitle(l.inStorage),
              for (final v in stored) ...[
                LotCard(v),
                const SizedBox(height: 10),
              ],
            ],
            if (lots.isEmpty)
              PaddedCard(
                child: EmptyState(
                  icon: Icons.eco_outlined,
                  text: l.homeEmpty,
                  action: FilledButton.icon(
                    onPressed: () => context.push('/harvest-form'),
                    icon: const Icon(Icons.add),
                    label: Text(l.newHarvest),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.eco_outlined,
                  label: l.qaHarvest,
                  onTap: () => context.push('/harvest-form'),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.how_to_reg_outlined,
                  label: l.qaAttendance,
                  onTap: () => context.go('/labour?tab=attendance'),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.payments_outlined,
                  label: l.qaPay,
                  onTap: () => context.go('/labour?tab=dues'),
                ),
              ],
            ),
            SectionTitle(l.nFarmTools),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final feature in <(String, IconData, String)>[
                  (l.fFertilizer, Icons.grass, '/fertilizer'),
                  (
                    l.fCollections,
                    Icons.shopping_basket_outlined,
                    '/collections',
                  ),
                  (l.xCalendar, Icons.calendar_month, '/calendar'),
                  (l.xProduce, Icons.eco_outlined, '/produce'),
                  (l.navHarvest, Icons.eco_outlined, '/lots'),
                  (l.navLabour, Icons.groups_outlined, '/labour'),
                  (l.xDiary, Icons.menu_book_outlined, '/diary'),
                  (l.xSales, Icons.receipt_long_outlined, '/sales'),
                  (l.xExpenses, Icons.payments_outlined, '/expenses'),
                  (l.xReports, Icons.bar_chart_outlined, '/reports'),
                ])
                  ActionChip(
                    avatar: Icon(feature.$2, size: 18),
                    label: Text(feature.$1),
                    onPressed: () => context.push(feature.$3),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SectionTitle(l.money),
            KvRow(l.xSpentMonth, fmt.money(spent)),
            KpiRow(
              children: [
                Kpi(
                  label: l.toPayWorkers,
                  value: fmt.moneyCompact(toPay),
                  highlight: toPay > 0,
                  onTap: () => context.go('/labour?tab=dues'),
                ),
                Kpi(
                  label: l.toReceive,
                  value: fmt.moneyCompact(toReceive),
                  onTap: () => context.push('/sales'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DryingCard extends ConsumerWidget {
  const _DryingCard(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final lot = v.lot;
    final day = v.dryingDayOn(ref.watch(todayProvider))!;
    return PaddedCard(
      onTap: () => context.push('/lot/${lot.id}'),
      color: const Color(0xFFFFFAF6),
      borderColor: AppColors.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lot.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                lot.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.dayOf(day, lot.dryingTargetDays),
            style: display(22, color: AppColors.accentDark),
          ),
          const SizedBox(height: 8),
          ProgressLine(dryingProgress(day, lot.dryingTargetDays)),
          const SizedBox(height: 8),
          Text(
            [
              l.expectedDone(
                fmt.dayMonth(
                  expectedDryingEnd(lot.dryingStartedOn!, lot.dryingTargetDays),
                ),
              ),
              '${l.coveredForRain}: ${l.nTimes(v.count(LotEventKind.cover))}',
            ].join(' · '),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(lotsRepositoryProvider)
                  .addEvent(lot.id, LotEventKind.cover);
              if (context.mounted) showSnack(context, l.coverLogged);
            },
            icon: const Icon(Icons.umbrella_outlined, size: 18),
            label: Text(l.logRainCover),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: PaddedCard(
      onTap: onTap,
      child: Column(
        children: [
          RoundIcon(
            icon,
            color: AppColors.accent,
            background: AppColors.accentSoft,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
