import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

import 'package:drift/drift.dart';

import '../finance/finance_repository.dart';
import '../loans/data/loans_repository.dart';
import '../loans/data/memberships_repository.dart';
import '../produce/produce_repository.dart';
import '../diary/data/diary_repository.dart';
import '../stock/data/stock_repository.dart';

final stockRepositoryProvider = Provider(
  (ref) => StockRepository(ref.watch(databaseProvider)),
);
final stockBalancesProvider = StreamProvider(
  (ref) => ref.watch(stockRepositoryProvider).watchBalances(),
);
final diaryRepositoryProvider = Provider(
  (ref) => DiaryRepository(ref.watch(databaseProvider)),
);
final diaryProvider = StreamProvider(
  (ref) => ref.watch(diaryRepositoryProvider).watchAll(),
);
final financeRepositoryProvider = Provider(
  (ref) => FinanceRepository(ref.watch(databaseProvider)),
);
final loansRepositoryProvider = Provider(
  (ref) => LoansRepository(ref.watch(databaseProvider)),
);
final loansProvider = StreamProvider(
  (ref) => ref.watch(loansRepositoryProvider).watch(ref.watch(todayProvider)),
);
final expensesProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.expenses)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.desc(e.date)]))
      .watch();
});
final parcelsProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.landParcels)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.asc(e.surveyNumber)]))
      .watch();
});
final policiesProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.insurancePolicies)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.desc(e.paidOn)]))
      .watch();
});
final claimsProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.insuranceClaims)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.desc(e.lossOn)]))
      .watch();
});
final schemesProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.schemeApplications)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.desc(e.appliedOn)]))
      .watch();
});
final membershipsRepositoryProvider = Provider(
  (ref) => MembershipsRepository(ref.watch(databaseProvider)),
);
final membershipsProvider = StreamProvider(
  (ref) => ref.watch(membershipsRepositoryProvider).watch(),
);
final produceRepositoryProvider = Provider(
  (ref) => ProduceRepository(ref.watch(databaseProvider)),
);
final produceProvider = StreamProvider(
  (ref) => ref.watch(produceRepositoryProvider).watch(),
);
final remindersProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.reminders)
        ..where((e) => e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.asc(e.dueOn)]))
      .watch();
});
