import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../../../core/dates.dart';
import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/season.dart';
import '../../../core/validation.dart';
import '../../labour/data/labour_repository.dart';
import '../../labour/data/daily_work.dart';
import '../domain/lot_calc.dart';
import '../domain/lot_view.dart';

/// A labour line typed into a lot form before it is saved.
class LabourInput {
  const LabourInput({
    required this.workerId,
    required this.qty,
    required this.unit,
    required this.rate,
    this.note = '',
  });

  final String? workerId;
  final double qty;
  final RateUnit unit;
  final int rate;
  final String note;

  int get amount => lineAmount(qty, rate);
}

class SaleLineInput {
  const SaleLineInput({
    required this.grade,
    required this.kg,
    required this.rate,
  });

  final ArecaGrade grade;
  final double kg;
  final int rate;

  int get amount => lineAmount(kg, rate);
}

class LotsRepository {
  LotsRepository(this._db);

  final AppDatabase _db;

  late final _lotTables = <TableInfo<Table, Object?>>[
    _db.lots,
    _db.lotGrades,
    _db.lotLabour,
    _db.lotEvents,
    _db.sales,
    _db.saleLines,
    _db.buyers,
    _db.workers,
    _db.plots,
    _db.expenses,
    _db.dailyWorkAllocations,
    _db.attendanceEntries,
  ];

  Stream<List<LotView>> watchLotViews() =>
      _db.watchAll(_lotTables, loadLotViews);

  Future<List<LotView>> loadLotViews() async {
    final lots =
        await (_db.select(_db.lots)
              ..where((l) => l.deleted.equals(false))
              ..orderBy([
                (l) => OrderingTerm.desc(l.harvestedOn),
                (l) => OrderingTerm.desc(l.code),
              ]))
            .get();
    final grades = await (_db.select(
      _db.lotGrades,
    )..where((g) => g.deleted.equals(false))).get();
    final expenses = await (_db.select(
      _db.expenses,
    )..where((e) => e.deleted.equals(false))).get();
    final quantities = await DailyWork(_db).quantities();
    final labourRows =
        await (_db.select(_db.lotLabour)
              ..where((l) => l.deleted.equals(false))
              ..orderBy([(l) => OrderingTerm.asc(l.date)]))
            .get();
    final labour = [
      for (final l in labourRows)
        l.copyWith(qty: quantities[DailyWork.key('lot_labour', l.id)] ?? l.qty),
    ];
    final events =
        await (_db.select(_db.lotEvents)
              ..where((e) => e.deleted.equals(false))
              ..orderBy([(e) => OrderingTerm.desc(e.at)]))
            .get();
    final sales =
        await (_db.select(_db.sales)
              ..where((s) => s.deleted.equals(false))
              ..orderBy([(s) => OrderingTerm.desc(s.date)]))
            .get();
    final lines = await (_db.select(
      _db.saleLines,
    )..where((l) => l.deleted.equals(false))).get();
    final buyers = {
      for (final b in await _db.select(_db.buyers).get()) b.id: b,
    };
    final workers = {
      for (final w in await _db.select(_db.workers).get()) w.id: w,
    };
    final plots = {for (final p in await _db.select(_db.plots).get()) p.id: p};

    final gradesByLot = grades.groupListsBy((g) => g.lotId);
    final labourByLot = labour.groupListsBy((l) => l.lotId);
    final eventsByLot = events.groupListsBy((e) => e.lotId);
    final linesBySale = lines.groupListsBy((l) => l.saleId);
    final salesByLot = sales
        .where((s) => s.lotId != null)
        .groupListsBy((s) => s.lotId!);

    return [
      for (final lot in lots)
        LotView(
          lot: lot,
          grades: gradesByLot[lot.id] ?? const [],
          labour: [
            for (final l in labourByLot[lot.id] ?? const <LotLabourEntry>[])
              LabourLine(l, workers[l.workerId]),
          ],
          events: eventsByLot[lot.id] ?? const [],
          sales: [
            for (final s in salesByLot[lot.id] ?? const <Sale>[])
              SaleView(s, buyers[s.buyerId], linesBySale[s.id] ?? const []),
          ],
          plots: [for (final id in lot.plotIds) ?plots[id]],
          otherCosts: expenses
              .where((e) => e.lotId == lot.id)
              .fold(0, (s, e) => s + e.amount),
        ),
    ];
  }

  Future<String> nextCode(Crop crop, Season season) async {
    final codes = await (_db.selectOnly(
      _db.lots,
    )..addColumns([_db.lots.code])).map((r) => r.read(_db.lots.code)!).get();
    return lotCode(crop, season, nextLotSequence(codes, crop, season));
  }

  /// Creates a lot at the harvest stage, with the climbers' and collectors'
  /// wages booked to their ledgers (F4.3).
  Future<String> createHarvestLot({
    required Crop crop,
    required DateTime harvestedOn,
    required String title,
    required List<String> plotIds,
    int? palmsClimbed,
    double? freshKg,
    double? freshBags,
    String quantityMode = 'kg',
    bool recordCollection = true,
    int seasonStartMonth = 6,
    String notes = '',
    List<LabourInput> labour = const [],
  }) => _db.transaction(() async {
    require(quantityMode == 'kg' || quantityMode == 'bags');
    for (final q in [freshKg, freshBags]) {
      if (q != null) require(q.isFinite && q >= 0);
    }
    require(quantityMode == 'bags' ? freshKg == null : freshBags == null);
    final season = Season.of(harvestedOn, startMonth: seasonStartMonth);
    final lot = await _db
        .into(_db.lots)
        .insertReturning(
          LotsCompanion.insert(
            code: await nextCode(crop, season),
            crop: crop,
            seasonStartYear: season.startYear,
            title: title.trim(),
            plotIds: Value(plotIds),
            harvestedOn: dateOnly(harvestedOn),
            palmsClimbed: Value(palmsClimbed),
            freshKg: Value(freshKg),
            freshBags: Value(freshBags),
            quantityMode: Value(quantityMode),
            notes: Value(notes),
          ),
        );
    if (recordCollection) {
      await _db
          .into(_db.arecaCollections)
          .insert(
            ArecaCollectionsCompanion.insert(
              collectedOn: dateOnly(harvestedOn),
              plotIds: Value(plotIds),
              kind: const Value('harvest'),
              unit: Value(quantityMode),
              quantity: Value(quantityMode == 'bags' ? freshBags : freshKg),
              lotId: Value(lot.id),
            ),
          );
    }
    await addLabour(lot.id, LotStage.harvest, dateOnly(harvestedOn), labour);
    return lot.id;
  });

  Future<void> updateLot(String id, LotsCompanion changes) =>
      (_db.update(_db.lots)..where((l) => l.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> startDrying(
    String id, {
    required DateTime on,
    required String yard,
    int targetDays = defaultDryingDays,
  }) => updateLot(
    id,
    LotsCompanion(
      dryingStartedOn: Value(dateOnly(on)),
      yard: Value(yard.trim()),
      dryingTargetDays: Value(targetDays),
    ),
  );

  Future<void> finishDrying(
    String id, {
    required DateTime on,
    double? driedKg,
    double? driedBags,
  }) => _db.transaction(() async {
    final lot = await (_db.select(
      _db.lots,
    )..where((l) => l.id.equals(id))).getSingle();
    require(
      !dateOnly(on).isBefore(lot.dryingStartedOn ?? lot.harvestedOn) &&
          !dateOnly(on).isAfter(today()),
      'date',
    );
    for (final q in [driedKg, driedBags]) {
      if (q != null) require(q.isFinite && q >= 0);
    }
    require(lot.quantityMode == 'bags' ? driedKg == null : driedBags == null);
    await updateLot(
      id,
      LotsCompanion(
        dryingEndedOn: Value(dateOnly(on)),
        driedKg: Value(driedKg),
        driedBags: Value(driedBags),
      ),
    );
  });

  /// Peeling result and the peelers' wages (F4.5).
  Future<void> recordPeeling(
    String id, {
    required DateTime on,
    required double chaliKg,
    double? driedKg,
    double? driedBags,
    List<LabourInput> peelers = const [],
  }) => _db.transaction(() async {
    final lot = await (_db.select(
      _db.lots,
    )..where((l) => l.id.equals(id))).getSingle();
    nonNegative(chaliKg);
    final view = (await loadLotViews()).firstWhere((v) => v.lot.id == id);
    // Corrections must preserve stock already committed to grades or sales,
    // including sales made directly from ungraded chali.
    require(chaliKg + 0.000001 >= view.soldKg, 'sold');
    require(chaliKg + 0.001 >= view.gradedKg, 'balance');
    require(
      !dateOnly(on).isBefore(lot.dryingEndedOn ?? lot.harvestedOn) &&
          !dateOnly(on).isAfter(today()),
      'date',
    );
    for (final q in [driedKg, driedBags]) {
      if (q != null) require(q.isFinite && q >= 0);
    }
    await updateLot(
      id,
      LotsCompanion(
        peeledOn: Value(dateOnly(on)),
        chaliKg: Value(chaliKg),
        driedBags: driedBags == null ? const Value.absent() : Value(driedBags),
        driedKg: driedKg == null ? const Value.absent() : Value(driedKg),
      ),
    );
    await addLabour(id, LotStage.peeling, dateOnly(on), peelers);
  });

  /// Replaces the lot's grade weights (F4.6). Zero or missing grades are removed.
  Future<void> setGrades(
    String lotId,
    Map<ArecaGrade, double> kg,
  ) => _db.transaction(() async {
    final view = (await loadLotViews()).firstWhere((v) => v.lot.id == lotId);
    for (final grade in ArecaGrade.values) {
      final quantity = kg[grade] ?? 0;
      nonNegative(quantity);
      require(quantity + 0.000001 >= (view.soldByGrade[grade] ?? 0), 'sold');
    }
    final total = kg.values.fold(0.0, (s, q) => s + q);
    require(
      view.lot.chaliKg == null || total <= view.lot.chaliKg! + 0.001,
      'balance',
    );
    final now = DateTime.now();
    for (final grade in ArecaGrade.values) {
      final value = kg[grade] ?? 0;
      final existing =
          await (_db.select(_db.lotGrades)..where(
                (g) => g.lotId.equals(lotId) & g.grade.equalsValue(grade),
              ))
              .getSingleOrNull();
      if (existing == null) {
        if (value > 0) {
          await _db
              .into(_db.lotGrades)
              .insert(
                LotGradesCompanion.insert(
                  lotId: lotId,
                  grade: grade,
                  kg: value,
                ),
              );
        }
      } else {
        await (_db.update(
          _db.lotGrades,
        )..where((g) => g.id.equals(existing.id))).write(
          LotGradesCompanion(
            kg: Value(value),
            deleted: Value(value <= 0),
            updatedAt: Value(now),
          ),
        );
      }
    }
  });

  Future<void> store(
    String id, {
    required DateTime on,
    required String place,
    int? bags,
    int? pricePerKg,
  }) => updateLot(
    id,
    LotsCompanion(
      storedOn: Value(dateOnly(on)),
      storagePlace: Value(place.trim()),
      bags: Value(bags),
      storedPricePerKg: Value(pricePerKg),
    ),
  );

  Future<void> addEvent(
    String lotId,
    LotEventKind kind, {
    DateTime? at,
    String value = '',
    String note = '',
  }) => _db
      .into(_db.lotEvents)
      .insert(
        LotEventsCompanion.insert(
          lotId: lotId,
          at: at ?? DateTime.now(),
          kind: kind,
          value: Value(value),
          note: Value(note),
        ),
      );

  Future<void> deleteEvent(String id) =>
      (_db.update(_db.lotEvents)..where((e) => e.id.equals(id))).write(
        LotEventsCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Books labour on a lot; named workers get a work entry in their ledger.
  Future<void> addLabour(
    String lotId,
    LotStage stage,
    DateTime date,
    List<LabourInput> lines,
  ) => _db.transaction(() async {
    if (lines.isEmpty) return;
    final lot = await (_db.select(
      _db.lots,
    )..where((l) => l.id.equals(lotId))).getSingle();
    require(!lot.deleted, 'linked');
    for (final line in lines) {
      positive(line.qty);
      positive(line.rate);
      final entry = await _db
          .into(_db.lotLabour)
          .insertReturning(
            LotLabourCompanion.insert(
              lotId: lotId,
              stage: stage,
              workerId: Value(line.workerId),
              date: dateOnly(date),
              qty: line.qty,
              unit: line.unit,
              rate: line.rate,
              amount: line.amount,
              note: Value(line.note),
            ),
          );
      if (line.workerId != null && line.unit == RateUnit.day) {
        await DailyWork(_db).book(
          type: refLotLabour,
          id: entry.id,
          owner: DailyWork.key(refLotLabour, entry.id),
          worker: line.workerId!,
          on: date,
          quantity: line.qty,
          rate: line.rate,
          note: '${lot.code} · ${stage.name}',
        );
      } else if (line.workerId != null) {
        await syncWorkTxn(
          _db,
          workerId: line.workerId!,
          date: dateOnly(date),
          amount: line.amount,
          note: '${lot.code} · ${stage.name}',
          refType: refLotLabour,
          refId: entry.id,
        );
      }
    }
  });

  Future<void> deleteLabour(String entryId) => _db.transaction(() async {
    await DailyWork(_db).release(refLotLabour, entryId);
    final now = DateTime.now();
    await (_db.update(_db.lotLabour)..where((l) => l.id.equals(entryId))).write(
      LotLabourCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (_db.update(_db.workerTxns)..where(
          (t) => t.refType.equals(refLotLabour) & t.refId.equals(entryId),
        ))
        .write(
          WorkerTxnsCompanion(
            deleted: const Value(true),
            updatedAt: Value(now),
          ),
        );
  });

  /// Removes the lot with its labour (and the matching ledger entries), grades,
  /// events and sales.
  Future<void> deleteLot(String id) => _db.transaction(() async {
    final now = DateTime.now();
    await (_db.update(
      _db.arecaCollections,
    )..where((c) => c.lotId.equals(id))).write(
      ArecaCollectionsCompanion(
        lotId: const Value(null),
        updatedAt: Value(now),
      ),
    );
    final labourIds =
        await (_db.selectOnly(_db.lotLabour)
              ..addColumns([_db.lotLabour.id])
              ..where(_db.lotLabour.lotId.equals(id)))
            .map((r) => r.read(_db.lotLabour.id)!)
            .get();
    for (final labourId in labourIds) {
      await deleteLabour(labourId);
    }
    final saleIds =
        await (_db.selectOnly(_db.sales)
              ..addColumns([_db.sales.id])
              ..where(_db.sales.lotId.equals(id)))
            .map((r) => r.read(_db.sales.id)!)
            .get();
    for (final saleId in saleIds) {
      await deleteSale(saleId);
    }
    await (_db.update(_db.lotGrades)..where((g) => g.lotId.equals(id))).write(
      LotGradesCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (_db.update(_db.lotEvents)..where((e) => e.lotId.equals(id))).write(
      LotEventsCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await updateLot(id, const LotsCompanion(deleted: Value(true)));
  });

  Stream<List<Buyer>> watchBuyers() =>
      (_db.select(_db.buyers)
            ..where((b) => b.deleted.equals(false))
            ..orderBy([(b) => OrderingTerm.asc(b.name)]))
          .watch();

  Future<String> saveBuyer({
    required String name,
    required BuyerKind kind,
    String phone = '',
    String place = '',
  }) async =>
      (await _db
              .into(_db.buyers)
              .insertReturning(
                BuyersCompanion.insert(
                  name: name.trim(),
                  kind: Value(kind),
                  phone: Value(phone),
                  place: Value(place),
                ),
              ))
          .id;

  /// A sale against a lot (F4.8, F6.1); part of a lot can be sold (F4.12).
  Future<String> recordSale({
    required String lotId,
    required String buyerId,
    required DateTime date,
    required List<SaleLineInput> lines,
    int deductions = 0,
    String deductionNote = '',
    int received = 0,
    String notes = '',
  }) => _db.transaction(() async {
    require(lines.isNotEmpty);
    final view = (await loadLotViews()).firstWhere((v) => v.lot.id == lotId);
    require(!dateOnly(date).isBefore(view.lot.harvestedOn), 'dates');
    final quantities = <ArecaGrade, double>{};
    for (final line in lines) {
      positive(line.kg);
      positive(line.rate);
      quantities.update(
        line.grade,
        (v) => v + line.kg,
        ifAbsent: () => line.kg,
      );
    }
    for (final e in quantities.entries) {
      require(e.value <= (view.remaining[e.key] ?? 0) + 0.000001, 'stock');
    }
    final gross = lines.fold(0, (s, l) => s + l.amount);
    nonNegative(deductions);
    nonNegative(received);
    require(deductions <= gross && received <= gross - deductions, 'balance');
    final sale = await _db
        .into(_db.sales)
        .insertReturning(
          SalesCompanion.insert(
            date: dateOnly(date),
            buyerId: buyerId,
            lotId: Value(lotId),
            deductions: Value(deductions),
            deductionNote: Value(deductionNote),
            received: Value(received),
            notes: Value(notes),
          ),
        );
    for (final line in lines.where((l) => l.kg > 0)) {
      await _db
          .into(_db.saleLines)
          .insert(
            SaleLinesCompanion.insert(
              saleId: sale.id,
              grade: line.grade,
              kg: line.kg,
              rate: line.rate,
              amount: line.amount,
            ),
          );
    }
    if (received > 0) await _db.into(_db.saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: false, date: dateOnly(date), amount: received));
    return sale.id;
  });

  Future<void> setReceived(
    String saleId,
    int received, {DateTime? date, String notes = ''}
  ) => _db.transaction(() async {
    nonNegative(received);
    final sale = await (_db.select(
      _db.sales,
    )..where((s) => s.id.equals(saleId) & s.deleted.equals(false))).getSingle();
    final lines = await (_db.select(
      _db.saleLines,
    )..where((l) => l.saleId.equals(saleId) & l.deleted.equals(false))).get();
    final net = lines.fold(0, (s, l) => s + l.amount) - sale.deductions;
    require(received <= net, 'balance');
    final paidOn = dateOnly(date ?? DateTime.now());
    require(!paidOn.isBefore(sale.date) && !paidOn.isAfter(dateOnly(DateTime.now())), 'dates');
    if (received != sale.received) await _db.into(_db.saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: false, date: paidOn, amount: received - sale.received, notes: Value(notes)));

    await (_db.update(_db.sales)..where((s) => s.id.equals(saleId))).write(
      SalesCompanion(
        received: Value(received),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<void> deleteSale(String saleId) => _db.transaction(() async {
    final now = DateTime.now();
    await (_db.update(
      _db.saleLines,
    )..where((l) => l.saleId.equals(saleId))).write(
      SaleLinesCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
    await (_db.update(_db.sales)..where((s) => s.id.equals(saleId))).write(
      SalesCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
  });
}
