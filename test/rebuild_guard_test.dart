// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// Counts its builds, and depends on the breakpoint of its region, as
/// adaptive content does.
class Probe extends StatelessWidget {
  const new({super.key, required this.builds});

  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    AdaptiveRegion.breakpointOf(context);
    builds.add(0);
    return const SizedBox.expand();
  }
}

void main() {
  testWidgets('a pane entering does not rebuild the other pane', (
    tester,
  ) async {
    final builds = <int>[];
    Widget layout({required bool open}) => app(
      Scaffold(
        body: SupportingPaneLayout(
          focus: Probe(builds: builds),
          supporting: open ? const SizedBox.expand() : null,
        ),
      ),
    );
    setWindowSize(tester, const Size(1000, 800));
    await tester.pumpWidget(layout(open: false));
    final alone = tester.getSize(find.byType(Probe)).width;
    await tester.pumpWidget(layout(open: true));
    builds.clear();
    await settle(tester);
    expect(builds, isEmpty);
    // The pane did enter, and took its room.
    expect(tester.getSize(find.byType(Probe)).width, alone - 360 - 24);
  });

  testWidgets('dragging the handle does not rebuild the panes', (tester) async {
    final builds = <int>[];
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ListDetailLayout<int>(
            selectedId: 1,
            resizable: true,
            listBuilder: (context) => Probe(builds: builds),
            detailBuilder: (context, id, placement) => Probe(builds: builds),
          ),
        ),
      ),
    );
    builds.clear();
    final list = tester.getSize(find.byType(Probe).first).width;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PaneResizer)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(5, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The drag moves the panes, within the breakpoints they are at.
    expect(tester.getSize(find.byType(Probe).first).width, greaterThan(list));
    await gesture.up();
    await settle(tester);
    expect(builds, isEmpty);
  });

  testWidgets('a breakpoint dependent rebuilds only when the breakpoint '
      'changes', (tester) async {
    final builds = <Breakpoint>[];
    setWindowSize(tester, const Size(900, 800));
    await tester.pumpWidget(
      app(
        AdaptiveRegion(
          child: Builder(
            builder: (context) {
              builds.add(AdaptiveRegion.breakpointOf(context));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(builds, [Breakpoint.expanded]);

    // A wider window of the same breakpoint, and a shorter one.
    setWindowSize(tester, const Size(1100, 800));
    await tester.pump();
    setWindowSize(tester, const Size(1100, 400));
    await tester.pump();
    expect(builds, [Breakpoint.expanded]);

    setWindowSize(tester, const Size(1250, 400));
    await tester.pump();
    expect(builds, [Breakpoint.expanded, Breakpoint.large]);
  });
}
