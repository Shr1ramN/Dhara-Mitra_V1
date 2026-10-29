import 'dart:io';

import 'package:dhara_mitra/core/farm_host.dart';
import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/farm/data/farm_repository.dart';
import 'package:dhara_mitra/features/farm/ui/farms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String> getApplicationDocumentsPath() async => path;
  @override
  Future<String> getTemporaryPath() async => path;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });
  testWidgets(
    'new farm Back restores the previous session; active and last farm deletion switch safely',
    (tester) async {
      final originalPaths = PathProviderPlatform.instance;
      final root = Directory.systemTemp.createTempSync('farm-host-');
      PathProviderPlatform.instance = _Paths(root.path);
      const notifications = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (call) async {
          if (call.method == 'pendingNotificationRequests') return <dynamic>[];
          return true;
        },
      );
      await initializeDateFormatting();
      final catalogue = FarmProfiles(root);
      late FarmSession initial;
      await tester.runAsync(() async {
        final seed = await FarmSession.open('default');
        await FarmRepository(seed.db)
            .saveFarm(name: 'Original farm', village: '', seasonStartMonth: 6);
        await seed.db.close();
        initial = await FarmSession.open('default');
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 100; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump(const Duration(milliseconds: 50));
            try {
              await root.delete(recursive: true);
              break;
            } on FileSystemException {
              if (attempt == 99) rethrow;
            }
          }
        });
        PathProviderPlatform.instance = originalPaths;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          notifications,
          null,
        );
      });
      await tester.pumpWidget(FarmHost(initial: initial, catalogue: catalogue));
      Future<void> operate(Future<void> Function() action) async {
        await tester.runAsync(() async {
          var done = false;
          final operation = action().whenComplete(() => done = true);
          for (var attempt = 0; !done && attempt < 200; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump(const Duration(milliseconds: 20));
          }
          expect(done, isTrue, reason: 'Farm operation did not finish');
          await operation;
        });
        await tester.pumpAndSettle();
      }

      ProviderContainer container() => ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      late String draft;
      await operate(() async {
        draft = await catalogue.add();
        await container().read(switchFarmProvider)(draft);
      });
      expect(container().read(databaseProvider).profileId, draft);
      await operate(() async {
        await tester.binding.handlePopRoute();
      });
      expect(container().read(databaseProvider).profileId, 'default');
      await operate(() => container().read(deleteFarmProvider)(draft));
      await operate(() async {
        expect((await catalogue.read()).ids, ['default']);
      });
      await operate(() => container().read(deleteFarmProvider)('default'));
      expect(container().read(databaseProvider).profileId, isNot('default'));
      await operate(() async {
        final state = await catalogue.read();
        expect(state.ids, [state.active]);
        expect(state.active, container().read(databaseProvider).profileId);
        expect(
          await FarmRepository(container().read(databaseProvider)).getFarm(),
          isNull,
        );
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 5; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
    },
  );
}
