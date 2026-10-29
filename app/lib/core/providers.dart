import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/farm/data/farm_repository.dart';
import '../features/labour/data/labour_repository.dart';
import '../features/lots/data/lots_repository.dart';
import '../features/lots/domain/lot_view.dart';
import 'dates.dart' as dates;
import 'db/database.dart';
import 'farm_profiles.dart';

final farmCatalogueProvider = Provider<Future<FarmProfiles>>(
  (ref) => FarmProfiles.onDevice(),
);

const languageSetting = 'language';

/// Opened by FarmSession and overridden in FarmHost's workspace scope.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider is set in FarmHost'),
);

/// Language saved on the phone, read once at start-up.
final initialLanguageProvider = Provider<String>((ref) => 'en');

/// Overridable so tests and screenshots can pin "today".
final todayProvider = Provider<DateTime>((ref) => dates.today());

final farmRepositoryProvider = Provider(
  (ref) => FarmRepository(ref.watch(databaseProvider)),
);
final labourRepositoryProvider = Provider(
  (ref) => LabourRepository(ref.watch(databaseProvider)),
);
final lotsRepositoryProvider = Provider(
  (ref) => LotsRepository(ref.watch(databaseProvider)),
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.read(initialLanguageProvider));

  Future<void> set(String languageCode) async {
    state = Locale(languageCode);
    await ref.read(databaseProvider).putSetting(languageSetting, languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

final farmProvider = StreamProvider<Farm?>(
  (ref) => ref.watch(farmRepositoryProvider).watchFarm(),
);

final plotsProvider = StreamProvider<List<Plot>>(
  (ref) => ref.watch(farmRepositoryProvider).watchPlots(),
);

final workerSummariesProvider = StreamProvider<List<WorkerSummary>>(
  (ref) => ref.watch(labourRepositoryProvider).watchWorkerSummaries(),
);

final workerNamesProvider = Provider<Map<String, String>>(
  (ref) => {
    for (final s
        in ref.watch(workerSummariesProvider).value ?? const <WorkerSummary>[])
      s.worker.id: s.worker.name,
  },
);

final workerSummaryProvider =
    Provider.family<AsyncValue<WorkerSummary?>, String>(
      (ref, id) => ref
          .watch(workerSummariesProvider)
          .whenData((all) => all.firstWhereOrNull((s) => s.worker.id == id)),
    );

final ledgerProvider = StreamProvider.family<List<LedgerLine>, String>(
  (ref, workerId) => ref.watch(labourRepositoryProvider).watchLedger(workerId),
);

final attendanceProvider =
    StreamProvider.family<Map<String, AttendanceEntry>, DateTime>(
      (ref, day) => ref.watch(labourRepositoryProvider).watchAttendance(day),
    );

final lotViewsProvider = StreamProvider<List<LotView>>(
  (ref) => ref.watch(lotsRepositoryProvider).watchLotViews(),
);

final lotViewProvider = Provider.family<AsyncValue<LotView?>, String>(
  (ref, id) => ref
      .watch(lotViewsProvider)
      .whenData((all) => all.firstWhereOrNull((v) => v.lot.id == id)),
);

final buyersProvider = StreamProvider<List<Buyer>>(
  (ref) => ref.watch(lotsRepositoryProvider).watchBuyers(),
);
