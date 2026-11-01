import 'dart:io';
import 'dart:ui' as ui;

import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/appearance.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/l10n.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/farm/data/farm_crops.dart';
import 'package:drift/drift.dart'
    show DatabaseConnection, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    for (final font in ['Inter', 'NotoSansKannada', 'SpaceGrotesk']) {
      await (FontLoader(font)..addFont(
            rootBundle.load(
              'assets/fonts/$font-${font == 'SpaceGrotesk' ? 'SemiBold' : 'Regular'}.ttf',
            ),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Ahem',
    )..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('V3_SCREENSHOTS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('v3-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await Directory('build/v3-ui').create(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> checkScroll(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 7; i++) {
      final scroll = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      if (scroll.evaluate().isEmpty) break;
      await tester.drag(scroll.first, const Offset(0, -330));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }

  for (final lang in ['en', 'kn']) {
    for (final mode in ThemeMode.values) {
      testWidgets('V3 $lang ${mode.name} fits large text on 320px phones', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 820);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final db = AppDatabase(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        );
        late Worker worker;
        await tester.runAsync(() async {
          await db
              .into(db.farms)
              .insert(FarmsCompanion.insert(name: 'Theme test farm'));
          worker = await db
              .into(db.workers)
              .insertReturning(
                WorkersCompanion.insert(
                  name: 'ರಾಮು',
                  dayRate: const Value(70033),
                ),
              );
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              initialLanguageProvider.overrideWithValue(lang),
              initialThemeModeProvider.overrideWithValue(mode),
              todayProvider.overrideWithValue(DateTime(2026, 11, 1)),
            ],
            child: RepaintBoundary(
              key: const ValueKey('v3-capture'),
              child: const DharaMitraApp(hasFarm: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        for (final route in [
          '/',
          '/labour',
          '/labour?tab=attendance',
          '/labour?tab=dues',
          '/labour?tab=reports',
          '/worker/${worker.id}',
          '/farm',
          '/date-note',
          '/date-note?label=harvest',
          '/more',
          '/backup',
          '/calendar',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(Scaffold).last),
              theme = Theme.of(tester.element(find.byType(Scaffold).last));
          expect(
            theme.brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang ${mode.name} $route',
          );
          if (route == '/more') {
            final l = context.l;
            await tester.scrollUntilVisible(
              find.text(l.exportExcel),
              250,
              scrollable: find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first,
            );
            expect(find.text(l.exportExcel), findsOneWidget);
            for (final removed in [
              l.xPrices,
              l.xWeather,
              l.xReminders,
              l.xSales,
              l.xLoans,
              l.xLand,
              l.xInsurance,
            ]) {
              expect(find.text(removed), findsNothing);
            }
          }
          if (route == '/farm') {
            expect(find.text(context.l.whatDoYouGrow), findsOneWidget);
            expect(find.text(context.l.arecaPalms), findsNothing);
            expect(find.text(context.l.coconutTrees), findsNothing);
          }
          if (route == '/date-note') {
            expect(find.text(context.l.farmActivity), findsOneWidget);
            expect(find.text('Harvest'), findsNothing);
          }
          await screenshot(
            tester,
            '$lang-${mode.name}-${route.replaceAll(RegExp('[^a-z]+'), '-')}',
          );
          await checkScroll(tester);
        }
        // The date opens exactly the three groups, with no individual labour actions.
        await tester.scrollUntilVisible(
          find.text('1'),
          -250,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.ensureVisible(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        final sheet = find.byType(BottomSheet), l = tester.element(sheet).l;
        expect(
          find.descendant(of: sheet, matching: find.byType(ListTile)),
          findsNWidgets(3),
        );
        for (final name in [l.labourManagement, l.farmActivity, l.navHarvest]) {
          expect(
            find.descendant(of: sheet, matching: find.text(name)),
            findsOneWidget,
          );
        }
        await screenshot(tester, '$lang-${mode.name}-date-actions');
        Navigator.of(tester.element(sheet)).pop();
        await tester.pumpAndSettle();
        if (mode == ThemeMode.system) {
          tester.platformDispatcher.platformBrightnessTestValue =
              Brightness.light;
          await tester.pumpAndSettle();
          expect(
            Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
            Brightness.light,
          );
        }
        await tester.pumpWidget(const SizedBox());
        await db.close();
        await tester.pump();
      });
    }
  }
  testWidgets('theme selection saves and is restored after restart', (
    tester,
  ) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DharaMitraApp(hasFarm: true, initialLocation: '/more'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
      Brightness.dark,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(themePreferenceKey), 'dark');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialThemeModeProvider.overrideWithValue(
            parseThemeMode(prefs.getString(themePreferenceKey)),
          ),
        ],
        child: const DharaMitraApp(hasFarm: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
      Brightness.dark,
    );
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump();
  });
  testWidgets('farm setup saves arbitrary crops without mandatory plots', (
    tester,
  ) async {
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
    await tester.enterText(find.byType(TextFormField), 'Mango farm');
    final crop = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Add a crop',
    );
    await tester.ensureVisible(crop);
    await tester.enterText(crop, 'Mango');
    await tester.tap(find.widgetWithText(TextButton, 'Add a crop'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Start using Dhara Mitra');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      expect((await db.select(db.farms).getSingle()).name, 'Mango farm');
      expect(await loadFarmCrops(db), ['Mango']);
      expect(await db.select(db.plots).get(), isEmpty);
    });
    expect(find.textContaining('Namaskara'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
    await tester.pump();
  });
}
