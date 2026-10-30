import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/lots/ui/collections_screen.dart';
import 'features/farm/ui/farms_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n.dart';
import 'features/calendar/farm_calendar.dart';
import 'core/app_navigation.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/farm/ui/farm_screen.dart';
import 'features/farm/ui/plot_form_screen.dart';
import 'features/home/ui/home_screen.dart';
import 'features/labour/ui/labour_screen.dart';
import 'features/labour/ui/worker_form_screen.dart';
import 'features/labour/ui/worker_screen.dart';
import 'features/lots/ui/harvest_form_screen.dart';
import 'features/lots/ui/lot_screen.dart';
import 'features/lots/ui/lots_screen.dart';
import 'features/lots/ui/sale_form_screen.dart';
import 'features/settings/ui/more_screen.dart';
import 'features/diary/ui/diary_screen.dart';
import 'features/stock/ui/stock_screen.dart';
import 'features/finance/finance_screens.dart';
import 'features/loans/ui/loans_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/produce/produce_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/security/security.dart';
import 'features/weather/weather_screen.dart';
import 'features/prices/prices_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/backup/backup_screen.dart';
import 'features/auth/sign_in_screen.dart';

GoRouter buildRouter({
  required bool hasFarm,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? (hasFarm ? '/' : '/setup'),
  routes: [
    ShellRoute(
      builder: (_, _, child) =>
          FarmNavigationFrame(hasFarm: hasFarm, child: child),
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const SignInScreen(settings: true),
        ),
        GoRoute(path: '/farms', builder: (_, _) => const FarmsScreen()),
        GoRoute(
          path: '/collections',
          builder: (_, _) => const CollectionsScreen(),
        ),
        GoRoute(path: '/weather', builder: (_, _) => const WeatherScreen()),
        GoRoute(path: '/prices', builder: (_, _) => const PricesScreen()),
        GoRoute(path: '/reminders', builder: (_, _) => const RemindersScreen()),
        GoRoute(path: '/lots', builder: (_, _) => const LotsScreen()),
        GoRoute(
          path: '/labour',
          builder: (_, s) => LabourScreen(
            key: ValueKey(s.uri.toString()),
            initialTab:
                LabourTab.values.asNameMap()[s.uri.queryParameters['tab']] ??
                LabourTab.workers,
          ),
        ),
        GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
        GoRoute(path: '/security', builder: (_, _) => const SecurityScreen()),
        GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
        GoRoute(path: '/fertilizer', builder: (_, _) => const DiaryForm()),
        GoRoute(path: '/stock', builder: (_, _) => const StockScreen()),
        GoRoute(path: '/expenses', builder: (_, _) => const ExpensesScreen()),
        GoRoute(path: '/land', builder: (_, _) => const LandScreen()),
        GoRoute(path: '/loans', builder: (_, _) => const LoansScreen()),
        GoRoute(path: '/insurance', builder: (_, _) => const InsuranceScreen()),
        GoRoute(path: '/documents', builder: (_, _) => const DocumentsScreen()),
        GoRoute(path: '/produce', builder: (_, _) => const ProduceScreen()),
        GoRoute(path: '/sales', builder: (_, _) => const SalesScreen()),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(
          path: '/setup',
          builder: (_, _) => const FarmScreen(isSetup: true),
        ),
        GoRoute(
          path: '/farm',
          builder: (_, _) => const FarmScreen(isSetup: false),
        ),
        GoRoute(
          path: '/plot',
          builder: (_, s) =>
              PlotFormScreen(plotId: s.uri.queryParameters['id']),
        ),
        GoRoute(
          path: '/worker-form',
          builder: (_, s) =>
              WorkerFormScreen(workerId: s.uri.queryParameters['id']),
        ),
        GoRoute(
          path: '/worker/:id',
          builder: (_, s) => WorkerScreen(workerId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/harvest-form',
          builder: (_, _) => const HarvestFormScreen(),
        ),
        GoRoute(
          path: '/lot/:id',
          builder: (_, s) => LotScreen(lotId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'sale',
              builder: (_, s) => SaleFormScreen(lotId: s.pathParameters['id']!),
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => _Shell(shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  builder: (_, _) => const FarmCalendarScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell(this.shell);

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            label: l.xCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l.navMore,
          ),
        ],
      ),
    );
  }
}

class DharaMitraApp extends ConsumerStatefulWidget {
  const DharaMitraApp({super.key, required this.hasFarm, this.initialLocation});

  final bool hasFarm;
  final String? initialLocation;

  @override
  ConsumerState<DharaMitraApp> createState() => _DharaMitraAppState();
}

class _DharaMitraAppState extends ConsumerState<DharaMitraApp> {
  late final GoRouter _router = buildRouter(
    hasFarm: widget.hasFarm,
    initialLocation: widget.initialLocation,
  );
  String get _landingPage =>
      widget.hasFarm || ref.read(farmProvider).value != null ? '/' : '/setup';
  late final _backDispatcher = FarmBackButtonDispatcher(
    _router,
    landingPage: () => _landingPage,
    leaveSetup: () => ref.read(returnToFarmProvider)(),
  );
  late final _routerConfig = RouterConfig(
    routeInformationProvider: _router.routeInformationProvider,
    routeInformationParser: _router.routeInformationParser,
    routerDelegate: _router.routerDelegate,
    backButtonDispatcher: _backDispatcher,
  );

  @override
  void initState() {
    super.initState();
    _router.routeInformationProvider.addListener(_syncFrameworkBackHandling);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFrameworkBackHandling();
    });
  }

  void _syncFrameworkBackHandling() {
    SystemNavigator.setFrameworkHandlesBack(
      _backDispatcher.canHandleBack || _router.canPop(),
    );
  }

  @override
  void dispose() {
    _router.routeInformationProvider.removeListener(_syncFrameworkBackHandling);
    _backDispatcher.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => context.l.appName,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: ref.watch(localeProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: _routerConfig,
    // A section opened with go() can still navigate back through our dispatcher
    // even when its Navigator contains a single page. Tell Android ahead of time.
    onNavigationNotification: (notification) {
      SystemNavigator.setFrameworkHandlesBack(
        notification.canHandlePop || _backDispatcher.canHandleBack,
      );
      return true;
    },
    builder: (_, child) => AppLockGate(child: child!),
  );
}
