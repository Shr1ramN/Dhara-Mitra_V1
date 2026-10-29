import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/validation.dart';
import '../lots/domain/lot_calc.dart';
import '../common/forms.dart';

Future<void> editCalendarPayment(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final db = ref.read(databaseProvider);
  final receipt = await (db.select(
    db.saleReceipts,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  final worker = receipt == null
      ? await (db.select(
          db.workerTxns,
        )..where((t) => t.id.equals(id))).getSingle()
      : null;
  if (!context.mounted) return;
  await openEntryForm(
    context,
    title: context.l.xRecordPayment,
    fields: [
      EntryField(
        'date',
        context.l.date,
        kind: InputKind.date,
        required: true,
        initial: receipt?.date ?? worker!.date,
      ),
      EntryField(
        'amount',
        context.l.xAmount,
        kind: InputKind.money,
        required: true,
        positive: true,
        initial: paiseToInput(receipt?.amount ?? worker!.amount),
      ),
      EntryField(
        'notes',
        context.l.notes,
        kind: InputKind.notes,
        initial: receipt?.notes ?? worker!.note,
      ),
    ],
    onSave: (v) => db.transaction(() async {
      final date = v.date('date');
      require(!date.isAfter(DateTime.now()), 'dates');
      if (receipt != null) {
        final current = await (db.select(
          db.saleReceipts,
        )..where((t) => t.id.equals(id))).getSingle();
        if (current.produce) {
          final sale = await (db.select(
            db.produceSales,
          )..where((t) => t.id.equals(current.saleId))).getSingle();
          final total = sale.received - current.amount + v.money('amount');
          require(!sale.deleted && !date.isBefore(sale.date), 'dates');
          require(
            total >= 0 && total <= sale.gross - sale.deductions,
            'balance',
          );
          await (db.update(
            db.produceSales,
          )..where((t) => t.id.equals(sale.id))).write(
            ProduceSalesCompanion(
              received: Value(total),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } else {
          final sale = await (db.select(
            db.sales,
          )..where((t) => t.id.equals(current.saleId))).getSingle();
          final lines = await (db.select(
            db.saleLines,
          )..where((t) => t.saleId.equals(sale.id))).get();
          final total = sale.received - current.amount + v.money('amount');
          final net =
              lines
                  .where((l) => !l.deleted)
                  .fold(0, (sum, l) => sum + l.amount) -
              sale.deductions;
          require(!sale.deleted && !date.isBefore(sale.date), 'dates');
          require(total >= 0 && total <= net, 'balance');
          await (db.update(db.sales)..where((t) => t.id.equals(sale.id))).write(
            SalesCompanion(
              received: Value(total),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        await (db.update(db.saleReceipts)..where((t) => t.id.equals(id))).write(
          SaleReceiptsCompanion(
            date: Value(date),
            amount: Value(v.money('amount')),
            notes: Value(v.text('notes')),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        require(worker!.kind != TxnKind.work && worker.refType == null);
        await (db.update(db.workerTxns)..where((t) => t.id.equals(id))).write(
          WorkerTxnsCompanion(
            date: Value(date),
            amount: Value(v.money('amount')),
            note: Value(v.text('notes')),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }),
  );
}

Future<void> editCalendarSale(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final db = ref.read(databaseProvider);
  final sale = await (db.select(
    db.sales,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  final produce = sale == null
      ? await (db.select(
          db.produceSales,
        )..where((t) => t.id.equals(id))).getSingle()
      : null;
  final buyers = await db.select(db.buyers).get();
  final lines = sale == null
      ? <SaleLine>[]
      : (await (db.select(
              db.saleLines,
            )..where((t) => t.saleId.equals(id))).get())
            .where((l) => !l.deleted)
            .toList();
  if (!context.mounted) return;
  await openEntryForm(
    context,
    title: context.l.xSales,
    fields: [
      EntryField(
        'buyer',
        context.l.xBuyer,
        kind: InputKind.choice,
        required: true,
        initial: sale?.buyerId ?? produce!.buyerId,
        options: {
          for (final b in buyers.where((b) => !b.deleted)) b.id: b.name,
        },
      ),
      EntryField(
        'date',
        context.l.date,
        kind: InputKind.date,
        required: true,
        initial: sale?.date ?? produce!.date,
      ),
      if (produce != null) ...[
        EntryField(
          'quantity',
          context.l.xQuantity,
          kind: InputKind.quantity,
          required: true,
          positive: true,
          initial: produce.quantity,
        ),
        EntryField(
          'rate',
          context.l.xAmount,
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: paiseToInput(produce.rate),
        ),
      ],
      for (final line in lines) ...[
        EntryField(
          'qty-${line.id}',
          '${context.l.grade(line.grade)} · ${context.l.kgUnit}',
          kind: InputKind.quantity,
          required: true,
          positive: true,
          initial: line.kg,
        ),
        EntryField(
          'rate-${line.id}',
          '${context.l.grade(line.grade)} · ${context.l.xAmount}',
          kind: InputKind.money,
          required: true,
          positive: true,
          initial: paiseToInput(line.rate),
        ),
      ],
      EntryField(
        'deductions',
        context.l.deductions,
        kind: InputKind.money,
        initial: paiseToInput(sale?.deductions ?? produce!.deductions),
      ),
      EntryField(
        'notes',
        context.l.notes,
        kind: InputKind.notes,
        initial: sale?.notes ?? produce!.notes,
      ),
    ],
    onSave: (v) => db.transaction(() async {
      final date = v.date('date');
      final receipts = await (db.select(
        db.saleReceipts,
      )..where((r) => r.saleId.equals(id))).get();
      require(
        !date.isAfter(DateTime.now()) &&
            receipts
                .where((r) => !r.deleted)
                .every((r) => !date.isAfter(r.date)),
        'dates',
      );
      if (sale != null) {
        final lot = await (db.select(
          db.lots,
        )..where((t) => t.id.equals(sale.lotId!))).getSingle();
        require(!date.isBefore(lot.harvestedOn), 'dates');
        final view = (await ref.read(lotsRepositoryProvider).loadLotViews())
            .firstWhere((v) => v.lot.id == lot.id);
        final current = await (db.select(
          db.sales,
        )..where((t) => t.id.equals(id))).getSingle();
        var gross = 0;
        for (final grade in ArecaGrade.values) {
          final oldQty = lines
              .where((l) => l.grade == grade)
              .fold(0.0, (s, l) => s + l.kg);
          final newQty = lines
              .where((l) => l.grade == grade)
              .fold(0.0, (s, l) => s + v.number('qty-${l.id}'));
          require(
            newQty <= (view.remaining[grade] ?? 0) + oldQty + 0.000001,
            'stock',
          );
        }
        for (final line in lines) {
          final amount = lineAmount(
            v.number('qty-${line.id}'),
            v.money('rate-${line.id}'),
          );
          gross += amount;
          await (db.update(
            db.saleLines,
          )..where((t) => t.id.equals(line.id))).write(
            SaleLinesCompanion(
              kg: Value(v.number('qty-${line.id}')),
              rate: Value(v.money('rate-${line.id}')),
              amount: Value(amount),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
        require(
          v.money('deductions') >= 0 &&
              gross - v.money('deductions') >= current.received,
          'balance',
        );
        await (db.update(db.sales)..where((t) => t.id.equals(id))).write(
          SalesCompanion(
            deductions: Value(v.money('deductions')),
            buyerId: Value(v.text('buyer')),
            date: Value(date),
            notes: Value(v.text('notes')),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        final lot = await (db.select(
          db.produceLots,
        )..where((t) => t.id.equals(produce!.lotId))).getSingle();
        require(!date.isBefore(lot.dryingEndedOn ?? lot.harvestedOn), 'dates');
        final current = await (db.select(
          db.produceSales,
        )..where((t) => t.id.equals(id))).getSingle();
        final other = await (db.select(
          db.produceSales,
        )..where((t) => t.lotId.equals(lot.id))).get();
        final sold = other
            .where((s) => !s.deleted && s.id != id)
            .fold(0.0, (s, l) => s + l.quantity);
        final qty = v.number('quantity');
        require(qty + sold <= (lot.quantity ?? 0) + 0.000001, 'stock');
        require(lot.unit == 'kg' || qty == qty.roundToDouble());
        final gross = lineAmount(qty, v.money('rate'));
        require(
          v.money('deductions') >= 0 &&
              gross - v.money('deductions') >= current.received,
          'balance',
        );
        await (db.update(db.produceSales)..where((t) => t.id.equals(id))).write(
          ProduceSalesCompanion(
            quantity: Value(qty),
            rate: Value(v.money('rate')),
            gross: Value(gross),
            deductions: Value(v.money('deductions')),
            buyerId: Value(v.text('buyer')),
            date: Value(date),
            notes: Value(v.text('notes')),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }),
  );
}

Future<void> editCalendarHarvest(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final db = ref.read(databaseProvider);
  final lot = await (db.select(
    db.lots,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  final produce = lot == null
      ? await (db.select(
          db.produceLots,
        )..where((t) => t.id.equals(id))).getSingleOrNull()
      : null;
  if (lot == null && produce == null) return;
  if (!context.mounted) return;
  await openEntryForm(
    context,
    title: context.l.navHarvest,
    fields: [
      EntryField(
        'title',
        context.l.xTitle,
        required: true,
        initial: lot?.title ?? produce!.title,
      ),
      EntryField(
        'date',
        context.l.date,
        kind: InputKind.date,
        required: true,
        initial: lot?.harvestedOn ?? produce!.harvestedOn,
      ),
      EntryField(
        'quantity',
        context.l.xHarvestQuantity,
        kind: InputKind.quantity,
        required: true,
        positive: true,
        initial: lot == null
            ? produce!.freshQuantity
            : lot.quantityMode == 'bags'
            ? lot.freshBags
            : lot.freshKg,
      ),
      EntryField(
        'notes',
        context.l.notes,
        kind: InputKind.notes,
        initial: lot?.notes ?? produce!.notes,
      ),
    ],
    onSave: (v) => db.transaction(() async {
      final date = v.date('date');
      require(!date.isAfter(DateTime.now()), 'dates');
      if (lot != null) {
        final view = (await ref.read(lotsRepositoryProvider).loadLotViews())
            .firstWhere((v) => v.lot.id == id);
        final dates = [
          if (lot.dryingStartedOn != null) lot.dryingStartedOn!,
          ...view.sales.map((s) => s.sale.date),
          ...view.labour.map((l) => l.entry.date),
        ];
        require(dates.every((d) => !date.isAfter(d)), 'dates');
        await ref
            .read(lotsRepositoryProvider)
            .updateLot(
              id,
              LotsCompanion(
                title: Value(v.text('title')),
                harvestedOn: Value(date),
                freshBags: lot.quantityMode == 'bags'
                    ? Value(v.number('quantity'))
                    : const Value.absent(),
                freshKg: lot.quantityMode == 'bags'
                    ? const Value.absent()
                    : Value(v.number('quantity')),
                notes: Value(v.text('notes')),
              ),
            );
      } else {
        final sales = await (db.select(
          db.produceSales,
        )..where((t) => t.lotId.equals(id))).get();
        final qty = v.number('quantity');
        require(produce!.freshUnit == 'kg' || qty == qty.roundToDouble());
        require(
          sales.where((s) => !s.deleted).every((s) => !date.isAfter(s.date)),
          'dates',
        );
        require(
          produce.dryingStartedOn == null ||
              !date.isAfter(produce.dryingStartedOn!),
          'dates',
        );
        final unchangedProduct =
            produce.product == produce.crop || produce.product == 'nut';
        if (unchangedProduct) {
          require(
            qty >=
                sales
                    .where((s) => !s.deleted)
                    .fold(0.0, (sum, s) => sum + s.quantity),
            'stock',
          );
        }
        await (db.update(db.produceLots)..where((t) => t.id.equals(id))).write(
          ProduceLotsCompanion(
            title: Value(v.text('title')),
            harvestedOn: Value(date),
            freshQuantity: Value(qty),
            quantity: unchangedProduct && produce.quantity != null
                ? Value(qty)
                : const Value.absent(),
            notes: Value(v.text('notes')),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }),
  );
}
