import 'dart:convert';

import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/l10n.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/core/theme.dart';
import 'package:dhara_mitra/features/calendar/calendar_records.dart';
import 'package:dhara_mitra/features/calendar/date_note.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);
  for (final lang in ['en', 'kn']) {
    testWidgets(
      'purchase saves required item, paise and selected date in $lang',
      (tester) async {
        final db = AppDatabase(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        );
        final day = DateTime(2026, 11, 5);
        await tester.runAsync(() async {
          await db.select(db.reminders).get();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildTheme(),
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DateNoteEditor(date: day, suggested: 'purchase'),
                      ),
                    ),
                    child: const Text('Open purchase'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open purchase'));
        await tester.pumpAndSettle();
        final save = find.widgetWithText(
          FilledButton,
          lang == 'en' ? 'Save' : 'ಉಳಿಸಿ',
        );
        // Use the only filled button on the active form regardless of translation.
        final saveButton = save.evaluate().isNotEmpty
            ? save
            : find.byType(FilledButton).last;
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(3));
        await tester.enterText(find.byType(TextFormField).at(0), 'Fertiliser');
        await tester.enterText(find.byType(TextFormField).at(1), '123.45');
        await tester.enterText(find.byType(TextFormField).at(2), 'Two bags');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final row = await db.select(db.reminders).getSingle();
          expect(row.title, 'purchase');
          expect(row.dueOn, day);
          expect(noteValues(row.notes)['costPaise'], 12345);
          expect(noteValues(row.notes)['item'], 'Fertiliser');
          expect(noteValues(row.notes)['description'], 'Two bags');
        });
        expect(find.text('Open purchase'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await db.close();
        await tester.pump();
      },
    );

    testWidgets('sale record uses saved buyer name in $lang', (tester) async {
      String title = '';
      final record = CalendarRecord(
        'sale',
        DateTime(2026, 11, 5),
        'note',
        'sale',
        '',
        '/',
        rawNotes: notePrefix + jsonEncode({'buyer': '  Ramesh  '}),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              title = recordTitle(context, record);
              return Text(title);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(title, lang == 'en' ? 'Sold to Ramesh' : 'Ramesh ಅವರಿಗೆ ಮಾರಾಟ');
      expect(find.text(title), findsOneWidget);
    });
  }
}
