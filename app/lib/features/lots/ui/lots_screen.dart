import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../domain/lot_calc.dart';
import '../domain/lot_view.dart';

enum _Filter { active, sold, all }

class LotsScreen extends ConsumerStatefulWidget {
  const LotsScreen({super.key});

  @override
  ConsumerState<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends ConsumerState<LotsScreen> {
  _Filter _filter = _Filter.active;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.lotsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.spa_outlined),
            tooltip: l.xProduce,
            onPressed: () => context.push('/produce'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/harvest-form'),
        icon: const Icon(Icons.add),
        label: Text(l.newHarvest),
      ),
      body: AsyncBody(
        value: ref.watch(lotViewsProvider),
        builder: (all) {
          final lots = switch (_filter) {
            _Filter.active =>
              all.where((v) => v.stage != LotStage.sold).toList(),
            _Filter.sold => all.where((v) => v.stage == LotStage.sold).toList(),
            _Filter.all => all,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.spa_outlined),
                label: Text(l.xProduce),
                onPressed: () => context.push('/produce'),
              ),
              SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _Filter.active,
                    label: Text(l.filterActive),
                  ),
                  ButtonSegment(value: _Filter.sold, label: Text(l.filterSold)),
                  ButtonSegment(value: _Filter.all, label: Text(l.filterAll)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: 12),
              if (lots.isEmpty)
                EmptyState(icon: Icons.eco_outlined, text: l.noLots),
              for (final v in lots) ...[LotCard(v), const SizedBox(height: 10)],
            ],
          );
        },
      ),
    );
  }
}

class LotCard extends ConsumerWidget {
  const LotCard(this.v, {super.key});

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final today = ref.watch(todayProvider);
    final lot = v.lot;
    return PaddedCard(
      onTap: () => context.push('/lot/${lot.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropDot(lot.crop),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.crop(lot.crop)} · ${l.seasonLabel(v.season.label)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              StagePill(v.stage),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lot.title.isEmpty ? lot.code : lot.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            lot.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ..._detail(context, today, l, fmt),
        ],
      ),
    );
  }

  List<Widget> _detail(
    BuildContext context,
    DateTime today,
    AppLocalizations l,
    Formats fmt,
  ) {
    final lot = v.lot;
    switch (v.stage) {
      case LotStage.harvest:
        return [
          Text(
            [
              fmt.date(lot.harvestedOn),
              if (lot.palmsClimbed != null) l.palmsCount(lot.palmsClimbed!),
              if (lot.freshKg != null) fmt.kg(lot.freshKg!),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ];
      case LotStage.drying:
        final day = v.dryingDayOn(today)!;
        final ended = lot.dryingEndedOn != null;
        return [
          Text(
            ended ? l.finishDrying : l.dayOf(day, lot.dryingTargetDays),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ProgressLine(ended ? 1 : dryingProgress(day, lot.dryingTargetDays)),
        ];
      case LotStage.peeling:
        return [
          Text(
            [
              if (lot.dryingEndedOn != null)
                '${l.finished} ${fmt.dayMonth(lot.dryingEndedOn!)}',
              if (lot.driedKg != null) fmt.kg(lot.driedKg!),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ];
      case LotStage.grading:
      case LotStage.storage:
        final days = v.storageDaysOn(today);
        return [
          Text(
            [
              l.kgLeft(formatQty(v.remainingKg)),
              if (days != null) l.daysInStore(days),
            ].join(' · '),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ];
      case LotStage.sold:
        return [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.profit,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              Text(
                fmt.money(v.profit),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: v.profit >= 0 ? AppColors.up : AppColors.down,
                ),
              ),
            ],
          ),
          if (v.pending > 0)
            Text(
              '${l.pending} ${fmt.money(v.pending)}',
              style: const TextStyle(color: AppColors.warnText),
            ),
        ];
    }
  }
}
