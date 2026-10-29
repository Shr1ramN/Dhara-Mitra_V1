import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/db/database.dart';
import '../../../core/providers.dart';
import '../../../core/money.dart';
import '../../../core/quantity.dart';
import '../../../core/widgets.dart';
import '../../common/feature_providers.dart';
import '../../common/forms.dart';
import '../data/stock_repository.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  Future<void> _item(
    BuildContext context,
    WidgetRef ref, {
    StockBalance? balance,
  }) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: balance == null ? l.add : l.edit,
      fields: [
        EntryField(
          'name',
          l.xStockName,
          required: true,
          initial: balance?.item.name,
        ),
        EntryField(
          'unit',
          l.xUnit,
          kind: InputKind.choice,
          required: true,
          initial: balance?.item.unit ?? 'kg',
          options: {
            'kg': l.kgUnit,
            'g': 'g',
            'litre': 'L',
            'ml': 'ml',
            'bag': l.xBags,
            'piece': l.xCount,
          },
        ),
        EntryField(
          'minimum',
          l.xMinimum,
          kind: InputKind.quantity,
          initial: balance?.item.minimum ?? 0,
        ),
      ],
      onSave: (v) async {
        await ref
            .read(stockRepositoryProvider)
            .saveItem(
              id: balance?.item.id,
              name: v.text('name'),
              unit: v.text('unit'),
              minimum: v.number('minimum'),
            );
      },
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    StockBalance balance,
  ) async {
    final l = context.l;
    await openEntryForm(
      context,
      title: '${l.xPurchase} · ${balance.item.name}',
      fields: [
        EntryField(
          'date',
          l.date,
          kind: InputKind.date,
          required: true,
          initial: ref.read(todayProvider),
        ),
        EntryField(
          'quantity',
          '${l.xQuantity} (${balance.item.unit})',
          kind: InputKind.quantity,
          required: true,
          positive: true,
        ),
        EntryField(
          'cost',
          l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
        ),
        EntryField('supplier', l.xSupplier),
        EntryField('notes', l.notes, kind: InputKind.notes),
      ],
      onSave: (v) async {
        await ref
            .read(stockRepositoryProvider)
            .purchase(
              itemId: balance.item.id,
              date: v.date('date'),
              quantity: v.number('quantity'),
              cost: v.money('cost'),
              supplier: v.text('supplier'),
              note: v.text('notes'),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.xStock)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _item(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.add),
      ),
      body: AsyncBody(
        value: ref.watch(stockBalancesProvider),
        builder: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(l.xStockHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (items.isEmpty)
              EmptyState(icon: Icons.inventory_2_outlined, text: l.xEmpty),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaddedCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _StockDetail(item.item.id),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (item.low) Chip(label: Text(l.xLowStock)),
                          IconButton(
                            onPressed: () => _item(context, ref, balance: item),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l.edit,
                          ),
                        ],
                      ),
                      Text(
                        '${formatQty(item.quantity)} ${item.item.unit} · ${l.xValue}: ${formatRupees(item.value)}',
                      ),
                      Text(
                        '${l.xAverageCost}: ${formatRupees(item.averageRate, showPaise: true)} / ${item.item.unit}',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _purchase(context, ref, item),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(l.xPurchase),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockDetail extends ConsumerWidget {
  const _StockDetail(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.xTransactions)),
    body: StreamBuilder<List<StockMovement>>(
      stream: ref.watch(stockRepositoryProvider).watchMovements(id),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final m in snapshot.data ?? const <StockMovement>[])
            ListTile(
              leading: Icon(
                m.quantity > 0 ? Icons.add_shopping_cart : Icons.grass,
              ),
              title: Text(
                '${m.quantity > 0 ? '+' : ''}${formatQty(m.quantity)} · ${formatRupees(m.cost)}',
              ),
              subtitle: Text(
                '${context.fmt.date(m.date)} · ${m.supplier}\n${m.note}',
              ),
              isThreeLine: true,
            ),
        ],
      ),
    ),
  );
}
