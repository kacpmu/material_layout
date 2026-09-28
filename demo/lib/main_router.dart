// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app/demo_app.dart';
import 'app/shell.dart';
import 'screens/articles.dart';
import 'screens/extra.dart';
import 'screens/feed.dart';
import 'screens/inbox.dart';
import 'screens/layout.dart';

/// Runs the demo under go_router, with the inbox selection in the URL:
/// `/inbox` shows no selection and `/inbox/3` selects message 3.
///
/// The layout never touches the URL. It reports selections, and the route
/// passes the selection back; resizing the window changes the layout and
/// leaves the URL alone. The two inbox routes share a page key and do not
/// transition, so selecting a message updates the page in place instead of
/// pushing a new one.
void main() {
  usePathUrlStrategy();
  runApp(DemoApp(routerConfig: createRouter()));
}

const _inboxPage = ValueKey('inbox');

/// The demo's routes, starting at [initialLocation].
GoRouter createRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? Destination.inbox.path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => DemoShell(
        destination: Destination.values[shell.currentIndex],
        onDestinationSelected: (destination) => shell.goBranch(
          destination.index,
          initialLocation: destination.index == shell.currentIndex,
        ),
        body: shell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              pageBuilder: (context, state) => const NoTransitionPage(
                key: _inboxPage,
                child: _RoutedInbox(selectedId: null),
              ),
            ),
            GoRoute(
              path: '/inbox/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                key: _inboxPage,
                child: _RoutedInbox(
                  selectedId: int.tryParse(state.pathParameters['id']!),
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Destination.articles.path,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ArticlesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Destination.feed.path,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FeedScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Destination.layout.path,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: LayoutScreen()),
            ),
          ],
        ),
        // The destinations that the navigation settings add, in their order.
        for (final destination in Destination.values.where((d) => d.isExtra))
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: destination.path,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: ExtraScreen(destination: destination),
                ),
              ),
            ],
          ),
      ],
    ),
  ],
);

class _RoutedInbox extends StatelessWidget {
  const new({required this.selectedId});

  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    final id = selectedId;
    final known = Mail.of(context).messages.any((message) => message.id == id);
    return InboxScreen(
      selectedId: known ? id : null,
      onSelectionChanged: (id) =>
          context.go(id == null ? '/inbox' : '/inbox/$id'),
    );
  }
}
