import 'package:drift/drift.dart';

import 'tables.dart';

class WorkerRates extends Table with SyncColumns {
  TextColumn get workerId => text().references(Workers, #id)();
  TextColumn get work => text()();
  TextColumn get unit => text()();
  IntColumn get rate => integer()();
}

class PlotCrops extends Table with SyncColumns {
  TextColumn get plotId => text().references(Plots, #id)();
  TextColumn get crop => text()();
  TextColumn get variety => text().withDefault(const Constant(''))();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get plantedOn => dateTime().nullable()();
  BoolColumn get bearing => boolean().withDefault(const Constant(true))();
  IntColumn get ratoon => integer().withDefault(const Constant(0))();
  TextColumn get trailedOn => text().withDefault(const Constant(''))();
  TextColumn get photo => text().withDefault(const Constant(''))();
}

class StockItems extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  RealColumn get minimum => real().withDefault(const Constant(0))();
}

/// Positive purchases and negative consumption, valued in paise. Inventory is
/// valued at moving weighted-average purchase cost, never today's selling price.
class StockMovements extends Table with SyncColumns {
  TextColumn get itemId => text().references(StockItems, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get kind => text()();
  RealColumn get quantity => real()();
  IntColumn get cost => integer()();
  TextColumn get supplier => text().withDefault(const Constant(''))();
  TextColumn get refId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class Activities extends Table with SyncColumns {
  DateTimeColumn get date => dateTime()();
  IntColumn get days => integer().withDefault(const Constant(1))();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get crops =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get plotIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get remindOn => dateTime().nullable()();
}

class ActivityInputs extends Table with SyncColumns {
  TextColumn get activityId => text().references(Activities, #id)();
  TextColumn get itemId => text().references(StockItems, #id)();
  RealColumn get quantity => real()();
  IntColumn get cost => integer()();
}

class ActivityLabour extends Table with SyncColumns {
  TextColumn get attendanceIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get activityId => text().references(Activities, #id)();
  TextColumn get workerId => text().references(Workers, #id)();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  IntColumn get rate => integer()();
  IntColumn get amount => integer()();
}

class Expenses extends Table with SyncColumns {
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  IntColumn get amount => integer()();
  TextColumn get crop => text().nullable()();
  TextColumn get plotId => text().nullable().references(Plots, #id)();
  TextColumn get lotId => text().nullable().references(Lots, #id)();
  TextColumn get produceLotId =>
      text().nullable().references(ProduceLots, #id)();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class LandParcels extends Table with SyncColumns {
  TextColumn get surveyNumber => text()();
  TextColumn get hissa => text().withDefault(const Constant(''))();
  TextColumn get village => text().withDefault(const Constant(''))();
  RealColumn get acres => real()();
  TextColumn get plotIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class Loans extends Table with SyncColumns {
  TextColumn get lender => text()();
  TextColumn get lenderKind => text()();
  TextColumn get kind => text()();
  IntColumn get sanctioned => integer()();
  DateTimeColumn get sanctionedOn => dateTime()();
  RealColumn get annualRate => real()();
  TextColumn get interestMethod =>
      text().withDefault(const Constant('simple'))();
  IntColumn get compoundingMonths =>
      integer().withDefault(const Constant(12))();
  IntColumn get tenureMonths => integer().withDefault(const Constant(12))();
  TextColumn get parcelId => text().nullable().references(LandParcels, #id)();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get timelyConcession =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class LoanTransactions extends Table with SyncColumns {
  TextColumn get loanId => text().references(Loans, #id)();
  DateTimeColumn get date => dateTime()();

  /// withdrawal, principal, interest or charge; repayments split explicitly.
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get mode => text().withDefault(const Constant('cash'))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class Memberships extends Table with SyncColumns {
  TextColumn get organization => text()();
  TextColumn get memberNumber => text()();
  RealColumn get shares => real().withDefault(const Constant(0))();
  IntColumn get shareValue => integer().withDefault(const Constant(0))();
  DateTimeColumn get joinedOn => dateTime()();
}

class MembershipTransactions extends Table with SyncColumns {
  TextColumn get membershipId => text().references(Memberships, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  RealColumn get shares => real().withDefault(const Constant(0))();
}

class InsurancePolicies extends Table with SyncColumns {
  TextColumn get scheme => text()();
  TextColumn get crop => text()();
  IntColumn get seasonStartYear => integer()();
  RealColumn get acres => real()();
  IntColumn get premium => integer()();
  DateTimeColumn get paidOn => dateTime()();
  TextColumn get policyNumber => text()();
  DateTimeColumn get enrolBy => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
}

class InsuranceClaims extends Table with SyncColumns {
  TextColumn get policyId => text().references(InsurancePolicies, #id)();
  DateTimeColumn get lossOn => dateTime()();
  DateTimeColumn get filedOn => dateTime().nullable()();
  IntColumn get claimed => integer()();
  IntColumn get received => integer().withDefault(const Constant(0))();
  DateTimeColumn get receivedOn => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class SchemeApplications extends Table with SyncColumns {
  TextColumn get scheme => text()();
  TextColumn get department => text()();
  DateTimeColumn get appliedOn => dateTime()();
  TextColumn get applicationNumber => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  IntColumn get subsidy => integer().withDefault(const Constant(0))();
  DateTimeColumn get receivedOn => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class StoredDocuments extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get kind => text()();
  TextColumn get path => text()();
  TextColumn get originalName => text()();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
}

class Reminders extends Table with SyncColumns {
  TextColumn get title => text()();
  DateTimeColumn get dueOn => dateTime()();
  TextColumn get kind => text().withDefault(const Constant('task'))();
  TextColumn get refId => text().nullable()();
  IntColumn get amount => integer().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class RainEntries extends Table with SyncColumns {
  DateTimeColumn get date => dateTime().unique()();
  RealColumn get millimetres => real()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class PriceSnapshots extends Table with SyncColumns {
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text()();
  TextColumn get market => text()();
  TextColumn get crop => text()();
  TextColumn get grade => text()();
  IntColumn get minimum => integer()();
  IntColumn get maximum => integer()();
  IntColumn get modal => integer()();
}

class PriceAlerts extends Table with SyncColumns {
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  TextColumn get crop => text()();
  TextColumn get grade => text()();
  TextColumn get market => text().withDefault(const Constant(''))();
  IntColumn get target => integer()();
  TextColumn get direction => text().withDefault(const Constant('above'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class WeatherCaches extends Table {
  TextColumn get key => text()();
  DateTimeColumn get fetchedOn => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Non-areca lots retain their actual units (nuts, bunches or kg). They are not
/// forced into areca-specific grades or chali-weight columns.
class ProduceLots extends Table with SyncColumns {
  TextColumn get code => text().unique()();
  TextColumn get crop => text()();
  TextColumn get title => text()();
  IntColumn get seasonStartYear => integer()();
  TextColumn get plotIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  DateTimeColumn get harvestedOn => dateTime()();
  RealColumn get freshQuantity => real()();
  TextColumn get freshUnit => text()();
  TextColumn get stage => text().withDefault(const Constant('harvest'))();
  TextColumn get product => text()();
  TextColumn get unit => text()();
  RealColumn get quantity => real().nullable()();
  DateTimeColumn get dryingStartedOn => dateTime().nullable()();
  DateTimeColumn get dryingEndedOn => dateTime().nullable()();
  DateTimeColumn get storedOn => dateTime().nullable()();
  TextColumn get storagePlace => text().withDefault(const Constant(''))();
  IntColumn get bags => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class ProduceLabour extends Table with SyncColumns {
  TextColumn get lotId => text().references(ProduceLots, #id)();
  TextColumn get workerId => text().references(Workers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get work => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  IntColumn get rate => integer()();
  IntColumn get amount => integer()();
}

class ProduceSales extends Table with SyncColumns {
  TextColumn get lotId => text().references(ProduceLots, #id)();
  TextColumn get buyerId => text().references(Buyers, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get quantity => real()();
  IntColumn get rate => integer()();
  IntColumn get gross => integer()();
  IntColumn get deductions => integer().withDefault(const Constant(0))();
  IntColumn get received => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// Signed adjustments retain payment history when a received total is corrected.
class SaleReceipts extends Table with SyncColumns {
  TextColumn get saleId => text()();
  BoolColumn get produce => boolean()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}
