import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n.dart';
import 'providers.dart';
import '../features/farm/ui/farms_screen.dart';

/// Give dialogs and nested pages the first chance to handle Back. A section
/// opened with go() has no previous route, so return to the farm's landing page.
class FarmBackButtonDispatcher extends RootBackButtonDispatcher {
  FarmBackButtonDispatcher(
    this.router, {
    required this.landingPage,
    required this.leaveSetup,
  });
  final GoRouter router;
  final String Function() landingPage;
  final Future<bool> Function() leaveSetup;

  @override
  Future<bool> didPopRoute() async {
    if (await super.didPopRoute()) return true;
    final landing = landingPage();
    if (router.routeInformationProvider.value.uri.path == landing) {
      return landing == '/setup' ? leaveSetup() : false;
    }
    router.go(landing);
    return true;
  }
}

/// A route shell keeps controls above every feature navigator while retaining
/// the root navigator's overlay for accessible tooltips and dialogs.
class FarmNavigationFrame extends ConsumerWidget {
  const FarmNavigationFrame({
    super.key,
    required this.child,
    required this.hasFarm,
  });
  final Widget child;
  final bool hasFarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(farmProvider).value;
    final landing = hasFarm || farm != null ? '/' : '/setup';
    final router = GoRouter.of(context);
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('app-home'),
                    tooltip: context.l.navHome,
                    onPressed: () async {
                      if (landing == '/setup' &&
                          await ref.read(returnToFarmProvider)()) {
                        return;
                      }
                      router.go(landing);
                    },
                    icon: Image.asset(
                      'assets/branding/logo.png',
                      width: 28,
                      height: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farm == null
                          ? context.l.appName
                          : [
                              farm.name,
                              if (farm.village.isNotEmpty) farm.village,
                            ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
