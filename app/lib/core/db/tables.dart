import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../enums.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// Every synced table gets a UUID key, a change time and a soft-delete flag,
/// so rows can be backed up and restored (plan section 5).
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      fromDb.isEmpty ? const [] : fromDb.split(',');

  @override
  String toSql(List<String> value) => value.join(',');
}

class RoleListConverter extends TypeConverter<List<WorkerRole>, String> {
  const RoleListConverter();

  @override
  List<WorkerRole> fromSql(String fromDb) => [
    for (final name in const StringListConverter().fromSql(fromDb))
      ?WorkerRole.values.asNameMap()[name],
  ];

  @override
  String toSql(List<WorkerRole> value) => value.map((r) => r.name).join(',');
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Farms extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get village => text().withDefault(const Constant(''))();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get seasonStartMonth => integer().withDefault(const Constant(6))();
}

class Plots extends Table with SyncColumns {
  TextColumn get name => text()();
  RealColumn get acres => real().withDefault(const Constant(0))();
  TextColumn get soil => text().withDefault(const Constant(''))();
  TextColumn get irrigation =>
      textEnum<Irrigation>().withDefault(Constant(Irrigation.none.name))();
  IntColumn get arecaPalms => integer().withDefault(const Constant(0))();
  IntColumn get coconutTrees => integer().withDefault(const Constant(0))();
  IntColumn get pepperVines => integer().withDefault(const Constant(0))();
  IntColumn get bananaClumps => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class Workers extends Table with SyncColumns {
  TextColumn get telephone => text().withDefault(const Constant(''))();
  TextColumn get customRoles =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get village => text().withDefault(const Constant(''))();
  TextColumn get roles =>
      text().map(const RoleListConverter()).withDefault(const Constant(''))();

  /// Paise per day.
  IntColumn get dayRate => integer().withDefault(const Constant(0))();
  IntColumn get halfDayRate => integer().nullable()();

  /// Paise per [pieceUnit] (per palm, per kg, …) for piece work.
  IntColumn get pieceRate => integer().nullable()();
  TextColumn get pieceUnit => textEnum<RateUnit>().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class AttendanceEntries extends Table with SyncColumns {
  IntColumn get rate => integer().nullable()();
  TextColumn get sourceActivityId => text().nullable()();
  TextColumn get workerId => text().references(Workers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => textEnum<AttendanceStatus>()();
  TextColumn get work => text().withDefault(const Constant(''))();
  IntColumn get amount => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {workerId, date},
  ];
}

/// Every rupee between the owner and a worker. Work entries made by attendance
/// or lot labour point back to their source through [refType] / [refId].
class WorkerTxns extends Table with SyncColumns {
  TextColumn get workerId => text().references(Workers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get kind => textEnum<TxnKind>()();
  IntColumn get amount => integer()();
  TextColumn get mode => textEnum<PayMode>().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
}

class Lots extends Table with SyncColumns {
  TextColumn get quantityMode => text().withDefault(const Constant('kg'))();
  RealColumn get freshBags => real().nullable()();
  RealColumn get driedBags => real().nullable()();
  TextColumn get code => text()();
  TextColumn get crop => textEnum<Crop>()();
  IntColumn get seasonStartYear => integer()();
  TextColumn get title => text()();
  TextColumn get plotIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  DateTimeColumn get harvestedOn => dateTime()();
  IntColumn get palmsClimbed => integer().nullable()();
  RealColumn get freshKg => real().nullable()();
  DateTimeColumn get dryingStartedOn => dateTime().nullable()();
  DateTimeColumn get dryingEndedOn => dateTime().nullable()();
  IntColumn get dryingTargetDays => integer().withDefault(const Constant(40))();
  TextColumn get yard => text().withDefault(const Constant(''))();

  /// Dried nuts in husk, weighed before peeling.
  RealColumn get driedKg => real().nullable()();
  DateTimeColumn get peeledOn => dateTime().nullable()();

  /// Chali after peeling.
  RealColumn get chaliKg => real().nullable()();
  DateTimeColumn get storedOn => dateTime().nullable()();
  DateTimeColumn get takenOutOn => dateTime().nullable()();
  TextColumn get storagePlace => text().withDefault(const Constant(''))();
  IntColumn get bags => integer().nullable()();

  /// Paise per kg on the day it was stored.
  IntColumn get storedPricePerKg => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

/// A pickup is recorded once and assigned to at most one drying lot.
class ArecaCollections extends Table with SyncColumns {
  DateTimeColumn get collectedOn => dateTime()();
  TextColumn get plotIds =>
      text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('daily'))();
  TextColumn get unit => text().withDefault(const Constant('bags'))();
  RealColumn get quantity => real().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get lotId => text().nullable().references(Lots, #id)();
}

/// A source's share of one attendance wage. Amount is materialized so reports
/// and backups retain exact paise after rounding and attendance corrections.
class DailyWorkAllocations extends Table with SyncColumns {
  TextColumn get attendanceId => text().references(AttendanceEntries, #id)();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();
  RealColumn get quantity => real()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
}

class LotEvents extends Table with SyncColumns {
  TextColumn get lotId => text().references(Lots, #id)();
  DateTimeColumn get at => dateTime()();
  TextColumn get kind => textEnum<LotEventKind>()();
  TextColumn get value => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('LotLabourEntry')
class LotLabour extends Table with SyncColumns {
  TextColumn get lotId => text().references(Lots, #id)();
  TextColumn get stage => textEnum<LotStage>()();
  TextColumn get workerId => text().nullable().references(Workers, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get qty => real()();
  TextColumn get unit => textEnum<RateUnit>()();
  IntColumn get rate => integer()();
  IntColumn get amount => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class LotGrades extends Table with SyncColumns {
  TextColumn get lotId => text().references(Lots, #id)();
  TextColumn get grade => textEnum<ArecaGrade>()();
  RealColumn get kg => real()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {lotId, grade},
  ];
}

class Buyers extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind =>
      textEnum<BuyerKind>().withDefault(Constant(BuyerKind.trader.name))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get place => text().withDefault(const Constant(''))();
}

class Sales extends Table with SyncColumns {
  DateTimeColumn get date => dateTime()();
  TextColumn get buyerId => text().references(Buyers, #id)();
  TextColumn get lotId => text().nullable().references(Lots, #id)();

  /// Moisture cut, commission, hamali, transport — paise, taken off the gross.
  IntColumn get deductions => integer().withDefault(const Constant(0))();
  TextColumn get deductionNote => text().withDefault(const Constant(''))();
  IntColumn get received => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class SaleLines extends Table with SyncColumns {
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get grade => textEnum<ArecaGrade>()();
  RealColumn get kg => real()();

  /// Paise per kg.
  IntColumn get rate => integer()();
  IntColumn get amount => integer()();
}
