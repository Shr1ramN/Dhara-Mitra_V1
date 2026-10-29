import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../../core/season.dart';
import '../../core/validation.dart';
import '../labour/data/labour_repository.dart';
import '../labour/data/daily_work.dart';
import '../lots/domain/lot_calc.dart';

class ProduceView {
  const ProduceView(this.lot, this.sales, this.labour, this.otherCosts);
  final ProduceLot lot;
  final List<ProduceSale> sales;
  final List<ProduceLabourData> labour;
  final int otherCosts;
  double get sold => sales.fold(0.0, (s, x) => s + x.quantity);
  double get remaining => (lot.quantity ?? 0) - sold;
  int get net => sales.fold(0, (s, x) => s + x.gross - x.deductions);
  int get received => sales.fold(0, (s, x) => s + x.received);
  int get pending => net - received;
  int get cost => labour.fold(otherCosts, (s, x) => s + x.amount);
  int get profit => net - cost;
  String get stage =>
      sales.isNotEmpty && lot.quantity != null && remaining <= 0.000001
      ? 'sold'
      : lot.stage;
}

class ProduceRepository {
  ProduceRepository(this.db);
  final AppDatabase db;
  Stream<List<ProduceView>> watch() => db.watchAll([
    db.produceLots,
    db.produceSales,
    db.produceLabour,
    db.expenses,
    db.dailyWorkAllocations,
    db.attendanceEntries,
  ], load);
  Future<List<ProduceView>> load() async {
    final lots =
        await (db.select(db.produceLots)
              ..where((l) => l.deleted.equals(false))
              ..orderBy([(l) => OrderingTerm.desc(l.harvestedOn)]))
            .get();
    final sales = await (db.select(
      db.produceSales,
    )..where((s) => s.deleted.equals(false))).get();
    final quantities = await DailyWork(db).quantities();
    final labourRows = await (db.select(
      db.produceLabour,
    )..where((s) => s.deleted.equals(false))).get();
    final labour = [
      for (final l in labourRows)
        l.copyWith(
          quantity:
              quantities[DailyWork.key('produceLabour', l.id)] ?? l.quantity,
        ),
    ];
    final costs = await (db.select(
      db.expenses,
    )..where((s) => s.deleted.equals(false))).get();
    return [
      for (final l in lots)
        ProduceView(
          l,
          sales.where((s) => s.lotId == l.id).toList(),
          labour.where((s) => s.lotId == l.id).toList(),
          costs
              .where((e) => e.produceLotId == l.id)
              .fold(0, (s, e) => s + e.amount),
        ),
    ];
  }

  void _quantity(double q, String unit) {
    positive(q);
    require(['kg', 'nut', 'bunch'].contains(unit));
    if (unit != 'kg') require(q == q.roundToDouble());
  }

  Future<String> harvest({
    required String crop,
    required DateTime on,
    required double quantity,
    required String unit,
    required String title,
    List<String> plotIds = const [],
    int seasonStartMonth = 6,
    String notes = '',
  }) => db.transaction(() async {
    require(
      ['coconut', 'pepper', 'banana'].contains(crop) && title.trim().isNotEmpty,
    );
    _quantity(quantity, unit);
    require(crop != 'coconut' || unit == 'nut');
    require(crop != 'pepper' || unit == 'kg');
    final season = Season.of(on, startMonth: seasonStartMonth);
    final prefix = '${Crop.values.byName(crop).codeLetter}-${season.code}-';
    final all = await db.select(db.produceLots).get();
    var sequence = 1;
    for (final l in all.where((l) => l.code.startsWith(prefix))) {
      final n = int.tryParse(l.code.substring(prefix.length));
      if (n != null && n >= sequence) sequence = n + 1;
    }
    return (await db
            .into(db.produceLots)
            .insertReturning(
              ProduceLotsCompanion.insert(
                code: '$prefix${sequence.toString().padLeft(2, '0')}',
                crop: crop,
                title: title.trim(),
                seasonStartYear: season.startYear,
                plotIds: Value(plotIds),
                harvestedOn: dateOnly(on),
                freshQuantity: quantity,
                freshUnit: unit,
                product: crop == 'coconut' ? 'nut' : crop,
                unit: unit,
                quantity: Value(crop == 'pepper' ? null : quantity),
                notes: Value(notes.trim()),
              ),
            ))
        .id;
  });
  Future<ProduceView> _view(String id) async =>
      (await load()).firstWhere((v) => v.lot.id == id);
  Future<void> processing(String id, String stage, DateTime on) =>
      db.transaction(() async {
        final v = await _view(id);
        require(!dateOnly(on).isBefore(v.lot.harvestedOn), 'dates');
        require(v.sales.isEmpty, 'sold');
        require(
          (v.lot.crop == 'pepper' && stage == 'threshing') ||
              (v.lot.crop == 'coconut' && stage == 'dehusking'),
        );
        require(v.lot.stage == 'harvest');
        await (db.update(db.produceLots)..where((l) => l.id.equals(id))).write(
          ProduceLotsCompanion(
            stage: Value(stage),
            quantity: const Value(null),
            product: Value(v.lot.crop == 'coconut' ? 'copra' : 'pepper'),
            unit: const Value('kg'),
            updatedAt: Value(DateTime.now()),
          ),
        );
      });
  Future<void> startDrying(String id, DateTime on) => db.transaction(() async {
    final v = await _view(id);
    require(['threshing', 'dehusking'].contains(v.lot.stage));
    require(!dateOnly(on).isBefore(v.lot.harvestedOn), 'dates');
    await (db.update(db.produceLots)..where((l) => l.id.equals(id))).write(
      ProduceLotsCompanion(
        dryingStartedOn: Value(dateOnly(on)),
        stage: const Value('drying'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> finish(
    String id, {
    required DateTime on,
    required double quantity,
    required String unit,
  }) => db.transaction(() async {
    _quantity(quantity, unit);
    final v = await _view(id);
    require(v.sales.isEmpty, 'sold');
    require(
      !dateOnly(on).isBefore(v.lot.dryingStartedOn ?? v.lot.harvestedOn),
      'dates',
    );
    if (v.lot.crop != 'banana') {
      require(v.lot.stage == 'drying' && unit == 'kg');
    }
    if (v.lot.crop == 'banana') require(['kg', 'bunch'].contains(unit));
    if (unit == v.lot.freshUnit) {
      require(quantity <= v.lot.freshQuantity + 0.000001, 'balance');
    }
    await (db.update(db.produceLots)..where((l) => l.id.equals(id))).write(
      ProduceLotsCompanion(
        quantity: Value(quantity),
        unit: Value(unit),
        dryingEndedOn: Value(v.lot.crop == 'banana' ? null : dateOnly(on)),
        stage: const Value('processed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> store(
    String id, {
    required DateTime on,
    required String place,
    int bags = 0,
  }) => db.transaction(() async {
    final v = await _view(id);
    require(v.lot.quantity != null && v.remaining > 0);
    require(place.trim().isNotEmpty);
    nonNegative(bags);
    require(
      !dateOnly(on).isBefore(v.lot.dryingEndedOn ?? v.lot.harvestedOn),
      'dates',
    );
    await (db.update(db.produceLots)..where((l) => l.id.equals(id))).write(
      ProduceLotsCompanion(
        storedOn: Value(dateOnly(on)),
        storagePlace: Value(place.trim()),
        bags: Value(bags),
        stage: const Value('storage'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> labour(
    String id, {
    required String workerId,
    required DateTime on,
    required String work,
    required double quantity,
    required String unit,
    required int rate,
  }) => db.transaction(() async {
    positive(quantity);
    positive(rate);
    require(RateUnit.values.any((u) => u.name == unit));
    final v = await _view(id);
    require(!dateOnly(on).isBefore(v.lot.harvestedOn), 'dates');
    final amount = lineAmount(quantity, rate);
    final row = await db
        .into(db.produceLabour)
        .insertReturning(
          ProduceLabourCompanion.insert(
            lotId: id,
            workerId: workerId,
            date: dateOnly(on),
            work: work,
            quantity: quantity,
            unit: unit,
            rate: rate,
            amount: amount,
          ),
        );
    if (unit == 'day') {
      await DailyWork(db).book(
        type: 'produceLabour',
        id: row.id,
        owner: DailyWork.key('produceLabour', row.id),
        worker: workerId,
        on: on,
        quantity: quantity,
        rate: rate,
        note: '${v.lot.code} · $work',
      );
    } else {
      await syncWorkTxn(
        db,
        workerId: workerId,
        date: dateOnly(on),
        amount: amount,
        note: '${v.lot.code} · $work',
        refType: 'produceLabour',
        refId: row.id,
      );
    }
  });
  Future<void> deleteLabour(String id) => db.transaction(() async {
    await DailyWork(db).release('produceLabour', id);
    await (db.update(db.produceLabour)..where((l) => l.id.equals(id))).write(
      ProduceLabourCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (db.update(
          db.workerTxns,
        )..where((t) => t.refType.equals('produceLabour') & t.refId.equals(id)))
        .write(
          WorkerTxnsCompanion(
            deleted: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
  });

  Future<void> sale(
    String id, {
    required String buyerId,
    required DateTime on,
    required double quantity,
    required int rate,
    int deductions = 0,
    int received = 0,
    String notes = '',
  }) => db.transaction(() async {
    final v = await _view(id);
    _quantity(quantity, v.lot.unit);
    positive(rate);
    nonNegative(deductions);
    nonNegative(received);
    require(
      v.lot.quantity != null && quantity <= v.remaining + 0.000001,
      'stock',
    );
    require(
      !dateOnly(on).isBefore(v.lot.dryingEndedOn ?? v.lot.harvestedOn),
      'dates',
    );
    final gross = lineAmount(quantity, rate);
    require(deductions <= gross && received <= gross - deductions, 'balance');
    final sale = await db
        .into(db.produceSales)
        .insertReturning(
          ProduceSalesCompanion.insert(
            lotId: id,
            buyerId: buyerId,
            date: dateOnly(on),
            quantity: quantity,
            rate: rate,
            gross: gross,
            deductions: Value(deductions),
            received: Value(received),
            notes: Value(notes.trim()),
          ),
        );
    if (received > 0) await db.into(db.saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: true, date: dateOnly(on), amount: received));
  });
  Future<void> receive(String saleId, int amount, {DateTime? date, String notes = ''}) => db.transaction(() async {
    positive(amount);
    final sale = await (db.select(
      db.produceSales,
    )..where((s) => s.id.equals(saleId) & s.deleted.equals(false))).getSingle();
    require(amount <= sale.gross - sale.deductions - sale.received, 'balance');
    final paidOn = dateOnly(date ?? DateTime.now());
    require(!paidOn.isBefore(sale.date) && !paidOn.isAfter(dateOnly(DateTime.now())), 'dates');
    await db.into(db.saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: true, date: paidOn, amount: amount, notes: Value(notes)));

    await (db.update(db.produceSales)..where((s) => s.id.equals(saleId))).write(
      ProduceSalesCompanion(
        received: Value(sale.received + amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> delete(String id) => db.transaction(() async {
    final v = await _view(id);
    final now = DateTime.now();
    for (final l in v.labour) {
      await DailyWork(db).release('produceLabour', l.id);
      await (db.update(db.workerTxns)..where(
            (t) => t.refType.equals('produceLabour') & t.refId.equals(l.id),
          ))
          .write(
            WorkerTxnsCompanion(
              deleted: const Value(true),
              updatedAt: Value(now),
            ),
          );
    }
    await (db.update(db.produceLabour)..where((l) => l.lotId.equals(id))).write(
      ProduceLabourCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (db.update(db.produceSales)..where((l) => l.lotId.equals(id))).write(
      ProduceSalesCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (db.update(db.produceLots)..where((l) => l.id.equals(id))).write(
      ProduceLotsCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
  });
}
