import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/enums.dart';
import '../../core/season.dart';

class ReportLine {
  const ReportLine({
    required this.date,
    required this.label,
    required this.category,
    required this.amount,
    required this.income,
    this.crops = const [],
    this.plots = const [],
    this.workerId,
  });
  final DateTime date;
  final String label, category;
  final int amount;
  final bool income;
  final List<String> crops, plots;
  final String? workerId;

  /// Shared entries are split equally, distributing leftover paise in sorted
  /// ID order so crop/plot subtotals add up exactly to the whole-farm total.
  int allocated({String? crop, String? plot}) {
    final cs = crops.isEmpty ? [''] : (crops.toSet().toList()..sort());
    final ps = plots.isEmpty ? [''] : (plots.toSet().toList()..sort());
    final count = cs.length * ps.length;
    var index = 0, total = 0;
    for (final c in cs) {
      for (final p in ps) {
        final value = amount ~/ count + (index < amount % count ? 1 : 0);
        if ((crop == null || crop == c) && (plot == null || plot == p)) {
          total += value;
        }
        index++;
      }
    }
    return total;
  }
}

class FarmReport {
  const FarmReport(
    this.lines,
    this.yieldByUnit,
    this.acres,
    this.crop,
    this.plot,
  );
  final List<ReportLine> lines;
  final Map<String, double> yieldByUnit;
  final double acres;
  final String? crop, plot;
  int get income => lines
      .where((r) => r.income)
      .fold(0, (s, r) => s + r.allocated(crop: crop, plot: plot));
  int get costs => lines
      .where((r) => !r.income)
      .fold(0, (s, r) => s + r.allocated(crop: crop, plot: plot));
  int get profit => income - costs;
  Map<String, int> get categories {
    final result = <String, int>{};
    for (final line in lines) {
      result.update(
        line.category,
        (v) => v + line.allocated(crop: crop, plot: plot),
        ifAbsent: () => line.allocated(crop: crop, plot: plot),
      );
    }
    return result;
  }

  Map<String, int> get labourByWorker {
    final result = <String, int>{};
    for (final line in lines.where((l) => l.workerId != null)) {
      result.update(
        line.workerId!,
        (v) => v + line.allocated(crop: crop, plot: plot),
        ifAbsent: () => line.allocated(crop: crop, plot: plot),
      );
    }
    return result;
  }
}

class ReportRepository {
  ReportRepository(this.db);
  final AppDatabase db;
  Stream<FarmReport> watch({
    required Season season,
    required DateTime today,
    int startMonth = 6,
    String? crop,
    String? plot,
  }) => db.watchAll(
    db.allTables,
    () => build(
      season: season,
      today: today,
      startMonth: startMonth,
      crop: crop,
      plot: plot,
    ),
  );

  Future<FarmReport> build({
    required Season season,
    required DateTime today,
    int startMonth = 6,
    String? crop,
    String? plot,
  }) => db.transaction(() async {
    final start = season.firstDay(startMonth: startMonth);
    final end = season.lastDay(startMonth: startMonth);
    final until = today.isBefore(end)
        ? DateTime(today.year, today.month, today.day)
        : end;
    bool within(DateTime date) => !date.isBefore(start) && !date.isAfter(until);
    final lines = <ReportLine>[];
    void add(
      DateTime date,
      String label,
      String category,
      int amount,
      bool income, {
      List<String> crops = const [],
      List<String> plots = const [],
      String? worker,
    }) {
      if (within(date)) {
        lines.add(
          ReportLine(
            date: date,
            label: label,
            category: category,
            amount: amount,
            income: income,
            crops: crops,
            plots: plots,
            workerId: worker,
          ),
        );
      }
    }

    final lots = {
      for (final l in await (db.select(
        db.lots,
      )..where((l) => l.deleted.equals(false))).get())
        l.id: l,
    };
    final produce = {
      for (final l in await (db.select(
        db.produceLots,
      )..where((l) => l.deleted.equals(false))).get())
        l.id: l,
    };
    final activities = {
      for (final a in await (db.select(
        db.activities,
      )..where((a) => a.deleted.equals(false))).get())
        a.id: a,
    };
    final activityLabour = {
      for (final a in await (db.select(
        db.activityLabour,
      )..where((a) => a.deleted.equals(false))).get())
        a.id: a,
    };
    final allocations = await (db.select(
      db.dailyWorkAllocations,
    )..where((a) => a.deleted.equals(false))).get();
    final lotLabour = {
      for (final a in await (db.select(
        db.lotLabour,
      )..where((a) => a.deleted.equals(false))).get())
        a.id: a,
    };
    final produceLabour = {
      for (final a in await (db.select(
        db.produceLabour,
      )..where((a) => a.deleted.equals(false))).get())
        a.id: a,
    };
    final saleLines = await (db.select(
      db.saleLines,
    )..where((s) => s.deleted.equals(false))).get();
    for (final sale in await (db.select(
      db.sales,
    )..where((s) => s.deleted.equals(false))).get()) {
      final lot = lots[sale.lotId];
      final gross = saleLines
          .where((l) => l.saleId == sale.id)
          .fold(0, (s, l) => s + l.amount);
      add(
        sale.date,
        lot?.code ?? sale.id,
        'sales',
        gross - sale.deductions,
        true,
        crops: lot == null ? [] : [lot.crop.name],
        plots: lot?.plotIds ?? [],
      );
    }
    for (final sale in await (db.select(
      db.produceSales,
    )..where((s) => s.deleted.equals(false))).get()) {
      final lot = produce[sale.lotId];
      add(
        sale.date,
        lot?.code ?? sale.id,
        'sales',
        sale.gross - sale.deductions,
        true,
        crops: lot == null ? [] : [lot.crop],
        plots: lot?.plotIds ?? [],
      );
    }
    for (final txn
        in await (db.select(db.workerTxns)..where(
              (t) => t.deleted.equals(false) & t.kind.equalsValue(TxnKind.work),
            ))
            .get()) {
      if (txn.refType == 'attendance') {
        var allocated = 0;
        for (final link in allocations.where(
          (a) => a.attendanceId == txn.refId,
        )) {
          final a = link.sourceType == 'activityLabour'
              ? activities[activityLabour[link.sourceId]?.activityId]
              : null;
          final l = link.sourceType == 'lot_labour'
              ? lots[lotLabour[link.sourceId]?.lotId]
              : null;
          final p = link.sourceType == 'produceLabour'
              ? produce[produceLabour[link.sourceId]?.lotId]
              : null;
          allocated += link.amount;
          add(
            txn.date,
            a?.title ?? l?.code ?? p?.code ?? txn.note,
            'labour',
            link.amount,
            false,
            crops:
                a?.crops ??
                (l != null
                    ? [l.crop.name]
                    : p != null
                    ? [p.crop]
                    : []),
            plots: a?.plotIds ?? l?.plotIds ?? p?.plotIds ?? [],
            worker: txn.workerId,
          );
        }
        if (txn.amount > allocated) {
          add(
            txn.date,
            txn.note,
            'labour',
            txn.amount - allocated,
            false,
            worker: txn.workerId,
          );
        }
        continue;
      }
      final activity = txn.refType == 'activityLabour'
          ? activities[activityLabour[txn.refId]?.activityId]
          : null;
      final lot = lots[lotLabour[txn.refId]?.lotId];
      final other = produce[produceLabour[txn.refId]?.lotId];
      add(
        txn.date,
        txn.note,
        'labour',
        txn.amount,
        false,
        crops:
            activity?.crops ??
            (lot != null
                ? [lot.crop.name]
                : other != null
                ? [other.crop]
                : []),
        plots: activity?.plotIds ?? lot?.plotIds ?? other?.plotIds ?? [],
        worker: txn.workerId,
      );
    }
    // Anonymous contract labour has no worker ledger entry, but is still a cost.
    for (final l in lotLabour.values.where((l) => l.workerId == null)) {
      final lot = lots[l.lotId];
      add(
        l.date,
        lot?.code ?? l.note,
        'labour',
        l.amount,
        false,
        crops: lot == null ? [] : [lot.crop.name],
        plots: lot?.plotIds ?? [],
      );
    }
    for (final input in await (db.select(
      db.activityInputs,
    )..where((i) => i.deleted.equals(false))).get()) {
      final a = activities[input.activityId];
      if (a != null) {
        add(
          a.date,
          a.title,
          'inputs',
          input.cost,
          false,
          crops: a.crops,
          plots: a.plotIds,
        );
      }
    }
    for (final expense in await (db.select(
      db.expenses,
    )..where((e) => e.deleted.equals(false))).get()) {
      final lot = lots[expense.lotId];
      final other = produce[expense.produceLotId];
      add(
        expense.date,
        expense.notes.isEmpty ? expense.category : expense.notes,
        'expense',
        expense.amount,
        false,
        crops: expense.crop != null
            ? [expense.crop!]
            : lot != null
            ? [lot.crop.name]
            : other != null
            ? [other.crop]
            : [],
        plots: expense.plotId != null
            ? [expense.plotId!]
            : lot?.plotIds ?? other?.plotIds ?? [],
      );
    }
    for (final txn
        in await (db.select(db.loanTransactions)..where(
              (t) => t.deleted.equals(false) & t.kind.equals('interest'),
            ))
            .get()) {
      add(txn.date, txn.note, 'interest', txn.amount, false);
    }
    final policies = {
      for (final p in await (db.select(
        db.insurancePolicies,
      )..where((p) => p.deleted.equals(false))).get())
        p.id: p,
    };
    for (final p in policies.values) {
      add(p.paidOn, p.scheme, 'premium', p.premium, false, crops: [p.crop]);
    }
    for (final claim in await (db.select(
      db.insuranceClaims,
    )..where((c) => c.deleted.equals(false))).get()) {
      if (claim.receivedOn != null) {
        add(
          claim.receivedOn!,
          policies[claim.policyId]?.scheme ?? claim.id,
          'claim',
          claim.received,
          true,
          crops: policies[claim.policyId] == null
              ? []
              : [policies[claim.policyId]!.crop],
        );
      }
    }
    for (final s in await (db.select(
      db.schemeApplications,
    )..where((s) => s.deleted.equals(false))).get()) {
      if (s.receivedOn != null) {
        add(s.receivedOn!, s.scheme, 'subsidy', s.subsidy, true);
      }
    }
    for (final t
        in await (db.select(db.membershipTransactions)..where(
              (t) => t.deleted.equals(false) & t.kind.equals('dividend'),
            ))
            .get()) {
      add(t.date, t.membershipId, 'dividend', t.amount, true);
    }
    final yields = <String, double>{};
    void addYield(
      DateTime date,
      String cropName,
      String unit,
      double qty,
      List<String> plots,
    ) {
      if (!within(date) ||
          (crop != null && crop != cropName) ||
          (plot != null && !plots.contains(plot))) {
        return;
      }
      final allocated = plot == null || plots.isEmpty
          ? qty
          : qty / plots.toSet().length;
      yields.update(
        '$cropName|$unit',
        (v) => v + allocated,
        ifAbsent: () => allocated,
      );
    }

    for (final lot in lots.values) {
      if (lot.chaliKg != null) {
        addYield(
          lot.harvestedOn,
          lot.crop.name,
          'kg',
          lot.chaliKg!,
          lot.plotIds,
        );
      }
    }
    for (final lot in produce.values) {
      if (lot.quantity != null) {
        addYield(
          lot.harvestedOn,
          lot.crop,
          lot.unit,
          lot.quantity!,
          lot.plotIds,
        );
      }
    }
    final plots = await (db.select(
      db.plots,
    )..where((p) => p.deleted.equals(false))).get();
    final acres = plots
        .where((p) => plot == null || p.id == plot)
        .fold(0.0, (s, p) => s + p.acres);
    lines.sort((a, b) => a.date.compareTo(b.date));
    return FarmReport(lines, yields, acres, crop, plot);
  });
}
