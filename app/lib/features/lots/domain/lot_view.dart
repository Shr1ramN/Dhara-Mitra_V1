import 'dart:math' as math;

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/season.dart';
import 'lot_calc.dart';

class LabourLine {
  const LabourLine(this.entry, this.worker);

  final LotLabourEntry entry;
  final Worker? worker;
}

class SaleView {
  const SaleView(this.sale, this.buyer, this.lines);

  final Sale sale;
  final Buyer? buyer;
  final List<SaleLine> lines;

  int get gross => lines.fold(0, (sum, l) => sum + l.amount);
  int get net => gross - sale.deductions;
  int get pending => math.max(0, net - sale.received);
  double get kg => lines.fold(0.0, (sum, l) => sum + l.kg);
}

/// Everything known about one harvest lot, with the numbers worked out.
class LotView {
  LotView({
    required this.lot,
    required this.grades,
    required this.labour,
    required this.events,
    required this.sales,
    required this.plots,
    this.otherCosts = 0,
  });

  final Lot lot;
  final List<LotGrade> grades;
  final List<LabourLine> labour;

  /// Newest first.
  final List<LotEvent> events;
  final List<SaleView> sales;
  final List<Plot> plots;
  final int otherCosts;

  Season get season => Season(lot.seasonStartYear);

  Map<ArecaGrade, double> get gradeKg => {
    for (final g in grades) g.grade: g.kg,
  };

  double get gradedKg => grades.fold(0.0, (sum, g) => sum + g.kg);

  /// Graded kg per grade, or all of the chali if it was not graded.
  Map<ArecaGrade, double> get availableByGrade => grades.isNotEmpty
      ? gradeKg
      : {if ((lot.chaliKg ?? 0) > 0) ArecaGrade.chali: lot.chaliKg!};

  double get availableKg =>
      sellableKg(gradedKg: gradedKg, chaliKg: lot.chaliKg);

  Map<ArecaGrade, double> get soldByGrade {
    final sold = <ArecaGrade, double>{};
    for (final s in sales) {
      for (final l in s.lines) {
        sold[l.grade] = (sold[l.grade] ?? 0) + l.kg;
      }
    }
    return sold;
  }

  double get soldKg => sales.fold(0.0, (sum, s) => sum + s.kg);

  Map<ArecaGrade, double> get remaining =>
      remainingByGrade(available: availableByGrade, sold: soldByGrade);

  double get remainingKg => remaining.values.fold(0.0, (a, b) => a + b);

  LotStage get stage => lotStage(
    dryingStartedOn: lot.dryingStartedOn,
    dryingEndedOn: lot.dryingEndedOn,
    chaliKg: lot.chaliKg,
    gradedKg: gradedKg,
    storedOn: lot.storedOn,
    soldKg: soldKg,
  );

  int labourCost([LotStage? stage]) => labour
      .where((l) => stage == null || l.entry.stage == stage)
      .fold(0, (sum, l) => sum + l.entry.amount);

  int get totalCost => labourCost() + otherCosts;

  int get saleNet => sales.fold(0, (sum, s) => sum + s.net);

  int get received => sales.fold(0, (sum, s) => sum + s.sale.received);

  int get pending => sales.fold(0, (sum, s) => sum + s.pending);

  int get profit => saleNet - totalCost;

  int? get costPerKgChali =>
      costPerKg(costPaise: totalCost, kg: lot.chaliKg ?? 0);

  double? get outTurn =>
      outTurnPercent(driedKg: lot.driedKg, chaliKg: lot.chaliKg);

  int count(LotEventKind kind) => events.where((e) => e.kind == kind).length;

  int? dryingDayOn(DateTime today) => lot.dryingStartedOn == null
      ? null
      : dryingDay(
          startedOn: lot.dryingStartedOn!,
          endedOn: lot.dryingEndedOn,
          today: today,
        );

  int? storageDaysOn(DateTime today) => lot.storedOn == null
      ? null
      : storageDays(
          storedOn: lot.storedOn!,
          takenOutOn: lot.takenOutOn,
          today: today,
        );

  /// Value of what is left at [pricePerKg] (paise), e.g. the price when stored.
  int valueAt(int pricePerKg) => lineAmount(remainingKg, pricePerKg);
}
