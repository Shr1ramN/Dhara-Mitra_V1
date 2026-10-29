import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/validation.dart';
import 'lots_repository.dart';

class CollectionsRepository {
  CollectionsRepository(this.db);
  final AppDatabase db;

  Stream<List<ArecaCollection>> watch() =>
      (db.select(db.arecaCollections)
            ..where((c) => c.deleted.equals(false))
            ..orderBy([(c) => OrderingTerm.desc(c.collectedOn)]))
          .watch();

  Future<void> save({
    String? id,
    required DateTime on,
    required List<String> plotIds,
    required String unit,
    double? quantity,
    String notes = '',
    String kind = 'daily',
  }) => db.transaction(() async {
    require(unit == 'bags' || unit == 'kg');
    require(kind == 'daily' || kind == 'harvest');
    require(!dateOnly(on).isAfter(today()));
    if (quantity != null) require(quantity.isFinite && quantity > 0);
    String? assignedLot;
    if (id != null) {
      final old = await (db.select(
        db.arecaCollections,
      )..where((c) => c.id.equals(id))).getSingle();
      require(!old.deleted, 'assigned');
      assignedLot = old.lotId;
      if (assignedLot != null) {
        require(
          old.collectedOn == dateOnly(on) &&
              old.unit == unit &&
              old.plotIds.length == plotIds.length &&
              old.plotIds.toSet().containsAll(plotIds),
          'assigned',
        );
      }
    }
    for (final id in plotIds) {
      require(
        await (db.select(db.plots)
                  ..where((p) => p.id.equals(id) & p.deleted.equals(false)))
                .getSingleOrNull() !=
            null,
      );
    }
    final row = ArecaCollectionsCompanion(
      id: id == null ? const Value.absent() : Value(id),
      collectedOn: Value(dateOnly(on)),
      plotIds: Value(plotIds),
      unit: Value(unit),
      quantity: Value(quantity),
      notes: Value(notes.trim()),
      kind: Value(kind),
      updatedAt: Value(DateTime.now()),
    );
    if (id == null) {
      await db.into(db.arecaCollections).insert(row);
    } else {
      await (db.update(
        db.arecaCollections,
      )..where((c) => c.id.equals(id))).write(row);
    }
    if (assignedLot != null) await _refreshQuantity(assignedLot);
  });

  Future<void> _refreshQuantity(String id) async {
    final rows = await (db.select(
      db.arecaCollections,
    )..where((c) => c.lotId.equals(id) & c.deleted.equals(false))).get();
    final lot = await (db.select(
      db.lots,
    )..where((l) => l.id.equals(id))).getSingle();
    require(!lot.deleted && rows.isNotEmpty);
    final total = rows.any((c) => c.quantity == null)
        ? null
        : rows.fold(0.0, (sum, c) => sum + c.quantity!);
    await LotsRepository(db).updateLot(
      id,
      LotsCompanion(
        freshBags: lot.quantityMode == 'bags'
            ? Value(total)
            : const Value.absent(),
        freshKg: lot.quantityMode == 'kg' ? Value(total) : const Value.absent(),
      ),
    );
  }

  Future<void> remove(String id) => db.transaction(() async {
    final row = await (db.select(
      db.arecaCollections,
    )..where((c) => c.id.equals(id))).getSingle();
    require(row.lotId == null, 'assigned');
    await (db.update(db.arecaCollections)..where((c) => c.id.equals(id))).write(
      ArecaCollectionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<String> dryTogether(
    Set<String> ids, {
    required DateTime on,
    required String title,
    String yard = '',
    int seasonStartMonth = 6,
  }) => db.transaction(() async {
    require(ids.isNotEmpty);
    final rows = await (db.select(
      db.arecaCollections,
    )..where((c) => c.id.isIn(ids))).get();
    require(
      rows.length == ids.length &&
          rows.every((c) => !c.deleted && c.lotId == null),
      'assigned',
    );
    require(rows.map((c) => c.unit).toSet().length == 1, 'units');
    require(
      !dateOnly(on).isAfter(today()) &&
          rows.every((c) => !c.collectedOn.isAfter(dateOnly(on))),
      'date',
    );
    rows.sort((a, b) => a.collectedOn.compareTo(b.collectedOn));
    final unit = rows.first.unit;
    final quantity = rows.any((c) => c.quantity == null)
        ? null
        : rows.fold(0.0, (sum, c) => sum + c.quantity!);
    final lots = LotsRepository(db);
    final lotId = await lots.createHarvestLot(
      crop: Crop.areca,
      harvestedOn: rows.first.collectedOn,
      title: title.trim(),
      plotIds: rows.expand((c) => c.plotIds).toSet().toList(),
      quantityMode: unit,
      freshKg: unit == 'kg' ? quantity : null,
      freshBags: unit == 'bags' ? quantity : null,
      seasonStartMonth: seasonStartMonth,
      recordCollection: false,
    );
    await (db.update(db.arecaCollections)..where((c) => c.id.isIn(ids))).write(
      ArecaCollectionsCompanion(
        lotId: Value(lotId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await lots.startDrying(lotId, on: on, yard: yard);
    return lotId;
  });
}
