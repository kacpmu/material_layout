import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'package:demo/data/demo_settings.dart';
import 'package:demo/screens/articles_screen.dart';
import 'package:demo/shell/demo_shell.dart';
import 'package:demo/screens/feed_screen.dart';
import 'package:demo/screens/inbox/inbox_screen.dart';
import 'package:demo/screens/sheets_screen.dart';

/// The same demo as `main_navigator.dart`, but driven by **GoRouter**.
///
/// Both entrypoints render the identical [DemoShell]; only the push/pop
/// strategy differs. Start with `main_navigator.dart` — it is the simpler of
/// the two — then read this one to see the same screens under a router.
///
/// Top-level navigation is a [StatefulShellRoute.indexedStack] (one branch per
/// destination, each keeping its own state). The inbox selection lives in the
/// **URL**: `/inbox` shows the list, `/inbox/:id` selects an item. The list-detail
/// screen runs in *controlled* mode — it reflects the `:id` from the route and
/// reports taps back via `context.go(...)`, so the URL is the source of truth
/// while [ListDetailLayout] still owns the adaptive presentation (inline detail
/// when wide, a pushed page when narrow).
///
/// Routes: `/inbox`, `/inbox/:id`, `/articles`, `/feed`, `/sheets`.
///
/// Run with `flutter run -t lib/main_router.dart -d chrome`.
void main() {
  // Clean `/inbox/1` URLs on web instead of `/#/inbox/1`, so the address bar
  // actually reads as the selection. A no-op off web.
  usePathUrlStrategy();
  runApp(const AdaptiveLayoutsRouterDemoApp());
}

class AdaptiveLayoutsRouterDemoApp extends StatefulWidget {
  const AdaptiveLayoutsRouterDemoApp({super.key});

  @override
  State<AdaptiveLayoutsRouterDemoApp> createState() =>
      _AdaptiveLayoutsRouterDemoAppState();
}

class _AdaptiveLayoutsRouterDemoAppState
    extends State<AdaptiveLayoutsRouterDemoApp> {
  DemoSettings _settings = const DemoSettings();

  // Created once; route builders read live settings from DemoSettingsScope, so
  // the router instance is stable across settings changes.
  late final GoRouter _router = GoRouter(
    initialLocation: '/inbox',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _RouterShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            // Two sibling routes share one page key, so navigating between
            // "no selection" and "item selected" preserves the screen (and its
            // nested detail Navigator) — only `selectedId` changes.
            GoRoute(
              path: '/inbox',
              pageBuilder: (context, state) => const NoTransitionPage(
                key: ValueKey('inbox'),
                child: _InboxBranch(selectedId: null),
              ),
            ),
            GoRoute(
              path: '/inbox/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                key: const ValueKey('inbox'),
                child: _InboxBranch(
                  selectedId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/articles',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: _ArticlesBranch()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FeedScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/sheets',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SheetsScreen()),
            ),
          ]),
        ],
      ),
    ],
  );

  ThemeData _theme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: const Color(0xFF4F6BED),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'material_layout (GoRouter)',
      debugShowCheckedModeBanner: false,
      themeMode: _settings.themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: _router,
      // RTL above the router covers pushed routes and sheets; the settings scope
      // makes the live settings available to every route.
      builder: (context, child) => Directionality(
        textDirection: _settings.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: DemoSettingsScope(
          settings: _settings,
          onChanged: (s) => setState(() => _settings = s),
          child: child!,
        ),
      ),
    );
  }
}

/// The adaptive navigation shell, wrapping the router's
/// [StatefulNavigationShell].
///
/// Renders the very same [DemoShell] as `main_navigator.dart`. The only
/// difference is what a destination tap does: `goBranch` swaps branches and
/// puts the location in the URL, where the other entrypoint calls `setState`.
class _RouterShell extends StatelessWidget {
  const _RouterShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return DemoShell(
      selectedIndex: navigationShell.currentIndex,
      // Tapping the active destination resets it to the branch's root.
      onDestinationSelected: (i) => navigationShell.goBranch(
        i,
        initialLocation: i == navigationShell.currentIndex,
      ),
      body: navigationShell,
    );
  }
}

/// Inbox: a list-detail in *controlled* mode — selection mirrors `/inbox/:id`.
class _InboxBranch extends StatelessWidget {
  const _InboxBranch({required this.selectedId});

  final Object? selectedId;

  @override
  Widget build(BuildContext context) {
    final settings = DemoSettingsScope.of(context).settings;
    return SafeArea(
      child: InboxScreen(
        resizable: settings.resizablePanes,
        behavior: settings.listDetailBehavior,
        dismissible: settings.supportingDismissible,
        selectedId: selectedId,
        onSelectionChanged: (id) =>
            context.go(id == null ? '/inbox' : '/inbox/$id'),
      ),
    );
  }
}

class _ArticlesBranch extends StatelessWidget {
  const _ArticlesBranch();

  @override
  Widget build(BuildContext context) {
    final settings = DemoSettingsScope.of(context).settings;
    return ArticlesScreen(
      resizable: settings.resizablePanes,
      dismissible: settings.supportingDismissible,
    );
  }
}
