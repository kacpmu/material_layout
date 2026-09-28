// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const listKey = ValueKey('list');
const detailKey = ValueKey('detail');

Widget resizable({
  PaneSplitController? splitController,
  Breakpoint twoPaneBreakpoint = Breakpoint.expanded,
  Widget dragHandle = const PaneResizer(),
}) => app(
  Scaffold(
    body: ListDetailLayout<int>(
      selectedId: 1,
      resizable: true,
      dragHandle: dragHandle,
      splitController: splitController,
      twoPaneBreakpoint: twoPaneBreakpoint,
      listBuilder: (context) => const SizedBox.expand(key: listKey),
      detailBuilder: (context, id, placement) =>
          const SizedBox.expand(key: detailKey),
    ),
  ),
);

Rect listRect(WidgetTester tester) => tester.getRect(find.byKey(listKey));

Rect detailRect(WidgetTester tester) => tester.getRect(find.byKey(detailKey));

Finder get handle => find.byType(PaneResizer);

Future<void> resize(WidgetTester tester, Size size) async {
  setWindowSize(tester, size);
  await tester.pump();
  await settle(tester);
}

// Drags the handle by [dx] without a fling: the pointer first clears the
// touch slop, and rests before it lifts.
Future<void> dragHandle(WidgetTester tester, double dx) async {
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(Offset(dx.sign * 20, 0));
  await tester.pump();
  await gesture.moveBy(Offset(dx, 0));
  await tester.pump(const Duration(milliseconds: 500));
  await gesture.up();
  await settle(tester);
}

void main() {
  testWidgets('a layout shows a handle only when resizable and two panes '
      'show', (tester) async {
    setWindowSize(tester, const Size(1000, 800));
    await tester.pumpWidget(resizable());
    expect(handle, findsOneWidget);
    expect(find.byType(PaneDragHandle), findsOneWidget);
    await resize(tester, const Size(400, 800));
    expect(handle, findsNothing);

    // Two panes of a layout that is not resizable have none.
    await resize(tester, const Size(1000, 800));
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ListDetailLayout<int>(
            selectedId: 1,
            listBuilder: (context) => const SizedBox.expand(key: listKey),
            detailBuilder: (context, id, placement) =>
                const SizedBox.expand(key: detailKey),
          ),
        ),
      ),
    );
    expect(find.byKey(detailKey), findsOneWidget);
    expect(handle, findsNothing);
  });

  group('The drag handle', () {
    testWidgets('sits on the spacer, with a 48dp target', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      final box = tester.getRect(handle);
      expect(box.width, 48);
      expect(box.center.dx, listRect(tester).right + 12);
      expect(box.height, 800);
    });

    testWidgets('takes double taps across its whole target, and nowhere '
        'beside it along the spacer', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      final center = tester.getCenter(handle);
      // In the list, beside the spacer and away from the handle's square.
      await doubleTapAt(tester, center.translate(-20, -300));
      await settle(tester);
      expect(find.byKey(listKey), findsOneWidget);
      // Within the square, beside the grip.
      await doubleTapAt(tester, center.translate(-20, 0));
      await settle(tester);
      expect(find.byKey(listKey), findsNothing);
    });

    testWidgets('takes input along the whole spacer', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      // On the spacer, far from the grip.
      final top = Offset(tester.getCenter(handle).dx, 100);
      final gesture = await tester.startGesture(top);
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));

      await doubleTapAt(tester, Offset(tester.getCenter(handle).dx, 100));
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
    });

    testWidgets('leaves the panes beside it their input', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      var taps = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListDetailLayout<int>(
              selectedId: 1,
              resizable: true,
              listBuilder: (context) => GestureDetector(
                key: listKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox.expand(),
              ),
              detailBuilder: (context, id, placement) =>
                  const SizedBox.expand(key: detailKey),
            ),
          ),
        ),
      );
      final list = listRect(tester);
      final grip = tester.getCenter(handle);
      // 8dp inside the list: within the handle's box, outside its target.
      for (final y in [100.0, grip.dy - 30, grip.dy + 30]) {
        await tester.tapAt(Offset(list.right - 8, y));
        await settle(tester);
      }
      expect(taps, 3);
      expect(listRect(tester).width, 360);
    });

    testWidgets('rests in the margin beside a hidden pane, which the other '
        'leaves the whole width', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      expect(detailRect(tester).left, 24);
      expect(detailRect(tester).right, 1000 - 24);
      expect(tester.getCenter(handle).dx, 12);
      // Its target reaches past the edge, and into the pane beside it.
      await doubleTapAt(tester, Offset(2, tester.getCenter(handle).dy));
      await settle(tester);
      expect(listRect(tester).width, 360);

      split.value = PaneSplit.expanded;
      await settle(tester);
      expect(listRect(tester).left, 24);
      expect(listRect(tester).right, 1000 - 24);
      expect(tester.getCenter(handle).dx, 1000 - 12);
    });

    testWidgets('in a layout given as a pane of another, rests in the '
        'margin the pane meets', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      // The outer layout's pane reaches the edges, and the list-detail
      // layout in it keeps the margins there itself.
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: ListDetailLayout<int>(
                selectedId: 1,
                resizable: true,
                splitController: split,
                listBuilder: (context) => const SizedBox.expand(key: listKey),
                detailBuilder: (context, id, placement) =>
                    const SizedBox.expand(key: detailKey),
              ),
            ),
          ),
        ),
      );
      expect(detailRect(tester).left, 24);
      expect(detailRect(tester).right, 1000 - 24);
      expect(tester.getCenter(handle).dx, 12);
      await doubleTapAt(tester, Offset(2, tester.getCenter(handle).dy));
      await settle(tester);
      expect(listRect(tester).width, 360);
      expect(listRect(tester).left, 24);
    });

    testWidgets('where there is no margin, rests half a spacer inside the '
        'pane that stays', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      // Wrapped in another widget, the list-detail layout is not recognised
      // as a layout: its pane is set in, and it keeps no margin of its own.
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: Builder(
                builder: (context) => ListDetailLayout<int>(
                  selectedId: 1,
                  resizable: true,
                  splitController: split,
                  listBuilder: (context) => const SizedBox.expand(key: listKey),
                  detailBuilder: (context, id, placement) =>
                      const SizedBox.expand(key: detailKey),
                ),
              ),
            ),
          ),
        ),
      );
      // The detail takes the whole pane, and the handle rests over it.
      expect(detailRect(tester).left, 24);
      expect(detailRect(tester).right, 1000 - 24);
      expect(tester.getCenter(handle).dx, 24 + 12);
      await doubleTapAt(tester, tester.getCenter(handle));
      await settle(tester);
      expect(listRect(tester).width, 360);
    });

    testWidgets('grows its grip from 4×48dp to 12×52dp while pressed', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      final paint = find.descendant(
        of: find.byType(PaneDragHandle),
        matching: find.byType(CustomPaint),
      );
      final center = Offset(24, tester.getSize(paint).height / 2);
      RRect grip(double width, double height) => RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: width, height: height),
        Radius.circular(width / 2),
      );
      expect(tester.renderObject(paint), paints..rrect(rrect: grip(4, 48)));

      final gesture = await tester.startGesture(tester.getCenter(handle));
      await settle(tester);
      expect(tester.renderObject(paint), paints..rrect(rrect: grip(12, 52)));
      await gesture.up();
      await settle(tester);
      // Let go, the grip returns to rest; held that long, the press was a
      // long press, which split the panes evenly.
      expect(tester.renderObject(paint), paints..rrect(rrect: grip(4, 48)));
      expect(
        PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle))),
        isNot(contains(WidgetState.pressed)),
      );
      expect((listRect(tester).right + detailRect(tester).left) / 2, 1000 / 2);
    });

    testWidgets('grows its grip on the fast spatial spring', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      final paint = find.descendant(
        of: find.byType(PaneDragHandle),
        matching: find.byType(CustomPaint),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      // A press shows at once, whatever the gesture turns out to be.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final spring = const MotionScheme.expressive().fastSpatial.simulation(
        0,
        1,
      );
      final expected = 4 + (12 - 4) * spring.x(0.03);
      expect(
        tester.renderObject(paint),
        paints..something((method, arguments) {
          if (method != #drawRRect) return false;
          final rrect = arguments.first as RRect;
          return (rrect.width - expected).abs() < 0.05;
        }),
      );
      await gesture.up();
      await settle(tester);
    });

    testWidgets('a double tap collapses the fixed pane and another shows it '
        'again', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      await doubleTap(tester, handle);
      await settle(tester);
      expect(find.byKey(listKey), findsNothing);
      // The detail takes the whole width, and the handle rests in the margin
      // beside the hidden pane, so that it can show the pane again.
      expect(detailRect(tester).left, 24);
      expect(detailRect(tester).right, 1000 - 24);
      expect(tester.getCenter(handle).dx, 12);

      await doubleTap(tester, handle);
      await settle(tester);
      expect(listRect(tester).width, 360);
    });

    testWidgets('a single tap returns to the default split', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: const PaneSplit.width(412));
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      expect(listRect(tester).width, 412);
      await tester.tap(handle);
      await settle(tester);
      expect(listRect(tester).width, 360);
      expect(split.value, PaneSplit.automatic);
    });

    testWidgets('a drag settles on the nearest stop', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      expect(listRect(tester).width, 412);

      await dragHandle(tester, -40);
      expect(listRect(tester).width, 360);
      expect(split.value, const PaneSplit.width(360));

      await dragHandle(tester, 220);
      expect(split.value, PaneSplit.centered);
      final list = listRect(tester);
      final detail = detailRect(tester);
      expect((list.right + detail.left) / 2, 650);
    });

    testWidgets('dragged past the pane minimum, the pane collapses', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(resizable());
      await dragHandle(tester, -400);
      expect(find.byKey(listKey), findsNothing);
      expect(detailRect(tester).left, 24);
    });

    testWidgets('at medium, a drag may give either pane the whole width', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        resizable(splitController: split, twoPaneBreakpoint: Breakpoint.medium),
      );
      await dragHandle(tester, 330);
      expect(split.value, PaneSplit.expanded);
      expect(find.byKey(detailKey), findsNothing);
      expect(listRect(tester).right, 700 - 24);

      split.value = PaneSplit.automatic;
      await settle(tester);
      await dragHandle(tester, -330);
      expect(split.value, PaneSplit.collapsed);
      expect(find.byKey(listKey), findsNothing);
    });
  });

  group('Dragging', () {
    testWidgets('a hidden pane shows as it is dragged back', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(resizable());
      await doubleTap(tester, handle);
      await settle(tester);
      expect(find.byKey(listKey), findsNothing);

      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(280, 0));
      await tester.pump();
      expect(find.byKey(listKey), findsOneWidget);
      expect(listRect(tester).right, greaterThan(24 + 200));
      await gesture.up();
      await settle(tester);
      expect(listRect(tester).width, 360);
    });

    testWidgets('a drag in a nested layout starts where the panes are', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: PaneSplit.expanded);
      addTearDown(split.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: ListDetailLayout<int>(
                selectedId: 1,
                resizable: true,
                splitController: split,
                listBuilder: (context) => const SizedBox.expand(key: listKey),
                detailBuilder: (context, id, placement) =>
                    const SizedBox.expand(key: detailKey),
              ),
            ),
          ),
        ),
      );
      final before = tester.getCenter(handle).dx;
      final list = listRect(tester).width;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(19, 0));
      await tester.pump();
      expect(tester.getCenter(handle).dx, closeTo(before - 1, 1));
      expect(listRect(tester).width, closeTo(list - 1, 1));
      await gesture.up();
      await settle(tester);
    });

    testWidgets('a pointer the platform cancels restores the split', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.cancel();
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 412);
    });

    testWidgets('a drag carried on by another pointer survives the first '
        'one being cancelled', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      final center = tester.getCenter(handle);
      final first = await tester.startGesture(center, pointer: 1);
      await first.moveBy(const Offset(-20, 0));
      await tester.pump();
      final second = await tester.startGesture(
        center.translate(0, 10),
        pointer: 2,
      );
      await tester.pump();
      await first.cancel();
      await second.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await second.up();
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));
    });

    testWidgets('a drag ends with its handle', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      // The window narrows to one pane mid-drag, which removes the handle.
      await resize(tester, const Size(500, 800));
      expect(handle, findsNothing);
      await gesture.up();
      await settle(tester);
      expect(split.value, PaneSplit.automatic);

      await resize(tester, const Size(1300, 800));
      expect(listRect(tester).width, 412);
      expect(detailRect(tester).left, 24 + 412 + 24);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
    });
  });

  group('Settling', () {
    testWidgets('with no stops, a drag rests where it is let go, within the '
        "panes' minimum widths", (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: const PaneResizer(snapStops: []),
        ),
      );
      await dragHandle(tester, -30);
      // The drag starts where it clears the touch slop.
      expect(split.value, const PaneSplit.width(412 - 30));
      expect(listRect(tester).width, 382);

      // Past the minimum, the pane stops there rather than collapsing.
      await dragHandle(tester, -300);
      expect(split.value, const PaneSplit.width(360));
      expect(find.byKey(listKey), findsOneWidget);
    });

    testWidgets('a fling past the last stop settles on it', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: PaneSplit.centered);
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      // The detail beside a list of fixed width never hides: the centred
      // split is the last stop.
      await tester.fling(handle, const Offset(200, 0), 2000);
      await settle(tester);
      expect(split.value, PaneSplit.centered);
      expect(find.byKey(detailKey), findsOneWidget);

      await tester.fling(handle, const Offset(-100, 0), 2000);
      await settle(tester);
      // From the centred split, the fling passes 412dp and 360dp, and settles
      // on the stop just ahead: 412dp, the default.
      expect(split.value, PaneSplit.automatic);
    });

    testWidgets('a handle replaced during a drag gives the split back', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(listRect(tester).width, lessThan(412));

      // Another handle, as when the app changes its gestures mid-drag.
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: PaneResizer(key: UniqueKey()),
        ),
      );
      await settle(tester);
      expect(listRect(tester).width, 412);
      await gesture.up();
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 412);
    });

    testWidgets('a layout that starts with a pane hidden shows both at the '
        'default split', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      expect(find.byKey(listKey), findsNothing);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 412);
    });

    testWidgets('a split that is not remembered shows both panes again at '
        'the default', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController(split: const PaneSplit.width(412));
      addTearDown(split.dispose);
      Widget layout(PaneResizeMemory memory) => app(
        Scaffold(
          body: ListDetailLayout<int>(
            selectedId: 1,
            resizable: true,
            resizeMemory: memory,
            splitController: split,
            listBuilder: (context) => const SizedBox.expand(key: listKey),
            detailBuilder: (context, id, placement) =>
                const SizedBox.expand(key: detailKey),
          ),
        ),
      );
      await tester.pumpWidget(layout(PaneResizeMemory.persistent));
      expect(listRect(tester).width, 412);
      await doubleTap(tester, handle);
      await settle(tester);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, const PaneSplit.width(412));

      await tester.pumpWidget(layout(PaneResizeMemory.temporary));
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 360);
    });
  });

  group('A pane the handle may not hide', () {
    testWidgets('keeps its minimum width while a drag pushes it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      // Far past the detail's minimum width, towards the window's edge.
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        expect(detailRect(tester).width, greaterThanOrEqualTo(360));
        expect(detailRect(tester).right, 1300 - 24);
      }
      // The drag holds there, and turns back at once.
      final held = tester.getCenter(handle).dx;
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      expect(tester.getCenter(handle).dx, moreOrLessEquals(held - 50));
      await gesture.up();
      await settle(tester);
      expect(split.value.showsBothPanes, isTrue);
      expect(find.byKey(detailKey), findsOneWidget);
    });

    testWidgets('as a list that never collapses, keeps its minimum width', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListDetailLayout<int>(
              selectedId: 1,
              resizable: true,
              listCollapse: PaneCollapse.never,
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) =>
                  const SizedBox.expand(key: detailKey),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      for (var step = 0; step < 6; step++) {
        await gesture.moveBy(const Offset(-100, 0));
        await tester.pump();
        expect(listRect(tester).width, 360);
        expect(listRect(tester).left, 24);
      }
      await gesture.up();
      await settle(tester);
      expect(listRect(tester).width, 360);
    });
  });

  group('Default split', () {
    testWidgets('settling on the default width keeps the default, which '
        'follows the breakpoint', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      // Settles back on 360dp, the default at expanded.
      await dragHandle(tester, 5);
      expect(split.value, PaneSplit.automatic);
      await resize(tester, const Size(1300, 800));
      expect(listRect(tester).width, 412);
    });

    testWidgets('an even split at medium keeps the default too', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        resizable(splitController: split, twoPaneBreakpoint: Breakpoint.medium),
      );
      await dragHandle(tester, 30);
      expect(split.value, PaneSplit.automatic);
      await resize(tester, const Size(1300, 800));
      expect(listRect(tester).width, 412);
    });
  });

  group('Persistent resizing', () {
    testWidgets('a collapsed pane stays collapsed at every size', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable(twoPaneBreakpoint: Breakpoint.medium));
      await doubleTap(tester, handle);
      await settle(tester);
      expect(find.byKey(listKey), findsNothing);

      // The detail stays at the whole width.
      for (final width in [700.0, 1300.0, 1700.0, 1000.0]) {
        await resize(tester, Size(width, 800));
        expect(find.byKey(listKey), findsNothing, reason: '$width');
        expect(detailRect(tester).left, 24, reason: '$width');
        expect(detailRect(tester).right, width - 24, reason: '$width');
      }
    });

    testWidgets('a width survives breakpoint changes', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(resizable());
      await dragHandle(tester, -40);
      expect(listRect(tester).width, 360);
      await resize(tester, const Size(1700, 800));
      expect(listRect(tester).width, 360);
      await resize(tester, const Size(1000, 800));
      expect(listRect(tester).width, 360);
    });
  });

  group('Keyboard and assistive technology', () {
    Future<void> focusHandle(WidgetTester tester) async {
      Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
      await tester.pump();
    }

    testWidgets('Enter toggles the pane', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(resizable());
      await focusHandle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.byKey(listKey), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settle(tester);
      expect(listRect(tester).width, 360);
    });

    testWidgets('arrow keys move between stops; Home and End go to the '
        'ends', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));
      await focusHandle(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      // 412dp is the default at large: the split returns to the default,
      // which then follows the breakpoint.
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 412);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);
      expect(split.value, PaneSplit.centered);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
    });

    testWidgets('arrow keys follow the screen in right-to-left layouts', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListDetailLayout<int>(
              selectedId: 1,
              resizable: true,
              splitController: split,
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) =>
                  const SizedBox.expand(key: detailKey),
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await focusHandle(tester);
      // The list is on the right: moving the spacer left widens it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(split.value, PaneSplit.centered);
    });

    testWidgets('it is a slider with an action per stop', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(resizable(splitController: split));

      final node = find.semantics.byLabel('Resize panes');
      final data = node.evaluate().single.getSemanticsData();
      expect(data.flagsCollection.isSlider, isTrue);
      // The list's share of the 1228dp the panes share.
      expect(data.value, '${(412 / 1228 * 100).round()}%');
      // Hint overrides are custom actions too; they carry no label.
      final labels = [
        for (final id in data.customSemanticsActionIds!)
          ?CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, [
        'Collapse pane',
        'Set pane width to 360',
        'Set pane width to 412',
        'Split panes evenly',
      ]);

      tester.semantics.customAction(
        node,
        const CustomSemanticsAction(label: 'Split panes evenly'),
      );
      await settle(tester);
      expect(split.value, PaneSplit.centered);

      tester.semantics.decrease(find.semantics.byLabel('Resize panes'));
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect(listRect(tester).width, 412);
      semantics.dispose();
    });
  });

  testWidgets('the handle reports the split at the current size', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController(split: const PaneSplit.width(412));
    addTearDown(split.dispose);
    await tester.pumpWidget(resizable(splitController: split));
    SemanticsData data() => find.semantics
        .byLabel('Resize panes')
        .evaluate()
        .single
        .getSemanticsData();
    expect(data().value, '${(412 / 1228 * 100).round()}%');

    split.value = PaneSplit.centered;
    await settle(tester);
    expect(data().value, '50%');
    await resize(tester, const Size(1700, 800));
    expect(data().value, '50%');
    // The next stop down is 412dp of the 1628dp the panes share.
    expect(data().decreasedValue, '${(412 / 1628 * 100).round()}%');
    semantics.dispose();
  });

  testWidgets('a custom grip keeps the behaviour', (tester) async {
    setWindowSize(tester, const Size(1000, 800));
    await tester.pumpWidget(
      resizable(
        dragHandle: const PaneResizer(
          child: SizedBox(key: ValueKey('grip'), width: 8, height: 8),
        ),
      ),
    );
    expect(find.byType(PaneDragHandle), findsNothing);
    // The grip only draws; the handle around it takes the double tap.
    await doubleTap(tester, find.byKey(const ValueKey('grip')));
    await settle(tester);
    expect(find.byKey(listKey), findsNothing);
  });

  testWidgets('custom snap stops replace the defaults', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    await tester.pumpWidget(
      resizable(
        splitController: split,
        dragHandle: const PaneResizer(snapStops: [PaneSplit.width(500)]),
      ),
    );
    await dragHandle(tester, -40);
    expect(split.value, const PaneSplit.width(500));
    expect(listRect(tester).width, 500);
  });

  group('Beside a pane the split hides', () {
    // A linear motion, which moves the panes steadily and then stops.
    const motion = PaneMotion(
      enter: Motion.curved(
        duration: Duration(milliseconds: 320),
        curve: Curves.linear,
      ),
      exit: Motion.curved(
        duration: Duration(milliseconds: 320),
        curve: Curves.linear,
      ),
    );

    // The detail's left edge, frame by frame.
    Future<List<double>> edges(WidgetTester tester) async {
      final lefts = <double>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final detail = find.byKey(detailKey);
        if (detail.evaluate().isNotEmpty) lefts.add(detailRect(tester).left);
      }
      return lefts;
    }

    for (final placement in MarginPlacement.values) {
      testWidgets("a pane opens and closes the handle's room as it moves "
          '(${placement.name})', (tester) async {
        final split = PaneSplitController(split: PaneSplit.collapsed);
        addTearDown(split.dispose);
        Widget layout(int? selectedId) => app(
          Scaffold(
            body: ListDetailLayout<int>(
              selectedId: selectedId,
              onSelectionChanged: (_) {},
              resizable: true,
              splitController: split,
              marginPlacement: placement,
              motion: motion,
              emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) =>
                  const SizedBox.expand(key: detailKey),
            ),
          ),
        );
        setWindowSize(tester, const Size(1000, 800));
        await tester.pumpWidget(layout(null));
        await settle(tester);

        // Whether a pointer at the handle's centre reaches it.
        bool handleTakesInput() => tester
            .hitTestOnBinding(tester.getCenter(handle))
            .path
            .any((entry) => entry.target == tester.renderObject(handle));

        // Entering, the detail moves steadily into its place, never back,
        // and the handle comes with it, taking input once it has arrived.
        await tester.pumpWidget(layout(1));
        await tester.pump(const Duration(milliseconds: 16));
        expect(handle, findsOneWidget);
        expect(handleTakesInput(), isFalse);
        final entering = await edges(tester);
        expect(entering.first - entering.last, greaterThan(100));
        for (var i = 1; i < entering.length; i++) {
          expect(
            entering[i],
            lessThanOrEqualTo(entering[i - 1] + 0.5),
            reason: '$entering',
          );
        }
        await settle(tester);
        expect(detailRect(tester).left, entering.last);
        expect(tester.getCenter(handle).dx, 12);
        expect(handleTakesInput(), isTrue);

        // Leaving, it moves toward the trailing edge from the first frame.
        await tester.pumpWidget(layout(null));
        final leaving = await edges(tester);
        expect(leaving.first, greaterThan(entering.last), reason: '$leaving');
        for (var i = 1; i < leaving.length; i++) {
          expect(
            leaving[i],
            greaterThanOrEqualTo(leaving[i - 1] - 0.5),
            reason: '$leaving',
          );
        }
      });
    }
  });
}
