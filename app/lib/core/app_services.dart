import 'v1.dart';
import 'dart:async';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/stock/data/stock_repository.dart';
import '../features/weather/weather_repository.dart';
import '../features/farm/data/farm_repository.dart';
import '../features/prices/prices_repository.dart';
import '../features/labour/data/labour_repository.dart';
import 'db/database.dart';
import 'farm_profiles.dart';
import 'l10n.dart';
import 'notifications.dart';

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (v1) return true;
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    var success = true;
    final preferences = await SharedPreferences.getInstance();
    final owner = preferences.getString('account.activeOwner');
    if (owner == null || owner.isEmpty) return true;
    final local = await FarmProfiles.onDevice();
    final profiles = await FarmProfiles(
      local.root,
      ownerId: owner == 'local' ? null : owner,
    ).read();
    for (final id in profiles.ids) {
      final db = AppDatabase.onDevice(profileId: id);
      try {
        try {
          await refreshWeather(db);
        } catch (_) {
          /* Keep cached data. */
        }
        await refreshAlerts(db);
      } catch (_) {
        success = false;
      } finally {
        await db.close();
      }
    }
    return success;
  });
}

Future<void> refreshWeather(AppDatabase db) async {
  final farm = await FarmRepository(db).getFarm();
  if (farm?.lat == null || farm?.lng == null) return;
  final cached = await (db.select(
    db.weatherCaches,
  )..where((w) => w.key.equals('forecast'))).getSingleOrNull();
  if (cached != null &&
      cached.latitude == farm!.lat &&
      cached.longitude == farm.lng &&
      DateTime.now().difference(cached.fetchedOn) < const Duration(hours: 6)) {
    return;
  }
  await WeatherRepository(db).refresh(farm!.lat!, farm.lng!);
}

Future<void> refreshAlerts(AppDatabase db) async {
  final notifications = FarmNotifications(db);
  await notifications.syncReminders();
  if (await db.setting('notifications_enabled') != 'true') return;
  final l = await AppLocalizations.delegate.load(
    Locale(await db.setting('language') ?? 'en'),
  );
  for (final stock in await StockRepository(db).balances()) {
    final key = 'alert.stock.${stock.item.id}';
    final wasLow = await db.setting(key) == 'true';
    if (stock.low && !wasLow) {
      await notifications.show(
        'stock:${stock.item.id}',
        l.xLowStock,
        stock.item.name,
      );
      await db.putSetting(key, 'true');
    } else if (!stock.low && wasLow) {
      await db.putSetting(key, 'false');
    }
  }
  final prices = await PricesRepository(db).watch().first;
  final alerts = await (db.select(
    db.priceAlerts,
  )..where((a) => a.deleted.equals(false) & a.active.equals(true))).get();
  for (final a in alerts) {
    final latest = prices
        .where(
          (p) =>
              p.crop == a.crop &&
              p.grade == a.grade &&
              p.unit == a.unit &&
              (a.market.isEmpty || p.market == a.market),
        )
        .firstOrNull;
    if (latest == null) continue;
    final triggered = a.direction == 'above'
        ? latest.modal >= a.target
        : latest.modal <= a.target;
    final key = 'alert.price.${a.id}.${a.updatedAt.microsecondsSinceEpoch}';
    final old = await db.setting(key) == 'true';
    if (triggered && !old) {
      await notifications.show(
        'price:${a.id}',
        l.xPriceAlert,
        '${latest.market} · ${latest.grade} · ${Formats('en', l).money(latest.modal)} / ${latest.unit}',
      );
      await db.putSetting(key, 'true');
    } else if (!triggered && old) {
      await db.putSetting(key, 'false');
    }
  }
  final due = (await LabourRepository(db).watchWorkerSummaries().first).fold(
    0,
    (s, w) => s + (w.balance.due > 0 ? w.balance.due : 0),
  );
  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, 9);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  if (due > 0) {
    await notifications.schedule(
      'worker-dues',
      l.toPayWorkers,
      Formats('en', l).money(due),
      next,
      daily: true,
    );
  } else {
    await notifications.cancel('worker-dues');
  }
  final lots =
      await (db.select(db.lots)..where(
            (l) =>
                l.deleted.equals(false) &
                l.dryingStartedOn.isNotNull() &
                l.dryingEndedOn.isNull(),
          ))
          .get();
  final produce = await (db.select(
    db.produceLots,
  )..where((l) => l.deleted.equals(false) & l.stage.equals('drying'))).get();
  final cached = await (db.select(
    db.weatherCaches,
  )..where((w) => w.key.equals('forecast'))).getSingleOrNull();
  final farm = await FarmRepository(db).getFarm();
  if ((lots.isEmpty && produce.isEmpty) ||
      cached == null ||
      now.difference(cached.fetchedOn) > const Duration(hours: 24) ||
      cached.latitude != farm?.lat ||
      cached.longitude != farm?.lng) {
    await notifications.cancel('drying-rain');
    return;
  }
  final rain = Forecast.parse(cached.payload).hours
      .where(
        (h) =>
            h.date.isAfter(now) &&
            h.date.isBefore(now.add(const Duration(hours: 24))) &&
            (h.chance >= 50 || h.rain >= .5),
      )
      .firstOrNull;
  if (rain == null) {
    await notifications.cancel('drying-rain');
    return;
  }
  var on = rain.date.subtract(const Duration(minutes: 30));
  if (on.isBefore(now)) on = now.add(const Duration(minutes: 1));
  await notifications.schedule(
    'drying-rain',
    l.xRainWarning,
    [...lots.map((l) => l.code), ...produce.map((l) => l.code)].join(', '),
    on,
  );
}

class AppServices {
  AppServices(this.db);
  final AppDatabase db;
  Timer? _debounce;
  StreamSubscription<Set<TableUpdate>>? _subscription;
  bool _running = false, _again = false, _disposed = false;
  Completer<void>? _idle;
  Future<void> start() async {
    if (v1) return;
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      'dhara-background-refresh',
      'refresh',
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
    _subscription = db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.reminders,
            db.stockItems,
            db.stockMovements,
            db.workerTxns,
            db.priceAlerts,
            db.priceSnapshots,
            db.lots,
            db.produceLots,
            db.farms,
            db.weatherCaches,
          ]),
        )
        .listen((_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(seconds: 1), () => _refresh());
        });
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _idle = Completer<void>();
    try {
      do {
        _again = false;
        try {
          await refreshWeather(db);
        } catch (_) {
          /* Offline cache remains available. */
        }
        await refreshAlerts(db);
      } while (_again && !_disposed);
    } catch (error) {
      debugPrint('Farm refresh: ${error.runtimeType}');
    } finally {
      _running = false;
      _idle?.complete();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _debounce?.cancel();
    await _subscription?.cancel();
    await _idle?.future;
  }
}
