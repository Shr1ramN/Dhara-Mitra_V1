import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/loans/data/loans_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final day = DateTime(2026, 1, 10);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final kind in ['withdrawal', 'charge']) {
    test(
      'closing a loan rejects a future $kind and preserves reminders',
      () async {
        final repo = LoansRepository(db);
        final id = await repo.create(
          lender: 'Bank',
          lenderKind: 'bank',
          kind: 'term',
          sanctioned: 100000,
          sanctionedOn: day,
          annualRate: 0,
        );
        await repo.addTransaction(
          loanId: id,
          date: DateTime(2026, 1, 11),
          kind: kind,
          amount: 10000,
        );

        await expectLater(repo.close(id, day), throwsA(isA<FarmException>()));
        expect((await db.select(db.loans).get()).single.status, 'active');
        expect((await db.select(db.reminders).get()).single.done, isFalse);
        expect(
          (await repo.load(DateTime(2026, 1, 11))).single.balance.total,
          10000,
        );
      },
    );
  }

  test('a repaid loan can close on its final transaction day', () async {
    final repo = LoansRepository(db);
    final id = await repo.create(
      lender: 'Bank',
      lenderKind: 'bank',
      kind: 'term',
      sanctioned: 100000,
      sanctionedOn: day,
      annualRate: 0,
      withdrawn: 10000,
    );
    await repo.addTransaction(
      loanId: id,
      date: day,
      kind: 'principal',
      amount: 10000,
    );
    await repo.close(id, day);
    expect((await db.select(db.loans).get()).single.status, 'closed');
    expect((await db.select(db.reminders).get()).single.done, isTrue);
  });

  for (final graded in [false, true]) {
    test(
      'peeling cannot fall below ${graded ? 'graded' : 'sold ungraded'} stock',
      () async {
        final repo = LotsRepository(db);
        final id = await repo.createHarvestLot(
          crop: Crop.areca,
          harvestedOn: day,
          title: 'Round',
          plotIds: [],
        );
        await repo.recordPeeling(id, on: day, chaliKg: 100);
        String? saleId;
        if (graded) {
          await repo.setGrades(id, {ArecaGrade.chali: 60, ArecaGrade.koka: 20});
        } else {
          final buyer = await repo.saveBuyer(
            name: 'Buyer',
            kind: BuyerKind.trader,
          );
          saleId = await repo.recordSale(
            lotId: id,
            buyerId: buyer,
            date: day,
            lines: [
              const SaleLineInput(grade: ArecaGrade.chali, kg: 80, rate: 10000),
            ],
          );
        }
        await expectLater(
          repo.recordPeeling(id, on: day, chaliKg: 79),
          throwsA(isA<FarmException>()),
        );
        expect((await repo.loadLotViews()).single.lot.chaliKg, 100);
        await repo.recordPeeling(id, on: day, chaliKg: 80);
        expect((await repo.loadLotViews()).single.remainingKg, graded ? 80 : 0);

        if (graded) {
          await repo.setGrades(id, {});
        } else {
          await repo.deleteSale(saleId!);
        }
        await repo.recordPeeling(id, on: day, chaliKg: 50);
        expect((await repo.loadLotViews()).single.remainingKg, 50);
      },
    );
  }
}
