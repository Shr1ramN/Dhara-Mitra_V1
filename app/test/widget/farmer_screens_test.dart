import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/lots/ui/collections_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  for (final language in ['en', 'kn']) {
    testWidgets('farmer forms fit a narrow phone in $language', (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await db
            .into(db.farms)
            .insert(FarmsCompanion.insert(name: 'My garden'));
        await db
            .into(db.plots)
            .insert(PlotsCompanion.insert(name: 'Upper plot'));
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            initialLanguageProvider.overrideWithValue(language),
          ],
          child: const DharaMitraApp(hasFarm: true),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final route in [
        '/farm',
        '/worker-form',
        '/harvest-form',
        '/collections',
        '/fertilizer',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language $route');
        expect(find.byType(Scaffold), findsWidgets);
      }
      router.go('/collections');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionForm), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    });
  }
  testWidgets('setup does not ask for coordinates', (tester) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DharaMitraApp(hasFarm: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Choose farm on map'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Latitude'), findsNothing);
    expect(find.text('Longitude'), findsNothing);
    expect(find.text('Choose farm on map'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump();
  });
}
