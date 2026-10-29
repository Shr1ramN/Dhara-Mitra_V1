import 'dart:convert';

import 'package:dhara_mitra/features/auth/account_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = '11111111-1111-1111-1111-111111111111';
  final user = {
    'id': owner,
    'aud': 'authenticated',
    'email': 'farmer@example.com',
    'created_at': '2026-01-01T00:00:00Z',
    'app_metadata': {},
    'user_metadata': {},
  };
  late AccountController account;
  late SupabaseClient client;
  late List<http.Request> requests;
  late Map<String, dynamic> session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'account.local': true});
    requests = [];
    final expiry =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final token =
        '${encode({'alg': 'HS256'})}.${encode({'sub': owner, 'exp': expiry})}.test-signature';
    session = {
      'access_token': token,
      'refresh_token': 'test-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': user,
    };
    client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = switch (request.url.path) {
          '/auth/v1/token' => session,
          '/auth/v1/user' => user,
          '/auth/v1/signup' => {'user': user},
          _ => <String, dynamic>{},
        };
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    account = AccountController(
      await SharedPreferences.getInstance(),
      client: client,
    );
  });
  tearDown(() async {
    account.dispose();
    await client.dispose();
  });

  test('email sign-in selects account and local sign-out retains no account session', () async {
    await account.signIn(' farmer@example.com ', 'password123');
    await Future<void>.delayed(Duration.zero);
    expect(account.user?.id, owner);
    expect(account.workspaceKey, owner);
    expect(account.local, false);
    expect(account.preferences.getString('account.activeOwner'), owner);
    final payload = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(payload['email'], 'farmer@example.com');
    await account.signOut();
    expect(account.user, isNull);
    expect(account.hasWorkspace, false);
    expect(account.preferences.getString('account.activeOwner'), '');
  });

  test('registration without a session waits for email confirmation', () async {
    expect(await account.signUp('farmer@example.com', 'password123'), false);
    expect(account.user, isNull);
    expect(requests.single.url.queryParameters['redirect_to'], authRedirect);
  });

  test(
    'recovery callback opens password recovery and update exits it',
    () async {
      final callback = Uri.parse(
        '$authRedirect#access_token=${session['access_token']}'
        '&refresh_token=test-refresh&expires_in=3600&token_type=bearer&type=recovery',
      );
      await account.handleLink(callback);
      await Future<void>.delayed(Duration.zero);
      expect(account.recovering, true);
      expect(account.preferences.getBool('account.recovery'), true);
      expect(account.preferences.getString('account.activeOwner'), '');
      final count = requests.length;
      await account.handleLink(callback);
      expect(requests, hasLength(count));
      await account.updatePassword('new-password123');
      expect(account.recovering, false);
      expect(account.preferences.getBool('account.recovery'), false);
      expect(account.preferences.getString('account.activeOwner'), owner);
    },
  );

  test(
    'unrelated links are ignored and invalid callbacks expose retryable error',
    () async {
      await account.handleLink(
        Uri.parse('other://auth/callback#access_token=secret'),
      );
      expect(requests, isEmpty);
      expect(account.authError, false);
      await account.handleLink(
        Uri.parse('$authRedirect#error_description=expired'),
      );
      expect(account.authError, true);
      expect(account.user, isNull);
    },
  );
}
