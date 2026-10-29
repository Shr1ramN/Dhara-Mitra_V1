import 'package:drift/drift.dart';

import '../../core/db/database.dart';
import '../../core/dates.dart';
import '../../core/validation.dart';

class FinanceRepository {
  FinanceRepository(this.db);
  final AppDatabase db;

  Future<void> expense({
    String? id,
    required DateTime date,
    required String category,
    required int amount,
    String? crop,
    String? plotId,
    String? lotId,
    String? produceLotId,
    String notes = '',
  }) async {
    positive(amount);
    require(category.trim().isNotEmpty);
    await db
        .into(db.expenses)
        .insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: id == null ? const Value.absent() : Value(id),
            date: dateOnly(date),
            category: category,
            amount: amount,
            crop: Value(crop),
            plotId: Value(plotId),
            lotId: Value(lotId),
            produceLotId:Value(produceLotId),
            notes: Value(notes.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteExpense(String id) =>
      (db.update(db.expenses)..where((e) => e.id.equals(id))).write(
        ExpensesCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<String> parcel({
    String? id,
    required String survey,
    String hissa = '',
    String village = '',
    required double acres,
    List<String> plotIds = const [],
    String notes = '',
  }) async {
    require(survey.trim().isNotEmpty);
    positive(acres);
    final key = id ?? newId();
    await db
        .into(db.landParcels)
        .insertOnConflictUpdate(
          LandParcelsCompanion.insert(
            id: Value(key),
            surveyNumber: survey.trim(),
            acres: acres,
            hissa: Value(hissa.trim()),
            village: Value(village.trim()),
            plotIds: Value(plotIds),
            notes: Value(notes.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return key;
  }

  Future<String> policy({
    String? id,
    required String scheme,
    required String crop,
    required int season,
    required double acres,
    required int premium,
    required DateTime paidOn,
    required String number,
    DateTime? enrolBy,
    String status = 'active',
  }) => db.transaction(() async {
    require(scheme.trim().isNotEmpty && number.trim().isNotEmpty);
    positive(acres);
    nonNegative(premium);
    final key = id ?? newId();
    await db
        .into(db.insurancePolicies)
        .insertOnConflictUpdate(
          InsurancePoliciesCompanion.insert(
            id: Value(key),
            scheme: scheme.trim(),
            crop: crop,
            seasonStartYear: season,
            acres: acres,
            premium: premium,
            paidOn: dateOnly(paidOn),
            policyNumber: number.trim(),
            enrolBy: Value(enrolBy),
            status: Value(status),
            updatedAt: Value(DateTime.now()),
          ),
        );
    await (db.update(
      db.reminders,
    )..where((r) => r.kind.equals('insurance') & r.refId.equals(key))).write(
      RemindersCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (enrolBy != null) {
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              title: scheme.trim(),
              dueOn: dateOnly(enrolBy),
              kind: const Value('insurance'),
              refId: Value(key),
              amount: Value(premium),
            ),
          );
    }
    return key;
  });

  Future<void> claim({
    String? id,
    required String policyId,
    required DateTime lossOn,
    DateTime? filedOn,
    required int claimed,
    int received = 0,
    DateTime? receivedOn,
    String status = 'draft',
    String notes = '',
  }) async {
    positive(claimed);
    nonNegative(received);
    require(received <= claimed, 'balance');
    if (filedOn != null) {
      require(!dateOnly(filedOn).isBefore(dateOnly(lossOn)), 'dates');
    }
    require(received == 0 || receivedOn != null, 'dates');
    if (receivedOn != null) {
      require(
        !dateOnly(receivedOn).isBefore(dateOnly(filedOn ?? lossOn)),
        'dates',
      );
    }
    await db
        .into(db.insuranceClaims)
        .insertOnConflictUpdate(
          InsuranceClaimsCompanion.insert(
            id: id == null ? const Value.absent() : Value(id),
            policyId: policyId,
            lossOn: dateOnly(lossOn),
            filedOn: Value(filedOn == null ? null : dateOnly(filedOn)),
            claimed: claimed,
            received: Value(received),
            receivedOn: Value(receivedOn == null ? null : dateOnly(receivedOn)),
            status: Value(status),
            notes: Value(notes.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> scheme({
    String? id,
    required String scheme,
    required String department,
    required DateTime appliedOn,
    String number = '',
    String status = 'applied',
    int subsidy = 0,
    DateTime? receivedOn,
    String notes = '',
  }) async {
    require(scheme.trim().isNotEmpty && department.trim().isNotEmpty);
    nonNegative(subsidy);
    if (receivedOn != null) {
      require(!dateOnly(receivedOn).isBefore(dateOnly(appliedOn)), 'dates');
    }
    await db
        .into(db.schemeApplications)
        .insertOnConflictUpdate(
          SchemeApplicationsCompanion.insert(
            id: id == null ? const Value.absent() : Value(id),
            scheme: scheme.trim(),
            department: department.trim(),
            appliedOn: dateOnly(appliedOn),
            applicationNumber: Value(number.trim()),
            status: Value(status),
            subsidy: Value(subsidy),
            receivedOn: Value(receivedOn == null ? null : dateOnly(receivedOn)),
            notes: Value(notes.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
