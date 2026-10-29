import 'dart:math' as math;

import '../../../core/dates.dart';
import '../../../core/enums.dart';
import '../../../core/season.dart';

const int defaultDryingDays = 40;

/// "A-2627-01": crop letter, season code, running number in that season (F4.1).
String lotCode(Crop crop, Season season, int sequence) =>
    '${crop.codeLetter}-${season.code}-${sequence.toString().padLeft(2, '0')}';

/// Next running number, given the codes already used for this crop and season.
int nextLotSequence(Iterable<String> existingCodes, Crop crop, Season season) {
  final prefix = '${crop.codeLetter}-${season.code}-';
  var highest = 0;
  for (final code in existingCodes) {
    if (!code.startsWith(prefix)) continue;
    final n = int.tryParse(code.substring(prefix.length));
    if (n != null && n > highest) highest = n;
  }
  return highest + 1;
}

/// Day N on the yard: the day drying started is day 1 (F4.4).
int dryingDay({
  required DateTime startedOn,
  DateTime? endedOn,
  required DateTime today,
}) => math.max(1, daysBetween(startedOn, endedOn ?? today) + 1);

DateTime expectedDryingEnd(DateTime startedOn, int targetDays) =>
    addDays(startedOn, targetDays - 1);

double dryingProgress(int day, int targetDays) =>
    targetDays <= 0 ? 1 : (day / targetDays).clamp(0, 1).toDouble();

/// Whole days the produce has been in storage (F4.7).
int storageDays({
  required DateTime storedOn,
  DateTime? takenOutOn,
  required DateTime today,
}) => math.max(0, daysBetween(storedOn, takenOutOn ?? today));

/// Chali out of dried nuts in husk, as a percentage (F4.5).
double? outTurnPercent({required double? driedKg, required double? chaliKg}) {
  if (driedKg == null || chaliKg == null || driedKg <= 0) return null;
  return chaliKg / driedKg * 100;
}

/// qty × rate, rounded to the paisa.
int lineAmount(double qty, int ratePaise) => (qty * ratePaise).round();

int? costPerKg({required int costPaise, required double kg}) =>
    kg <= 0 ? null : (costPaise / kg).round();

/// What can be sold: graded kg if grading was done, otherwise the chali weight.
double sellableKg({required double gradedKg, required double? chaliKg}) =>
    gradedKg > 0 ? gradedKg : (chaliKg ?? 0);

/// The stage a lot is in now, worked out from what has been recorded (F4.2).
LotStage lotStage({
  required DateTime? dryingStartedOn,
  required DateTime? dryingEndedOn,
  required double? chaliKg,
  required double gradedKg,
  required DateTime? storedOn,
  required double soldKg,
}) {
  final available = sellableKg(gradedKg: gradedKg, chaliKg: chaliKg);
  if (available > 0 && soldKg >= available - 0.0001) return LotStage.sold;
  if (storedOn != null || gradedKg > 0) return LotStage.storage;
  if (chaliKg != null) return LotStage.grading;
  if (dryingEndedOn != null) return LotStage.peeling;
  if (dryingStartedOn != null) return LotStage.drying;
  return LotStage.harvest;
}

/// Kg still unsold for each grade (F4.12 partial sales).
Map<ArecaGrade, double> remainingByGrade({
  required Map<ArecaGrade, double> available,
  required Map<ArecaGrade, double> sold,
}) => {
  for (final grade in ArecaGrade.values)
    if ((available[grade] ?? 0) > 0)
      grade: math.max(0, (available[grade] ?? 0) - (sold[grade] ?? 0)),
};
