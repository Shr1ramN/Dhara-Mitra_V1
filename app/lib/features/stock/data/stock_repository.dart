import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/dates.dart';
import '../../../core/validation.dart';

class StockBalance {
  const StockBalance(this.item, this.quantity, this.value);
  final StockItem item;
  final double quantity;
  final int value;
  int get averageRate => quantity <= 0.000001 ? 0 : (value / quantity).round();
  bool get low => quantity <= item.minimum;
}

class StockRepository {
  StockRepository(this.db);
  final AppDatabase db;

  Stream<List<StockBalance>> watchBalances() =>
      db.watchAll([db.stockItems, db.stockMovements], balances);

  Future<List<StockBalance>> balances() async {
    final items =
        await (db.select(db.stockItems)
              ..where((s) => s.deleted.equals(false))
              ..orderBy([(s) => OrderingTerm.asc(s.name)]))
            .get();
    final movements = await (db.select(
      db.stockMovements,
    )..where((s) => s.deleted.equals(false))).get();
    return [
      for (final item in items)
        StockBalance(
          item,
          movements
              .where((m) => m.itemId == item.id)
              .fold(0.0, (s, m) => s + m.quantity),
          movements
              .where((m) => m.itemId == item.id)
              .fold(0, (s, m) => s + m.cost),
        ),
    ];
  }

  Future<String> saveItem({
    String? id,
    required String name,
    required String unit,
    double minimum = 0,
  }) async {
    require(
      name.trim().isNotEmpty &&
          ['kg', 'g', 'litre', 'ml', 'bag', 'piece'].contains(unit),
    );
    nonNegative(minimum);
    if (id != null) {
      final old = await (db.select(
        db.stockItems,
      )..where((s) => s.id.equals(id))).getSingle();
      if (old.unit != unit) {
        final used = await (db.select(
          db.stockMovements,
        )..where((s) => s.itemId.equals(id))).get();
        require(used.isEmpty, 'linked');
      }
      await (db.update(db.stockItems)..where((s) => s.id.equals(id))).write(
        StockItemsCompanion(
          name: Value(name.trim()),
          unit: Value(unit),
          minimum: Value(minimum),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return id;
    }
    return (await db
            .into(db.stockItems)
            .insertReturning(
              StockItemsCompanion.insert(
                name: name.trim(),
                unit: Value(unit),
                minimum: Value(minimum),
              ),
            ))
        .id;
  }

  Future<String> purchase({
    required String itemId,
    required DateTime date,
    required double quantity,
    required int cost,
    String supplier = '',
    String note = '',
  }) async {
    positive(quantity);
    positive(cost);
    final item =
        await (db.select(db.stockItems)
              ..where((s) => s.id.equals(itemId) & s.deleted.equals(false)))
            .getSingleOrNull();
    require(item != null);
    return (await db
            .into(db.stockMovements)
            .insertReturning(
              StockMovementsCompanion.insert(
                itemId: itemId,
                date: dateOnly(date),
                kind: 'purchase',
                quantity: quantity,
                cost: cost,
                supplier: Value(supplier.trim()),
                note: Value(note.trim()),
              ),
            ))
        .id;
  }

  Stream<List<StockMovement>> watchMovements(String itemId) =>
      (db.select(db.stockMovements)
            ..where((s) => s.itemId.equals(itemId) & s.deleted.equals(false))
            ..orderBy([
              (s) => OrderingTerm.desc(s.date),
              (s) => OrderingTerm.desc(s.updatedAt),
            ]))
          .watch();
}
