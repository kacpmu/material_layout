// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:demo/app/demo_app.dart';
import 'package:demo/app/shell.dart';
import 'package:demo/main_router.dart';
import 'package:demo/screens/extra.dart';
import 'package:demo/screens/inbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

// The router entrypoint, with the selection in the URL.

void setWindowSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<GoRouter> pumpRouter(WidgetTester tester, String location) async {
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(DemoApp(routerConfig: router));
  await settle(tester);
  return router;
}

String location(GoRouter router) =>
    router.routeInformationProvider.value.uri.toString();

Finder get subject => find.text('Draft of the accessibility notes');
Finder get list => find.text('Ada Okafor');

void main() {
  testWidgets('the same URL shows two panes at 1400dp and one at 400dp', (
    tester,
  ) async {
    DetailPlacement placement() =>
        tester.widget<MessageDetail>(find.byType(MessageDetail)).placement;

    setWindowSize(tester, const Size(1400, 900));
    await pumpRouter(tester, '/inbox/3');
    expect(list, findsOneWidget);
    expect(subject, findsOneWidget);
    expect(placement(), DetailPlacement.pane);

    setWindowSize(tester, const Size(400, 800));
    await pumpRouter(tester, '/inbox/3');
    expect(list, findsNothing);
    expect(placement(), DetailPlacement.page);
  });

  testWidgets('resizing leaves the URL and the history alone', (tester) async {
    setWindowSize(tester, const Size(1400, 900));
    final router = await pumpRouter(tester, '/inbox/3');
    final canPop = router.canPop();
    for (final width in [400.0, 1400.0, 700.0, 1000.0, 400.0]) {
      setWindowSize(tester, Size(width, 900));
      await settle(tester);
      expect(location(router), '/inbox/3', reason: '$width');
      expect(router.canPop(), canPop, reason: '$width');
    }
  });

  testWidgets('selecting another message updates the page in place', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final router = await pumpRouter(tester, '/inbox/3');
    final listRect = tester.getRect(list);
    await tester.tap(find.text('Dana Moreau'));
    await tester.pump();
    expect(location(router), '/inbox/4');
    // The list did not move: nothing transitioned the whole screen.
    expect(tester.getRect(list), listRect);
    expect(find.text('Lunch next week?'), findsOneWidget);
  });

  testWidgets('back from the message beside the list goes to /inbox', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final router = await pumpRouter(tester, '/inbox/3');
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(location(router), '/inbox');
    expect(subject, findsNothing);
    expect(find.text('Select a message to read it'), findsOneWidget);
  });

  testWidgets('a deep link at one pane shows the detail at once, with a '
      'working back affordance', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    final router = createRouter(initialLocation: '/inbox/3');
    addTearDown(router.dispose);
    await tester.pumpWidget(DemoApp(routerConfig: router));
    await tester.pump();
    expect(subject, findsOneWidget);
    final route = ModalRoute.of(tester.element(subject))!;
    expect(route.animation!.value, 1);

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(location(router), '/inbox');
    expect(list, findsOneWidget);
  });

  testWidgets('the destinations the navigation settings add have URLs of '
      'their own', (tester) async {
    NavigationRail rail() => tester.widget(find.byType(NavigationRail));
    setWindowSize(tester, const Size(1400, 900));
    final router = await pumpRouter(tester, '/photos');
    expect(
      tester.widget<ExtraScreen>(find.byType(ExtraScreen)).destination,
      Destination.photos,
    );
    // The rail carries the demo's own four, and marks none of them.
    expect(rail().selectedIndex, isNull);

    final settings = Settings.controllerOf(
      tester.element(find.byType(DemoShell)),
    );
    settings.value = settings.value.copyWith(
      railCount: Destination.values.length,
    );
    await settle(tester);
    expect(rail().selectedIndex, Destination.photos.index);
    // The rail scrolls to it.
    final maps = find
        .descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Maps'),
        )
        .first;
    await tester.ensureVisible(maps);
    await tester.pump();
    await tester.tap(maps);
    await settle(tester);
    expect(location(router), '/maps');
    expect(
      tester.widget<ExtraScreen>(find.byType(ExtraScreen)).destination,
      Destination.maps,
    );
  });
}
