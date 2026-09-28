// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

/// An inbox that adapts to its window: one pane and a navigation bar on a
/// phone, two resizable panes and a navigation rail on a wider screen.
///
/// The full demo, with a reader, a feed and side sheets, is in `demo/`.
void main() => runApp(const MaterialApp(home: _Inbox()));

class _Inbox extends StatefulWidget {
  const new();

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  var _destination = 0;

  @override
  Widget build(BuildContext context) => NavigationScaffold(
    navigationBar: NavigationBar(
      selectedIndex: _destination,
      onDestinationSelected: (index) => setState(() => _destination = index),
      destinations: [
        for (final (icon, label) in _destinations)
          NavigationDestination(icon: Icon(icon), label: label),
      ],
    ),
    navigationRail: NavigationRail(
      selectedIndex: _destination,
      onDestinationSelected: (index) => setState(() => _destination = index),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final (icon, label) in _destinations)
          NavigationRailDestination(icon: Icon(icon), label: Text(label)),
      ],
    ),
    body: ListDetailLayout<int>(
      resizable: true,
      emptyBehavior: const ListDetailEmptyBehavior.placeholder(
        child: Center(child: Text('Select a message')),
      ),
      listBuilder: (context) {
        final layout = ListDetailLayout.of<int>(context);
        return ListView(
          children: [
            for (var id = 0; id < 20; id++)
              ListTile(
                title: Text('Message $id'),
                subtitle: const Text('A short preview of the message'),
                selected: layout.isSelected(id),
                onTap: () => layout.select(id),
              ),
          ],
        );
      },
      detailBuilder: (context, id, placement) {
        final body = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Message $id',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('The body of the message.'),
          ],
        );
        // The same app bar and body in both placements, so that the detail
        // keeps its state as it moves. On a page of its own, the bar has a
        // back button. Beside the list it has none; the detail can be
        // closed instead, back to the placeholder.
        final layout = ListDetailLayout.of<int>(context);
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: placement == DetailPlacement.page,
            actions: [
              if (layout.canClose)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: layout.close,
                ),
            ],
          ),
          body: body,
        );
      },
    ),
  );
}

const _destinations = [
  (Icons.inbox, 'Inbox'),
  (Icons.star_outline, 'Starred'),
  (Icons.send_outlined, 'Sent'),
];
