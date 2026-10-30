import 'package:dhara_mitra/core/l10n.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/core/theme.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:dhara_mitra/features/calendar/farm_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Future<void> pumpCalendar(
    WidgetTester tester, {
    String language = 'en',
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayProvider.overrideWithValue(DateTime(2026, 10, 29)),
          calendarRecordsProvider.overrideWith(
            (ref) => Stream.value([
              CalendarRecord(
                '1',
                DateTime(2026, 10, 29),
                'activity',
                'Manure north',
                '',
                '/',
              ),
              CalendarRecord(
                '2',
                DateTime(2026, 10, 28),
                'activity',
                'Manure south',
                '',
                '/',
              ),
              CalendarRecord(
                '3',
                DateTime(2026, 9, 29),
                'expense',
                'Manure bill',
                '',
                '/',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const FarmCalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  for (final keyboard in [true, false]) {
    testWidgets('search submission reveals results: keyboard=$keyboard', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await tester.enterText(find.byType(TextField), 'manure south');
      if (keyboard) {
        await tester.testTextInput.receiveAction(TextInputAction.search);
      } else {
        await tester.tap(find.widgetWithIcon(IconButton, Icons.search_rounded));
      }
      await tester.pumpAndSettle();
      expect(find.text('Manure south'), findsOneWidget);
      expect(find.text('Manure north'), findsNothing);
      expect(find.text('Matching records').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('narrow calendar search, date scope and reset stay consistent', (
    tester,
  ) async {
    await pumpCalendar(tester);
    expect(find.text('Every day tells a story.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'manure');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Manure south'));
    expect(find.text('Manure north'), findsOneWidget);
    expect(find.text('Manure south'), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('28')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Manure south'));
    expect(find.text('Manure north'), findsNothing);
    expect(find.text('Manure south'), findsOneWidget);
    await reveal(tester, find.text('Reset filters'));
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('Reset filters'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category combines with search and clearing search keeps category',
    (tester) async {
      await pumpCalendar(tester);
      await tester.enterText(find.byType(TextField), 'manure');
      await tester.pumpAndSettle();
      final activity = find.widgetWithText(ChoiceChip, 'Work');
      await Scrollable.ensureVisible(tester.element(activity), alignment: 0.5);
      await tester.tap(activity);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Manure south'));
      expect(find.text('Manure bill'), findsNothing);
      expect(find.text('Manure south'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TextField),
        -240,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byType(TextField)),
        alignment: 0.5,
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(activity).selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month navigation updates agenda and Kannada fits narrow screen',
    (tester) async {
      await pumpCalendar(tester);
      await reveal(tester, find.byTooltip('Previous month'));
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Manure bill'));
      expect(find.text('Manure bill'), findsOneWidget);
      expect(find.text('Manure north'), findsNothing);
      expect(tester.takeException(), isNull);
      await pumpCalendar(tester, language: 'kn');
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
