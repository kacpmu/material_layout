// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_ui/material_ui.dart';

import 'app/demo_app.dart';
import 'app/shell.dart';
import 'screens/articles.dart';
import 'screens/extra.dart';
import 'screens/feed.dart';
import 'screens/inbox.dart';
import 'screens/layout.dart';

/// Runs the demo with plain state: the destination and the inbox selection
/// are fields of a [State], and the destinations sit in an [IndexedStack] so
/// that each keeps its state.
///
/// `lib/main_router.dart` runs the same screens under a router, with the
/// inbox selection in the URL.
void main() => runApp(const DemoApp(home: NavigatorDemo()));

/// The demo's home: the shell and its destinations.
class NavigatorDemo extends StatefulWidget {
  const new({super.key});

  @override
  State<NavigatorDemo> createState() => NavigatorDemoState();
}

class NavigatorDemoState extends State<NavigatorDemo> {
  var _destination = Destination.inbox;
  int? _message;

  @override
  Widget build(BuildContext context) => DemoShell(
    destination: _destination,
    onDestinationSelected: (destination) =>
        setState(() => _destination = destination),
    body: IndexedStack(
      index: _destination.index,
      children: [
        InboxScreen(
          selectedId: _message,
          onSelectionChanged: (id) => setState(() => _message = id),
        ),
        const ArticlesScreen(),
        const FeedScreen(),
        const LayoutScreen(),
        for (final destination in Destination.values.where((d) => d.isExtra))
          ExtraScreen(destination: destination),
      ],
    ),
  );
}
