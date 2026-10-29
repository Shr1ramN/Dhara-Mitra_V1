import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:dhara_mitra/features/lots/domain/lot_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lot codes', () {
    test('format', () {
      expect(lotCode(Crop.areca, const Season(2026), 1), 'A-2627-01');
      expect(lotCode(Crop.pepper, const Season(2025), 12), 'P-2526-12');
    });

    test('next sequence ignores other crops and seasons', () {
      final codes = ['A-2627-01', 'A-2627-03', 'C-2627-08', 'A-2526-09'];
      expect(nextLotSequence(codes, Crop.areca, const Season(2026)), 4);
      expect(nextLotSequence(codes, Crop.banana, const Season(2026)), 1);
    });
  });

  group('drying', () {
    final start = DateTime(2026, 10, 2);

    test('start day is day 1', () {
      expect(dryingDay(startedOn: start, today: start), 1);
      expect(dryingDay(startedOn: start, today: DateTime(2026, 10, 22)), 21);
    });

    test('stops counting once drying ended', () {
      expect(
        dryingDay(
          startedOn: start,
          endedOn: DateTime(2026, 11, 10),
          today: DateTime(2026, 12, 1),
        ),
        40,
      );
    });

    test('never below day 1 if the date is in the future', () {
      expect(dryingDay(startedOn: start, today: DateTime(2026, 10, 1)), 1);
    });

    test('expected end and progress', () {
      expect(expectedDryingEnd(start, 40), DateTime(2026, 11, 10));
      expect(dryingProgress(21, 40), closeTo(0.525, 1e-9));
      expect(dryingProgress(50, 40), 1);
    });
  });

  test('storage days', () {
    final stored = DateTime(2026, 3, 1);
    expect(storageDays(storedOn: stored, today: DateTime(2026, 10, 23)), 236);
    expect(
      storageDays(
        storedOn: stored,
        takenOutOn: DateTime(2026, 3, 11),
        today: DateTime(2026, 10, 23),
      ),
      10,
    );
    expect(storageDays(storedOn: stored, today: DateTime(2026, 2, 1)), 0);
  });

  group('peeling and money', () {
    test('out-turn', () {
      expect(
        outTurnPercent(driedKg: 1460, chaliKg: 1080),
        closeTo(73.97, 0.01),
      );
      expect(outTurnPercent(driedKg: null, chaliKg: 1080), isNull);
      expect(outTurnPercent(driedKg: 0, chaliKg: 10), isNull);
    });

    test('line amount and cost per kg', () {
      expect(lineAmount(540, 700), 378000);
      expect(lineAmount(2.5, 80000), 200000);
      expect(costPerKg(costPaise: 2500000, kg: 1000), 2500);
      expect(costPerKg(costPaise: 100, kg: 0), isNull);
    });
  });

  group('stage', () {
    LotStage stage({
      DateTime? dryStart,
      DateTime? dryEnd,
      double? chali,
      double graded = 0,
      DateTime? stored,
      double sold = 0,
    }) => lotStage(
      dryingStartedOn: dryStart,
      dryingEndedOn: dryEnd,
      chaliKg: chali,
      gradedKg: graded,
      storedOn: stored,
      soldKg: sold,
    );
    final d = DateTime(2026, 1, 1);

    test('follows the chali journey', () {
      expect(stage(), LotStage.harvest);
      expect(stage(dryStart: d), LotStage.drying);
      expect(stage(dryStart: d, dryEnd: d), LotStage.peeling);
      expect(stage(dryStart: d, dryEnd: d, chali: 1080), LotStage.grading);
      expect(
        stage(dryStart: d, dryEnd: d, chali: 1080, graded: 1080),
        LotStage.storage,
      );
      expect(
        stage(
          dryStart: d,
          dryEnd: d,
          chali: 1080,
          graded: 1080,
          stored: d,
          sold: 500,
        ),
        LotStage.storage,
      );
      expect(
        stage(
          dryStart: d,
          dryEnd: d,
          chali: 1080,
          graded: 1080,
          stored: d,
          sold: 1080,
        ),
        LotStage.sold,
      );
    });

    test('selling ungraded chali in full marks it sold', () {
      expect(
        stage(dryStart: d, dryEnd: d, chali: 400, sold: 400),
        LotStage.sold,
      );
    });
  });

  test('remaining by grade', () {
    final left = remainingByGrade(
      available: {
        ArecaGrade.chali: 940,
        ArecaGrade.patora: 90,
        ArecaGrade.koka: 0,
      },
      sold: {ArecaGrade.chali: 500, ArecaGrade.patora: 120},
    );
    expect(left, {ArecaGrade.chali: 440, ArecaGrade.patora: 0});
  });
}
