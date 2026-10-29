import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/dates.dart';
import '../../core/validation.dart';

class PricesRepository {
  PricesRepository(this.db);
  final AppDatabase db;
  Stream<List<PriceSnapshot>> watch() =>
      (db.select(db.priceSnapshots)
            ..where((p) => p.deleted.equals(false))
            ..orderBy([
              (p) => OrderingTerm.desc(p.date),
              (p) => OrderingTerm.desc(p.updatedAt),
            ]))
          .watch();
  Future<void> save({
    required DateTime date,
    required String source,
    required String market,
    required String crop,
    required String grade,
    required String unit,
    required int modal,
    int? minimum,
    int? maximum,
  }) async {
    require(
      source.trim().isNotEmpty && market.trim().isNotEmpty && grade.isNotEmpty,
    );
    positive(modal);
    require(['kg', 'quintal', 'nut', 'bunch'].contains(unit));
    var low = minimum ?? modal;
    var high = maximum ?? modal;
    var typical = modal;
    require(low > 0 && low <= typical && typical <= high);
    final canonical = unit == 'quintal' ? 'kg' : unit;
    if (unit == 'quintal') {
      low = (low / 100).round();
      high = (high / 100).round();
      typical = (typical / 100).round();
      positive(low);
    }
    final day = dateOnly(date);
    final old =
        await (db.select(db.priceSnapshots)..where(
              (p) =>
                  p.date.equals(day) &
                  p.source.equals(source.trim()) &
                  p.market.equals(market.trim()) &
                  p.crop.equals(crop) &
                  p.grade.equals(grade) &
                  p.unit.equals(canonical),
            ))
            .getSingleOrNull();
    await db
        .into(db.priceSnapshots)
        .insertOnConflictUpdate(
          PriceSnapshotsCompanion.insert(
            id: old == null ? const Value.absent() : Value(old.id),
            date: day,
            source: source.trim(),
            market: market.trim(),
            crop: crop,
            grade: grade,
            unit: Value(canonical),
            minimum: low,
            maximum: high,
            modal: typical,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> alert({
    required String crop,
    required String grade,
    required String unit,
    required int target,
    String market = '',
    String direction = 'above',
  }) async {
    positive(target);
    require(['above', 'below'].contains(direction));
    require(['kg', 'nut', 'bunch'].contains(unit));
    require(grade.isNotEmpty);
    await db
        .into(db.priceAlerts)
        .insert(
          PriceAlertsCompanion.insert(
            crop: crop,
            grade: grade,
            unit: Value(unit),
            target: target,
            market: Value(market.trim()),
            direction: Value(direction),
          ),
        );
  }
}
