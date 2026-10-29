import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../../core/dates.dart';
import '../../../core/validation.dart';

class MembershipView {
  const MembershipView(this.member, this.transactions);
  final Membership member;
  final List<MembershipTransaction> transactions;
  double get shares =>
      member.shares +
      transactions
          .where((t) => t.kind == 'share_purchase')
          .fold(0.0, (s, t) => s + t.shares);
}

class MembershipsRepository {
  MembershipsRepository(this.db);
  final AppDatabase db;
  Stream<List<MembershipView>> watch() =>
      db.watchAll([db.memberships, db.membershipTransactions], load);
  Future<List<MembershipView>> load() async {
    final members =
        await (db.select(db.memberships)
              ..where((m) => m.deleted.equals(false))
              ..orderBy([(m) => OrderingTerm.asc(m.organization)]))
            .get();
    final txns =
        await (db.select(db.membershipTransactions)
              ..where((t) => t.deleted.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return [
      for (final member in members)
        MembershipView(
          member,
          txns.where((t) => t.membershipId == member.id).toList(),
        ),
    ];
  }

  Future<String> save({
    String? id,
    required String organization,
    required String number,
    required DateTime joinedOn,
    double shares = 0,
    int shareValue = 0,
  }) => db.transaction(() async {
    require(organization.trim().isNotEmpty && number.trim().isNotEmpty);
    nonNegative(shares);
    nonNegative(shareValue);
    if (id != null) {
      await _member(id);
      final txns =
          await (db.select(db.membershipTransactions)..where(
                (t) => t.membershipId.equals(id) & t.deleted.equals(false),
              ))
              .get();
      require(txns.every((t) => !t.date.isBefore(dateOnly(joinedOn))), 'dates');
    }
    final memberId = id ?? newId();
    await db
        .into(db.memberships)
        .insertOnConflictUpdate(
          MembershipsCompanion.insert(
            id: Value(memberId),
            organization: organization.trim(),
            memberNumber: number.trim(),
            joinedOn: dateOnly(joinedOn),
            shares: Value(shares),
            shareValue: Value(shareValue),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return memberId;
  });
  Future<Membership> _member(String id) => (db.select(
    db.memberships,
  )..where((m) => m.id.equals(id) & m.deleted.equals(false))).getSingle();
  Future<String> transaction({
    String? id,
    required String membershipId,
    required DateTime date,
    required String kind,
    required int amount,
    double shares = 0,
  }) => db.transaction(() async {
    final member = await _member(membershipId);
    require(kind == 'share_purchase' || kind == 'dividend');
    positive(amount);
    require(!dateOnly(date).isBefore(member.joinedOn), 'dates');
    if (kind == 'share_purchase') {
      positive(shares);
    } else {
      require(shares == 0);
    }
    if (id != null) {
      require(
        await (db.select(db.membershipTransactions)..where(
                  (t) =>
                      t.id.equals(id) &
                      t.membershipId.equals(membershipId) &
                      t.deleted.equals(false),
                ))
                .getSingleOrNull() !=
            null,
      );
    }
    final txnId = id ?? newId();
    await db
        .into(db.membershipTransactions)
        .insertOnConflictUpdate(
          MembershipTransactionsCompanion.insert(
            id: Value(txnId),
            membershipId: membershipId,
            date: dateOnly(date),
            kind: kind,
            amount: amount,
            shares: Value(shares),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return txnId;
  });
  Future<void> deleteTransaction(String id) => db.transaction(() async {
    await (db.update(
      db.membershipTransactions,
    )..where((t) => t.id.equals(id))).write(
      MembershipTransactionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
  Future<void> delete(String id) => db.transaction(() async {
    await _member(id);
    final now = DateTime.now();
    await (db.update(
      db.membershipTransactions,
    )..where((t) => t.membershipId.equals(id))).write(
      MembershipTransactionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await (db.update(db.memberships)..where((m) => m.id.equals(id))).write(
      MembershipsCompanion(deleted: const Value(true), updatedAt: Value(now)),
    );
  });
}
