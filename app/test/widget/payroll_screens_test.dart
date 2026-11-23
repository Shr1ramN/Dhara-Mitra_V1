import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/enums.dart';
import 'package:dhara_mitra/core/l10n.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/core/theme.dart';
import 'package:dhara_mitra/core/v1.dart';
import 'package:dhara_mitra/features/calendar/date_note.dart';
import 'package:dhara_mitra/features/labour/data/labour_repository.dart';
import 'package:dhara_mitra/features/labour/ui/attendance_tab.dart';
import 'package:dhara_mitra/features/labour/ui/payroll_screens.dart';
import 'package:drift/drift.dart'
    show DatabaseConnection, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final defaults = FontLoader('Ahem')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    await defaults.load();
    for (final font in ['Inter', 'NotoSansKannada', 'SpaceGrotesk']) {
      final loader = FontLoader(font)
        ..addFont(
          rootBundle.load(
            'assets/fonts/$font-${font == 'SpaceGrotesk' ? 'SemiBold' : 'Regular'}.ttf',
          ),
        );
      await loader.load();
    }
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('PAYROLL_SCREENSHOTS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await Directory('build/payroll-ui').create(recursive: true);
      await File('${dir.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> scrollCheck(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 8; i++) {
      final scroll = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first;
      if (scroll.evaluate().isEmpty) break;
      await tester.drag(scroll, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }

  testWidgets(
    'other worker requires actual wage and saves exact half-day pay',
    (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      await tester.runAsync(() async {
        await db
            .into(db.workers)
            .insert(
              WorkersCompanion.insert(
                name: 'Variable',
                wageType: const Value('other'),
              ),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildTheme(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: AttendanceTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final half = find.byType(ChoiceChip).at(1);
      await tester.ensureVisible(half);
      await tester.tap(half);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect(await db.select(db.attendanceEntries).get(), isEmpty);
      });
      await tester.enterText(find.byType(TextFormField), '333.33');
      await tester.ensureVisible(half);
      await tester.tap(half);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect(
          (await db.select(db.attendanceEntries).getSingle()).amount,
          33333,
        );
      });
      expect(find.textContaining('₹333.33'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
      await tester.pump();
    },
  );

  for (final lang in ['en', 'kn']) {
    testWidgets('populated farm search and attendance work in $lang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      final today = DateTime(2026, 10, 31);
      final workerName = lang == 'kn' ? 'ಕೆಲಸಗಾರ 01' : 'Worker 01';
      final lot = lang == 'kn' ? 'ಉತ್ತರದ ಅಡಿಕೆ' : 'North arecanut';
      await tester.runAsync(() async {
        await db.into(db.farms).insert(FarmsCompanion.insert(name: 'Malnad'));
        final workers = [
          for (var i = 1; i <= 24; i++)
            WorkersCompanion.insert(
              name:
                  "${lang == 'kn' ? 'ಕೆಲಸಗಾರ' : 'Worker'} ${i.toString().padLeft(2, '0')}",
              dayRate: const Value(60000),
            ),
        ];
        await db.batch((batch) => batch.insertAll(db.workers, workers));
        final savedWorkers = await db.select(db.workers).get();
        final labour = LabourRepository(db);
        for (var day = 1; day <= 30; day++) {
          await labour.saveAttendance(DateTime(2026, 10, day), {
            for (final worker in savedWorkers)
              worker.id: const AttendanceMark(AttendanceStatus.present),
          });
        }
        await db.batch(
          (batch) => batch.insertAll(db.reminders, [
            for (var day = 1; day <= 30; day++)
              for (final (title, fields) in <(String, Map<String, Object>)>[
                ('Irrigation', {'crop': lot, 'description': 'Upper plot'}),
                ('Harvest', {'crop': lot, 'quantity': 12, 'unit': 'bags'}),
                ('sale', {'crop': lot, 'buyer': 'Ravi', 'incomePaise': 125025}),
                ('purchase', {'item': 'Seed', 'costPaise': 50010}),
              ])
                RemindersCompanion.insert(
                  title: title,
                  dueOn: DateTime(2026, 10, day),
                  kind: const Value('dateNote'),
                  done: const Value(true),
                  notes: Value(notePrefix + jsonEncode(fields)),
                ),
          ]),
        );
        await db.putSetting(
          'attendance.work.2026-10-30T00:00:00.000',
          'Previous day work',
        );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            initialLanguageProvider.overrideWithValue(lang),
            todayProvider.overrideWithValue(today),
          ],
          child: const DharaMitraApp(hasFarm: true),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go('/calendar?category=harvest');
      await tester.pumpAndSettle();
      final count = find.widgetWithText(Chip, '30');
      expect(count.hitTestable(), findsOneWidget);
      final search = find.byType(TextField);
      await tester.ensureVisible(search);
      await tester.enterText(search, lot);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(count.hitTestable(), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
      final attendance = find.text(lang == 'kn' ? 'ಹಾಜರಾತಿ' : 'Attendance');
      await tester.ensureVisible(attendance);
      await tester.tap(attendance);
      await tester.pumpAndSettle();
      final previous = find.widgetWithIcon(IconButton, Icons.chevron_left);
      final goBackOneDay = tester.widget<IconButton>(previous).onPressed!;
      goBackOneDay();
      goBackOneDay();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Previous day work',
      );
      final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
      await tester.tap(next);
      await tester.pumpAndSettle();
      final firstWorker = find
          .ancestor(of: find.text(workerName), matching: find.byType(Card))
          .first;
      final half = find
          .descendant(of: firstWorker, matching: find.byType(ChoiceChip))
          .at(1);
      await tester.ensureVisible(half);
      await tester.pumpAndSettle();
      await tester.tap(half);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final attendance = await db.select(db.attendanceEntries).get();
        expect(attendance, hasLength(721));
        final saved = attendance.singleWhere((entry) => entry.date == today);
        expect(saved.status, AttendanceStatus.half);
        expect(saved.amount, 30000);
        expect(saved.work, isEmpty);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await db.close();
    });

    testWidgets('labour and calendar fit 320px with enlarged text in $lang', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 820);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
            .insert(FarmsCompanion.insert(name: 'Test farm'));
        worker = await db
            .into(db.workers)
            .insertReturning(
              WorkersCompanion.insert(
                name: lang == 'kn' ? 'ರಾಮಚಂದ್ರ ಗೌಡ' : 'Ramachandra Gowda',
                dayRate: const Value(70033),
              ),
            );
        await db
            .into(db.workers)
            .insert(
              WorkersCompanion.insert(
                name: lang == 'kn' ? 'ಲಕ್ಷ್ಮೀ' : 'Lakshmi',
                wageType: const Value('other'),
              ),
            );
        await LabourRepository(db).saveAttendance(DateTime(2026, 10, 26), {
          worker.id: const AttendanceMark(AttendanceStatus.present),
        });
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                title: 'Irrigation',
                dueOn: DateTime(2026, 11, 1),
                kind: const Value('dateNote'),
                done: const Value(true),
              ),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            initialLanguageProvider.overrideWithValue(lang),
            todayProvider.overrideWithValue(DateTime(2026, 11, 1)),
          ],
          child: RepaintBoundary(
            key: const ValueKey('capture'),
            child: DharaMitraApp(hasFarm: true),
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
        '/worker-form',
        '/date-note?label=purchase',
        '/my-crops',
        '/more',
        '/calendar',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $route');
        if (route == '/') {
          final recent = find
              .ancestor(
                of: find.text(lang == 'kn' ? 'ಇತ್ತೀಚಿನ ಕೆಲಸ' : 'Recent work'),
                matching: find.byType(Column),
              )
              .first;
          expect(
            find.descendant(of: recent, matching: find.text('1')),
            findsOneWidget,
          );
          final amount = find.text('₹700.33').first;
          final paragraph = tester.renderObject<RenderParagraph>(amount);
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 7),
          );
          expect(
            boxes.map((b) => b.top).toSet().length,
            1,
            reason: 'A money amount must stay on one line',
          );
        }
        await capture(
          tester,
          '$lang-${route.replaceAll(RegExp('[^a-z]+'), '-')}',
        );
        await scrollCheck(tester);
      }
      await tester.pumpWidget(const SizedBox());
      await db.close();
      await tester.pump();
    });
    testWidgets(
      'settlement loan and harvest forms wrap in $lang at large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 820);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        );
        late Worker worker;
        await tester.runAsync(() async {
          worker = await db
              .into(db.workers)
              .insertReturning(
                WorkersCompanion.insert(
                  name: 'Worker',
                  dayRate: const Value(70000),
                ),
              );
        });
        for (final item in <(String, Widget)>[
          (
            'purchase',
            DateNoteEditor(date: DateTime(2026, 11, 5), suggested: 'purchase'),
          ),
          ('settlement', SettlementForm(worker: worker)),
          ('loan', WorkerLoanForm(worker: worker)),
          (
            'harvest',
            DateNoteEditor(
              date: DateTime(2026, 10, 26),
              suggested: lang == 'kn' ? 'ಕೊಯ್ಲು' : 'Harvest',
            ),
          ),
        ]) {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey(item.$1),
              overrides: [databaseProvider.overrideWithValue(db)],
              child: RepaintBoundary(
                key: const ValueKey('capture'),
                child: MaterialApp(
                  locale: Locale(lang),
                  theme: buildTheme(),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(1.4)),
                    child: child!,
                  ),
                  home: item.$2,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await capture(tester, '$lang-${item.$1}');
          await scrollCheck(tester);
        }
        await tester.pumpWidget(const SizedBox());
        await db.close();
        await tester.pump();
      },
    );
  }
  testWidgets('half-day tap autosaves immediately and survives reopening', (
    tester,
  ) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    late Worker worker;
    await tester.runAsync(() async {
      worker = await db
          .into(db.workers)
          .insertReturning(
            WorkersCompanion.insert(
              name: 'Worker',
              dayRate: const Value(70000),
            ),
          );
    });
    Widget app() => ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        entryDayProvider.overrideWithValue(DateTime(2026, 10, 26)),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AttendanceTab()),
      ),
    );
    // Choose the date through the provider after its notifier has been built.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final chip = find.byType(ChoiceChip).at(1);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final entry = await db.select(db.attendanceEntries).getSingle();
      expect(entry.workerId, worker.id);
      expect(entry.status, AttendanceStatus.half);
      expect(entry.amount, 35000);
    });
    expect(find.text('Save attendance'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(1)).selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump();
  });
}
