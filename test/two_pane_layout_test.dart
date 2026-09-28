// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/rendering.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const firstKey = ValueKey('first');
const secondKey = ValueKey('second');

Widget panes({
  Widget? first = const SizedBox.expand(key: firstKey),
  Widget? second = const SizedBox.expand(key: secondKey),
  PaneArrangement arrangement = const PaneArrangement.fixedAndFlexible(),
  Breakpoint twoPaneBreakpoint = Breakpoint.expanded,
  PaneReflow reflow = PaneReflow.stack,
  bool resizable = false,
  PaneSplitController? splitController,
  PaneCollapse? firstCollapse,
  PaneCollapse? secondCollapse,
  VoidCallback? onFirstDismissed,
  VoidCallback? onSecondDismissed,
  MarginPlacement? marginPlacement,
  PaneMotion? motion = const PaneMotion.none(),
}) => TwoPaneLayout(
  first: first,
  second: second,
  arrangement: arrangement,
  twoPaneBreakpoint: twoPaneBreakpoint,
  reflow: reflow,
  resizable: resizable,
  splitController: splitController,
  firstCollapse: firstCollapse,
  secondCollapse: secondCollapse,
  onFirstDismissed: onFirstDismissed,
  onSecondDismissed: onSecondDismissed,
  marginPlacement: marginPlacement,
  motion: motion,
);

Widget host(Widget layout) => app(Scaffold(body: layout));

Rect firstRect(WidgetTester tester) => tester.getRect(find.byKey(firstKey));

Rect secondRect(WidgetTester tester) => tester.getRect(find.byKey(secondKey));

Finder get handle => find.byType(PaneResizer);

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

void main() {
  group('Arrangements', () {
    testWidgets('a fixed first pane sits beside a flexible second, at '
        "Material's widths by default", (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(host(panes()));
      expect(firstRect(tester), const Rect.fromLTRB(24, 0, 24 + 360, 800));
      expect(secondRect(tester), const Rect.fromLTRB(408, 0, 1000 - 24, 800));

      setWindowSize(tester, const Size(1300, 800));
      await tester.pump();
      expect(firstRect(tester).width, 412);
      expect(secondRect(tester).left, 24 + 412 + 24);
      expect(secondRect(tester).right, 1300 - 24);
    });

    testWidgets('a fixed pane keeps the width it is given, on either side', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        host(
          panes(
            arrangement: const PaneArrangement.fixedAndFlexible(
              fixed: PaneSlot.second,
              width: 300,
            ),
          ),
        ),
      );
      expect(secondRect(tester).width, 300);
      expect(secondRect(tester).right, 1000 - 24);
      expect(firstRect(tester).left, 24);
      expect(firstRect(tester).right, 1000 - 24 - 300 - 24);
    });

    testWidgets('a split-pane arrangement keeps the spacer centred in the '
        'window', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      // A rail-like strip beside the layout narrows only the leading pane.
      await tester.pumpWidget(
        host(
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: panes(arrangement: const PaneArrangement.splitPane()),
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      expect((firstRect(tester).right + secondRect(tester).left) / 2, 500);
      expect(secondRect(tester).right, 1000 - 24);
    });

    testWidgets('a split-pane arrangement that does not reach the window '
        "centre splits the space between its margins evenly", (tester) async {
      setWindowSize(tester, const Size(1800, 800));
      await tester.pumpWidget(
        host(
          Row(
            children: [
              const SizedBox(width: 900),
              Expanded(
                child: panes(arrangement: const PaneArrangement.splitPane()),
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      // 900dp from 900dp: 24dp margins, and the spacer centred in the 852dp
      // between them.
      expect(
        (firstRect(tester).right + secondRect(tester).left) / 2,
        900 + 24 + 852 / 2,
      );
      expect(firstRect(tester).width, secondRect(tester).width);
    });

    testWidgets('at medium, two panes split evenly whatever the arrangement', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(
        host(
          panes(
            twoPaneBreakpoint: Breakpoint.medium,
            arrangement: const PaneArrangement.fixedAndFlexible(width: 200),
          ),
        ),
      );
      expect(firstRect(tester).width, secondRect(tester).width);
      expect((firstRect(tester).right + secondRect(tester).left) / 2, 350);
    });
  });

  group('Below the two-pane breakpoint', () {
    testWidgets('the panes stack, the first above the second', (tester) async {
      setWindowSize(tester, const Size(500, 824));
      await tester.pumpWidget(host(panes()));
      final first = firstRect(tester);
      final second = secondRect(tester);
      expect(first, const Rect.fromLTRB(16, 0, 500 - 16, 400));
      expect(second, const Rect.fromLTRB(16, 424, 500 - 16, 824));
    });

    testWidgets('or one pane shows, the one the layout reflows to', (
      tester,
    ) async {
      setWindowSize(tester, const Size(500, 800));
      await tester.pumpWidget(host(panes(reflow: PaneReflow.first)));
      expect(firstRect(tester), const Rect.fromLTRB(16, 0, 500 - 16, 800));
      expect(find.byKey(secondKey), findsNothing);

      await tester.pumpWidget(host(panes(reflow: PaneReflow.second)));
      expect(secondRect(tester), const Rect.fromLTRB(16, 0, 500 - 16, 800));
      expect(find.byKey(firstKey), findsNothing);

      // Where there is no such pane, the other shows.
      await tester.pumpWidget(
        host(panes(reflow: PaneReflow.second, second: null)),
      );
      expect(firstRect(tester).width, 500 - 32);
      await tester.pumpWidget(
        host(panes(reflow: PaneReflow.first, first: null)),
      );
      expect(secondRect(tester).width, 500 - 32);
    });

    testWidgets('a change of breakpoint rearranges the panes at once', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        host(panes(reflow: PaneReflow.first, motion: null)),
      );
      setWindowSize(tester, const Size(500, 800));
      await tester.pump();
      expect(firstRect(tester).width, 500 - 32);
      expect(find.byKey(secondKey), findsNothing);
    });
  });

  group('Panes that come and go', () {
    testWidgets('a pane given as null leaves, and one given again enters', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(host(panes(motion: null)));
      await tester.pumpWidget(host(panes(second: null, motion: null)));
      await tester.pump(const Duration(milliseconds: 50));
      // The pane is still leaving, with its content.
      expect(secondRect(tester).left, greaterThan(408));
      await settle(tester);
      expect(find.byKey(secondKey), findsNothing);
      expect(firstRect(tester), const Rect.fromLTRB(24, 0, 1000 - 24, 800));

      await tester.pumpWidget(host(panes(motion: null)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(firstRect(tester).width, greaterThan(360));
      await settle(tester);
      expect(firstRect(tester).width, 360);
    });

    testWidgets('a side sheet in a pane closes through its dismissal', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      var dismissed = 0;
      await tester.pumpWidget(
        host(
          panes(
            second: const SideSheet(child: Text('Details')),
            onSecondDismissed: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, 1);
    });
  });

  group('The drag handle', () {
    testWidgets('hides the fixed pane, leaving the other the whole width', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(panes(resizable: true, splitController: split)),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
      expect(find.byKey(firstKey), findsNothing);
      expect(secondRect(tester), const Rect.fromLTRB(24, 0, 1000 - 24, 800));
      expect(tester.getCenter(handle).dx, 12);
    });

    testWidgets('never hides the flexible pane by default', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(host(panes(resizable: true)));
      final data = find.semantics
          .byLabel('Resize panes')
          .evaluate()
          .single
          .getSemanticsData();
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
      semantics.dispose();
    });

    testWidgets('dismisses a pane that can be dismissed rather than hide it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      var dismissed = 0;
      await tester.pumpWidget(
        host(panes(resizable: true, onFirstDismissed: () => dismissed++)),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect(dismissed, 1);
      // The app removes the pane; until then it stays.
      expect(firstRect(tester).width, 360);
    });

    testWidgets('hides the panes it is told to', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          panes(
            resizable: true,
            splitController: split,
            firstCollapse: PaneCollapse.never,
            secondCollapse: PaneCollapse.collapse,
          ),
        ),
      );
      // The first pane stays; the handle hides the second instead.
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.expanded);
      expect(firstRect(tester), const Rect.fromLTRB(24, 0, 1000 - 24, 800));
      expect(tester.getCenter(handle).dx, 1000 - 12);
    });

    testWidgets('where it may hide either pane, a double tap hides the first', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          panes(
            resizable: true,
            splitController: split,
            arrangement: const PaneArrangement.splitPane(),
          ),
        ),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.collapsed);
    });

    testWidgets('two flexible panes that start with one hidden show both '
        'centred', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          panes(
            arrangement: const PaneArrangement.splitPane(),
            resizable: true,
            splitController: split,
          ),
        ),
      );
      expect(find.byKey(firstKey), findsNothing);
      expect(secondRect(tester), const Rect.fromLTRB(24, 0, 1300 - 24, 800));
      await doubleTap(tester, handle);
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
      expect((firstRect(tester).right + secondRect(tester).left) / 2, 650);
    });

    testWidgets('where the panes split evenly, hides either', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(700, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          panes(
            resizable: true,
            splitController: split,
            twoPaneBreakpoint: Breakpoint.medium,
          ),
        ),
      );
      expect(actionLabels(tester), [
        'Collapse pane',
        'Split panes evenly',
        'Expand pane to full width',
      ]);
      final handleAt = tester.getCenter(handle);
      final gesture = await tester.startGesture(handleAt);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(330, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await settle(tester);
      expect(split.value, PaneSplit.expanded);
      expect(find.byKey(secondKey), findsNothing);
      expect(firstRect(tester), const Rect.fromLTRB(24, 0, 700 - 24, 800));
      expect(tester.getCenter(handle).dx, 700 - 12);
      semantics.dispose();
    });

    testWidgets('hides a fixed second pane, leaving the first the whole '
        'width', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          panes(
            arrangement: const PaneArrangement.fixedAndFlexible(
              fixed: PaneSlot.second,
            ),
            resizable: true,
            splitController: split,
          ),
        ),
      );
      expect(secondRect(tester).width, 360);
      expect(secondRect(tester).right, 1000 - 24);
      await doubleTap(tester, handle);
      await settle(tester);
      // The split describes the fixed pane, here the second.
      expect(split.value, PaneSplit.collapsed);
      expect(find.byKey(secondKey), findsNothing);
      expect(firstRect(tester), const Rect.fromLTRB(24, 0, 1000 - 24, 800));
      expect(tester.getCenter(handle).dx, 1000 - 12);
    });

    testWidgets('dismisses a fixed second pane that can be dismissed', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      var first = 0;
      var second = 0;
      await tester.pumpWidget(
        host(
          panes(
            arrangement: const PaneArrangement.fixedAndFlexible(
              fixed: PaneSlot.second,
            ),
            resizable: true,
            onFirstDismissed: () => first++,
            onSecondDismissed: () => second++,
          ),
        ),
      );
      await doubleTap(tester, handle);
      await settle(tester);
      expect((first, second), (0, 1));
      // The app removes the pane; until then both stay.
      expect(secondRect(tester).width, 360);
      expect(find.byKey(firstKey), findsOneWidget);
    });

    testWidgets('refuses a dismissal it cannot report, and one pane at '
        'compact', (tester) async {
      final dismiss = PaneCollapse.values.last;
      final compact = Breakpoint.values.first;
      expect(() => TwoPaneLayout(firstCollapse: dismiss), throwsAssertionError);
      expect(
        () => TwoPaneLayout(secondCollapse: dismiss),
        throwsAssertionError,
      );
      expect(
        () => TwoPaneLayout(twoPaneBreakpoint: compact),
        throwsAssertionError,
      );
      expect(
        TwoPaneLayout(firstCollapse: dismiss, onFirstDismissed: () {}),
        isA<TwoPaneLayout>(),
      );
    });
  });

  group('Nesting', () {
    testWidgets('the fixed pane keeps to one pane, however wide', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1700, 800));
      Widget nested() => ListDetailLayout<int>(
        selectedId: 1,
        listBuilder: (context) => const SizedBox.expand(key: ValueKey('list')),
        detailBuilder: (context, id, placement) =>
            const SizedBox.expand(key: ValueKey('detail')),
      );
      await tester.pumpWidget(
        host(
          panes(
            arrangement: const PaneArrangement.fixedAndFlexible(width: 900),
            first: nested(),
          ),
        ),
      );
      await settle(tester);
      // 900dp is expanded, where the layout alone shows two panes.
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(find.byKey(const ValueKey('detail')), findsOneWidget);
    });

    testWidgets('the other pane may hold a side sheet as the third pane at '
        'extra-large only', (tester) async {
      Widget three() => host(
        panes(
          second: SupportingPaneLayout(
            focus: const SizedBox.expand(key: ValueKey('focus')),
            supporting: const SideSheet(child: Text('Sheet')),
            onSupportingDismissed: () {},
          ),
        ),
      );
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(three());
      await settle(tester);
      expect(find.text('Sheet'), findsOneWidget);
      final sheet = tester.getRect(find.byType(SideSheet));
      expect(
        sheet.left,
        greaterThan(tester.getRect(find.byKey(firstKey)).right),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('focus'))).right,
        lessThan(sheet.left),
      );

      setWindowSize(tester, const Size(1300, 800));
      await tester.pump();
      await settle(tester);
      expect(find.text('Sheet'), findsNothing);
    });
  });

  group('Region', () {
    testWidgets('reports its panes to a navigation scaffold', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      Widget scaffold(Breakpoint twoPaneBreakpoint) => app(
        NavigationScaffold(
          navigationBar: const SizedBox(key: ValueKey('bar'), height: 80),
          navigationRail: const SizedBox(key: ValueKey('rail'), width: 80),
          motion: const PaneMotion.none(),
          body: panes(twoPaneBreakpoint: twoPaneBreakpoint),
        ),
      );
      await tester.pumpWidget(scaffold(Breakpoint.medium));
      await settle(tester);
      // Two panes at medium keep the whole width: a bar below them.
      expect(find.byKey(const ValueKey('bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail')), findsNothing);

      await tester.pumpWidget(scaffold(Breakpoint.expanded));
      await settle(tester);
      expect(find.byKey(const ValueKey('rail')), findsOneWidget);
    });

    testWidgets('a layout nested in its flexible pane keeps to the panes it '
        'leaves', (tester) async {
      setWindowSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        host(
          panes(
            second: panes(
              first: const SizedBox.expand(key: ValueKey('inner first')),
              second: const SizedBox.expand(key: ValueKey('inner second')),
            ),
          ),
        ),
      );
      // Two side by side below extra-large: the inner panes stack.
      final innerFirst = tester.getRect(
        find.byKey(const ValueKey('inner first')),
      );
      final innerSecond = tester.getRect(
        find.byKey(const ValueKey('inner second')),
      );
      expect(innerFirst.left, innerSecond.left);
      expect(innerSecond.top, greaterThan(innerFirst.bottom));
      expect(firstRect(tester).width, 412);
    });

    testWidgets('a layout given as a pane keeps the margins it meets', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        host(
          panes(
            second: TwoPaneLayout(
              first: const SizedBox.expand(key: ValueKey('inner first')),
              motion: const PaneMotion.none(),
            ),
          ),
        ),
      );
      final inner = tester.element(find.byType(TwoPaneLayout).last);
      expect(AdaptiveRegion.sizeOf(inner).width, 1300 - 24 - 412 - 24);
      expect(
        AdaptiveRegion.marginsOf(inner),
        const EdgeInsetsDirectional.only(end: 24),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('inner first'))).right,
        1300 - 24,
      );
    });

    testWidgets('a vertical hinge puts a pane on each side of it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(340, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(host(panes()));
      await settle(tester);
      expect(firstRect(tester).right, lessThanOrEqualTo(340));
      expect(secondRect(tester).left, greaterThanOrEqualTo(360));
    });

    testWidgets('a fold across it holds stacked panes on each side', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTWH(0, 390, 1000, 20),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(host(panes()));
      await settle(tester);
      expect(firstRect(tester).bottom, lessThanOrEqualTo(390));
      expect(secondRect(tester).top, greaterThanOrEqualTo(410));
    });

    testWidgets('kept within the panes, the margins leave the panes the '
        'whole region', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      EdgeInsetsDirectional? firstMargins;
      await tester.pumpWidget(
        host(
          panes(
            marginPlacement: MarginPlacement.inside,
            first: Builder(
              builder: (context) {
                firstMargins = AdaptiveRegion.marginsOf(context);
                return const SizedBox.expand(key: firstKey);
              },
            ),
          ),
        ),
      );
      expect(firstRect(tester).left, 0);
      expect(firstRect(tester).width, 24 + 360);
      expect(secondRect(tester).right, 1000);
      expect(firstMargins, const EdgeInsetsDirectional.only(start: 24));
    });
  });
}
