// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kDoubleTapTimeout, kLongPressTimeout, kTouchSlop;
import 'package:flutter/rendering.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const listKey = ValueKey('list');

Widget resizable({
  Widget dragHandle = const PaneResizer(),
  PaneSplitController? splitController,
}) => app(
  Scaffold(
    body: ListDetailLayout<int>(
      selectedId: 1,
      resizable: true,
      dragHandle: dragHandle,
      splitController: splitController,
      motion: const PaneMotion.none(),
      listBuilder: (context) => const SizedBox.expand(key: listKey),
      detailBuilder: (context, id, placement) => const SizedBox.expand(),
    ),
  ),
);

Finder get handle => find.byType(PaneResizer);

void main() {
  testWidgets('each gesture calls its callback with the handle', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    final tapped = <PaneSplit>[];
    await tester.pumpWidget(
      resizable(
        splitController: split,
        dragHandle: PaneResizer(
          onTap: (handle) => tapped.add(handle.split),
          onDoubleTap: null,
          onLongPress: (handle) => handle.moveTo(PaneSplit.centered),
        ),
      ),
    );
    // Without a double tap to wait for, a tap is not held back.
    await tester.tap(handle);
    await tester.pump();
    expect(tapped, [PaneSplit.automatic]);

    await tester.longPress(handle);
    await settle(tester);
    expect(split.value, PaneSplit.centered);
    expect(tapped, [PaneSplit.automatic]);
  });

  testWidgets('a tap waits to see whether a double tap follows, where one '
      'is listened for', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    var taps = 0;
    var doubleTaps = 0;
    await tester.pumpWidget(
      resizable(
        dragHandle: PaneResizer(
          onTap: (_) => taps++,
          onDoubleTap: (_) => doubleTaps++,
        ),
      ),
    );
    await tester.tap(handle);
    await tester.pump();
    expect(taps, 0);
    await tester.pump(kDoubleTapTimeout);
    expect(taps, 1);

    await doubleTap(tester, handle);
    await tester.pump(kDoubleTapTimeout);
    expect(doubleTaps, 1);
    expect(taps, 1);
  });

  testWidgets('by default, a tap restores the default split, and a long '
      'press splits the panes evenly', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController(split: const PaneSplit.width(360));
    addTearDown(split.dispose);
    await tester.pumpWidget(resizable(splitController: split));
    await tester.tap(handle);
    await tester.pump(kDoubleTapTimeout);
    await settle(tester);
    expect(split.value, PaneSplit.automatic);

    await tester.longPress(handle);
    await settle(tester);
    expect(split.value, PaneSplit.centered);

    // A tap shows a hidden pane again, at the default split.
    split.value = PaneSplit.collapsed;
    await settle(tester);
    await tester.tap(handle);
    await tester.pump(kDoubleTapTimeout);
    await settle(tester);
    expect(split.value, PaneSplit.automatic);
    expect(tester.getRect(find.byKey(listKey)).width, 412);
  });

  group('A handle held for a long press', () {
    Future<TestGesture> hold(WidgetTester tester) async {
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      return gesture;
    }

    testWidgets('and let go where it was held, is long-pressed, a tremble '
        'aside', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      var longPresses = 0;
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: PaneResizer(onLongPress: (_) => longPresses++),
        ),
      );
      final gesture = await hold(tester);
      // Nothing happens until the handle is let go.
      expect(longPresses, 0);
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump();
      await gesture.up();
      await settle(tester);
      expect(longPresses, 1);
      expect(split.value, PaneSplit.automatic);
      expect(tester.getRect(find.byKey(listKey)).width, 412);
    });

    testWidgets('and then moved, is dragged instead', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      var longPresses = 0;
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: PaneResizer(onLongPress: (_) => longPresses++),
        ),
      );
      final start = tester.getCenter(handle).dx;
      final gesture = await hold(tester);
      // Past the touch slop, the drag starts where the pointer is, as any
      // drag does.
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(tester.getCenter(handle).dx, start);
      expect(
        PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle))),
        contains(WidgetState.dragged),
      );
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(tester.getCenter(handle).dx, moreOrLessEquals(start - 40));
      await gesture.up();
      await settle(tester);
      expect(longPresses, 0);
      expect(split.value, const PaneSplit.width(360));
      expect(
        PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle))),
        isNot(contains(WidgetState.dragged)),
      );
    });

    testWidgets('and flung, settles on the stop ahead', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      var longPresses = 0;
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: PaneResizer(onLongPress: (_) => longPresses++),
        ),
      );
      final gesture = await hold(tester);
      // A quick movement to the right, from the 412dp stop.
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(
          const Offset(8, 0),
          timeStamp: Duration(milliseconds: 600 + i * 8),
        );
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 640));
      await settle(tester);
      expect(split.value, PaneSplit.centered);
      expect(longPresses, 0);
    });

    testWidgets('and trembling up to the touch slop, or moving across the '
        'spacer, is still long-pressed', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      var longPresses = 0;
      await tester.pumpWidget(
        resizable(dragHandle: PaneResizer(onLongPress: (_) => longPresses++)),
      );
      for (final move in const [Offset(-kTouchSlop, 0), Offset(0, 30)]) {
        final gesture = await hold(tester);
        await gesture.moveBy(move);
        await tester.pump();
        await gesture.up();
        await settle(tester);
      }
      expect(longPresses, 2);
    });

    testWidgets('in a right-to-left layout, drags and flings as the screen '
        'goes', (tester) async {
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
              motion: const PaneMotion.none(),
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) => const SizedBox(),
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      // The list is on the right: moving left widens it.
      final gesture = await hold(tester);
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(tester.getRect(find.byKey(listKey)).width, 412 + 40);
      await gesture.up();
      await settle(tester);

      split.value = PaneSplit.automatic;
      await settle(tester);
      final fling = await hold(tester);
      for (var i = 0; i < 5; i++) {
        await fling.moveBy(
          const Offset(-8, 0),
          timeStamp: Duration(milliseconds: 600 + i * 8),
        );
      }
      await fling.up(timeStamp: const Duration(milliseconds: 640));
      await settle(tester);
      expect(split.value, PaneSplit.centered);
    });

    testWidgets('and moved, then cancelled, returns to where it was', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      var longPresses = 0;
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: PaneResizer(onLongPress: (_) => longPresses++),
        ),
      );
      Set<WidgetState> states() =>
          PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle)));
      final gesture = await hold(tester);
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(tester.getRect(find.byKey(listKey)).width, 412 - 40);
      await gesture.cancel();
      await settle(tester);
      expect(longPresses, 0);
      expect(split.value, PaneSplit.automatic);
      expect(tester.getRect(find.byKey(listKey)).width, 412);
      expect(states(), isNot(contains(WidgetState.dragged)));
    });

    testWidgets('without a long press to listen for, and let go where it '
        'was held, is a tap', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      var taps = 0;
      var longPresses = 0;
      Future<void> holdAndLetGo(PaneHandleCallback? onLongPress) async {
        await tester.pumpWidget(
          resizable(
            dragHandle: PaneResizer(
              onTap: (_) => taps++,
              onDoubleTap: null,
              onLongPress: onLongPress,
            ),
          ),
        );
        final gesture = await hold(tester);
        await gesture.up();
        await settle(tester);
      }

      await holdAndLetGo((_) => longPresses++);
      expect((taps, longPresses), (0, 1));
      await holdAndLetGo(null);
      expect((taps, longPresses), (1, 1));
    });

    testWidgets('without a long press to listen for, is dragged as any '
        'other', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        resizable(
          splitController: split,
          dragHandle: const PaneResizer(onLongPress: null),
        ),
      );
      final gesture = await hold(tester);
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.up();
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));
    });
  });

  testWidgets('shows the grip when it is hovered', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    // Hover shows where the last input was a mouse or a keyboard.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(resizable());
    Set<WidgetState> states() =>
        PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle)));
    expect(states(), isEmpty);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(handle));
    await tester.pump();
    expect(states(), {WidgetState.hovered});
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(states(), isEmpty);
  });

  testWidgets('a trackpad resizes without pressing the handle', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    await tester.pumpWidget(resizable(splitController: split));
    Set<WidgetState> states() =>
        PaneResizer.statesOf(tester.element(find.byType(PaneDragHandle)));
    final trackpad = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await trackpad.panZoomStart(tester.getCenter(handle));
    await tester.pump();
    expect(states(), isNot(contains(WidgetState.pressed)));
    await trackpad.panZoomUpdate(
      tester.getCenter(handle),
      pan: const Offset(-20, 0),
    );
    await tester.pump();
    await trackpad.panZoomUpdate(
      tester.getCenter(handle),
      pan: const Offset(-60, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(states(), contains(WidgetState.dragged));
    expect(states(), isNot(contains(WidgetState.pressed)));
    await trackpad.panZoomEnd();
    await settle(tester);
    expect(split.value, const PaneSplit.width(360));
    expect(states(), isEmpty);
  });

  testWidgets('up and down follow the value, whatever the direction', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    for (final direction in TextDirection.values) {
      split.value = PaneSplit.automatic;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListDetailLayout<int>(
              key: ValueKey(direction),
              selectedId: 1,
              resizable: true,
              splitController: split,
              motion: const PaneMotion.none(),
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) => const SizedBox(),
            ),
          ),
          textDirection: direction,
        ),
      );
      Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await settle(tester);
      expect(split.value, PaneSplit.centered, reason: '$direction');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(split.value, PaneSplit.automatic, reason: '$direction');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(split.value, const PaneSplit.width(360), reason: '$direction');
    }
  });

  testWidgets('assistive technology widens and narrows the pane by a stop, '
      'and hears where it lands', (tester) async {
    final semantics = tester.ensureSemantics();
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    await tester.pumpWidget(resizable(splitController: split));
    final node = find.semantics.byLabel('Resize panes');
    final data = node.evaluate().single.getSemanticsData();
    // 1228dp shared: 412dp now, centred next, 360dp before.
    expect(data.increasedValue, '${(614 / 1228 * 100).round()}%');
    expect(data.decreasedValue, '${(360 / 1228 * 100).round()}%');
    tester.takeAnnouncements();
    tester.semantics.increase(node);
    await settle(tester);
    expect(split.value, PaneSplit.centered);
    expect(tester.takeAnnouncements().map((a) => a.message), ['50%']);
    // At the last stop, there is nothing wider.
    final last = find.semantics.byLabel('Resize panes');
    expect(
      last.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.increase,
      ),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('a grip reads the handle: its split and stops, and moves it', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    PaneHandle? grip;
    await tester.pumpWidget(
      resizable(
        splitController: split,
        dragHandle: PaneResizer(
          child: Builder(
            builder: (context) {
              grip = PaneHandle.maybeOf(context);
              return const SizedBox.square(dimension: 8);
            },
          ),
        ),
      ),
    );
    expect(grip!.split, PaneSplit.automatic);
    expect(grip!.stops, [
      PaneSplit.collapsed,
      const PaneSplit.width(360),
      const PaneSplit.width(412),
      PaneSplit.centered,
    ]);

    grip!.moveTo(const PaneSplit.width(360));
    await settle(tester);
    expect(split.value, const PaneSplit.width(360));
    expect(grip!.split, const PaneSplit.width(360));

    // The detail beside a list of fixed width is not one the handle hides.
    grip!.moveTo(PaneSplit.expanded);
    await settle(tester);
    expect(split.value, const PaneSplit.width(360));

    grip!.toggle();
    await settle(tester);
    expect(split.value, PaneSplit.collapsed);
    grip!.toggle();
    await settle(tester);
    expect(split.value, const PaneSplit.width(360));
  });

  testWidgets("a grip's stops are its resizer's", (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    PaneHandle? grip;
    await tester.pumpWidget(
      resizable(
        dragHandle: PaneResizer(
          snapStops: const [PaneSplit.width(400), PaneSplit.width(500)],
          child: Builder(
            builder: (context) {
              grip = PaneHandle.maybeOf(context);
              return const SizedBox.square(dimension: 8);
            },
          ),
        ),
      ),
    );
    expect(grip!.stops, const [PaneSplit.width(400), PaneSplit.width(500)]);
  });

  testWidgets('a handle of its own finds the layout it resizes', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    PaneHandle? own;
    await tester.pumpWidget(
      resizable(
        splitController: split,
        dragHandle: Builder(
          builder: (context) {
            own = PaneHandle.maybeOf(context);
            return const SizedBox.expand();
          },
        ),
      ),
    );
    own!.moveTo(PaneSplit.centered);
    await settle(tester);
    expect(split.value, PaneSplit.centered);
  });

  testWidgets('Enter, Space and the accessibility action toggle, whatever '
      'the gestures do', (tester) async {
    final semantics = tester.ensureSemantics();
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    await tester.pumpWidget(
      resizable(
        splitController: split,
        dragHandle: const PaneResizer(onDoubleTap: null),
      ),
    );
    Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(split.value, PaneSplit.collapsed);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settle(tester);
    expect(split.value, PaneSplit.automatic);

    final node = find.semantics.byLabel('Resize panes');
    expect(
      node.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(node);
    await settle(tester);
    expect(split.value, PaneSplit.collapsed);
    semantics.dispose();
  });

  testWidgets('a drag changes the value it reports, and announces nothing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    await tester.pumpWidget(resizable(splitController: split));
    tester.takeAnnouncements();
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await settle(tester);
    expect(split.value, const PaneSplit.width(360));
    expect(tester.takeAnnouncements(), isEmpty);
    expect(
      find.semantics
          .byLabel('Resize panes')
          .evaluate()
          .single
          .getSemanticsData()
          .value,
      '${(360 / 1228 * 100).round()}%',
    );
    semantics.dispose();
  });

  testWidgets('announces where a toggle or a move leaves the panes', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(resizable());
    tester.takeAnnouncements();
    await doubleTap(tester, handle);
    await settle(tester);
    expect(tester.takeAnnouncements().map((a) => a.message), [
      'Pane collapsed',
    ]);

    await doubleTap(tester, handle);
    await settle(tester);
    // The list's share of the 1228dp the panes share.
    expect(tester.takeAnnouncements().map((a) => a.message), [
      '${(412 / 1228 * 100).round()}%',
    ]);
  });
}
