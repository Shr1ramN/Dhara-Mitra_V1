import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/features/farm/data/farm_repository.dart';
import 'package:dhara_mitra/features/lots/data/lots_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting();
  });

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required bool hasFarm,
    String language = 'en',
    String? initialLocation,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialLanguageProvider.overrideWithValue(language),
          todayProvider.overrideWithValue(DateTime(2026, 11, 20)),
        ],
        child: DharaMitraApp(
          hasFarm: hasFarm,
          initialLocation: initialLocation,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump();
  }

  testWidgets('first run opens farm setup', (tester) async {
    await pumpApp(tester, hasFarm: false);
    expect(find.text('Set up your farm'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start using Dhara Mitra'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Start using Dhara Mitra'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('welcome restore returns to offline setup', (tester) async {
    await pumpApp(tester, hasFarm: false, initialLocation: '/backup');
    expect(find.text('Backup & restore'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Set up your farm'), findsOneWidget);
    expect(find.byTooltip('Account'), findsNothing);
    expect(find.byTooltip('Backup and restore'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('home, calendar and more tabs open', (tester) async {
    final farm = FarmRepository(db);
    await tester.runAsync(() async {
      await farm.saveFarm(
        name: 'Bhat Thota',
        village: 'Kemminje',
        seasonStartMonth: 6,
      );
      await farm.savePlot(
        PlotsCompanion.insert(name: 'Upper plot', acres: const Value(1.5)),
      );
    });
    await pumpApp(tester, hasFarm: true);

    expect(find.textContaining('Namaskara'), findsOneWidget);
    expect(find.text('Bhat Thota · Kemminje'), findsOneWidget);
    expect(find.text('Bhat Thota'), findsNothing);
    expect(find.byKey(const ValueKey('app-home')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_month_outlined), findsWidgets);
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Export database'), 400);
    expect(find.text('Export database'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('lot detail and sale form render a lot mid-journey', (
    tester,
  ) async {
    late String lotId;
    await tester.runAsync(() async {
      await FarmRepository(db)
          .saveFarm(name: 'Bhat Thota', village: '', seasonStartMonth: 6);
      final lots = LotsRepository(db);
      lotId = await lots.createHarvestLot(
        crop: Crop.areca,
        harvestedOn: DateTime(2026, 10, 1),
        title: 'Harvest round 1',
        plotIds: const [],
        palmsClimbed: 400,
      );
      await lots.startDrying(
        lotId,
        on: DateTime(2026, 10, 2),
        yard: 'Main yard',
      );
      await lots.addEvent(lotId, LotEventKind.cover);
    });
    await pumpApp(tester, hasFarm: true);

    await tester.scrollUntilVisible(find.text('Day 50 of ~40'), 200);
    expect(find.text('Day 50 of ~40'), findsOneWidget);
    await tester.tap(find.text('Harvest round 1').first);
    await tester.pumpAndSettle();
    expect(find.text('A-2627-01'), findsWidgets);
    expect(find.text('Drying finished'), findsOneWidget);

    await tester.runAsync(() async {
      final lots = LotsRepository(db);
      await lots.finishDrying(lotId, on: DateTime(2026, 10, 20), driedKg: 800);
      await lots.recordPeeling(lotId, on: DateTime(2026, 10, 25), chaliKg: 600);
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('75.0%'), 300);
    expect(find.text('75.0%'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Record sale'), 300);
    await tester.tap(find.text('Record sale'));
    await tester.pumpAndSettle();
    expect(find.text('What was sold'.toUpperCase()), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Kannada labels show when Kannada is chosen', (tester) async {
    await pumpApp(tester, hasFarm: false, language: 'kn');
    expect(find.text('Set up your farm'), findsNothing);
    await tearDownApp(tester);
  });
}
