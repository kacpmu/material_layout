// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Widget inbox() => NavigationScaffold(
  navigationBar: NavigationBar(
    destinations: const [
      NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
      NavigationDestination(icon: Icon(Icons.article), label: 'Articles'),
      NavigationDestination(icon: Icon(Icons.dashboard), label: 'Feed'),
    ],
  ),
  navigationRail: NavigationRail(
    selectedIndex: 0,
    destinations: const [
      NavigationRailDestination(icon: Icon(Icons.inbox), label: Text('Inbox')),
      NavigationRailDestination(
        icon: Icon(Icons.article),
        label: Text('Articles'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        label: Text('Feed'),
      ),
    ],
  ),
  body: ListDetailLayout<int>(
    resizable: true,
    listBuilder: (context) {
      final layout = ListDetailLayout.of<int>(context);
      return ListView(
        children: [
          for (var i = 0; i < 30; i++)
            ListTile(
              title: Text('Message $i'),
              selected: layout.isSelected(i),
              onTap: () => layout.select(i),
            ),
        ],
      );
    },
    detailBuilder: (context, id, placement) => switch (placement) {
      DetailPlacement.pane => Text('Detail $id'),
      DetailPlacement.page => Scaffold(
        appBar: AppBar(title: Text('Message $id')),
        body: Text('Detail $id'),
      ),
    },
  ),
);

void main() {
  testWidgets('smoke: list-detail in a navigation scaffold', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(app(inbox()));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.text('Message 3'));
    await settle(tester);
    expect(find.text('Detail 3'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    setWindowSize(tester, const Size(1300, 800));
    await tester.pump();
    await settle(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Detail 3'), findsOneWidget);
    expect(find.text('Message 3'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Message 5'));
    await settle(tester);
    expect(find.text('Detail 5'), findsOneWidget);
    expect(find.byType(PaneDragHandle), findsOneWidget);

    setWindowSize(tester, const Size(700, 800));
    await tester.pump();
    await settle(tester);
    expect(find.text('Detail 5'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
