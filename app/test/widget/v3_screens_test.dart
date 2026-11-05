import 'dart:async';
import 'dart:convert';

import 'package:dhara_mitra/features/backup/excel_export.dart';
import 'package:excel/excel.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/appearance.dart';
import 'package:dhara_mitra/features/calendar/date_note.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
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
          '/date-note?label=sale',
          '/more',
          '/backup',
          '/calendar',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(Scaffold).last),
              theme = Theme.of(tester.element(find.byType(Scaffold).last));
          expect(
            theme.textTheme.titleLarge!.color!.computeLuminance(),
            mode == ThemeMode.light ? lessThan(0.2) : greaterThan(0.6),
          );
          expect(
            theme.brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang ${mode.name} $route',
          );
          expect(
            recordTitle(
              context,
              CalendarRecord(
                'id',
                DateTime(2026),
                'attendance',
                'Ramu half',
                '',
                '',
              ),
            ),
            lang == 'en' ? 'Ramu · Half day' : 'Ramu · ಅರ್ಧ ದಿನ',
          );
          expect(translatedLabel(context, 'My custom work'), 'My custom work');
          expect(
            recordTitle(
              context,
              CalendarRecord(
                'id',
                DateTime(2026),
                'note',
                'Spray',
                '',
                '',
                rawNotes: '$notePrefix{"labelSource":"custom"}',
              ),
            ),
            'Spray',
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
          if (route == '/date-note?label=sale') {
            expect(
              find.text(lang == 'en' ? 'Sold to Buyer' : 'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ'),
              findsOneWidget,
            );
            expect(
              find.text(lang == 'en' ? 'What was done?' : 'ಏನು ಮಾಡಲಾಯಿತು?'),
              findsNothing,
            );
          }
          if (route == '/date-note?label=harvest') {
            expect(find.text(context.l.navHarvest), findsOneWidget);
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
          findsNWidgets(5),
        );
        for (final name in [l.labourManagement, l.farmActivity, l.navHarvest, l.farmPurchases]) {
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
    await tester.tap(find.byTooltip('Add a crop'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Name',
      ),
      'Mango',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
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
  testWidgets(
    'crop sale records buyer, quantity and exact income without changing wages',
    (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DharaMitraApp(hasFarm: true),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      unawaited(router.push('/date-note?label=sale'));
      await tester.pumpAndSettle();
      Future<void> enter(String label, String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Add crop'));
      await tester.pumpAndSettle();
      await enter('Name', 'Mango');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      await enter('Quantity', '3.5');
      await enter('Sold to whom?', 'Local buyer');
      await enter('Total income received (₹)', '1234.56');
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final row = await db.select(db.reminders).getSingle();
        final data = noteValues(row.notes);
        expect(row.title, 'sale');
        expect(data['incomePaise'], 123456);
        expect(data['buyer'], 'Local buyer');
        expect(data['crop'], 'Mango');
        expect(data['quantity'], 3.5);
        expect(data['unit'], 'kg');
        expect(await db.select(db.workerTxns).get(), isEmpty);
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    },
  );
  testWidgets(
    'multiple crops share one buyer and one exact income; Excel keeps crop items',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.runAsync(
        () => db.putSetting('my_crops', jsonEncode(['Mango', 'Pepper'])),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DharaMitraApp(
            hasFarm: true,
            initialLocation: '/date-note?label=sale',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What was done?'), findsNothing);
      await tester.tap(find.widgetWithText(InputChip, 'Mango'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InputChip, 'Pepper'));
      await tester.pumpAndSettle();
      final fields = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Quantity',
      );
      await tester.enterText(fields.at(0), '3.5');
      await tester.enterText(fields.at(1), '2');
      await tester.tap(find.text('Bags').last);
      await tester.pumpAndSettle();
      for (final entry in [
        ('Sold to whom?', 'Buyer one'),
        ('Total income received (₹)', '1111.11'),
      ]) {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == entry.$1,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.$2);
      }
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final row = await db.select(db.reminders).getSingle();
        final data = noteValues(row.notes);
        expect(data['buyer'], 'Buyer one');
        expect(data['incomePaise'], 111111);
        expect((data['items'] as List).length, 2);
        expect((data['items'] as List)[0], {
          'crop': 'Mango',
          'quantity': 3.5,
          'unit': 'kg',
        });
        expect((data['items'] as List)[1], {
          'crop': 'Pepper',
          'quantity': 2.0,
          'unit': 'bags',
        });
        final book = Excel.decodeBytes(await FarmExcelExport(db).bytes());
        expect(book['SaleItems'].rows.length, 3);
        expect(book['Income'].rows.length, 2);
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    },
  );
  testWidgets(
    'clean forms navigate directly; dirty forms keep or discard without touching saved records',
    (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DharaMitraApp(
            hasFarm: true,
            initialLocation: '/worker-form',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      await tester.tap(find.widgetWithText(NavigationDestination, 'Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsNothing);
      expect(router.state.uri.path, '/calendar');
      router.go('/worker-form');
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Name',
      );
      await tester.enterText(name, 'Unsaved worker');
      await tester.tap(find.widgetWithText(NavigationDestination, 'Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved worker'), findsOneWidget);
      unawaited(tester.binding.handlePopRoute());
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard and leave'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/calendar');
      await tester.runAsync(() async {
        expect(await db.select(db.workers).get(), isEmpty);
      });
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    },
  );
  testWidgets(
    'long press removes a suggestion permanently while records remain',
    (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.runAsync(() async {
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: 'Spray',
                dueOn: DateTime(2026, 11, 1),
                kind: const Value('dateNote'),
                notes: const Value('Old spray record'),
              ),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DharaMitraApp(
            hasFarm: true,
            initialLocation: '/date-note',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.widgetWithText(InputChip, 'Spray'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'Spray'), findsNothing);
      await tester.runAsync(() async {
        expect(
          (await db.select(db.reminders).getSingle()).notes,
          'Old spray record',
        );
        expect(
          jsonDecode((await db.setting('hidden_work_labels'))!),
          contains('spray'),
        );
      });
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/');
      await tester.pumpAndSettle();
      router.go('/date-note');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'Spray'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    },
  );
  testWidgets(
    'crop delete works across farm, harvest, activity and sales without deleting history',
    (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.runAsync(() async {
        await db
            .into(db.farms)
            .insert(FarmsCompanion.insert(name: 'Crop test farm'));
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: 'Harvest',
                dueOn: DateTime(2026, 11, 1),
                kind: const Value('dateNote'),
                notes: Value(
                  notePrefix +
                      jsonEncode({
                        'crop': 'Mango',
                        'quantity': 10,
                        'unit': 'bags',
                      }),
                ),
              ),
            );
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: 'sale',
                dueOn: DateTime(2026, 11, 1),
                kind: const Value('dateNote'),
                notes: Value(
                  notePrefix +
                      jsonEncode({
                        'crop': 'Mango',
                        'quantity': 2,
                        'unit': 'bags',
                        'buyer': 'Original buyer',
                        'incomePaise': 12345,
                      }),
                ),
              ),
            );
      });
      final old = await tester.runAsync(() => db.select(db.reminders).get());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DharaMitraApp(hasFarm: true),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final route in [
        '/farm',
        '/date-note?label=harvest',
        '/date-note',
        '/date-note?label=sale',
      ]) {
        await tester.runAsync(
          () => db.putSetting('my_crops', jsonEncode(['Mango', 'Pepper'])),
        );
        unawaited(router.push(route));
        await tester.pumpAndSettle();
        final chip = find.widgetWithText(InputChip, 'Mango');
        await tester.scrollUntilVisible(
          chip,
          200,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        final remove = find.descendant(
          of: chip,
          matching: find.byTooltip('Delete'),
        );
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(chip, findsOneWidget);
        await tester.longPress(chip);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(chip, findsNothing);
        if (route == '/farm') {
          final save = find.widgetWithText(FilledButton, 'Save');
          await tester.scrollUntilVisible(
            save,
            200,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.runAsync(() async {
          expect(await loadFarmCrops(db), ['Pepper']);
          final now = await db.select(db.reminders).get();
          expect(
            now.map((r) => r.notes).toList(),
            old!.map((r) => r.notes).toList(),
          );
        });
        router.go('/');
        await tester.pumpAndSettle();
      }
      router.go('/more');
      await tester.pumpAndSettle();
      expect(find.text('Tutorial'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    },
  );
}
