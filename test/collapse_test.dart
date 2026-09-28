// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/rendering.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const listKey = ValueKey('list');
const focusKey = ValueKey('focus');
const supportingKey = ValueKey('supporting');

Widget host(Widget layout) => app(Scaffold(body: layout));

// A list-detail layout whose selection the caller owns, and records.
Widget listDetail({
  required int? selectedId,
  ValueChanged<int?>? onSelectionChanged,
  PaneCollapse? listCollapse,
  PaneCollapse? detailCollapse,
  ListDetailEmptyBehavior<int> emptyBehavior =
      const ListDetailEmptyBehavior.placeholder(child: Text('Nothing')),
  PaneSplitController? splitController,
  Widget dragHandle = const PaneResizer(),
}) => ListDetailLayout<int>(
  selectedId: selectedId,
  onSelectionChanged: onSelectionChanged ?? (_) {},
  resizable: true,
  dragHandle: dragHandle,
  splitController: splitController,
  listCollapse: listCollapse,
  detailCollapse: detailCollapse,
  emptyBehavior: emptyBehavior,
  motion: const PaneMotion.none(),
  listBuilder: (context) {
    final layout = ListDetailLayout.of<int>(context);
    return ListView(
      key: listKey,
      children: [
        for (var i = 0; i < 5; i++)
          ListTile(
            key: ValueKey('item $i'),
            title: Text('Item $i'),
            selected: layout.isSelected(i),
            onTap: () => layout.select(i),
          ),
      ],
    );
  },
  detailBuilder: (context, id, placement) => switch (placement) {
    DetailPlacement.pane => SizedBox.expand(key: ValueKey('detail $id')),
    DetailPlacement.page => Scaffold(
      key: const ValueKey('page'),
      appBar: AppBar(title: Text('Page $id')),
      body: SizedBox.expand(key: ValueKey('detail $id')),
    ),
  },
);

Rect rectOfKey(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

Finder get handle => find.byType(PaneResizer);

Future<void> dragHandleBy(WidgetTester tester, double dx) async {
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(Offset(dx.sign * 20, 0));
  await tester.pump();
  await gesture.moveBy(Offset(dx, 0));
  await tester.pump(const Duration(milliseconds: 500));
  await gesture.up();
  await settle(tester);
}

List<String> actionLabels(WidgetTester tester) {
  final data = find.semantics
      .byLabel('Resize panes')
      .evaluate()
      .single
      .getSemanticsData();
  return [
    for (final id in data.customSemanticsActionIds!)
      ?CustomSemanticsAction.getAction(id)!.label,
  ];
}

bool itemSelected(WidgetTester tester, int id) =>
    tester.widget<ListTile>(find.byKey(ValueKey('item $id'))).selected;

void main() {
  group('List-detail', () {
    testWidgets('by default, the handle hides only the list beside a list '
        'of fixed width', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      expect(actionLabels(tester), [
        'Collapse pane',
        'Set pane width to 360',
        'Set pane width to 412',
        'Split panes evenly',
      ]);
      semantics.dispose();
    });

    testWidgets('a detail that collapses gives the list the whole width, '
        'with the handle in the trailing margin', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            detailCollapse: PaneCollapse.collapse,
            splitController: split,
          ),
        ),
      );
      await dragHandleBy(tester, 900);
      expect(split.value, PaneSplit.expanded);
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      expect(rectOfKey(tester, 'list'), const Rect.fromLTRB(24, 0, 1276, 800));
      expect(tester.getCenter(handle).dx, 1300 - 12);
    });

    testWidgets('selecting an item while the detail is hidden shows it '
        'again', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: const PaneSplit.width(400))
        ..value = PaneSplit.expanded;
      addTearDown(split.dispose);
      int? selected = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            listDetail(
              selectedId: selected,
              onSelectionChanged: (id) => setState(() => selected = id),
              detailCollapse: PaneCollapse.collapse,
              splitController: split,
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(split.value, const PaneSplit.width(400));
      expect(rectOfKey(tester, 'detail 2').left, 24 + 400 + 24);
    });

    testWidgets('selecting an item while the detail is hidden shows it at '
        'the default split, where the layout forgets resizes', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: const PaneSplit.width(400))
        ..value = PaneSplit.expanded;
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          ListDetailLayout<int>(
            selectedId: 1,
            resizable: true,
            resizeMemory: PaneResizeMemory.temporary,
            detailCollapse: PaneCollapse.collapse,
            splitController: split,
            motion: const PaneMotion.none(),
            listBuilder: (context) => ListView(
              key: listKey,
              children: [
                for (var i = 0; i < 5; i++)
                  ListTile(
                    title: Text('Item $i'),
                    onTap: () => ListDetailLayout.of<int>(context).select(i),
                  ),
              ],
            ),
            detailBuilder: (context, id, placement) =>
                SizedBox.expand(key: ValueKey('detail $id')),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(rectOfKey(tester, 'list').width, 412);
      expect(find.byKey(const ValueKey('detail 2')), findsOneWidget);
    });

    testWidgets('a detail that the handle dismisses closes as its close '
        'button does', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      final selections = <int?>[];
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            onSelectionChanged: selections.add,
            emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
            detailCollapse: PaneCollapse.dismiss,
            splitController: split,
          ),
        ),
      );
      await dragHandleBy(tester, 900);
      expect(selections, [null]);
      // The split stays; the selection the caller clears takes the detail.
      expect(split.value, PaneSplit.automatic);
      expect(rectOfKey(tester, 'list').width, 412);
    });

    testWidgets('a dismissed detail leaves the list alone, and a selection '
        'brings it back at the split it had', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: const PaneSplit.width(360));
      addTearDown(split.dispose);
      int? selected = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            listDetail(
              selectedId: selected,
              onSelectionChanged: (id) => setState(() => selected = id),
              emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
              detailCollapse: PaneCollapse.dismiss,
              splitController: split,
            ),
          ),
        ),
      );
      expect(actionLabels(tester), contains('Close pane'));
      await doubleTap(tester, handle);
      await settle(tester);
      // A double tap hides the list first, where the handle may hide it.
      expect(split.value, PaneSplit.collapsed);
      await doubleTap(tester, handle);
      await settle(tester);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            listDetail(
              selectedId: selected,
              onSelectionChanged: (id) => setState(() => selected = id),
              listCollapse: PaneCollapse.never,
              emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
              detailCollapse: PaneCollapse.dismiss,
              splitController: split,
            ),
          ),
        ),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect(selected, isNull);
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      expect(rectOfKey(tester, 'list'), const Rect.fromLTRB(24, 0, 1276, 800));
      // With the detail gone, there is no handle.
      expect(handle, findsNothing);

      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(rectOfKey(tester, 'list').width, 360);
      expect(find.byKey(const ValueKey('detail 2')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the handle fades out where it is as a dismissed detail '
        'leaves, taking no input, and comes in with a detail that enters', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      int? selected = 1;
      var dismissals = 0;
      Widget layout({PaneMotion? motion}) => StatefulBuilder(
        builder: (context, setState) => host(
          ListDetailLayout<int>(
            selectedId: selected,
            onSelectionChanged: (id) => setState(() {
              if (id == null) dismissals++;
              selected = id;
            }),
            resizable: true,
            listCollapse: PaneCollapse.never,
            detailCollapse: PaneCollapse.dismiss,
            emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
            motion: motion,
            listBuilder: (context) => ListView(
              key: listKey,
              children: [
                for (var i = 0; i < 5; i++)
                  ListTile(
                    title: Text('Item $i'),
                    onTap: () => ListDetailLayout.of<int>(context).select(i),
                  ),
              ],
            ),
            detailBuilder: (context, id, placement) =>
                SizedBox.expand(key: ValueKey('detail $id')),
          ),
        ),
      );
      // The handle's own fade, the nearest above it.
      double opacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(of: handle, matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;

      // Whether a pointer at the handle's centre reaches it.
      bool hits(Offset at) => tester
          .hitTestOnBinding(at)
          .path
          .any((entry) => entry.target == tester.renderObject(handle));

      // The handle's position and opacity, frame by frame, until it has
      // gone.
      Future<List<(double, double)>> fadeOut() async {
        final frames = <(double, double)>[];
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (handle.evaluate().isEmpty) break;
          frames.add((tester.getCenter(handle).dx, opacity()));
          // Fading, it is in the way of nothing.
          expect(hits(tester.getCenter(handle)), isFalse);
        }
        return frames;
      }

      await tester.pumpWidget(layout());
      await settle(tester);
      expect(opacity(), 1);
      final at = tester.getCenter(handle);
      expect(hits(at), isTrue);
      await doubleTap(tester, handle);
      expect(dismissals, 1);
      await tester.pump();
      var frames = await fadeOut();
      expect(frames, isNotEmpty);
      expect(frames.map((frame) => frame.$1), everyElement(at.dx));
      for (var i = 1; i < frames.length; i++) {
        expect(frames[i].$2, lessThan(frames[i - 1].$2));
      }
      await settle(tester);
      expect(handle, findsNothing);

      // A detail enters with the handle, which fades in as it comes, and
      // takes input once the detail has arrived.
      await tester.tap(find.text('Item 2'));
      await tester.pump();
      expect(handle, findsOneWidget);
      final opacities = <double>[];
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        opacities.add(opacity());
        if (frame == 2) expect(hits(tester.getCenter(handle)), isFalse);
      }
      expect(opacities.first, inExclusiveRange(0, 1));
      expect(opacities.last, 1);
      for (var i = 1; i < opacities.length; i++) {
        expect(opacities[i], greaterThanOrEqualTo(opacities[i - 1]));
      }
      await settle(tester);
      expect(hits(tester.getCenter(handle)), isTrue);

      // Let go past the end, a drag that dismisses the detail leaves the
      // handle where the pointer let it go, to fade out there.
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 300));
      final released = tester.getCenter(handle).dx;
      await gesture.up();
      expect(dismissals, 2);
      frames = await fadeOut();
      expect(frames, isNotEmpty);
      expect(frames.map((frame) => frame.$1), everyElement(released));
      await settle(tester);
      expect(handle, findsNothing);
      await tester.tap(find.text('Item 3'));
      await settle(tester);

      // Where the panes do not move, neither does the handle fade.
      await tester.pumpWidget(layout(motion: const PaneMotion.none()));
      await doubleTap(tester, handle);
      await tester.pump();
      expect(handle, findsNothing);
      await settle(tester);
    });

    testWidgets('only a detail that leaves the list alone can be dismissed '
        'with the handle', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      for (final emptyBehavior in const [
        ListDetailEmptyBehavior<int>.placeholder(),
        ListDetailEmptyBehavior<int>.select(0),
      ]) {
        await tester.pumpWidget(
          host(
            listDetail(
              selectedId: 1,
              emptyBehavior: emptyBehavior,
              detailCollapse: PaneCollapse.dismiss,
            ),
          ),
        );
        expect(tester.takeException(), isAssertionError);
        await tester.pumpWidget(const SizedBox());
      }
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
            detailCollapse: PaneCollapse.dismiss,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a list that never collapses leaves the toggle to the '
        'detail, or to nothing', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            listCollapse: PaneCollapse.never,
            detailCollapse: PaneCollapse.collapse,
            splitController: split,
          ),
        ),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.expanded);

      split.value = PaneSplit.automatic;
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            listCollapse: PaneCollapse.never,
            splitController: split,
          ),
        ),
      );
      await settle(tester);
      expect(actionLabels(tester), [
        'Set pane width to 360',
        'Set pane width to 412',
        'Split panes evenly',
      ]);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      final data = find.semantics
          .byLabel('Resize panes')
          .evaluate()
          .single
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      semantics.dispose();
    });

    testWidgets("custom stops leave out the ends the handle may not hide", (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            listCollapse: PaneCollapse.never,
            splitController: split,
            dragHandle: const PaneResizer(
              snapStops: [PaneSplit.collapsed, PaneSplit.width(500)],
            ),
          ),
        ),
      );
      await dragHandleBy(tester, -500);
      expect(split.value, const PaneSplit.width(500));
    });

    testWidgets('the app may set a split that the handle may not', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(listDetail(selectedId: 1, splitController: split)),
      );
      split.value = PaneSplit.expanded;
      await settle(tester);
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      expect(rectOfKey(tester, 'list').width, 1300 - 48);
    });
  });

  group('One pane with a selection', () {
    testWidgets('shows the detail, and the list there marks nothing', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      int? selected = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            listDetail(
              selectedId: selected,
              onSelectionChanged: (id) => setState(() => selected = id),
            ),
          ),
        ),
      );
      expect(itemSelected(tester, 1), isTrue);
      setWindowSize(tester, const Size(500, 800));
      await tester.pump();
      await settle(tester);
      expect(find.text('Page 1'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(selected, isNull);
      expect(find.text('Page 1'), findsNothing);
      expect(itemSelected(tester, 1), isFalse);
    });
  });

  group('Supporting pane', () {
    Widget supporting({
      VoidCallback? onSupportingDismissed,
      PaneSplitController? splitController,
      Widget supporting = const SizedBox.expand(key: supportingKey),
    }) => host(
      SupportingPaneLayout(
        focus: const SizedBox.expand(key: focusKey),
        supporting: supporting,
        resizable: true,
        splitController: splitController,
        onSupportingDismissed: onSupportingDismissed,
        motion: const PaneMotion.none(),
      ),
    );

    testWidgets('a pane that cannot be dismissed has no handle', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(supporting());
      expect(find.byKey(supportingKey), findsOneWidget);
      expect(handle, findsNothing);
    });

    testWidgets('the handle dismisses a pane that can be dismissed, with a '
        'drag or a double tap', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      var dismissed = 0;
      await tester.pumpWidget(
        supporting(
          splitController: split,
          onSupportingDismissed: () => dismissed++,
        ),
      );
      expect(actionLabels(tester), [
        'Close pane',
        'Set pane width to 360',
        'Set pane width to 412',
        'Split panes evenly',
      ]);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(dismissed, 1);
      // The pane returns to its place, from where the app takes it away.
      expect(split.value, PaneSplit.automatic);
      expect(rectOfKey(tester, 'supporting').width, 412);

      await dragHandleBy(tester, 600);
      expect(dismissed, 2);
      expect(split.value, PaneSplit.automatic);
      semantics.dispose();
    });

    testWidgets('the focus pane is never hidden, and a split that would hide '
        'either pane keeps both', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        supporting(splitController: split, onSupportingDismissed: () {}),
      );
      expect(
        actionLabels(tester),
        isNot(contains('Expand pane to full width')),
      );
      // The focus pane keeps its share while the drag lasts, too.
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      for (var step = 0; step < 12; step++) {
        await gesture.moveBy(const Offset(-100, 0));
        await tester.pump();
        expect(rectOfKey(tester, 'focus').left, 24);
        expect(
          rectOfKey(tester, 'focus').width,
          greaterThanOrEqualTo((1300 - 48 - 24) / 2 - 0.5),
        );
      }
      await gesture.up();
      await settle(tester);
      expect(find.byKey(focusKey), findsOneWidget);
      // The focus pane keeps half the space the panes' content shares.
      expect(
        rectOfKey(tester, 'focus').width,
        closeTo((1300 - 48 - 24) / 2, 0.5),
      );

      for (final hiding in [PaneSplit.expanded, PaneSplit.collapsed]) {
        split.value = const PaneSplit.width(300);
        await settle(tester);
        expect(rectOfKey(tester, 'supporting').width, 300);
        split.value = hiding;
        await settle(tester);
        expect(find.byKey(focusKey), findsOneWidget);
        expect(rectOfKey(tester, 'supporting').width, 412);
      }
      semantics.dispose();
    });

    testWidgets('a split that would hide a pane neither hides nor dismisses '
        'one, from the start either', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      var dismissed = 0;
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      await tester.pumpWidget(
        supporting(
          splitController: split,
          onSupportingDismissed: () => dismissed++,
        ),
      );
      expect(rectOfKey(tester, 'supporting').width, 412);
      split.value = PaneSplit.expanded;
      await settle(tester);
      expect(find.byKey(focusKey), findsOneWidget);
      expect(dismissed, 0);
    });

    testWidgets('a side sheet never takes the whole width', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        supporting(
          onSupportingDismissed: () {},
          supporting: const SideSheet(child: Text('Sheet')),
        ),
      );
      // No stop wider than the sheet's 400dp: neither 412dp nor the centred
      // split.
      expect(actionLabels(tester), [
        'Close pane',
        'Set pane width to 360',
        'Restore pane',
      ]);
      semantics.dispose();
    });
  });
}
