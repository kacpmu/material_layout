import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Widget _scaffold({int paneCount = 1}) {
  return MaterialApp(
    home: AdaptiveNavigationScaffold(
      paneCount: paneCount,
      body: const SizedBox.expand(),
      navigationBar: const SizedBox(height: 80, width: double.infinity),
      navigationRail: const SizedBox(width: 80, height: double.infinity),
    ),
  );
}

void main() {
  testWidgets('shows the bottom bar and hides the rail at compact width', (
    tester,
  ) async {
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(_scaffold());
    await pumpFrames(tester);

    expect(
      tester.getSize(find.byKey(navigationBarRevealKey)).height,
      greaterThan(0),
    );
    expect(tester.getSize(find.byKey(navigationRailRevealKey)).width, 0);
  });

  testWidgets('shows the rail and collapses the bar at expanded width', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    await tester.pumpWidget(_scaffold());
    await pumpFrames(tester);

    expect(
      tester.getSize(find.byKey(navigationRailRevealKey)).width,
      greaterThan(0),
    );
    expect(tester.getSize(find.byKey(navigationBarRevealKey)).height, 0);
  });

  group('at medium width', () {
    // Material 3 puts a single-pane medium layout on a rail, and moves
    // navigation back to the bar when the body itself holds two panes.
    testWidgets('a single-pane body takes the rail', (tester) async {
      setWindowSize(tester, const Size(700, 900));
      await tester.pumpWidget(_scaffold());
      await pumpFrames(tester);

      expect(
        tester.getSize(find.byKey(navigationRailRevealKey)).width,
        greaterThan(0),
      );
      expect(tester.getSize(find.byKey(navigationBarRevealKey)).height, 0);
    });

    testWidgets('a two-pane body takes the bar', (tester) async {
      setWindowSize(tester, const Size(700, 900));
      await tester.pumpWidget(_scaffold(paneCount: 2));
      await pumpFrames(tester);

      expect(
        tester.getSize(find.byKey(navigationBarRevealKey)).height,
        greaterThan(0),
      );
      expect(tester.getSize(find.byKey(navigationRailRevealKey)).width, 0);
    });
  });
}
