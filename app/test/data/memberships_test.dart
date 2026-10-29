import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/season.dart';
import 'package:dhara_mitra/core/validation.dart';
import 'package:dhara_mitra/features/loans/data/memberships_repository.dart';
import 'package:dhara_mitra/features/reports/report_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MembershipsRepository repo;
  late String member;
  final date = DateTime(2026, 10, 10);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = MembershipsRepository(db);
    member = await repo.save(
      organization: 'Cooperative',
      number: '123',
      joinedOn: date,
      shares: 10,
      shareValue: 10000,
    );
  });
  tearDown(() => db.close());
  test(
    'holdings derive from purchases once, dividends stay report income',
    () async {
      await repo.transaction(
        membershipId: member,
        date: date,
        kind: 'share_purchase',
        amount: 50000,
        shares: 5,
      );
      await repo.transaction(
        membershipId: member,
        date: date,
        kind: 'share_purchase',
        amount: 20000,
        shares: 2,
      );
      await repo.transaction(
        membershipId: member,
        date: date,
        kind: 'dividend',
        amount: 15000,
      );
      expect((await repo.load()).single.shares, 17);
      expect((await repo.load()).single.shares, 17);
      final report = await ReportRepository(db)
          .build(season: const Season(2026), today: date);
      expect(report.income, 15000);
      expect(report.costs, 0);
    },
  );
  test('editing and removing transactions and membership refresh balances and reports', () async {
    final purchase = await repo.transaction(
      membershipId: member,
      date: date,
      kind: 'share_purchase',
      amount: 50000,
      shares: 5,
    );
    final dividend = await repo.transaction(
      membershipId: member,
      date: date,
      kind: 'dividend',
      amount: 10000,
    );
    await repo.transaction(
      id: purchase,
      membershipId: member,
      date: date,
      kind: 'share_purchase',
      amount: 30000,
      shares: 3,
    );
    expect((await repo.load()).single.shares, 13);
    await repo.save(
      id: member,
      organization: 'Updated',
      number: '123',
      joinedOn: date,
      shares: 20,
    );
    expect((await repo.load()).single.shares, 23);
    await repo.deleteTransaction(purchase);
    expect((await repo.load()).single.shares, 20);
    await repo.deleteTransaction(dividend);
    expect(
      (await ReportRepository(
        db,
      ).build(season: const Season(2026), today: date)).income,
      0,
    );
    await repo.delete(member);
    expect(await repo.load(), isEmpty);
  });
  test(
    'invalid quantities amounts dates and cross-membership edits roll back',
    () async {
      for (final shares in [0.0, -1.0, double.nan]) {
        await expectLater(
          repo.transaction(
            membershipId: member,
            date: date,
            kind: 'share_purchase',
            amount: 10000,
            shares: shares,
          ),
          throwsA(isA<FarmException>()),
        );
      }
      await expectLater(
        repo.transaction(
          membershipId: member,
          date: date,
          kind: 'dividend',
          amount: 0,
        ),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        repo.transaction(
          membershipId: member,
          date: date,
          kind: 'dividend',
          amount: 100,
          shares: 2,
        ),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        repo.transaction(
          membershipId: member,
          date: date.subtract(const Duration(days: 1)),
          kind: 'dividend',
          amount: 100,
        ),
        throwsA(isA<FarmException>()),
      );
      final id = await repo.transaction(
        membershipId: member,
        date: date,
        kind: 'share_purchase',
        amount: 10000,
        shares: 1,
      );
      final other = await repo.save(
        organization: 'Other',
        number: '456',
        joinedOn: date,
      );
      await expectLater(
        repo.transaction(
          id: id,
          membershipId: other,
          date: date,
          kind: 'dividend',
          amount: 100,
        ),
        throwsA(isA<FarmException>()),
      );
      await expectLater(
        repo.save(
          id: member,
          organization: 'Changed',
          number: '123',
          joinedOn: date.add(const Duration(days: 1)),
          shares: 100,
        ),
        throwsA(isA<FarmException>()),
      );
      expect(
        (await repo.load()).firstWhere((v) => v.member.id == member).shares,
        11,
      );
    },
  );
}
