import 'dart:io';

import 'package:dhara_mitra/core/farm_profiles.dart';
import 'package:dhara_mitra/core/farm_host.dart';
import 'package:dhara_mitra/features/farm/data/farm_repository.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/auth/account_controller.dart';
import 'package:dhara_mitra/features/auth/account_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.root);
  final Directory root;

  @override
  Future<String> getApplicationDocumentsPath() async => root.path;

  @override
  Future<String> getTemporaryPath() async => root.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('account workspace pages share the opened farm database', (
    tester,
  ) async {
    final originalPaths = PathProviderPlatform.instance;
    final root = Directory.systemTemp.createTempSync('workspace-scope-');
    PathProviderPlatform.instance = _TestPaths(root);
    SharedPreferences.setMockInitialValues({'account.local': true});
    final account = AccountController(await SharedPreferences.getInstance());
    await initializeDateFormatting();
    var cleaned = false;
    Future<void> cleanup() async {
      if (cleaned) return;
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        // FarmHost closes its database asynchronously after service cleanup.
        for (var i = 0; ; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await Future<void>.delayed(const Duration(milliseconds: 50));
          try {
            await root.delete(recursive: true);
            break;
          } on FileSystemException {
            if (i == 99) rethrow;
          }
        }
      });
      account.dispose();
      PathProviderPlatform.instance = originalPaths;
      cleaned = true;
    }

    addTearDown(cleanup);

    await tester.runAsync(() async {
      final session = await FarmSession.open('default');
      await FarmRepository(session.db).saveFarm(
        name: 'Scope test farm',
        village: 'Test village',
        seasonStartMonth: 6,
      );
      await session.db.close();
    });

    await tester.pumpWidget(
      AccountHost(controller: account, localCatalogue: FarmProfiles(root)),
    );
    // Opening the real workspace uses filesystem I/O and a database isolate.
    await tester.runAsync(() async {
      for (
        var i = 0;
        i < 100 && find.textContaining('Scope test farm').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
    expect(find.text('Scope test farm · Test village'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final container = ProviderScope.containerOf(
      tester.element(find.text('Scope test farm · Test village')),
    );
    expect(container.read(accountControllerProvider), same(account));
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        if (container.read(farmProvider).hasValue &&
            container.read(workerSummariesProvider).hasValue &&
            container.read(lotViewsProvider).hasValue) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
    expect(container.read(farmProvider).requireValue?.name, 'Scope test farm');
    expect(container.read(workerSummariesProvider).requireValue, isEmpty);
    expect(container.read(lotViewsProvider).requireValue, isEmpty);
    expect(tester.takeException(), isNull);
    await cleanup();
  });
}
