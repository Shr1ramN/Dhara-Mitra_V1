import 'dart:async';

import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:dhara_mitra/features/lots/ui/collections_screen.dart';
import 'package:dhara_mitra/features/farm/ui/farms_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppDatabase db;
  late GoRouter router;
  final platformCalls = <String>[];
  final frameworkBackStates = <bool>[];
  setUpAll(() async {
    await initializeDateFormatting();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    platformCalls.clear();
    frameworkBackStates.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call.method);
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            frameworkBackStates.add(call.arguments as bool);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  Future<void> pump(
    WidgetTester tester, {
    String language = 'en',
    bool hasFarm = true,
    Future<bool> Function()? leaveSetup,
    Future<void> Function(String)? deleteFarm,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (hasFarm) {
      await tester.runAsync(() async {
        await db.into(db.farms).insert(FarmsCompanion.insert(name: 'My farm'));
      });
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialLanguageProvider.overrideWithValue(language),
          if (leaveSetup != null)
            returnToFarmProvider.overrideWithValue(leaveSetup),
          if (deleteFarm != null) ...[
            profilesProvider.overrideWith(
              (ref) async => [('default', 'My farm')],
            ),
            deleteFarmProvider.overrideWithValue(deleteFarm),
          ],
        ],
        child: DharaMitraApp(hasFarm: hasFarm),
      ),
    );
    await tester.pumpAndSettle();
    router = GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await db.close();
    await tester.pump();
  }

  testWidgets(
    'Android keeps Back in Flutter for sections with no navigator history',
    (tester) async {
      await pump(tester);
      expect(frameworkBackStates.last, isFalse);
      for (final path in ['/calendar', '/more', '/labour', '/backup']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.canPop(), isFalse, reason: path);
        expect(frameworkBackStates.last, isTrue, reason: path);
        router.go('/');
        await tester.pumpAndSettle();
        expect(frameworkBackStates.last, isFalse, reason: path);
      }
      await finish(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Back retraces bottom navigation and replaced feature routes one step at a time',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/more');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/calendar');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');

      router.go('/more');
      await tester.pumpAndSettle();
      router.go('/labour?tab=attendance');
      await tester.pumpAndSettle();
      router.go('/labour?tab=dues');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/labour?tab=attendance',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/more');
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      router.go('/');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      expect(platformCalls, contains('SystemNavigator.pop'));
      await finish(tester);
    },
  );

  testWidgets('home summary tiles fit a phone and open their farm tools', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Recent records'), findsNothing);
    for (final item in <(String, String)>[
      ('Recent work', '/calendar'),
      ('Worker dues', '/labour'),
      ('Harvests', '/lots'),
      ('Buyer balances', '/sales'),
    ]) {
      final tile = find.text(item.$1);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, item.$2);
      router.go('/');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await finish(tester);
  });

  testWidgets(
    'Android Back from each section and direct feature returns home without exiting',
    (tester) async {
      await pump(tester);
      for (final path in [
        '/lots',
        '/labour',
        '/more',
        '/account',
        '/backup',
        '/collections',
        '/diary',
        '/fertilizer',
        '/stock',
        '/expenses',
        '/reports',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/',
          reason: path,
        );
        expect(
          platformCalls,
          isNot(contains('SystemNavigator.pop')),
          reason: path,
        );
        expect(tester.takeException(), isNull, reason: path);
      }
      // Once already home, allow Android's normal exit behavior.
      await tester.binding.handlePopRoute();
      expect(platformCalls, contains('SystemNavigator.pop'));
      await finish(tester);
    },
  );
  testWidgets(
    'Back closes native nested forms and dialogs before leaving their parent page',
    (tester) async {
      await pump(tester);
      unawaited(router.push<void>('/collections'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionForm), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CollectionForm), findsNothing);
      expect(find.byType(CollectionsScreen), findsOneWidget);
      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(CollectionsScreen)),
          builder: (_) => const AlertDialog(title: Text('Dialog')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CollectionsScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byType(CollectionsScreen), findsNothing);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      await finish(tester);
    },
  );
  for (final language in ['en', 'kn']) {
    testWidgets(
      'phone Back and leaf Home work without the extra Back button in $language',
      (tester) async {
        await pump(tester, language: language);
        router.go('/labour');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-back')), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/');
        router.go('/collections');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('app-home')));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/');
        expect(find.byType(CollectionForm), findsNothing);
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
    testWidgets(
      'farm shortcuts and money have separate headings in $language',
      (tester) async {
        await pump(tester, language: language);
        final tools = language == 'en' ? 'FARM TOOLS' : 'ತೋಟದ ಕೆಲಸಗಳು';
        await tester.scrollUntilVisible(
          find.text(tools),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(tools), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(language == 'en' ? 'MONEY' : 'ಹಣಕಾಸು'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }
  testWidgets('Home during first-run setup stays in setup', (tester) async {
    await pump(tester, hasFarm: false);
    await tester.tap(find.byKey(const ValueKey('app-home')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/setup');
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
  testWidgets(
    'phone Back leaves additional farm setup after closing nested pages',
    (tester) async {
      var returns = 0;
      await pump(
        tester,
        hasFarm: false,
        leaveSetup: () async {
          returns++;
          return true;
        },
      );
      unawaited(router.push<void>('/plot'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(returns, 0);
      expect(router.routeInformationProvider.value.uri.path, '/setup');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(returns, 1);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      await finish(tester);
    },
  );
  testWidgets(
    'phone Back allows exiting first-run setup with no previous farm',
    (tester) async {
      await pump(tester, hasFarm: false);
      await tester.binding.handlePopRoute();
      expect(platformCalls, contains('SystemNavigator.pop'));
      await finish(tester);
    },
  );
  testWidgets(
    'farm deletion requires confirmation and cancel preserves the farm',
    (tester) async {
      var deleted = '';
      await pump(
        tester,
        deleteFarm: (id) async {
          deleted = id;
        },
      );
      router.go('/farms');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-farm-default')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleted, isEmpty);
      await tester.tap(find.byKey(const ValueKey('delete-farm-default')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 'default');
      await finish(tester);
    },
  );
}
