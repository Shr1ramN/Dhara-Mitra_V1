import '../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/quantity.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';
import '../common/feature_providers.dart';
import '../common/forms.dart';
import '../common/labels.dart';
import '../common/record_page.dart';
import '../lots/ui/lot_sheets.dart';
import 'produce_repository.dart';

class ProduceScreen extends ConsumerWidget {
  const ProduceScreen({super.key});
  Future<void> _harvest(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    final crop = await showModalBottomSheet<Crop>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in [Crop.coconut, Crop.pepper, Crop.banana])
              ListTile(
                title: Text(l.crop(c)),
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (crop == null || !context.mounted) return;
    final plots = ref.read(plotsProvider).value ?? [];
    await openEntryForm(
      context,
      title: l.newHarvest,
      fields: [
        EntryField(
          'title',
          l.xTitle,
          required: true,
          initial: '${l.crop(crop)} · ${l.newHarvest}',
        ),
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(entryDayProvider),
        ),
        EntryField(
          'quantity',
          l.xHarvestQuantity,
          kind: InputKind.quantity,
          required: true,
          positive: true,
        ),
        EntryField(
          'unit',
          l.xUnit,
          kind: InputKind.choice,
          required: true,
          initial: crop == Crop.coconut ? 'nut' : 'kg',
          options: crop == Crop.coconut
              ? {'nut': l.xNuts}
              : crop == Crop.pepper
              ? {'kg': l.kgUnit}
              : {'kg': l.kgUnit, 'bunch': l.xBunches},
        ),
        EntryField(
          'plots',
          l.plotsTitle,
          kind: InputKind.multiple,
          options: {for (final p in plots) p.id: p.name},
        ),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (v) async {
        await ref
            .read(produceRepositoryProvider)
            .harvest(
              crop: crop.name,
              on: v.date('date'),
              quantity: v.number('quantity'),
              unit: v.text('unit'),
              title: v.text('title'),
              plotIds: v.selected('plots'),
              notes: v.text('notes'),
              seasonStartMonth:
                  ref.read(farmProvider).value?.seasonStartMonth ?? 6,
            );
      },
    );
  }

  Future<void> _stage(
    BuildContext context,
    WidgetRef ref,
    ProduceView v,
    String action,
  ) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: action == 'finish'
          ? l.xFinishProcessing
          : action == 'drying'
          ? l.xStartDrying
          : recordLabel(context, action),
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(entryDayProvider),
        ),
        if (action == 'finish') ...[
          EntryField(
            'quantity',
            l.xFinishedQuantity,
            kind: InputKind.quantity,
            required: true,
            positive: true,
          ),
          EntryField(
            'unit',
            l.xUnit,
            kind: InputKind.choice,
            required: true,
            initial: v.lot.unit,
            options: v.lot.crop == 'banana'
                ? {'kg': l.kgUnit, 'bunch': l.xBunches}
                : {'kg': l.kgUnit},
          ),
        ],
        if (action == 'storage') ...[
          EntryField(
            'place',
            l.xPlace,
            required: true,
            initial: v.lot.storagePlace,
          ),
          EntryField(
            'bags',
            l.xBags,
            kind: InputKind.integer,
            initial: v.lot.bags,
          ),
        ],
      ],
      onSave: (input) async {
        final repo = ref.read(produceRepositoryProvider);
        if (action == 'finish') {
          await repo.finish(
            v.lot.id,
            on: input.date('date'),
            quantity: input.number('quantity'),
            unit: input.text('unit'),
          );
        } else if (action == 'storage') {
          await repo.store(
            v.lot.id,
            on: input.date('date'),
            place: input.text('place'),
            bags: input.integer('bags'),
          );
        } else if (action == 'drying') {
          await repo.startDrying(v.lot.id, input.date('date'));
        } else {
          await repo.processing(v.lot.id, action, input.date('date'));
        }
      },
    );
  }

  static Future<void> recordSale(
    BuildContext context,
    WidgetRef ref,
    ProduceView v,
  ) async {
    final l = context.l;
    final buyers = ref.read(buyersProvider).value ?? [];
    await openEntryForm(
      context,
      title: l.xRecordSale,
      fields: [
        EntryField(
          'buyer',
          l.xBuyer,
          kind: InputKind.choice,
          initial: '',
          options: {'': l.newBuyer, for (final b in buyers) b.id: b.name},
        ),
        EntryField('newBuyer', l.buyerName),
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(entryDayProvider),
        ),
        EntryField(
          'quantity',
          '${l.xQuantity} (${recordLabel(context, v.lot.unit)})',
          kind: InputKind.quantity,
          required: true,
          positive: true,
          maximum: v.remaining,
          initial: v.remaining,
        ),
        EntryField(
          'rate',
          l.xRate,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
        EntryField('deductions', l.xDeductions, kind: InputKind.money),
        EntryField('received', l.xReceived, kind: InputKind.money),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (input) => ref.read(databaseProvider).transaction(() async {
        var buyer = input.text('buyer');
        if (buyer.isEmpty) {
          require(input.text('newBuyer').isNotEmpty);
          buyer = await ref
              .read(lotsRepositoryProvider)
              .saveBuyer(name: input.text('newBuyer'), kind: BuyerKind.trader);
        }
        await ref
            .read(produceRepositoryProvider)
            .sale(
              v.lot.id,
              buyerId: buyer,
              on: input.date('date'),
              quantity: input.number('quantity'),
              rate: input.money('rate'),
              deductions: input.money('deductions'),
              received: input.money('received'),
              notes: input.text('notes'),
            );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final names = ref.watch(workerNamesProvider);
    final buyers = ref.watch(buyersProvider).value ?? [];
    return RecordPage(
      title: l.xProduce,
      value: ref.watch(produceProvider),
      onAdd: () => _harvest(context, ref),
      itemBuilder: (ProduceView v) => RecordItem(
        id: v.lot.id,
        title: v.lot.title,
        subtitle: '${v.lot.code} · ${recordLabel(context, v.stage)}',
        refType: 'produce',
        details: {
          l.date: context.fmt.date(v.lot.harvestedOn),
          l.xCrop: recordLabel(context, v.lot.crop),
          l.xHarvestQuantity:
              '${formatQty(v.lot.freshQuantity)} ${recordLabel(context, v.lot.freshUnit)}',
          if (v.lot.quantity != null)
            l.xAvailable:
                '${formatQty(v.remaining)} ${recordLabel(context, v.lot.unit)}',
          if (v.lot.crop == 'pepper' && v.lot.quantity != null)
            l.xOutTurn:
                '${(100 * v.lot.quantity! / v.lot.freshQuantity).toStringAsFixed(1)}%',
          if (v.lot.storedOn != null)
            l.xStorage:
                '${v.lot.storagePlace} · ${DateTime.now().difference(v.lot.storedOn!).inDays} ${l.xDays}',
          l.xCosts: context.fmt.money(v.cost),
          l.xIncome: context.fmt.money(v.net),
          l.xProfit: context.fmt.money(v.profit),
          l.xPending: context.fmt.money(v.pending),
          l.notes: v.lot.notes,
        },
        onDelete: () => ref.read(produceRepositoryProvider).delete(v.lot.id),
        actions: [
          if (v.stage == 'harvest' && v.sales.isEmpty && v.lot.crop != 'banana')
            OutlinedButton(
              onPressed: () => _stage(
                context,
                ref,
                v,
                v.lot.crop == 'pepper' ? 'threshing' : 'dehusking',
              ),
              child: Text(v.lot.crop == 'pepper' ? l.xThreshing : l.xDehusking),
            ),
          if (['threshing', 'dehusking'].contains(v.stage))
            OutlinedButton(
              onPressed: () => _stage(context, ref, v, 'drying'),
              child: Text(l.xStartDrying),
            ),
          if (v.stage == 'drying' ||
              (v.lot.crop == 'banana' && v.sales.isEmpty))
            OutlinedButton(
              onPressed: () => _stage(context, ref, v, 'finish'),
              child: Text(l.xFinishProcessing),
            ),
          if (v.lot.quantity != null && v.remaining > 0) ...[
            OutlinedButton(
              onPressed: () => _stage(context, ref, v, 'storage'),
              child: Text(l.xStorage),
            ),
            FilledButton(
              onPressed: () => recordSale(context, ref, v),
              child: Text(l.xRecordSale),
            ),
          ],
          for (final w in v.labour)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(names[w.workerId] ?? l.xWorker),
              subtitle: Text(w.work),
              onLongPress: () async {
                if (await confirm(context, title: l.deleteEntry) &&
                    context.mounted) {
                  await perform(
                    context,
                    () =>
                        ref.read(produceRepositoryProvider).deleteLabour(w.id),
                  );
                }
              },
              trailing: Text(context.fmt.money(w.amount)),
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.xAddLabour),
            onPressed: () async {
              final line = await showLabourLineSheet(
                context,
                unit: RateUnit.day,
              );
              if (!context.mounted || line == null) return;
              if (line.workerId == null) {
                showSnack(context, l.xWorker);
                return;
              }
              await perform(
                context,
                () => ref
                    .read(produceRepositoryProvider)
                    .labour(
                      v.lot.id,
                      workerId: line.workerId!,
                      on: ref.read(todayProvider),
                      work: recordLabel(context, v.stage),
                      quantity: line.qty,
                      unit: line.unit.name,
                      rate: line.rate,
                    ),
              );
            },
          ),
          for (final sale in v.sales)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                buyers.where((b) => b.id == sale.buyerId).firstOrNull?.name ??
                    l.xBuyer,
              ),
              subtitle: Text(
                '${context.fmt.date(sale.date)} · ${formatQty(sale.quantity)} ${recordLabel(context, v.lot.unit)}',
              ),
              trailing: Text(context.fmt.money(sale.gross - sale.deductions)),
            ),
        ],
      ),
    );
  }
}
