import 'package:dhara_mitra/core/l10n.dart';
import 'package:dhara_mitra/features/auth/account_controller.dart';
import 'package:dhara_mitra/features/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestAccount extends AccountController {
  TestAccount(super.preferences, {super.client});
  int signIns = 0;
  int signUps = 0;
  int resets = 0;
  @override
  Future<void> signIn(String email, String password) async => signIns++;
  @override
  Future<bool> signUp(String email, String password) async {
    signUps++;
    return false;
  }

  @override
  Future<void> resetPassword(String email) async => resets++;
}

void main() {
  late TestAccount account;
  late SupabaseClient client;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    account = TestAccount(
      await SharedPreferences.getInstance(),
      client: client,
    );
  });
  tearDown(() async {
    account.dispose();
    await client.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    AccountController? controller,
    String locale = 'en',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountControllerProvider.overrideWithValue(controller ?? account),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SignInScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(find.text(text), 250);
    }
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('local mode requires acknowledgement and remembers choice', (
    tester,
  ) async {
    await pump(tester);
    await tapText(tester, 'Continue locally');
    expect(find.textContaining('records cannot be recovered'), findsOneWidget);
    final proceed = find.widgetWithText(FilledButton, 'Continue locally');
    expect(tester.widget<FilledButton>(proceed).onPressed, isNull);
    expect(account.local, false);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(proceed);
    await tester.pumpAndSettle();
    expect(account.local, true);
    final restarted = AccountController(account.preferences);
    expect(restarted.local, true);
    expect(account.preferences.getString('account.activeOwner'), 'local');
    restarted.dispose();
  });

  testWidgets('local warning cancellation does not choose local mode', (
    tester,
  ) async {
    await pump(tester);
    await tapText(tester, 'Continue locally');
    await tapText(tester, 'Cancel');
    expect(account.local, false);
  });

  testWidgets('missing cloud config leaves local mode and restore available', (
    tester,
  ) async {
    final offline = AccountController(account.preferences);
    await pump(tester, controller: offline);
    expect(find.textContaining('not configured in this build'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Continue with Google'),
          )
          .onPressed,
      isNull,
    );
    await tapText(tester, 'Restore a backup in local mode');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue locally'));
    await tester.pumpAndSettle();
    expect(offline.local, true);
    expect(offline.openBackup, true);
    offline.dispose();
  });

  testWidgets('email form validates before sending credentials', (
    tester,
  ) async {
    await pump(tester);
    await tapText(tester, 'Sign in with email');
    await tapText(tester, 'Sign in');
    expect(account.signIns, 0);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'farmer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tapText(tester, 'Sign in');
    expect(account.signIns, 1);
  });

  testWidgets(
    'registration checks password confirmation and explains verification',
    (tester) async {
      await pump(tester);
      await tapText(tester, 'Sign in with email');
      await tapText(tester, 'Create an account');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'farmer@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await tapText(tester, 'Create an account');
      expect(account.signUps, 0);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tapText(tester, 'Create an account');
      expect(account.signUps, 1);
      expect(
        find.textContaining('Check your email to confirm'),
        findsOneWidget,
      );
    },
  );

  testWidgets('password reset needs only email and gives neutral response', (
    tester,
  ) async {
    await pump(tester);
    await tapText(tester, 'Sign in with email');
    await tapText(tester, 'Forgot password?');
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'farmer@example.com');
    await tapText(tester, 'Send password reset email');
    expect(account.resets, 1);
    expect(find.textContaining('If an account exists'), findsOneWidget);
  });

  testWidgets('Kannada welcome uses translated local warning', (tester) async {
    await pump(tester, locale: 'kn');
    await tapText(tester, 'ಸ್ಥಳೀಯವಾಗಿ ಮುಂದುವರಿಸಿ');
    expect(find.textContaining('ಮರಳಿ ಪಡೆಯಲು ಸಾಧ್ಯವಿಲ್ಲ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
