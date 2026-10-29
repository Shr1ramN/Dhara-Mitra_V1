import '../calendar/calendar_editors.dart';
import '../../core/v1.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/validation.dart';
import '../common/feature_providers.dart';
import '../common/forms.dart';
import '../common/record_page.dart';
import '../produce/produce_repository.dart';
import '../produce/produce_screen.dart';

class Receivable {
  const Receivable(
    this.id,
    this.buyerId,
    this.lotCode,
    this.date,
    this.net,
    this.received,
    this.produce,
  );
  final String id, buyerId, lotCode;
  final DateTime date;
  final int net, received;
  final bool produce;
  int get pending => net - received;
}

final receivablesProvider = Provider<AsyncValue<List<Receivable>>>((ref) {
  final areca = ref.watch(lotViewsProvider);
  final produce = ref.watch(produceProvider);
  if (areca.hasError) return AsyncError(areca.error!, areca.stackTrace!);
  if (produce.hasError) return AsyncError(produce.error!, produce.stackTrace!);
  if (!areca.hasValue || !produce.hasValue) return const AsyncLoading();
  final all = [
    for (final lot in areca.requireValue)
      for (final s in lot.sales)
        Receivable(
          s.sale.id,
          s.sale.buyerId,
          lot.lot.code,
          s.sale.date,
          s.net,
          s.sale.received,
          false,
        ),
    for (final lot in produce.requireValue)
      for (final s in lot.sales)
        Receivable(
          s.id,
          s.buyerId,
          lot.lot.code,
          s.date,
          s.gross - s.deductions,
          s.received,
          true,
        ),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return AsyncData(all);
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});
  Future<void> _buyer(
    BuildContext context,
    WidgetRef ref, [
    Buyer? buyer,
  ]) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xBuyer,
      fields: [
        EntryField('name', l.buyerName, required: true, initial: buyer?.name),
        EntryField(
          'kind',
          l.xType,
          kind: InputKind.choice,
          required: true,
          initial: buyer?.kind.name ?? 'trader',
          options: {for (final k in BuyerKind.values) k.name: l.buyerKind(k)},
        ),
        EntryField('phone', l.phone, initial: buyer?.phone),
        EntryField('place', l.xPlace, initial: buyer?.place),
      ],
      onSave: (v) async {
        final db = ref.read(databaseProvider);
        await db
            .into(db.buyers)
            .insertOnConflictUpdate(
              BuyersCompanion.insert(
                id: buyer == null ? const Value.absent() : Value(buyer.id),
                name: v.text('name'),
                kind: Value(BuyerKind.values.byName(v.text('kind'))),
                phone: Value(v.text('phone')),
                place: Value(v.text('place')),
                updatedAt: Value(DateTime.now()),
              ),
            );
      },
    );
  }

  Future<void> _payment(
    BuildContext context,
    WidgetRef ref,
    Receivable sale,
  ) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: l.xRecordPayment,
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(entryDayProvider),
        ),
        EntryField('notes', l.notes, kind: InputKind.notes),
        EntryField(
          'amount',
          l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
          maximum: sale.pending.toDouble(),
        ),
      ],
      onSave: (v) async {
        if (sale.produce) {
          await ref
              .read(produceRepositoryProvider)
              .receive(
                sale.id,
                v.money('amount'),
                date: v.date('date'),
                notes: v.text('notes'),
              );
        } else {
          await ref.read(databaseProvider).transaction(() async {
            final db = ref.read(databaseProvider);
            final latest = await (db.select(
              db.sales,
            )..where((s) => s.id.equals(sale.id))).getSingle();
            positive(v.money('amount'));
            await ref
                .read(lotsRepositoryProvider)
                .setReceived(
                  sale.id,
                  latest.received + v.money('amount'),
                  date: v.date('date'),
                  notes: v.text('notes'),
                );
          });
        }
      },
    );
  }

  Future<void> _sale(BuildContext context, WidgetRef ref) async {
    final l = context.l;
    final lots = ref.read(lotViewsProvider).value ?? [];
    final produce = ref.read(produceProvider).value ?? <ProduceView>[];
    final selection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final v in lots.where((v) => v.remainingKg > 0))
              ListTile(
                title: Text('${v.lot.code} · ${v.lot.title}'),
                onTap: () => Navigator.pop(context, 'areca:${v.lot.id}'),
              ),
            for (final v in produce.where(
              (v) => v.lot.quantity != null && v.remaining > 0,
            ))
              ListTile(
                title: Text('${v.lot.code} · ${v.lot.title}'),
                onTap: () => Navigator.pop(context, 'produce:${v.lot.id}'),
              ),
            if (!lots.any((v) => v.remainingKg > 0) &&
                !produce.any((v) => v.remaining > 0))
              Padding(padding: const EdgeInsets.all(24), child: Text(l.noLots)),
          ],
        ),
      ),
    );
    if (selection == null || !context.mounted) return;
    final id = selection.split(':')[1];
    if (selection.startsWith('areca:')) {
      await context.push('/lot/$id/sale');
    } else {
      await ProduceScreen.recordSale(
        context,
        ref,
        produce.firstWhere((v) => v.lot.id == id),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final sales = ref.watch(receivablesProvider);
    final buyers = ref.watch(buyersProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.xSales),
          bottom: TabBar(
            tabs: [
              Tab(text: l.xSales),
              Tab(text: l.xBuyer),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RecordPage<Receivable>(
              title: l.xSales,
              embedded: true,
              value: sales,
              onAdd: () => _sale(context, ref),
              itemBuilder: (s) => RecordItem(
                id: s.id,
                title:
                    buyers.value
                        ?.where((b) => b.id == s.buyerId)
                        .firstOrNull
                        ?.name ??
                    l.xBuyer,
                subtitle: '${s.lotCode} · ${context.fmt.date(s.date)}',
                details: {
                  l.net: context.fmt.money(s.net),
                  l.xReceived: context.fmt.money(s.received),
                  l.xPending: context.fmt.money(s.pending),
                },
                onEdit: () => editCalendarSale(context, ref, s.id),
                actions: [
                  if (s.pending > 0)
                    FilledButton(
                      onPressed: () => _payment(context, ref, s),
                      child: Text(l.xRecordPayment),
                    ),
                ],
              ),
            ),
            RecordPage<Buyer>(
              title: l.xBuyer,
              embedded: true,
              value: buyers,
              onAdd: () => _buyer(context, ref),
              itemBuilder: (b) {
                final transactions =
                    sales.value?.where((s) => s.buyerId == b.id).toList() ??
                    <Receivable>[];
                return RecordItem(
                  id: b.id,
                  title: b.name,
                  subtitle:
                      '${l.xPending}: ${context.fmt.money(transactions.fold(0, (s, x) => s + x.pending))}',
                  details: {
                    l.phone: b.phone,
                    l.xPlace: b.place,
                    l.xType: l.buyerKind(b.kind),
                  },
                  onEdit: () => _buyer(context, ref, b),
                  actions: [
                    for (final sale in transactions)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(sale.lotCode),
                        subtitle: Text(context.fmt.date(sale.date)),
                        trailing: Text(context.fmt.money(sale.pending)),
                        onTap: sale.pending > 0
                            ? () => _payment(context, ref, sale)
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
