import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

final initialLockProvider = Provider<bool>((ref) => false);

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialLockProvider);
  Future<void> set(bool enabled) async {
    await ref.read(databaseProvider).putSetting('app_lock', enabled.toString());
    state = enabled;
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(
  AppLockNotifier.new,
);

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l.xSecurity)),
    body: SwitchListTile(
      title: Text(context.l.xLockEnabled),
      value: ref.watch(appLockProvider),
      onChanged: (enabled) async {
        try {
          final auth = LocalAuthentication();
          if (!await auth.isDeviceSupported()) {
            if (context.mounted) {
              showSnack(context, context.l.xAuthenticationFailed);
            }
            return;
          }
          if (!context.mounted) return;
          if (!enabled &&
              !await auth.authenticate(localizedReason: context.l.xUnlock)) {
            return;
          }
          await ref.read(appLockProvider.notifier).set(enabled);
        } catch (_) {
          if (context.mounted) {
            showSnack(context, context.l.xAuthenticationFailed);
          }
        }
      },
    ),
  );
}

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('in.dharamitra/security');
  bool _locked = false, _authenticating = false;
  final _auth = LocalAuthentication();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = ref.read(appLockProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _secure(ref.read(appLockProvider));
      if (_locked) _unlock();
    });
  }

  Future<void> _secure(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('secureWindow', enabled);
    } on MissingPluginException {
      /* widget tests */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_authenticating) _auth.stopAuthentication().ignore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(appLockProvider) || _authenticating) return;
    if (state == AppLifecycleState.paused) {
      setState(() => _locked = true);
    }
    if (state == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    _authenticating = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: context.l.xUnlock,
        persistAcrossBackgrounding: true,
      );
      if (mounted && ok) setState(() => _locked = false);
    } catch (_) {
      /* Keep the cover in place; the user can retry device authentication. */
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockProvider, (old, enabled) {
      _secure(enabled);
      if (enabled) {
        setState(() => _locked = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
      } else {
        setState(() => _locked = false);
      }
    });
    return Stack(
      children: [
        ExcludeFocus(
          excluding: _locked,
          child: Offstage(offstage: _locked, child: widget.child),
        ),
        if (_locked)
          Positioned.fill(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 24),
                    Text(context.l.xUnlock),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _unlock,
                      child: Text(context.l.xContinue),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
