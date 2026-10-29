import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../farm_profiles.dart';
import '../../features/labour/data/daily_work.dart';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../enums.dart';
import 'tables.dart';
import 'extended_tables.dart';

export 'tables.dart' show newId;

part 'database.g.dart';

const databaseName = 'dhara_mitra';

@DriftDatabase(
  tables: [
    AppSettings,
    Farms,
    Plots,
    Workers,
    AttendanceEntries,
    WorkerTxns,
    Lots,
    LotEvents,
    LotLabour,
    LotGrades,
    Buyers,
    Sales,
    SaleLines,
    PlotCrops,
    StockItems,
    StockMovements,
    Activities,
    ActivityInputs,
    ActivityLabour,
    Expenses,
    LandParcels,
    Loans,
    LoanTransactions,
    Memberships,
    MembershipTransactions,
    InsurancePolicies,
    InsuranceClaims,
    SchemeApplications,
    StoredDocuments,
    Reminders,
    RainEntries,
    PriceSnapshots,
    PriceAlerts,
    WeatherCaches,
    ProduceLots,
    ProduceLabour,
    ProduceSales,
    WorkerRates,
    ArecaCollections,
    DailyWorkAllocations,
    SaleReceipts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.profileId = 'default'});
  final String profileId;

  factory AppDatabase.onDevice({String profileId = 'default'}) {
    if (!FarmProfiles.validId(profileId)) throw ArgumentError('Invalid farm');
    return AppDatabase(
      driftDatabase(
        name: profileId == 'default'
            ? databaseName
            : '${databaseName}_$profileId',
      ),
      profileId: profileId,
    );
  }

  Future<Directory> documentsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return profileId == 'default'
        ? root
        : Directory(p.join(root.path, 'farms', profileId));
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(attendanceEntries, attendanceEntries.rate);
        await m.addColumn(
          attendanceEntries,
          attendanceEntries.sourceActivityId,
        );
        for (final table in <TableInfo<Table, Object?>>[
          plotCrops,
          stockItems,
          stockMovements,
          activities,
          activityInputs,
          activityLabour,
          expenses,
          landParcels,
          loans,
          loanTransactions,
          memberships,
          membershipTransactions,
          insurancePolicies,
          insuranceClaims,
          schemeApplications,
          storedDocuments,
          reminders,
          rainEntries,
          priceSnapshots,
          priceAlerts,
          weatherCaches,
          produceLots,
          produceLabour,
          produceSales,
          workerRates,
        ]) {
          await m.createTable(table);
        }
      }
      if (from < 3) {
        await m.addColumn(workers, workers.telephone);
        await m.addColumn(workers, workers.customRoles);
        await m.addColumn(lots, lots.quantityMode);
        await m.addColumn(lots, lots.freshBags);
        await m.addColumn(lots, lots.driedBags);
        await m.createTable(arecaCollections);
        // Notification identifiers now include the farm profile.
        await customStatement(
          "DELETE FROM app_settings WHERE key LIKE 'scheduled.%'",
        );
      }
      if (from < 5) {
        await m.createTable(saleReceipts);
        for (final sale in await select(sales).get()) {
          if (!sale.deleted && sale.received != 0) {
            await into(saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: false, date: sale.date, amount: sale.received, notes: const Value('Opening received balance / ಆರಂಭಿಕ ಸ್ವೀಕೃತ ಮೊತ್ತ')));
          }
        }
        for (final sale in await select(produceSales).get()) {
          if (!sale.deleted && sale.received != 0) {
            await into(saleReceipts).insert(SaleReceiptsCompanion.insert(saleId: sale.id, produce: true, date: sale.date, amount: sale.received, notes: const Value('Opening received balance / ಆರಂಭಿಕ ಸ್ವೀಕೃತ ಮೊತ್ತ')));
          }
        }
      }
      if (from < 4) {
        await m.createTable(dailyWorkAllocations);
        await DailyWork(this).migrate();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Emits [load] now and again whenever any of [tables] changes.
  Stream<T> watchAll<T>(
    Iterable<TableInfo<Table, Object?>> tables,
    Future<T> Function() load,
  ) {
    late StreamController<T> controller;
    StreamSubscription<Set<TableUpdate>>? subscription;
    var running = false, pending = false, cancelled = false;
    Future<void> refresh() async {
      pending = true;
      if (running) return;
      running = true;
      try {
        while (pending && !cancelled) {
          pending = false;
          try {
            final value = await load();
            if (!cancelled) controller.add(value);
          } catch (error, stack) {
            if (!cancelled) controller.addError(error, stack);
          }
        }
      } finally {
        running = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = tableUpdates(TableUpdateQuery.onAllTables(tables))
            .listen(
              (_) => refresh(),
              onDone: () {
                cancelled = true;
                controller.close().ignore();
              },
            );
        refresh().ignore();
      },
      onCancel: () async {
        cancelled = true;
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<String?> setting(String key) async => (await (select(
    appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> putSetting(String key, String value) => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  /// Writes a consistent copy of the whole database to [path] (database export).
  Future<void> exportTo(String path) =>
      customStatement('VACUUM INTO ?', [path]);
}
