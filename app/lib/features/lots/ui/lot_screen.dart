import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../domain/lot_calc.dart';
import '../domain/lot_view.dart';
import 'lot_sheets.dart';
import '../../common/forms.dart';
import 'collections_screen.dart';

class LotScreen extends ConsumerWidget {
  const LotScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final value = ref.watch(lotViewProvider(lotId));
    final v = value.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(v?.lot.code ?? ''),
        actions: [
          if (v != null)
            PopupMenuButton<void>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: l.deleteLot,
                      body: l.deleteLotBody,
                    );
                    if (!ok || !context.mounted) return;
                    await ref.read(lotsRepositoryProvider).deleteLot(lotId);
                    if (context.mounted) context.pop();
                  },
                  child: Text(l.deleteLot),
                ),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: value,
        builder: (v) => v == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  _Header(v),
                  _HarvestSection(v),
                  LotCollections(lotId),
                  _DryingSection(v),
                  _PeelingSection(v),
                  _GradingSection(v),
                  _StorageSection(v),
                  _SalesSection(v),
                  _MoneySection(v),
                  _LogSection(v),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final reached = v.stage.index;
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropDot(v.lot.crop),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.crop(v.lot.crop)} · ${l.seasonLabel(v.season.label)}',
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
          Text(v.lot.title, style: display(20)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final s in LotStage.values) ...[
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: s.index <= reached
                          ? AppColors.accent
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                if (s != LotStage.sold) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.stage(v.stage),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Section title + card, used for each stage of the lot.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionTitle(title, trailing: trailing),
      PaddedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, height: 1.4),
    ),
  );
}

/// Labour lines of one stage, with add and long-press remove.
class _StageLabour extends ConsumerWidget {
  const _StageLabour(
    this.v,
    this.stage, {
    required this.unit,
    this.qty,
    this.role,
  });

  final LotView v;
  final LotStage stage;
  final RateUnit unit;
  final double? qty;
  final WorkerRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final lines = v.labour.where((x) => x.entry.stage == stage).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 20),
        for (final x in lines)
          GestureDetector(
            onLongPress: () async {
              final ok = await confirm(
                context,
                title: l.confirmDelete,
                body: l.removeLabourLine,
              );
              if (ok) {
                await ref.read(lotsRepositoryProvider).deleteLabour(x.entry.id);
              }
            },
            child: LabourLineTile(
              name:
                  x.worker?.name ?? (x.entry.note.isEmpty ? '—' : x.entry.note),
              qty: x.entry.qty,
              unit: x.entry.unit,
              rate: x.entry.rate,
              amount: x.entry.amount,
            ),
          ),
        if (lines.isNotEmpty)
          KvRow(l.labourCost, context.fmt.money(v.labourCost(stage))),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final line = await showLabourLineSheet(
                context,
                unit: unit,
                qty: qty,
                preferRole: role,
              );
              if (line != null && context.mounted) {
                await perform(context, () async {
                  await ref.read(lotsRepositoryProvider).addLabour(
                    v.lot.id,
                    stage,
                    ref.read(todayProvider),
                    [line],
                  );
                });
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.addLabourLine),
          ),
        ),
      ],
    );
  }
}

class _HarvestSection extends StatelessWidget {
  const _HarvestSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final lot = v.lot;
    return _Section(
      title: l.secHarvest,
      children: [
        KvRow(l.harvestDate, fmt.date(lot.harvestedOn)),
        if (v.plots.isNotEmpty)
          KvRow(l.plots, v.plots.map((p) => p.name).join(', ')),
        if (lot.palmsClimbed != null)
          KvRow(l.palmsClimbed, '${lot.palmsClimbed}'),
        if (lot.freshBags != null) KvRow(l.fFreshBags, '${lot.freshBags}'),
        if (lot.freshKg != null) KvRow(l.freshKg, fmt.kg(lot.freshKg!)),
        if (lot.notes.isNotEmpty) _Muted(lot.notes),
        _StageLabour(
          v,
          LotStage.harvest,
          unit: RateUnit.palm,
          qty: lot.palmsClimbed?.toDouble(),
          role: WorkerRole.climber,
        ),
      ],
    );
  }
}

class _DryingSection extends ConsumerWidget {
  const _DryingSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final lot = v.lot;
    final today = ref.watch(todayProvider);
    final repo = ref.read(lotsRepositoryProvider);

    if (lot.dryingStartedOn == null) {
      return _Section(
        title: l.secDrying,
        children: [
          _Muted(l.notStartedYet),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => showStartDryingSheet(context, v),
            child: Text(l.startDrying),
          ),
        ],
      );
    }
    final day = v.dryingDayOn(today)!;
    final ended = lot.dryingEndedOn != null;
    return _Section(
      title: l.secDrying,
      children: [
        if (!ended) ...[
          Text(l.dayOf(day, lot.dryingTargetDays), style: display(18)),
          const SizedBox(height: 8),
          ProgressLine(dryingProgress(day, lot.dryingTargetDays)),
          const SizedBox(height: 6),
          _Muted(
            l.expectedDone(
              fmt.date(
                expectedDryingEnd(lot.dryingStartedOn!, lot.dryingTargetDays),
              ),
            ),
          ),
        ],
        KvRow(l.started, fmt.date(lot.dryingStartedOn!)),
        if (ended) ...[
          KvRow(l.finished, fmt.date(lot.dryingEndedOn!)),
          KvRow(l.daysOnYard, '$day'),
        ],
        if (lot.yard.isNotEmpty) KvRow(l.yard, lot.yard),
        KvRow(l.coveredForRain, l.nTimes(v.count(LotEventKind.cover))),
        KvRow(l.turned, l.nTimes(v.count(LotEventKind.turn))),
        if (lot.driedBags != null) KvRow(l.fDriedBags, '${lot.driedBags}'),
        if (lot.driedKg != null) KvRow(l.driedKg, fmt.kg(lot.driedKg!)),
        if (!ended) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await repo.addEvent(lot.id, LotEventKind.cover);
                    if (context.mounted) showSnack(context, l.coverLogged);
                  },
                  icon: const Icon(Icons.umbrella_outlined, size: 18),
                  label: Text(l.logRainCover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await repo.addEvent(lot.id, LotEventKind.turn);
                    if (context.mounted) showSnack(context, l.turningLogged);
                  },
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: Text(l.logTurning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => showFinishDryingSheet(context, v),
            child: Text(l.finishDrying),
          ),
        ],
        _StageLabour(
          v,
          LotStage.drying,
          unit: RateUnit.day,
          role: WorkerRole.daily,
        ),
      ],
    );
  }
}

class _PeelingSection extends StatelessWidget {
  const _PeelingSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final lot = v.lot;
    if (lot.dryingEndedOn == null) {
      return _Section(title: l.secPeeling, children: [_Muted(l.notStartedYet)]);
    }
    if (lot.chaliKg == null) {
      return _Section(
        title: l.secPeeling,
        children: [
          if (lot.driedBags != null) KvRow(l.fDriedBags, '${lot.driedBags}'),
          if (lot.driedKg != null) KvRow(l.driedKg, fmt.kg(lot.driedKg!)),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => showPeelingSheet(context, v),
            child: Text(l.recordPeeling),
          ),
        ],
      );
    }
    return _Section(
      title: l.secPeeling,
      trailing: TextButton(
        onPressed: () => showPeelingSheet(context, v),
        child: Text(l.edit),
      ),
      children: [
        if (lot.peeledOn != null) KvRow(l.date, fmt.date(lot.peeledOn!)),
        if (lot.driedBags != null) KvRow(l.fDriedBags, '${lot.driedBags}'),
        if (lot.driedKg != null) KvRow(l.driedKg, fmt.kg(lot.driedKg!)),
        KvRow(l.chaliKg, fmt.kg(lot.chaliKg!)),
        if (v.outTurn != null) KvRow(l.outTurn, fmt.percent(v.outTurn!)),
        _StageLabour(
          v,
          LotStage.peeling,
          unit: RateUnit.kg,
          qty: lot.driedKg,
          role: WorkerRole.peeler,
        ),
      ],
    );
  }
}

class _GradingSection extends StatelessWidget {
  const _GradingSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    if (v.lot.chaliKg == null) {
      return _Section(title: l.secGrading, children: [_Muted(l.notStartedYet)]);
    }
    if (v.grades.isEmpty) {
      return _Section(
        title: l.secGrading,
        children: [
          _Muted(l.skipGrading),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showGradesSheet(context, v),
            child: Text(l.enterGrades),
          ),
        ],
      );
    }
    return _Section(
      title: l.secGrading,
      trailing: TextButton(
        onPressed: () => showGradesSheet(context, v),
        child: Text(l.editGrades),
      ),
      children: [
        for (final g in ArecaGrade.values)
          if (v.gradeKg[g] != null) KvRow(l.grade(g), fmt.kg(v.gradeKg[g]!)),
        const Divider(),
        KvRow(
          l.gradedTotal,
          '${fmt.kg(v.gradedKg)} / ${fmt.kg(v.lot.chaliKg!)}',
        ),
      ],
    );
  }
}

class _StorageSection extends ConsumerWidget {
  const _StorageSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final lot = v.lot;
    if (lot.chaliKg == null) {
      return _Section(title: l.secStorage, children: [_Muted(l.notStartedYet)]);
    }
    if (lot.storedOn == null) {
      return _Section(
        title: l.secStorage,
        children: [
          FilledButton.tonal(
            onPressed: () => showStorageSheet(context, v),
            child: Text(l.moveToStorage),
          ),
        ],
      );
    }
    final checks = v.events
        .where(
          (e) => e.kind == LotEventKind.moisture || e.kind == LotEventKind.pest,
        )
        .toList();
    return _Section(
      title: l.secStorage,
      trailing: TextButton(
        onPressed: () => showStorageSheet(context, v),
        child: Text(l.edit),
      ),
      children: [
        if (lot.storagePlace.isNotEmpty)
          KvRow(l.storagePlace, lot.storagePlace),
        KvRow(l.storedSince, fmt.date(lot.storedOn!)),
        KvRow(l.daysInStorage, '${v.storageDaysOn(ref.watch(todayProvider))}'),
        if (lot.bags != null) KvRow(l.bags, '${lot.bags}'),
        if (lot.storedPricePerKg != null) ...[
          KvRow(l.priceWhenStored, fmt.money(lot.storedPricePerKg!)),
          if (v.remainingKg > 0)
            KvRow(
              l.valueAtStoredPrice,
              fmt.money(v.valueAt(lot.storedPricePerKg!)),
            ),
        ],
        if (checks.isNotEmpty) ...[
          const Divider(),
          for (final e in checks.take(3))
            KvRow(
              '${l.eventKind(e.kind)} · ${fmt.dayMonth(e.at)}',
              e.value.isEmpty ? e.note : e.value,
            ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showCheckSheet(context, v),
          icon: const Icon(Icons.fact_check_outlined, size: 18),
          label: Text(l.logCheck),
        ),
      ],
    );
  }
}

class _SalesSection extends ConsumerWidget {
  const _SalesSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    final canSell = v.lot.chaliKg != null && v.remainingKg > 0;
    return _Section(
      title: l.secSales,
      children: [
        if (v.sales.isEmpty) _Muted(l.noSales),
        for (final s in v.sales)
          InkWell(
            onTap: () => showReceivedSheet(context, s),
            onLongPress: () async {
              final ok = await confirm(context, title: l.deleteSale);
              if (ok) {
                await ref.read(lotsRepositoryProvider).deleteSale(s.sale.id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.buyer?.name ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${fmt.date(s.sale.date)} · ${fmt.kg(s.kg)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.money(s.net),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        s.pending > 0
                            ? '${l.pending} ${fmt.money(s.pending)}'
                            : l.fullyPaid,
                        style: TextStyle(
                          fontSize: 12,
                          color: s.pending > 0
                              ? AppColors.warnText
                              : AppColors.up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (v.lot.chaliKg != null) ...[
          const Divider(),
          KvRow(l.soldSoFar, fmt.kg(v.soldKg)),
          KvRow(l.left, fmt.kg(v.remainingKg)),
        ],
        if (canSell) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push('/lot/${v.lot.id}/sale'),
            child: Text(l.recordSale),
          ),
        ],
      ],
    );
  }
}

class _MoneySection extends StatelessWidget {
  const _MoneySection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    return _Section(
      title: l.secMoney,
      children: [
        KvRow(l.lotCost, fmt.money(v.totalCost)),
        KvRow(l.saleValue, fmt.money(v.saleNet)),
        if (v.pending > 0)
          KvRow(
            l.pending,
            fmt.money(v.pending),
            valueColor: AppColors.warnText,
          ),
        if (v.sales.isNotEmpty)
          KvRow(
            l.profit,
            fmt.money(v.profit),
            valueColor: v.profit >= 0 ? AppColors.up : AppColors.down,
          ),
        if (v.costPerKgChali != null)
          KvRow(l.costPerKg, fmt.money(v.costPerKgChali!)),
      ],
    );
  }
}

class _LogSection extends ConsumerWidget {
  const _LogSection(this.v);

  final LotView v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final fmt = context.fmt;
    return _Section(
      title: l.secLog,
      trailing: TextButton.icon(
        onPressed: () => showCheckSheet(context, v),
        icon: const Icon(Icons.add, size: 18),
        label: Text(l.add),
      ),
      children: [
        if (v.events.isEmpty) _Muted(l.noLedger),
        for (final e in v.events)
          InkWell(
            onLongPress: () async {
              final ok = await confirm(context, title: l.deleteEntry);
              if (ok) await ref.read(lotsRepositoryProvider).deleteEvent(e.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      fmt.dayMonth(e.at),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      [
                        l.eventKind(e.kind),
                        if (e.value.isNotEmpty) e.value,
                        if (e.note.isNotEmpty) e.note,
                      ].join(' · '),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
