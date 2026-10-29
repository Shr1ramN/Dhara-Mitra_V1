import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../features/auth/account_controller.dart';
import 'db/database.dart';
import 'providers.dart';
import 'farm_profiles.dart';
import 'farm_deletion.dart';
import 'app_services.dart';
import 'notifications.dart';
import '../features/farm/data/farm_repository.dart';
import '../features/farm/ui/farms_screen.dart';
import '../features/security/security.dart';

class FarmSession {
  FarmSession(this.db, this.language, this.hasFarm, this.locked);
  final AppDatabase db;
  final String language;
  final bool hasFarm, locked;
  static Future<FarmSession> open(
    String id, {
    String language = 'en',
    bool locked = false,
  }) async {
    final db = AppDatabase.onDevice(profileId: id);
    try {
      if (await db.setting(languageSetting) == null) {
        await db.putSetting(languageSetting, language);
      }
      if (await db.setting('app_lock') == null) {
        await db.putSetting('app_lock', '$locked');
      }
      return FarmSession(
        db,
        (await db.setting(languageSetting))!,
        await FarmRepository(db).getFarm() != null,
        await db.setting('app_lock') == 'true',
      );
    } catch (_) {
      await db.close();
      rethrow;
    }
  }
}

class FarmHost extends StatefulWidget {
  const FarmHost({
    super.key,
    required this.initial,
    required this.catalogue,
    this.initialLocation,
    this.accountController,
  });
  final FarmSession initial;
  final FarmProfiles catalogue;
  final String? initialLocation;
  final AccountController? accountController;
  @override
  State<FarmHost> createState() => _FarmHostState();
}

class _FarmHostState extends State<FarmHost> {
  late FarmSession _session = widget.initial;
  late AppServices _services;
  late Future<void> _starting;
  bool _switching = false;
  bool _deleting = false;
  String? _previousFarm;
  @override
  void initState() {
    super.initState();
    _startServices();
  }

  void _startServices() {
    _services = AppServices(_session.db);
    _starting = _services.start().catchError((Object error) {
      debugPrint('Background setup: ${error.runtimeType}');
    });
    unawaited(_starting);
  }

  Future<void> _switch(String id) async {
    if (_switching) return;
    _switching = true;
    FarmSession? next;
    var installed = false;
    try {
      next = await FarmSession.open(
        id,
        language: await _session.db.setting(languageSetting) ?? 'en',
        locked: await _session.db.setting('app_lock') == 'true',
      );
      if (!next.hasFarm) {
        _previousFarm = _session.db.profileId;
      }
      await widget.catalogue.select(id);
      await _starting;
      await _services.dispose();
      final old = _session;
      if (!mounted) return;
      setState(() => _session = next!);
      installed = true;
      _startServices();
      await WidgetsBinding.instance.endOfFrame;
      await old.db.close();
    } finally {
      if (!installed) await next?.db.close();
      _switching = false;
    }
  }

  Future<bool> _returnToFarm() async {
    if (_switching || _deleting) return true;
    final state = await widget.catalogue.read();
    if (_previousFarm != null &&
        _previousFarm != _session.db.profileId &&
        state.ids.contains(_previousFarm)) {
      await _switch(_previousFarm!);
      return true;
    }
    final candidates = [
      ...state.ids.where(
        (id) => id != _session.db.profileId && id != _previousFarm,
      ),
    ];
    for (final id in candidates) {
      final db = AppDatabase.onDevice(profileId: id);
      bool hasFarm;
      try {
        hasFarm = await FarmRepository(db).getFarm() != null;
      } finally {
        await db.close();
      }
      if (hasFarm) {
        await _switch(id);
        return true;
      }
    }
    return false;
  }

  Future<void> _deleteFarm(String id) async {
    if (_deleting || _switching) throw StateError('Farm operation in progress');
    setState(() => _deleting = true);
    try {
      await _performDelete(id);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _performDelete(String id) async {
    final state = await widget.catalogue.read();
    if (!state.ids.contains(id)) throw ArgumentError('Unknown farm');
    if (_session.db.profileId == id) {
      final remaining = state.ids.where((item) => item != id);
      await _switch(
        remaining.isEmpty ? await widget.catalogue.add() : remaining.first,
      );
    }
    if (_session.db.profileId == id) throw StateError('Farm is still open');
    final db = AppDatabase.onDevice(profileId: id);
    try {
      await FarmNotifications(db).cancelProfiles({id});
      await deleteFarmData(widget.catalogue, db);
    } finally {
      await db.close();
    }
  }

  @override
  void dispose() {
    final session = _session;
    final services = _services;
    final starting = _starting;
    unawaited(() async {
      try {
        await starting;
        await services.dispose();
        final profiles = (await widget.catalogue.read()).ids.toSet();
        await FarmNotifications(session.db).cancelProfiles(profiles);
      } catch (error) {
        debugPrint('Workspace cleanup: ${error.runtimeType}');
      } finally {
        await session.db.close();
      }
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ObjectKey(_session),
    overrides: [
      // Keep account and farm dependencies in one root scope. Unscoped
      // repository providers otherwise resolve in an ancestor container.
      accountControllerProvider.overrideWithValue(widget.accountController),
      databaseProvider.overrideWithValue(_session.db),
      farmCatalogueProvider.overrideWithValue(Future.value(widget.catalogue)),
      initialLanguageProvider.overrideWithValue(_session.language),
      initialLockProvider.overrideWithValue(_session.locked),
      switchFarmProvider.overrideWithValue(_switch),
      returnToFarmProvider.overrideWithValue(_returnToFarm),
      deleteFarmProvider.overrideWithValue(_deleteFarm),
    ],
    child: AbsorbPointer(
      absorbing: _deleting,
      child: DharaMitraApp(
        hasFarm: _session.hasFarm,
        initialLocation: widget.initialLocation,
      ),
    ),
  );
}
