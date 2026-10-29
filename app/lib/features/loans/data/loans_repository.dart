import 'package:drift/drift.dart';

import '../../../core/dates.dart';
import '../../../core/db/database.dart';
import '../../../core/validation.dart';
import '../domain/loan_calc.dart';

class LoanView {
  const LoanView(this.loan, this.transactions, this.balance);
  final Loan loan;
  final List<LoanTransaction> transactions;
  final LoanBalance balance;
}

class LoansRepository {
  LoansRepository(this.db);
  final AppDatabase db;
  Stream<List<LoanView>> watch(DateTime today) =>
      db.watchAll([db.loans, db.loanTransactions], () => load(today));
  LoanBalance calculate(Loan l, List<LoanTransaction> txns, DateTime today) =>
      loanBalance(
        openedOn: l.sanctionedOn,
        annualRate: l.annualRate,
        method: l.interestMethod,
        compoundingMonths: l.compoundingMonths,
        sanctioned: l.sanctioned,
        events: txns.map((t) => LoanEvent(t.date, t.kind, t.amount)).toList(),
        asOf: today,
      );
  Future<List<LoanView>> load(DateTime today) async {
    final loans =
        await (db.select(db.loans)
              ..where((l) => l.deleted.equals(false))
              ..orderBy([(l) => OrderingTerm.asc(l.lender)]))
            .get();
    final transactions =
        await (db.select(db.loanTransactions)
              ..where((t) => t.deleted.equals(false))
              ..orderBy([
                (t) => OrderingTerm.asc(t.date),
                (t) => OrderingTerm.asc(t.updatedAt),
              ]))
            .get();
    return [
      for (final l in loans)
        LoanView(
          l,
          transactions.where((t) => t.loanId == l.id).toList(),
          calculate(
            l,
            transactions.where((t) => t.loanId == l.id).toList(),
            today,
          ),
        ),
    ];
  }

  Future<String> create({
    required String lender,
    required String lenderKind,
    required String kind,
    required int sanctioned,
    required DateTime sanctionedOn,
    required double annualRate,
    String method = 'simple',
    int compoundingMonths = 12,
    int tenureMonths = 12,
    String? parcelId,
    bool concession = false,
    String notes = '',
    int withdrawn = 0,
  }) => db.transaction(() async {
    require(lender.trim().isNotEmpty);
    positive(sanctioned);
    nonNegative(withdrawn);
    require(withdrawn <= sanctioned, 'balance');
    require(tenureMonths > 0 && tenureMonths <= 600);
    loanBalance(
      openedOn: sanctionedOn,
      annualRate: annualRate,
      method: method,
      compoundingMonths: compoundingMonths,
      events: [],
      asOf: sanctionedOn,
    );
    final row = await db
        .into(db.loans)
        .insertReturning(
          LoansCompanion.insert(
            lender: lender.trim(),
            lenderKind: lenderKind,
            kind: kind,
            sanctioned: sanctioned,
            sanctionedOn: dateOnly(sanctionedOn),
            annualRate: annualRate,
            interestMethod: Value(method),
            compoundingMonths: Value(compoundingMonths),
            tenureMonths: Value(tenureMonths),
            parcelId: Value(parcelId),
            timelyConcession: Value(concession),
            notes: Value(notes.trim()),
          ),
        );
    if (withdrawn > 0) {
      await db
          .into(db.loanTransactions)
          .insert(
            LoanTransactionsCompanion.insert(
              loanId: row.id,
              date: dateOnly(sanctionedOn),
              kind: 'withdrawal',
              amount: withdrawn,
            ),
          );
    }
    await db
        .into(db.reminders)
        .insert(
          RemindersCompanion.insert(
            title: lender.trim(),
            dueOn: addMonthsClamped(
              dateOnly(sanctionedOn),
              kind == 'crop_kcc' ? 12 : tenureMonths,
            ),
            kind: const Value('loan'),
            refId: Value(row.id),
          ),
        );
    return row.id;
  });
  Future<void> addTransaction({
    required String loanId,
    required DateTime date,
    required String kind,
    required int amount,
    String mode = 'cash',
    String note = '',
  }) => db.transaction(() async {
    positive(amount);
    require(['withdrawal', 'principal', 'interest', 'charge'].contains(kind));
    final loan = await (db.select(
      db.loans,
    )..where((l) => l.id.equals(loanId) & l.deleted.equals(false))).getSingle();
    require(loan.status == 'active');
    require(!dateOnly(date).isBefore(loan.sanctionedOn), 'dates');
    final old = await (db.select(
      db.loanTransactions,
    )..where((t) => t.loanId.equals(loanId) & t.deleted.equals(false))).get();
    final events = [
      ...old.map((t) => LoanEvent(t.date, t.kind, t.amount)),
      LoanEvent(dateOnly(date), kind, amount),
    ];
    final last = events
        .map((e) => e.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    loanBalance(
      openedOn: loan.sanctionedOn,
      annualRate: loan.annualRate,
      method: loan.interestMethod,
      compoundingMonths: loan.compoundingMonths,
      events: events,
      asOf: last,
      sanctioned: loan.sanctioned,
    );
    await db
        .into(db.loanTransactions)
        .insert(
          LoanTransactionsCompanion.insert(
            loanId: loanId,
            date: dateOnly(date),
            kind: kind,
            amount: amount,
            mode: Value(mode),
            note: Value(note.trim()),
          ),
        );
  });
  Future<void> deleteTransaction(String id) => db.transaction(() async {
    final txn = await (db.select(
      db.loanTransactions,
    )..where((t) => t.id.equals(id))).getSingle();
    final loan = await (db.select(
      db.loans,
    )..where((l) => l.id.equals(txn.loanId))).getSingle();
    require(loan.status == 'active');
    final remaining =
        await (db.select(db.loanTransactions)..where(
              (t) =>
                  t.loanId.equals(loan.id) &
                  t.id.equals(id).not() &
                  t.deleted.equals(false),
            ))
            .get();
    if (remaining.isNotEmpty) {
      calculate(
        loan,
        remaining,
        remaining.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }
    await (db.update(db.loanTransactions)..where((t) => t.id.equals(id))).write(
      LoanTransactionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> close(String id, DateTime today) => db.transaction(() async {
    final view = (await load(today)).firstWhere((v) => v.loan.id == id);
    // The as-of balance excludes future entries, which must remain editable
    // until their date has passed and the loan is actually settled.
    require(
      view.transactions.every(
        (t) => !dateOnly(t.date).isAfter(dateOnly(today)),
      ),
      'dates',
    );
    require(view.balance.total == 0, 'balance');
    await (db.update(db.loans)..where((l) => l.id.equals(id))).write(
      LoansCompanion(
        status: const Value('closed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (db.update(
      db.reminders,
    )..where((r) => r.kind.equals('loan') & r.refId.equals(id))).write(
      RemindersCompanion(
        done: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
}
