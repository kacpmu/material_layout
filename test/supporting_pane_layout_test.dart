// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const focusKey = ValueKey('focus');
const supportingKey = ValueKey('supporting');

Widget layout({
  Widget? supporting = const SizedBox.expand(key: supportingKey),
  VoidCallback? onSupportingDismissed,
  PaneSide side = PaneSide.trailing,
  bool resizable = false,
  PaneSplitController? splitController,
  PaneResizeMemory resizeMemory = PaneResizeMemory.temporary,
}) => app(
  Scaffold(
    body: SupportingPaneLayout(
      focus: const SizedBox.expand(key: focusKey),
      supporting: supporting,
      onSupportingDismissed: onSupportingDismissed,
      supportingSide: side,
      resizable: resizable,
      splitController: splitController,
      resizeMemory: resizeMemory,
    ),
  ),
);

Rect focusRect(WidgetTester tester) => tester.getRect(find.byKey(focusKey));

Rect supportingRect(WidgetTester tester) =>
    tester.getRect(find.byKey(supportingKey));

Future<void> resize(WidgetTester tester, Size size) async {
  setWindowSize(tester, size);
  await tester.pump();
  await settle(tester);
}

void main() {
  group('Placement', () {
    testWidgets('compact stacks the supporting pane below, at full width', (
      tester,
    ) async {
      setWindowSize(tester, const Size(400, 824));
      await tester.pumpWidget(layout());
      final focus = focusRect(tester);
      final supporting = supportingRect(tester);
      expect(focus.left, 16);
      expect(focus.right, 400 - 16);
      expect(supporting.left, 16);
      expect(supporting.right, 400 - 16);
      // Stacked panes keep the 24dp spacer between them, and the focus
      // pane takes two thirds of the height.
      expect(supporting.top - focus.bottom, 24);
      expect(focus.height, closeTo(800 * 2 / 3, 1e-9));
      expect(supporting.height, closeTo(800 / 3, 1e-9));
    });

    testWidgets('medium stacks it too, with 24dp margins', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(layout());
      expect(supportingRect(tester).top, greaterThan(focusRect(tester).bottom));
      expect(focusRect(tester).left, 24);
    });

    testWidgets('expanded puts it beside, 360dp wide, on the trailing side', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout());
      final focus = focusRect(tester);
      final supporting = supportingRect(tester);
      expect(supporting.width, 360);
      expect(supporting.right, 1000 - 24);
      expect(supporting.left - focus.right, 24);
      expect(focus.left, 24);
      expect(supporting.height, focus.height);
    });

    testWidgets('large makes it 412dp wide', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(layout());
      expect(supportingRect(tester).width, 412);
    });

    testWidgets('it may take the leading side', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout(side: PaneSide.leading));
      expect(supportingRect(tester).left, 24);
      expect(focusRect(tester).left, 24 + 360 + 24);
    });

    testWidgets('the focus pane keeps the majority of the space', (
      tester,
    ) async {
      for (final width in [1000.0, 1300.0, 1700.0]) {
        await resize(tester, Size(width, 800));
        if (width == 1000) await tester.pumpWidget(layout());
        expect(
          focusRect(tester).width,
          greaterThan(supportingRect(tester).width),
        );
      }
    });

    testWidgets('the focus pane keeps half the space against a wider split', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(900));
      addTearDown(split.dispose);
      await resize(tester, const Size(1300, 800));
      await tester.pumpWidget(layout(splitController: split));
      // Half of the 1228dp the panes share.
      expect(supportingRect(tester).width, 614);
      expect(focusRect(tester).width, 614);
    });

    testWidgets('a supporting widget with a preferred width narrows the '
        'pane to it', (tester) async {
      await resize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        layout(
          supporting: const PreferredSize(
            preferredSize: Size.fromWidth(300),
            child: SizedBox.expand(key: supportingKey),
          ),
        ),
      );
      expect(supportingRect(tester).width, 300);
      expect(supportingRect(tester).right, 1300 - 24);
      expect(focusRect(tester).right, 1300 - 24 - 300 - 24);
    });
  });

  group('Side sheet as a pane', () {
    Widget sheetLayout({
      bool open = true,
      VoidCallback? onSupportingDismissed,
    }) => layout(
      supporting: open
          ? const SideSheet(
              key: supportingKey,
              headline: Text('Filters'),
              child: Text('Content'),
            )
          : null,
      onSupportingDismissed: onSupportingDismissed ?? () {},
    );

    testWidgets('caps the pane at 400dp', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(sheetLayout());
      expect(supportingRect(tester).width, 400);
      await resize(tester, const Size(1000, 800));
      expect(supportingRect(tester).width, 360);
    });

    testWidgets('shrinks the body and leaves a margin before it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(sheetLayout(open: false));
      final alone = focusRect(tester);
      await tester.pumpWidget(sheetLayout());
      await settle(tester);
      final beside = focusRect(tester);
      expect(beside.width, lessThan(alone.width));
      expect(supportingRect(tester).left - beside.right, 24);
    });

    testWidgets('sits beside the content from medium', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(sheetLayout());
      final focus = focusRect(tester);
      final sheet = supportingRect(tester);
      expect(sheet.right, 700 - 24);
      expect(sheet.left - focus.right, 24);
      // The focus pane keeps the majority of the space.
      expect(focus.width, greaterThanOrEqualTo(sheet.width));
    });

    testWidgets('is hidden rather than stacked where it cannot sit beside '
        'the content', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(sheetLayout());
      expect(find.byKey(supportingKey), findsNothing);
      expect(focusRect(tester).height, 800);
      await resize(tester, const Size(700, 800));
      expect(find.byKey(supportingKey), findsOneWidget);
    });

    testWidgets('sits on the trailing edge only', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        layout(
          side: PaneSide.leading,
          supporting: const SideSheet(
            key: supportingKey,
            child: Text('Content'),
          ),
          onSupportingDismissed: () {},
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('never grows past its width', (tester) async {
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(
        layout(
          resizable: true,
          supporting: const SideSheet(key: supportingKey, child: Text('C')),
          onSupportingDismissed: () {},
        ),
      );
      Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);
      expect(supportingRect(tester).width, lessThanOrEqualTo(400));
      expect(supportingRect(tester).right, 1700 - 24);
    });

    testWidgets('keeps its width on the trailing side of a hinge', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(490, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(sheetLayout());
      await settle(tester);
      expect(supportingRect(tester).width, lessThanOrEqualTo(400));
      expect(supportingRect(tester).right, 1000 - 24);
      expect(focusRect(tester).right, lessThanOrEqualTo(490));
    });

    testWidgets('keeps the trailing side when the layout asks for the '
        'leading one', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(sheetLayout());
      await tester.pumpWidget(sheetLayout(open: false));
      await settle(tester);
      await tester.pumpWidget(
        layout(
          supporting: null,
          side: PaneSide.leading,
          onSupportingDismissed: () {},
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(focusRect(tester).left, 24);
    });

    testWidgets('slides in at medium when first opened', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(sheetLayout(open: false));
      final alone = focusRect(tester).width;
      await tester.pumpWidget(sheetLayout());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final entering = focusRect(tester).width;
      await settle(tester);
      final beside = focusRect(tester).width;
      expect(entering, lessThan(alone));
      expect(entering, greaterThan(beside));
    });

    testWidgets('resizes between its own width and narrower stops, never '
        'dismissed by a small drag', (tester) async {
      var dismissed = 0;
      Widget sheet(double width) => layout(
        resizable: true,
        supporting: SideSheet(
          key: supportingKey,
          width: width,
          child: const Text('C'),
        ),
        onSupportingDismissed: () => dismissed++,
      );
      Future<void> press(LogicalKeyboardKey key) async {
        Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(key);
        await settle(tester);
      }

      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(sheet(320));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await settle(tester);
      await press(LogicalKeyboardKey.end);
      expect(dismissed, 0);
      expect(supportingRect(tester).width, 320);

      await resize(tester, const Size(1300, 800));
      await tester.pumpWidget(sheet(400));
      await settle(tester);
      // The sheet is on the right: moving the handle right narrows it.
      await press(LogicalKeyboardKey.arrowRight);
      expect(supportingRect(tester).width, 360);
      await press(LogicalKeyboardKey.arrowLeft);
      expect(supportingRect(tester).width, 400);
      expect(dismissed, 0);
    });

    testWidgets('settles back to its width without growing past it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        layout(
          resizable: true,
          supporting: const SideSheet(key: supportingKey, child: Text('C')),
          onSupportingDismissed: () {},
        ),
      );
      final resting = focusRect(tester).right;
      Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(focusRect(tester).right, resting + 40);

      // Back to its width on a spring that overshoots: the pane stops there.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(focusRect(tester).right, greaterThanOrEqualTo(resting - 0.5));
      }
      expect(focusRect(tester).right, resting);
    });

    testWidgets('keeps a stop to return to beside a rail at medium', (
      tester,
    ) async {
      var dismissed = 0;
      setWindowSize(tester, const Size(800, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 96),
                Expanded(
                  child: SupportingPaneLayout(
                    resizable: true,
                    focus: const SizedBox.expand(key: focusKey),
                    supporting: const SideSheet(
                      key: supportingKey,
                      child: Text('C'),
                    ),
                    onSupportingDismissed: () => dismissed++,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final width = supportingRect(tester).width;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await settle(tester);
      Focus.of(tester.element(find.byType(PaneDragHandle))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);
      expect(dismissed, 0);
      expect(supportingRect(tester).width, width);
    });

    testWidgets('a drag past its width turns back at once', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        layout(
          resizable: true,
          supporting: const SideSheet(key: supportingKey, child: Text('C')),
          onSupportingDismissed: () {},
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      // Leftwards would widen the sheet, which is at its width already.
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      expect(supportingRect(tester).width, 400);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(supportingRect(tester).width, closeTo(380, 1));
      await gesture.up();
      await settle(tester);
    });

    testWidgets('a sheet narrower than the pane minimum sits a spacer from '
        'the content', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        layout(
          supporting: const SideSheet(
            key: supportingKey,
            width: 240,
            child: Text('C'),
          ),
          onSupportingDismissed: () {},
        ),
      );
      expect(supportingRect(tester).width, 240);
      expect(supportingRect(tester).left - focusRect(tester).right, 24);
    });

    testWidgets('leaves the focus pane the larger share at narrow medium '
        'widths', (tester) async {
      setWindowSize(tester, const Size(620, 800));
      await tester.pumpWidget(sheetLayout());
      expect(
        focusRect(tester).width,
        greaterThanOrEqualTo(supportingRect(tester).width),
      );
    });

    testWidgets('its close button dismisses the pane', (tester) async {
      var dismissed = 0;
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        sheetLayout(onSupportingDismissed: () => dismissed++),
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, 1);
    });
  });

  group('Show and hide', () {
    testWidgets('the pane animates in and out as it comes and goes', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout(supporting: null));
      expect(find.byKey(supportingKey), findsNothing);
      expect(focusRect(tester).width, 1000 - 48);

      await tester.pumpWidget(layout());
      await tester.pump(const Duration(milliseconds: 50));
      final entering = focusRect(tester).width;
      expect(entering, lessThan(1000 - 48));
      expect(entering, greaterThan(1000 - 48 - 360 - 24));
      await settle(tester);
      expect(focusRect(tester).width, 1000 - 48 - 360 - 24);

      await tester.pumpWidget(layout(supporting: null));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(supportingKey), findsOneWidget);
      await settle(tester);
      expect(find.byKey(supportingKey), findsNothing);
      expect(focusRect(tester).width, 1000 - 48);
    });

    testWidgets('the focus pane is arranged for the width it rests at as '
        'the pane comes and goes', (tester) async {
      final breakpoints = <Breakpoint>[];
      final widths = <double>[];
      final sidebar = <Breakpoint>[];
      Widget probe({required bool supporting}) => app(
        Scaffold(
          body: SupportingPaneLayout(
            focus: Builder(
              builder: (context) {
                breakpoints.add(AdaptiveRegion.breakpointOf(context));
                widths.add(AdaptiveRegion.sizeOf(context).width);
                return Row(
                  children: [
                    // A region narrower than the pane keeps its width as
                    // the pane grows and shrinks.
                    SizedBox(
                      width: 300,
                      child: AdaptiveRegion(
                        child: Builder(
                          builder: (context) {
                            sidebar.add(AdaptiveRegion.breakpointOf(context));
                            return const SizedBox.expand();
                          },
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.expand(key: focusKey)),
                  ],
                );
              },
            ),
            supporting: supporting
                ? const SizedBox.expand(key: supportingKey)
                : null,
          ),
        ),
      );
      Future<void> frames() async {
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      // Alone, the focus pane is expanded; beside the supporting pane it is
      // compact.
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(probe(supporting: false));
      expect(breakpoints.last, Breakpoint.expanded);

      breakpoints.clear();
      widths.clear();
      await tester.pumpWidget(probe(supporting: true));
      await frames();
      // From the first frame, while the pane is as wide as it was, its
      // content is arranged for where it is going, and stays so.
      expect(widths.first, 1000 - 48);
      expect(widths.last, lessThan(700));
      expect(breakpoints, everyElement(Breakpoint.compact));
      await settle(tester);
      expect(widths.last, 1000 - 48 - 360 - 24);

      breakpoints.clear();
      widths.clear();
      await tester.pumpWidget(probe(supporting: false));
      await frames();
      expect(widths.first, 1000 - 48 - 360 - 24);
      expect(widths.last, greaterThan(840));
      expect(breakpoints, everyElement(Breakpoint.expanded));
      expect(sidebar, everyElement(Breakpoint.compact));
    });

    testWidgets('a layout nested in the focus pane arranges its own panes '
        'for where they rest', (tester) async {
      final breakpoints = <Breakpoint>[];
      Widget probe({required bool sheet}) => app(
        Scaffold(
          body: SupportingPaneLayout(
            onSupportingDismissed: () {},
            focus: ListDetailLayout<int>(
              selectedId: 1,
              onSelectionChanged: (_) {},
              listBuilder: (context) => const SizedBox.expand(),
              detailBuilder: (context, id, placement) => Builder(
                builder: (context) {
                  breakpoints.add(AdaptiveRegion.breakpointOf(context));
                  AdaptiveRegion.sizeOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
            supporting: sheet ? const SideSheet(child: Text('Details')) : null,
          ),
        ),
      );
      // Beside the sheet, the detail is medium; without it, large.
      setWindowSize(tester, const Size(1700, 900));
      await tester.pumpWidget(probe(sheet: true));
      await settle(tester);
      expect(breakpoints.last, Breakpoint.medium);

      breakpoints.clear();
      await tester.pumpWidget(probe(sheet: false));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(breakpoints, everyElement(Breakpoint.large));
    });

    testWidgets('a leaving pane keeps its width and slides out', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout());
      await tester.pumpWidget(layout(supporting: null));
      await tester.pump(const Duration(milliseconds: 50));
      expect(supportingRect(tester).width, 360);
      expect(supportingRect(tester).left, greaterThan(1000 - 24 - 360));
    });
  });

  group('Resize memory', () {
    testWidgets('a temporary resize returns to the default when the pane is '
        'closed and reopened', (tester) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(layout(splitController: split));
      expect(supportingRect(tester).width, 300);

      await tester.pumpWidget(layout(supporting: null, splitController: split));
      await settle(tester);
      await tester.pumpWidget(layout(splitController: split));
      await settle(tester);
      expect(supportingRect(tester).width, 412);
      expect(split.value, PaneSplit.automatic);
    });

    testWidgets('a temporary resize is forgotten at another breakpoint', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(layout(splitController: split));
      await resize(tester, const Size(1000, 800));
      expect(supportingRect(tester).width, 360);
      await resize(tester, const Size(1300, 800));
      expect(supportingRect(tester).width, 412);
    });

    testWidgets('a temporary resize is forgotten when the pane moves below '
        'the focus pane and back', (tester) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(layout(splitController: split));
      await resize(tester, const Size(700, 800));
      await resize(tester, const Size(1300, 800));
      expect(supportingRect(tester).width, 412);
    });

    testWidgets('a pane dismissed with the handle reopens at the default', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      setWindowSize(tester, const Size(1300, 800));
      var shown = true;
      late StateSetter setShown;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setShown = setState;
            return layout(
              supporting: shown
                  ? const SizedBox.expand(key: supportingKey)
                  : null,
              onSupportingDismissed: () => setState(() => shown = false),
              resizable: true,
              splitController: split,
            );
          },
        ),
      );
      expect(supportingRect(tester).width, 300);
      await doubleTap(tester, find.byType(PaneResizer));
      await settle(tester);
      expect(shown, isFalse);
      expect(find.byKey(supportingKey), findsNothing);
      expect(find.byType(PaneResizer), findsNothing);

      setShown(() => shown = true);
      await settle(tester);
      expect(supportingRect(tester).width, 412);
      expect(split.value, PaneSplit.automatic);
    });

    testWidgets('forgetting a resize tells the controller after the frame', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      Widget withTitle() => app(
        Scaffold(
          // A listener outside the layout, rebuilt by the controller.
          appBar: AppBar(
            title: ListenableBuilder(
              listenable: split,
              builder: (context, _) => Text('${split.value}'),
            ),
          ),
          body: SupportingPaneLayout(
            focus: const SizedBox.expand(key: focusKey),
            supporting: const SizedBox.expand(key: supportingKey),
            splitController: split,
          ),
        ),
      );
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(withTitle());
      await resize(tester, const Size(1700, 800));
      expect(tester.takeException(), isNull);
      expect(find.text('PaneSplit.automatic'), findsOneWidget);
      expect(supportingRect(tester).width, 412);
    });

    testWidgets('a temporary resize is forgotten when the posture changes', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(412));
      addTearDown(split.dispose);
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout(splitController: split));
      expect(supportingRect(tester).width, 412);
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(490, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      await tester.pump();
      await settle(tester);
      tester.view.resetDisplayFeatures();
      await tester.pump();
      await settle(tester);
      expect(supportingRect(tester).width, 360);
    });

    testWidgets('a persistent resize survives closing and breakpoints', (
      tester,
    ) async {
      final split = PaneSplitController(split: const PaneSplit.width(300));
      addTearDown(split.dispose);
      const memory = PaneResizeMemory.persistent;
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        layout(splitController: split, resizeMemory: memory),
      );
      await tester.pumpWidget(
        layout(supporting: null, splitController: split, resizeMemory: memory),
      );
      await settle(tester);
      await tester.pumpWidget(
        layout(splitController: split, resizeMemory: memory),
      );
      await resize(tester, const Size(1000, 800));
      await resize(tester, const Size(1300, 800));
      expect(supportingRect(tester).width, 300);
    });
  });

  testWidgets('new supporting content starts at the top', (tester) async {
    Widget list(String name) => ListView(
      key: ValueKey(name),
      children: [
        for (var i = 0; i < 50; i++)
          SizedBox(height: 100, child: Text('$name $i')),
      ],
    );
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(layout(supporting: list('first')));
    await tester.drag(
      find.byKey(const ValueKey('first')),
      const Offset(0, -500),
    );
    await settle(tester);
    expect(find.text('first 0'), findsNothing);
    await tester.pumpWidget(layout(supporting: list('second')));
    await settle(tester);
    expect(find.text('second 0'), findsOneWidget);
  });

  group('Resizing', () {
    testWidgets('a drag ends when its pane goes', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      var dismissed = 0;
      Widget dismissible({bool shown = true}) => layout(
        supporting: shown ? const SizedBox.expand(key: supportingKey) : null,
        onSupportingDismissed: () => dismissed++,
        resizable: true,
      );
      await tester.pumpWidget(dismissible());
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();

      await tester.pumpWidget(dismissible(shown: false));
      await gesture.up();
      await settle(tester);
      expect(find.byKey(supportingKey), findsNothing);
      expect(focusRect(tester).width, 1300 - 48);
      expect(dismissed, 0);

      await tester.pumpWidget(dismissible());
      await settle(tester);
      expect(supportingRect(tester).width, 412);
      await doubleTap(tester, find.byType(PaneResizer));
      await settle(tester);
      expect(dismissed, 1);
    });

    testWidgets('changing sides while the pane is hidden keeps the focus '
        'pane in place', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(layout(supporting: null));
      await settle(tester);
      await tester.pumpWidget(layout(supporting: null, side: PaneSide.leading));
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(focusRect(tester).left, 24, reason: 'frame $frame');
        expect(focusRect(tester).right, 1000 - 24, reason: 'frame $frame');
      }
    });

    testWidgets('a leading pane keeps its content as it moves below the '
        'focus pane and back', (tester) async {
      var created = 0;
      Widget leading() => app(
        Scaffold(
          body: SupportingPaneLayout(
            supportingSide: PaneSide.leading,
            focus: _Counted(key: focusKey, onCreate: () => created++),
            supporting: const SizedBox.expand(key: supportingKey),
          ),
        ),
      );
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(leading());
      expect(supportingRect(tester).right, lessThan(focusRect(tester).left));
      await resize(tester, const Size(700, 800));
      expect(supportingRect(tester).top, greaterThan(focusRect(tester).bottom));
      await resize(tester, const Size(1000, 800));
      expect(created, 1);
    });
  });

  group('Folds and hinges', () {
    testWidgets('a vertical hinge in a compact region leaves the panes '
        'stacked as usual', (tester) async {
      setWindowSize(tester, const Size(500, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(240, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(layout());
      await settle(tester);
      expect(supportingRect(tester).top, greaterThan(focusRect(tester).bottom));
      expect(focusRect(tester).height, closeTo((800 - 24) * 2 / 3, 1));
    });

    void setFeature(WidgetTester tester, Rect bounds, DisplayFeatureType type) {
      tester.view.displayFeatures = [
        DisplayFeature(
          bounds: bounds,
          type: type,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
    }

    testWidgets('a half-open horizontal fold stacks the panes around it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      setFeature(
        tester,
        const Rect.fromLTWH(0, 400, 1000, 0),
        DisplayFeatureType.fold,
      );
      await tester.pumpWidget(layout());
      await settle(tester);
      expect(focusRect(tester).bottom, lessThanOrEqualTo(400));
      expect(supportingRect(tester).top, greaterThanOrEqualTo(400));
    });

    testWidgets('a vertical hinge puts one pane on each side of it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      setFeature(
        tester,
        const Rect.fromLTWH(340, 0, 20, 800),
        DisplayFeatureType.hinge,
      );
      await tester.pumpWidget(layout());
      await settle(tester);
      expect(focusRect(tester).right, lessThanOrEqualTo(340));
      expect(supportingRect(tester).left, greaterThanOrEqualTo(360));
    });

    testWidgets('a flat fold separates nothing', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(350, 0, 0, 800),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(layout());
      await settle(tester);
      // Medium stacks the panes, as with no fold at all.
      expect(supportingRect(tester).top, greaterThan(focusRect(tester).bottom));
    });
  });
}

class _Counted extends StatefulWidget {
  const new({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
