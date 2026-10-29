import 'package:dhara_mitra/app.dart';
import 'package:dhara_mitra/core/db/database.dart';
import 'package:dhara_mitra/core/providers.dart';
import 'package:drift/drift.dart' hide isNull,isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main(){
  late AppDatabase db;
  setUpAll(() async {await initializeDateFormatting();driftRuntimeOptions.dontWarnAboutMultipleDatabases=true;});
  setUp(()=>db=AppDatabase(DatabaseConnection(NativeDatabase.memory(),closeStreamsSynchronously:true)));
  Future<void> pump(WidgetTester tester,{String language='en'}) async {
    tester.view.physicalSize=const Size(1080,2340);tester.view.devicePixelRatio=3;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await db.into(db.farms).insert(FarmsCompanion.insert(name:'Test farm'));
      await db.into(db.plots).insert(PlotsCompanion.insert(name:'Upper plot',acres:const Value(1)));
    });
    await tester.pumpWidget(ProviderScope(overrides:[databaseProvider.overrideWithValue(db),initialLanguageProvider.overrideWithValue(language),
      todayProvider.overrideWithValue(DateTime(2026,10,25))],child:const DharaMitraApp(hasFarm:true)));
    await tester.pumpAndSettle();
  }
  Future<void> finish(WidgetTester tester) async {await tester.pumpWidget(const SizedBox());await db.close();await tester.pump();}
  testWidgets('every offline feature route renders on a narrow phone', (tester) async {
    await pump(tester);
    final router=GoRouter.of(tester.element(find.byType(Scaffold).first));
    for(final path in ['/diary','/stock','/expenses','/land','/loans','/insurance','/documents','/produce','/sales','/reports','/weather','/prices','/reminders','/calendar','/backup','/security']){
      router.go(path);await tester.pumpAndSettle();expect(tester.takeException(),isNull,reason:path);
      expect(find.byType(Scaffold),findsWidgets,reason:path);
    }
    await finish(tester);
  });
  testWidgets('stock form creates a real inventory item and returns to the list',(tester) async {
    await pump(tester);final router=GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go('/stock');await tester.pumpAndSettle();await tester.tap(find.byType(FloatingActionButton));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first,'Test fertiliser');await tester.enterText(find.byType(TextFormField).last,'5');
    await tester.runAsync(() async {await tester.tap(find.widgetWithText(FilledButton,'Save'));await Future<void>.delayed(const Duration(milliseconds:80));});
    await tester.pumpAndSettle();expect(find.text('Test fertiliser'),findsOneWidget);
    expect((await db.select(db.stockItems).get()).single.minimum,5);expect(tester.takeException(),isNull);
    await finish(tester);
  });
  testWidgets('new screens use Kannada labels after switching locale',(tester) async {
    await pump(tester,language:'kn');final router=GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go('/diary');await tester.pumpAndSettle();expect(find.text('ದಿನಚರಿ'),findsOneWidget);expect(find.text('Farm diary'),findsNothing);
    router.go('/backup');await tester.pumpAndSettle();expect(find.text('ಸುರಕ್ಷಿತ ಪ್ರತಿ ಮತ್ತು ಮರುಸ್ಥಾಪನೆ'),findsOneWidget);
    expect(tester.takeException(),isNull);await finish(tester);
  });
}
