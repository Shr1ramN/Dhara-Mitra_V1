import 'package:drift/drift.dart';

import '../../../core/db/database.dart';

class FarmRepository {
  FarmRepository(this._db);

  final AppDatabase _db;

  Stream<Farm?> watchFarm() =>
      (_db.select(_db.farms)
            ..where((f) => f.deleted.equals(false))
            ..limit(1))
          .watchSingleOrNull();

  Future<Farm?> getFarm() =>
      (_db.select(_db.farms)
            ..where((f) => f.deleted.equals(false))
            ..limit(1))
          .getSingleOrNull();

  Future<String> saveFarm({
    String? id,
    required String name,
    required String village,
    int seasonStartMonth = 6,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
  }) async {
    final row = FarmsCompanion(
      id: id == null ? const Value.absent() : Value(id),
      name: Value(name.trim()),
      village: Value(village.trim()),
      seasonStartMonth: Value(seasonStartMonth),
      lat: latitude,
      lng: longitude,
      updatedAt: Value(DateTime.now()),
    );
    if (id == null) {
      return (await _db.into(_db.farms).insertReturning(row)).id;
    }
    await (_db.update(_db.farms)..where((f) => f.id.equals(id))).write(row);
    return id;
  }

  Stream<List<Plot>> watchPlots() =>
      (_db.select(_db.plots)
            ..where((p) => p.deleted.equals(false))
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<List<Plot>> getPlots() =>
      (_db.select(_db.plots)..where((p) => p.deleted.equals(false))).get();

  /// Inserts when [plot] has no id, otherwise updates. Returns the id.
  Future<String> savePlot(PlotsCompanion plot) async {
    final row = plot.copyWith(updatedAt: Value(DateTime.now()));
    if (!row.id.present) {
      return (await _db.into(_db.plots).insertReturning(row)).id;
    }
    await (_db.update(
      _db.plots,
    )..where((p) => p.id.equals(row.id.value))).write(row);
    return row.id.value;
  }

  Future<void> deletePlot(String id) =>
      (_db.update(_db.plots)..where((p) => p.id.equals(id))).write(
        PlotsCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
