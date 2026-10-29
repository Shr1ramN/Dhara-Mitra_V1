import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart' show OrderingTerm, BooleanExpressionOperators;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'db/database.dart';
import 'l10n.dart';

int notificationId(String key) {
  var hash = 2166136261;
  for (final value in key.codeUnits) {
    hash = ((hash ^ value) * 16777619) & 0x7fffffff;
  }
  return hash;
}

class FarmNotifications {
  FarmNotifications(this.db);
  final AppDatabase db;
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'farm_reminders',
      'Dhara Mitra',
      channelDescription: 'Farm tasks and drying alerts',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_leaf'),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final allowed = await android?.requestNotificationsPermission() ?? false;
    await db.putSetting('notifications_enabled', allowed.toString());
    return allowed;
  }

  Future<void> show(String key, String title, String body) async {
    if (await db.setting('notifications_enabled') != 'true') return;
    await initialize();
    await _plugin.show(
      id: notificationId('${db.profileId}:$key'),
      title:
          '${(await db.select(db.farms).get()).firstOrNull?.name ?? ''} · $title',
      body: body,
      notificationDetails: details,
      payload: '${db.profileId}:alert:$key',
    );
  }

  Future<void> cancel(String key) async {
    await initialize();
    await _plugin.cancel(id: notificationId('${db.profileId}:$key'));
  }

  /// Stop scheduled alerts from the catalogue that has just been signed out.
  Future<void> cancelProfiles(Set<String> profiles) async {
    await initialize();
    for (final request in await _plugin.pendingNotificationRequests()) {
      final profile = (request.payload ?? '').split(':').first;
      if (profiles.contains(profile)) await _plugin.cancel(id: request.id);
    }
  }

  Future<void> schedule(
    String key,
    String title,
    String body,
    DateTime date, {
    String? payload,
    bool daily = false,
  }) async {
    if (await db.setting('notifications_enabled') != 'true') return;
    await initialize();
    await _plugin.zonedSchedule(
      id: notificationId('${db.profileId}:$key'),
      title:
          '${(await db.select(db.farms).get()).firstOrNull?.name ?? ''} · $title',
      body: body,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '${db.profileId}:${payload ?? key}',
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
    );
  }

  Future<void> syncReminders() async {
    if (await db.setting('notifications_enabled') != 'true') return;
    await initialize();
    final reminders =
        await (db.select(db.reminders)
              ..where((r) => r.deleted.equals(false) & r.done.equals(false))
              ..orderBy([(r) => OrderingTerm.asc(r.dueOn)]))
            .get();
    final l = await AppLocalizations.delegate.load(
      Locale(await db.setting('language') ?? 'en'),
    );
    final ids = reminders
        .map((r) => notificationId('${db.profileId}:reminder:${r.id}'))
        .toSet();
    final pendingIds = (await _plugin.pendingNotificationRequests())
        .map((request) => request.id)
        .toSet();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (db.profileId == 'default' &&
          ((pending.payload ?? '').startsWith('reminder:') ||
              pending.id == notificationId('worker-dues') ||
              pending.id == notificationId('drying-rain'))) {
        await _plugin.cancel(id: pending.id);
        continue;
      }
      if ((pending.payload ?? '').startsWith('${db.profileId}:reminder:') &&
          !ids.contains(pending.id)) {
        await _plugin.cancel(id: pending.id);
      }
    }
    final now = DateTime.now();
    for (final reminder in reminders.take(100)) {
      final key = 'reminder:${reminder.id}';
      final revision = reminder.updatedAt.toIso8601String();
      if (await db.setting('scheduled.$key') == revision &&
          pendingIds.contains(notificationId('${db.profileId}:$key'))) {
        continue;
      }
      var on = tz.TZDateTime(
        tz.local,
        reminder.dueOn.year,
        reminder.dueOn.month,
        reminder.dueOn.day,
        9,
      );
      if (on.isBefore(now)) {
        on = tz.TZDateTime.from(now.add(const Duration(minutes: 1)), tz.local);
      }
      await schedule(
        key,
        reminder.title,
        [
          l.xReminders,
          if (reminder.amount != null) Formats('en', l).money(reminder.amount!),
          reminder.notes,
        ].join(' · '),
        on,
        payload: key,
      );
      await db.putSetting('scheduled.$key', revision);
    }
  }
}
