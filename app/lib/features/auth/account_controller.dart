import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const authRedirect = 'in.dharamitra://auth/callback';

final accountControllerProvider = Provider<AccountController?>((ref) => null);

/// Account choice lives outside farm backups. Restoring a ZIP never signs in
/// another user or changes which account owns the current catalogue.
class AccountController extends ChangeNotifier {
  AccountController(
    this.preferences, {
    this.client,
    this.configurationFailed = false,
  }) {
    _subscription = client?.auth.onAuthStateChange.listen(
      (state) {
        if (state.session != null) {
          openBackup = false;
          unawaited(preferences.setBool('account.local', false));
        }
        if (state.event == AuthChangeEvent.signedOut) {
          recovering = false;
          unawaited(preferences.setBool('account.recovery', false));
        }
        if (state.event == AuthChangeEvent.passwordRecovery) {
          recovering = true;
          unawaited(preferences.setBool('account.recovery', true));
        }
        unawaited(_saveActiveWorkspace());
        notifyListeners();
      },
      onError: (Object error) {
        // A failed refresh must not discard locally cached farm records.
        authError = true;
        notifyListeners();
      },
    );
  }

  final SharedPreferences preferences;
  final SupabaseClient? client;
  final bool configurationFailed;
  StreamSubscription<AuthState>? _subscription;
  StreamSubscription<Uri>? _linkSubscription;
  final Set<String> _handledLinks = {};
  bool authError = false;
  bool openBackup = false;
  late bool recovering = preferences.getBool('account.recovery') ?? false;
  String get language => preferences.getString('account.language') ?? 'en';
  bool get local => preferences.getBool('account.local') ?? false;
  User? get user => client?.auth.currentUser;
  bool get hasWorkspace => user != null || local;
  String get workspaceKey => user?.id ?? 'local';

  Future<void> setLanguage(String code) async {
    await preferences.setString('account.language', code);
    notifyListeners();
  }

  Future<void> continueLocally() async {
    await preferences.setBool('account.local', true);
    await _saveActiveWorkspace();
    notifyListeners();
  }

  Future<void> _saveActiveWorkspace() => preferences.setString(
    'account.activeOwner',
    recovering ? '' : user?.id ?? (local ? 'local' : ''),
  );

  Future<void> initialize() async {
    if (user != null) await preferences.setBool('account.local', false);
    await _saveActiveWorkspace();
  }

  /// Attach after the auth listener, so cold-start recovery cannot be missed.
  Future<void> startLinkHandling() async {
    if (client == null) return;
    final links = AppLinks();
    _linkSubscription = links.uriLinkStream.listen(
      (uri) => unawaited(handleLink(uri)),
      onError: (Object error) {
        authError = true;
        notifyListeners();
      },
    );
    final initial = await links.getInitialLink();
    if (initial != null) await handleLink(initial);
  }

  Future<void> handleLink(Uri uri) async {
    if (client == null ||
        uri.scheme != 'in.dharamitra' ||
        uri.host != 'auth' ||
        uri.path != '/callback' ||
        !_handledLinks.add(uri.toString())) {
      return;
    }
    try {
      await client!.auth.getSessionFromUrl(uri);
      authError = false;
    } catch (_) {
      _handledLinks.remove(uri.toString());
      authError = true;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    // Local scope clears this device's session and works offline.
    await preferences.setBool('account.local', false);
    await preferences.setBool('account.recovery', false);
    recovering = false;
    openBackup = false;
    await client?.auth.signOut(scope: SignOutScope.local);
    await _saveActiveWorkspace();
    notifyListeners();
  }

  Future<void> google() async {
    final launched = await client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!launched) throw StateError('browser');
  }

  Future<void> signIn(String email, String password) async {
    await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> signUp(String email, String password) async {
    final result = await client!.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirect,
    );
    return result.session != null;
  }

  Future<void> resetPassword(String email) async {
    await client!.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirect,
    );
  }

  Future<void> updatePassword(String password) async {
    await client!.auth.updateUser(UserAttributes(password: password));
    await preferences.setBool('account.recovery', false);
    recovering = false;
    await _saveActiveWorkspace();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }
}
