import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/farm_host.dart';
import '../../core/farm_profiles.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import 'account_controller.dart';
import 'sign_in_screen.dart';

class AccountHost extends StatelessWidget {
  const AccountHost({
    super.key,
    required this.controller,
    required this.localCatalogue,
  });
  final AccountController controller;
  final FarmProfiles localCatalogue;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.hasWorkspace && !controller.recovering) {
        return _Workspace(
          key: ValueKey(controller.workspaceKey),
          catalogue: FarmProfiles(
            localCatalogue.root,
            ownerId: controller.user?.id,
          ),
          initialLocation: controller.openBackup ? '/backup' : null,
          language: controller.language,
          controller: controller,
        );
      }
      return ProviderScope(
        overrides: [accountControllerProvider.overrideWithValue(controller)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: Locale(controller.language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SignInScreen(),
        ),
      );
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    super.key,
    required this.catalogue,
    this.initialLocation,
    required this.language,
    required this.controller,
  });
  final FarmProfiles catalogue;
  final String? initialLocation;
  final String language;
  final AccountController controller;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  late Future<FarmSession> _opening = _open();
  FarmSession? _session;

  Future<FarmSession> _open() async {
    final active = (await widget.catalogue.read()).active;
    final session = await FarmSession.open(active, language: widget.language);
    if (!mounted) {
      await session.db.close();
      throw StateError('Workspace closed');
    }
    return _session = session;
  }

  @override
  void dispose() {
    // FarmHost closes its live session after its services have stopped.
    // If it never mounted, this widget still owns the opening database.
    if (!_hostMounted) _session?.db.close();
    super.dispose();
  }

  bool _hostMounted = false;

  @override
  Widget build(BuildContext context) => FutureBuilder<FarmSession>(
    future: _opening,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        _hostMounted = true;
        return FarmHost(
          initial: snapshot.data!,
          catalogue: widget.catalogue,
          initialLocation: widget.initialLocation,
          accountController: widget.controller,
        );
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? TextButton(
                    onPressed: () => setState(() => _opening = _open()),
                    child: const Text(
                      'Unable to open farm records. Retry / ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
