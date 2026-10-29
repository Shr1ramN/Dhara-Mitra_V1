import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/loans/data/memberships_repository.dart';
import 'package:dhara_mitra/features/loans/ui/loans_screen.dart';
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
    testWidgets(
      'membership purchase validates and updates displayed holdings in $language',
      (tester) async {
        final db = AppDatabase(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        );
        final repo = MembershipsRepository(db);
        final day = DateTime(2026, 10, 10);
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await db
              .into(db.farms)
              .insert(FarmsCompanion.insert(name: 'My farm'));
          await repo.save(
            organization: 'Society',
            number: '123',
            joinedOn: day,
            shares: 10,
          );
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              initialLanguageProvider.overrideWithValue(language),
              todayProvider.overrideWithValue(day),
            ],
            child: const DharaMitraApp(hasFarm: true),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        router.go('/loans');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.card_membership_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(MembershipsScreen), findsOneWidget);
        await tester.tap(find.text('Society'));
        await tester.pumpAndSettle();
        final purchase = language == 'en' ? 'Share purchase' : 'ಷೇರು ಖರೀದಿ';
        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, purchase),
        );
        await tester.tap(find.widgetWithText(OutlinedButton, purchase));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), '500');
        await tester.enterText(find.byType(TextFormField).at(1), '0');
        final save = language == 'en' ? 'Save' : 'ಉಳಿಸಿ';
        await tester.tap(find.widgetWithText(FilledButton, save));
        await tester.pumpAndSettle();
        expect((await repo.load()).single.shares, 10);
        await tester.enterText(find.byType(TextFormField).at(1), '5');
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, save));
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();
        expect((await repo.load()).single.shares, 15);
        expect(find.text('15'), findsOneWidget);
        final tile = find
            .ancestor(of: find.text(purchase), matching: find.byType(ListTile))
            .first;
        await tester.ensureVisible(tile);
        await tester.longPress(tile);
        await tester.pumpAndSettle();
        final remove = language == 'en' ? 'Delete' : 'ಅಳಿಸಿ';
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, remove));
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();
        expect((await repo.load()).single.shares, 10);
        final edit = language == 'en' ? 'Edit' : 'ಬದಲಿಸಿ';
        await tester.ensureVisible(find.widgetWithText(TextButton, edit));
        await tester.tap(find.widgetWithText(TextButton, edit));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(2), '20');
        await tester.ensureVisible(find.widgetWithText(FilledButton, save));
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, save));
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();
        expect((await repo.load()).single.shares, 20);

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await db.close();
        await tester.pump();
      },
    );
  }
}
