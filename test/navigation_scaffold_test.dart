// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const destinations = [
  NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
  NavigationDestination(icon: Icon(Icons.article), label: 'Articles'),
  NavigationDestination(icon: Icon(Icons.dashboard), label: 'Feed'),
];

const railDestinations = [
  NavigationRailDestination(icon: Icon(Icons.inbox), label: Text('Inbox')),
  NavigationRailDestination(icon: Icon(Icons.article), label: Text('Articles')),
  NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Feed')),
];

Widget scaffold({
  Key? key,
  required Widget body,
  int? paneCount,
  TextDirection textDirection = TextDirection.ltr,
  Widget? floatingActionButton,
}) => app(
  NavigationScaffold(
    key: key,
    paneCount: paneCount,
    navigationBar: NavigationBar(destinations: destinations),
    navigationRail: NavigationRail(
      selectedIndex: 0,
      destinations: railDestinations,
    ),
    floatingActionButton: floatingActionButton,
    body: body,
  ),
  textDirection: textDirection,
);

Widget twoPaneBody() => ListDetailLayout<int>(
  selectedId: 1,
  twoPaneBreakpoint: Breakpoint.medium,
  listBuilder: (context) => const SizedBox.expand(key: ValueKey('list')),
  detailBuilder: (context, id, placement) =>
      const SizedBox.expand(key: ValueKey('detail')),
);

Widget onePaneBody() =>
    const SupportingPaneLayout(focus: SizedBox.expand(key: ValueKey('pane')));

Finder get bar => find.byType(NavigationBar);
Finder get rail => find.byType(NavigationRail);

Future<void> resize(WidgetTester tester, Size size) async {
  setWindowSize(tester, size);
  await tester.pump();
  await settle(tester);
}

void main() {
  group('Placement', () {
    testWidgets('compact shows the bar', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(scaffold(body: const SizedBox.expand()));
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);
      expect(tester.getRect(bar).bottom, 800);
    });

    testWidgets('medium beside one pane shows the rail', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(scaffold(body: const SizedBox.expand()));
      await settle(tester);
      expect(rail, findsOneWidget);
      expect(bar, findsNothing);
    });

    testWidgets('medium below two panes shows the bar, learnt from the body', (
      tester,
    ) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(scaffold(body: twoPaneBody()));
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);
      // The panes keep the full width.
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail')));
      expect(list.left, 24);
      expect(detail.right, 700 - 24);
    });

    testWidgets('an explicit pane count overrides the body', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(
        scaffold(body: const SizedBox.expand(), paneCount: 2),
      );
      await settle(tester);
      expect(bar, findsOneWidget);

      // Over what the layouts report, too.
      await tester.pumpWidget(scaffold(body: twoPaneBody(), paneCount: 1));
      await settle(tester);
      expect(rail, findsOneWidget);
      expect(bar, findsNothing);
      await tester.pumpWidget(scaffold(body: onePaneBody(), paneCount: 2));
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);
    });

    testWidgets('resolves against its own region, with the theme\'s '
        'breakpoints', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      // 500dp of a wide window is compact.
      await tester.pumpWidget(
        app(
          Row(
            children: [
              SizedBox(
                width: 500,
                child: NavigationScaffold(
                  navigationBar: NavigationBar(destinations: destinations),
                  navigationRail: NavigationRail(
                    selectedIndex: 0,
                    destinations: railDestinations,
                  ),
                  body: const SizedBox.expand(),
                ),
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      );
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);

      // 900dp is expanded by default, and medium by these breakpoints: the
      // two panes there take the bar.
      setWindowSize(tester, const Size(900, 800));
      await tester.pumpWidget(
        app(
          MaterialLayoutTheme(
            data: const MaterialLayoutThemeData(
              breakpoints: Breakpoints(expandedMinWidth: 1000),
            ),
            child: NavigationScaffold(
              navigationBar: NavigationBar(destinations: destinations),
              navigationRail: NavigationRail(
                selectedIndex: 0,
                destinations: railDestinations,
              ),
              body: twoPaneBody(),
            ),
          ),
        ),
      );
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);
    });

    for (final width in [1000.0, 1300.0, 1700.0]) {
      testWidgets('${width}dp shows the rail, whatever the panes', (
        tester,
      ) async {
        setWindowSize(tester, Size(width, 800));
        await tester.pumpWidget(scaffold(body: twoPaneBody()));
        await settle(tester);
        expect(rail, findsOneWidget);
        expect(bar, findsNothing);
      });
    }

    testWidgets('never shows the bar and the rail together', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(scaffold(body: const SizedBox.expand()));
      await settle(tester);
      for (final width in [700.0, 1300.0, 500.0, 1000.0, 400.0]) {
        await resize(tester, Size(width, 800));
        expect(
          bar.evaluate().length + rail.evaluate().length,
          1,
          reason: '$width',
        );
      }
    });

    for (final (from, to) in [(400.0, 700.0), (700.0, 400.0)]) {
      testWidgets('swaps from ${from}dp to ${to}dp one component after the '
          'other', (tester) async {
        setWindowSize(tester, Size(from, 800));
        await tester.pumpWidget(
          scaffold(body: const SizedBox.expand(key: ValueKey('body'))),
        );
        await settle(tester);
        setWindowSize(tester, Size(to, 800));
        final arriving = to > from ? rail : bar;
        final leaving = to > from ? bar : rail;
        var arrived = false;
        for (var frame = 0; frame < 120; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final body = tester.getRect(find.byKey(const ValueKey('body')));
          final barHeight = 800 - body.bottom;
          final railWidth = body.left;
          expect(
            barHeight > 0 && railWidth > 0,
            isFalse,
            reason: 'frame $frame: bar $barHeight, rail $railWidth',
          );
          // Once the arriving component shows, the leaving one is gone for
          // good, not carried back by its spring.
          if (arriving.evaluate().isNotEmpty &&
              (to > from ? railWidth : barHeight) > 0) {
            arrived = true;
          }
          if (arrived) expect(leaving, findsNothing, reason: 'frame $frame');
        }
        expect(arrived, isTrue);
      });
    }

    testWidgets('shows no navigation rather than a component not prescribed', (
      tester,
    ) async {
      setWindowSize(tester, const Size(400, 800));
      // A compact app keeps its rail in a modal drawer instead of a bar.
      await tester.pumpWidget(
        app(
          NavigationScaffold(
            navigationRail: NavigationRail(
              selectedIndex: 0,
              destinations: railDestinations,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await settle(tester);
      expect(rail, findsNothing);
      await resize(tester, const Size(700, 800));
      expect(rail, findsOneWidget);
    });

    testWidgets('while they swap, only the arriving component takes input', (
      tester,
    ) async {
      final barTaps = <int>[];
      final railTaps = <int>[];
      Widget selectable() => app(
        NavigationScaffold(
          navigationBar: NavigationBar(
            destinations: destinations,
            onDestinationSelected: barTaps.add,
          ),
          navigationRail: NavigationRail(
            selectedIndex: 0,
            destinations: railDestinations,
            onDestinationSelected: railTaps.add,
          ),
          body: const SizedBox.expand(),
        ),
      );
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(selectable());
      await settle(tester);
      await tester.tap(
        find.descendant(of: bar, matching: find.text('Articles')),
      );
      expect(barTaps, [1]);

      setWindowSize(tester, const Size(700, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(bar, findsOneWidget);
      expect(rail, findsOneWidget);
      // The leaving bar, still on the screen, takes no taps, and no focus.
      final feed = tester.getRect(
        find.descendant(of: bar, matching: find.text('Feed')),
      );
      expect(feed.top, lessThan(800));
      await tester.tapAt(Offset(feed.center.dx, (feed.top + 1).clamp(0, 799)));
      expect(barTaps, [1]);
      final barFocus = Focus.of(
        tester.element(find.descendant(of: bar, matching: find.text('Feed'))),
      );
      expect(barFocus.canRequestFocus, isFalse);
      await settle(tester);
      expect(bar, findsNothing);

      // Settled, the rail takes them.
      await tester.tap(find.descendant(of: rail, matching: find.text('Feed')));
      expect(railTaps, [2]);
    });

    testWidgets('a layout in an inactive tab does not count, until its tab '
        'shows', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      Widget tabs(int index) => scaffold(
        body: IndexedStack(
          index: index,
          children: [const SizedBox.expand(), twoPaneBody()],
        ),
      );
      await tester.pumpWidget(tabs(0));
      await settle(tester);
      expect(rail, findsOneWidget);
      await tester.pumpWidget(tabs(1));
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(rail, findsNothing);
      await tester.pumpWidget(tabs(0));
      await settle(tester);
      expect(rail, findsOneWidget);
      expect(bar, findsNothing);
    });

    group('Another rule', () {
      Widget ruled(
        NavigationPlacementRule rule, {
        Widget body = const SizedBox.expand(key: ValueKey('body')),
        bool withBar = true,
        bool withRail = true,
      }) => app(
        NavigationScaffold(
          placementRule: rule,
          navigationBar: withBar
              ? NavigationBar(destinations: destinations)
              : null,
          navigationRail: withRail
              ? NavigationRail(selectedIndex: 0, destinations: railDestinations)
              : null,
          body: body,
        ),
      );

      testWidgets('the bar alone, at every width', (tester) async {
        setWindowSize(tester, const Size(400, 800));
        await tester.pumpWidget(
          ruled(const NavigationPlacementRule.only(NavigationPlacement.bar)),
        );
        for (final width in [400.0, 700.0, 1000.0, 1300.0, 1700.0]) {
          await resize(tester, Size(width, 800));
          expect(bar, findsOneWidget, reason: '$width');
          expect(rail, findsNothing, reason: '$width');
        }
      });

      testWidgets('the rail alone, compact included', (tester) async {
        setWindowSize(tester, const Size(400, 800));
        await tester.pumpWidget(
          ruled(const NavigationPlacementRule.only(NavigationPlacement.rail)),
        );
        await settle(tester);
        expect(rail, findsOneWidget);
        expect(bar, findsNothing);
        expect(tester.getRect(rail).left, 0);
      });

      testWidgets('a rail up to expanded, then the bar', (tester) async {
        final rule = NavigationPlacementRule.from(
          (breakpoint, paneCount) => breakpoint < Breakpoint.expanded
              ? NavigationPlacement.rail
              : NavigationPlacement.bar,
        );
        setWindowSize(tester, const Size(400, 800));
        await tester.pumpWidget(ruled(rule));
        await settle(tester);
        expect(rail, findsOneWidget);
        await resize(tester, const Size(1000, 800));
        expect(bar, findsOneWidget);
        expect(rail, findsNothing);
        await resize(tester, const Size(700, 800));
        expect(rail, findsOneWidget);
        expect(bar, findsNothing);
      });

      testWidgets('is told the pane count its layouts report', (tester) async {
        final rule = NavigationPlacementRule.from(
          (breakpoint, paneCount) => paneCount > 1
              ? NavigationPlacement.bar
              : NavigationPlacement.rail,
        );
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(ruled(rule, body: twoPaneBody()));
        await settle(tester);
        expect(bar, findsOneWidget);
        await tester.pumpWidget(ruled(rule, body: onePaneBody()));
        await settle(tester);
        expect(rail, findsOneWidget);
      });

      testWidgets('shows no navigation where the component it chose is not '
          'given', (tester) async {
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(
          ruled(
            const NavigationPlacementRule.only(NavigationPlacement.bar),
            withBar: false,
          ),
        );
        await settle(tester);
        expect(bar, findsNothing);
        expect(rail, findsNothing);
        expect(
          NavigationScaffold.placementOf(
            tester.element(find.byKey(const ValueKey('body'))),
          ),
          NavigationPlacement.none,
        );
      });

      testWidgets('given anew, swaps the components one after the other', (
        tester,
      ) async {
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(ruled(NavigationPlacementRule.material));
        await settle(tester);
        expect(rail, findsOneWidget);
        await tester.pumpWidget(
          ruled(const NavigationPlacementRule.only(NavigationPlacement.bar)),
        );
        for (var frame = 0; frame < 120; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final body = tester.getRect(find.byKey(const ValueKey('body')));
          expect(
            800 - body.bottom > 0 && body.left > 0,
            isFalse,
            reason: 'frame $frame',
          );
        }
        await settle(tester);
        expect(bar, findsOneWidget);
        expect(rail, findsNothing);
      });
    });

    group('Room for the rail', () {
      // A list-detail layout showing two panes from [twoPanesFrom], which
      // records every placement its detail is built in.
      Widget recordingBody(
        List<DetailPlacement> placements, {
        Breakpoint twoPanesFrom = Breakpoint.expanded,
      }) => ListDetailLayout<int>(
        selectedId: 1,
        twoPaneBreakpoint: twoPanesFrom,
        listBuilder: (context) => const SizedBox.expand(),
        detailBuilder: (context, id, placement) {
          placements.add(placement);
          return const SizedBox.expand();
        },
      );

      Widget ruled(NavigationPlacementRule rule, Widget body, {int? panes}) =>
          app(
            NavigationScaffold(
              placementRule: rule,
              paneCount: panes,
              navigationBar: NavigationBar(destinations: destinations),
              navigationRail: NavigationRail(
                selectedIndex: 0,
                destinations: railDestinations,
              ),
              body: body,
            ),
          );

      final railFromExpanded = NavigationPlacementRule.from(
        (breakpoint, paneCount) => breakpoint >= Breakpoint.expanded
            ? NavigationPlacement.rail
            : NavigationPlacement.bar,
      );

      for (final (name, rule, panes, twoPanesFrom, from, to) in [
        (
          'a rail from expanded',
          railFromExpanded,
          null,
          Breakpoint.expanded,
          830.0,
          850.0,
        ),
        (
          "Material's rule with one pane stated",
          NavigationPlacementRule.material,
          1,
          Breakpoint.medium,
          590.0,
          610.0,
        ),
      ]) {
        testWidgets('keeps the layouts at the panes that fit beside the '
            'arriving rail: $name', (tester) async {
          final placements = <DetailPlacement>[];
          setWindowSize(tester, Size(from, 800));
          await tester.pumpWidget(
            ruled(
              rule,
              recordingBody(placements, twoPanesFrom: twoPanesFrom),
              panes: panes,
            ),
          );
          await settle(tester);
          placements.clear();
          setWindowSize(tester, Size(to, 800));
          for (var frame = 0; frame < 60; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(rail, findsOneWidget);
          // The body's width is too little for two panes once the rail is
          // in, so the detail never becomes a pane on the way.
          expect(placements, isNotEmpty);
          expect(placements, everyElement(DetailPlacement.page));
        });
      }

      for (final (from, to, expected) in [
        (590.0, 640.0, DetailPlacement.page),
        (720.0, 640.0, DetailPlacement.pane),
      ]) {
        testWidgets("Material's rule keeps the navigation the body had where "
            'two panes fit only without the rail: ${from}dp to ${to}dp', (
          tester,
        ) async {
          final placements = <DetailPlacement>[];
          setWindowSize(tester, Size(from, 800));
          await tester.pumpWidget(
            ruled(
              NavigationPlacementRule.material,
              recordingBody(placements, twoPanesFrom: Breakpoint.medium),
            ),
          );
          await settle(tester);
          placements.clear();
          setWindowSize(tester, Size(to, 800));
          final growing = to > from;
          for (var frame = 0; frame < 60; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            // Shrinking, the bar stays throughout.
            if (!growing) expect(rail, findsNothing, reason: 'frame $frame');
          }
          // Growing, the window takes the rail, beside one pane; shrinking,
          // it keeps the bar, below two.
          expect(rail, growing ? findsOneWidget : findsNothing);
          expect(bar, growing ? findsNothing : findsOneWidget);
          expect(placements, isNotEmpty);
          expect(placements, everyElement(expected));
        });
      }

      testWidgets('gives the layouts the whole width as soon as the rail '
          'leaves', (tester) async {
        final placements = <DetailPlacement>[];
        final barFromExpanded = NavigationPlacementRule.from(
          (breakpoint, paneCount) => breakpoint >= Breakpoint.expanded
              ? NavigationPlacement.bar
              : NavigationPlacement.rail,
        );
        setWindowSize(tester, const Size(830, 800));
        await tester.pumpWidget(
          ruled(barFromExpanded, recordingBody(placements)),
        );
        await settle(tester);
        expect(placements.last, DetailPlacement.page);
        setWindowSize(tester, const Size(850, 800));
        await tester.pump(const Duration(milliseconds: 16));
        // Two panes at once, while the rail is still on its way out.
        expect(placements.last, DetailPlacement.pane);
        expect(rail, findsOneWidget);
        await settle(tester);
        expect(rail, findsNothing);
      });

      testWidgets("keeps the rail's room while its width follows it in", (
        tester,
      ) async {
        setWindowSize(tester, const Size(830, 800));
        await tester.pumpWidget(
          ruled(railFromExpanded, const SizedBox.expand(key: ValueKey('body'))),
        );
        await settle(tester);
        setWindowSize(tester, const Size(850, 800));
        final widths = <double>[];
        for (var frame = 0; frame < 60; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final body = find.byKey(const ValueKey('body'));
          widths.add(tester.getSize(body).width);
          // The region resolves for the room left once the rail is in.
          expect(
            AdaptiveRegion.breakpointOf(tester.element(body)),
            Breakpoint.medium,
            reason: 'frame $frame',
          );
        }
        // The pixels still move with the rail.
        expect(widths.first, 850);
        expect(widths.last, 850 - tester.getSize(rail).width);
      });

      testWidgets('a first placement that depends on the panes waits for '
          'the layouts to count them', (tester) async {
        setWindowSize(tester, const Size(700, 800));
        await tester.pumpWidget(scaffold(body: twoPaneBody()));
        // The first frame shows no navigation while the layouts count.
        expect(
          NavigationScaffold.placementOf(
            tester.element(find.byKey(const ValueKey('list'))),
          ),
          NavigationPlacement.none,
        );
        await tester.pump();
        // Then the bar, in place at once: no rail placed on a guess and
        // swapped away.
        expect(rail, findsNothing);
        expect(tester.getRect(bar).bottom, 800);
        final top = tester.getRect(bar).top;
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getRect(bar).top, top);
      });

      testWidgets('a first placement that does not depend on the panes '
          'shows at once', (tester) async {
        for (final (size, panes, expected) in [
          (const Size(400, 800), null, NavigationPlacement.bar),
          (const Size(1000, 800), null, NavigationPlacement.rail),
          (const Size(700, 800), 1, NavigationPlacement.rail),
        ]) {
          setWindowSize(tester, size);
          await tester.pumpWidget(
            scaffold(
              key: ValueKey(size),
              body: const SizedBox.expand(key: ValueKey('body')),
              paneCount: panes,
            ),
          );
          expect(
            NavigationScaffold.placementOf(
              tester.element(find.byKey(const ValueKey('body'))),
            ),
            expected,
            reason: '$size',
          );
          expect(
            expected == NavigationPlacement.bar ? bar : rail,
            findsOneWidget,
          );
        }
      });
    });

    testWidgets('a layout that leaves stops counting', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(scaffold(body: twoPaneBody()));
      await settle(tester);
      expect(bar, findsOneWidget);
      await tester.pumpWidget(scaffold(body: const SizedBox.expand()));
      await settle(tester);
      expect(rail, findsOneWidget);
    });
  });

  group('The rail', () {
    testWidgets('sits on the leading edge, outside the panes, in place of '
        'the margin there', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(scaffold(body: twoPaneBody()));
      await settle(tester);
      final railRect = tester.getRect(rail);
      expect(railRect.left, 0);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.left, railRect.right);
      final detail = tester.getRect(find.byKey(const ValueKey('detail')));
      expect(detail.right, 1300 - 24);
    });

    testWidgets('sits on the right in a right-to-left layout', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        scaffold(body: twoPaneBody(), textDirection: TextDirection.rtl),
      );
      await settle(tester);
      final railRect = tester.getRect(rail);
      expect(railRect.right, 1300);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.right, railRect.left);
    });

    testWidgets('takes the margin over as it arrives', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(scaffold(body: onePaneBody()));
      await settle(tester);
      final pane = find.byKey(const ValueKey('pane'));
      expect(tester.getRect(pane).left, 16);

      setWindowSize(tester, const Size(700, 800));
      final starts = <double>[];
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        starts.add(tester.getRect(pane).left);
      }
      await settle(tester);
      // The pane moves over with the rail, never back toward the edge.
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i], greaterThanOrEqualTo(starts[i - 1] - 0.5));
      }
      expect(tester.getRect(pane).left, tester.getRect(rail).right);
    });

    testWidgets('narrows the body, which layouts resolve against', (
      tester,
    ) async {
      Breakpoint? breakpoint;
      setWindowSize(tester, const Size(900, 800));
      await tester.pumpWidget(
        scaffold(
          body: Builder(
            builder: (context) {
              breakpoint = AdaptiveRegion.breakpointOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await settle(tester);
      // 900dp is expanded; beside an 80dp rail the body is medium.
      expect(breakpoint, Breakpoint.medium);
    });
  });

  testWidgets('publishes its placement', (tester) async {
    final placements = <NavigationPlacement>[];
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      scaffold(
        body: const SizedBox.expand(),
        floatingActionButton: Builder(
          builder: (context) {
            placements.add(NavigationScaffold.placementOf(context));
            return const SizedBox();
          },
        ),
      ),
    );
    await settle(tester);
    expect(placements.last, NavigationPlacement.bar);
    await resize(tester, const Size(1000, 800));
    expect(placements.last, NavigationPlacement.rail);
  });

  testWidgets('a navigation bar carries three to five destinations', (
    tester,
  ) async {
    setWindowSize(tester, const Size(400, 800));
    Widget withBar(List<NavigationDestination> destinations) => app(
      NavigationScaffold(
        navigationBar: NavigationBar(destinations: destinations),
        body: const SizedBox.expand(),
      ),
    );
    await tester.pumpWidget(withBar(destinations.sublist(1)));
    expect(tester.takeException(), isFlutterError);
    await tester.pumpWidget(withBar([...destinations, ...destinations]));
    expect(tester.takeException(), isFlutterError);
    await tester.pumpWidget(withBar(destinations));
    expect(tester.takeException(), isNull);
  });

  testWidgets("passes the other arguments on to its Scaffold", (tester) async {
    setWindowSize(tester, const Size(400, 800));
    const fab = FloatingActionButton(onPressed: null, child: Icon(Icons.add));
    const drawer = Drawer(child: Text('Drawer'));
    const endDrawer = Drawer(child: Text('End drawer'));
    const sheet = SizedBox(height: 40, child: Text('Sheet'));
    final appBar = AppBar(title: const Text('Title'));
    await tester.pumpWidget(
      app(
        NavigationScaffold(
          navigationBar: NavigationBar(destinations: destinations),
          appBar: appBar,
          floatingActionButton: fab,
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomSheet: sheet,
          backgroundColor: const Color(0xFF123456),
          resizeToAvoidBottomInset: false,
          restorationId: 'scaffold',
          body: const SizedBox.expand(),
        ),
      ),
    );
    await settle(tester);
    final scaffold = tester.widget<Scaffold>(
      find
          .descendant(
            of: find.byType(NavigationScaffold),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    expect(scaffold.appBar, same(appBar));
    expect(scaffold.floatingActionButton, same(fab));
    expect(
      scaffold.floatingActionButtonLocation,
      FloatingActionButtonLocation.startFloat,
    );
    expect(scaffold.drawer, same(drawer));
    expect(scaffold.endDrawer, same(endDrawer));
    expect(scaffold.bottomSheet, same(sheet));
    expect(scaffold.backgroundColor, const Color(0xFF123456));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    expect(scaffold.restorationId, 'scaffold');
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Sheet'), findsOneWidget);
  });

  testWidgets('swaps the bar and the rail on its own motion', (tester) async {
    Widget moving(Duration duration) => app(
      NavigationScaffold(
        navigationBar: NavigationBar(destinations: destinations),
        navigationRail: NavigationRail(
          selectedIndex: 0,
          destinations: railDestinations,
        ),
        motion: PaneMotion(
          enter: Motion.curved(duration: duration, curve: Curves.linear),
          exit: Motion.curved(duration: duration, curve: Curves.linear),
        ),
        body: const SizedBox.expand(key: ValueKey('body')),
      ),
    );
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(moving(const Duration(milliseconds: 400)));
    await settle(tester);
    setWindowSize(tester, const Size(700, 800));
    await tester.pump();
    // Half way through the bar's 400ms exit, it is still going.
    await tester.pump(const Duration(milliseconds: 200));
    final barHeight =
        800 - tester.getRect(find.byKey(const ValueKey('body'))).bottom;
    expect(barHeight, greaterThan(0));
    expect(rail, findsOneWidget);
    await settle(tester);
    expect(bar, findsNothing);
  });

  group("The body's insets are those of a Scaffold's body", () {
    // What the body learns of the insets, with a scaffold of [build].
    Future<MediaQueryData> bodyMedia(
      WidgetTester tester,
      Widget Function(Widget body) build,
    ) async {
      late MediaQueryData seen;
      await tester.pumpWidget(
        app(
          build(
            Builder(
              builder: (context) {
                seen = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await settle(tester);
      return seen;
    }

    Widget navigation(
      Widget body, {
      PreferredSizeWidget? appBar,
      bool extendBody = false,
    }) => NavigationScaffold(
      appBar: appBar,
      extendBody: extendBody,
      navigationBar: NavigationBar(destinations: destinations),
      navigationRail: NavigationRail(
        selectedIndex: 0,
        destinations: railDestinations,
      ),
      body: body,
    );

    Widget plain(
      Widget body, {
      PreferredSizeWidget? appBar,
      bool extendBody = false,
    }) => Scaffold(
      appBar: appBar,
      extendBody: extendBody,
      bottomNavigationBar: NavigationBar(destinations: destinations),
      body: body,
    );

    testWidgets('under an app bar and above a bar', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.resetPadding);
      final bar = AppBar(title: const Text('Title'));
      final expected = await bodyMedia(
        tester,
        (body) => plain(body, appBar: bar),
      );
      final actual = await bodyMedia(
        tester,
        (body) => navigation(body, appBar: bar),
      );
      expect(actual.padding, expected.padding);
      expect(actual.padding, EdgeInsets.zero);
    });

    testWidgets('above the keyboard', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      final expected = await bodyMedia(tester, plain);
      final actual = await bodyMedia(tester, navigation);
      expect(actual.viewInsets, expected.viewInsets);
      expect(actual.viewInsets.bottom, 0);
    });

    testWidgets('behind the bar with extendBody', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      final expected = await bodyMedia(
        tester,
        (body) => plain(body, extendBody: true),
      );
      final actual = await bodyMedia(
        tester,
        (body) => navigation(body, extendBody: true),
      );
      expect(actual.padding.bottom, expected.padding.bottom);
      expect(actual.padding.bottom, greaterThan(0));
    });
  });

  for (final rtl in [false, true]) {
    testWidgets('the rail takes over the leading inset as it arrives, and '
        'gives it back as it leaves${rtl ? ', right to left' : ''}', (
      tester,
    ) async {
      tester.view.padding = rtl
          ? const FakeViewPadding(right: 48)
          : const FakeViewPadding(left: 48);
      addTearDown(tester.view.resetPadding);
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        scaffold(
          body: onePaneBody(),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      );
      await settle(tester);
      final pane = find.byKey(const ValueKey('pane'));
      // How far the pane's leading edge is from the window's leading edge.
      double leading(double width) =>
          rtl ? width - tester.getRect(pane).right : tester.getRect(pane).left;
      // Beyond the inset by the compact margin.
      expect(leading(400), 48 + 16);
      final lefts = <double>[leading(400)];

      setWindowSize(tester, const Size(700, 800));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        lefts.add(leading(700));
      }
      // Clear of the inset throughout, moving only toward the rail's edge.
      expect(lefts, everyElement(greaterThanOrEqualTo(48)));
      for (var i = 1; i < lefts.length; i++) {
        expect(lefts[i], greaterThanOrEqualTo(lefts[i - 1] - 0.5));
      }
      // The rail keeps clear of the inset itself, and the pane starts where
      // it ends.
      final railRect = tester.getRect(rail);
      expect(leading(700), rtl ? 700 - railRect.left : railRect.right);

      final back = <double>[lefts.last];
      setWindowSize(tester, const Size(400, 800));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        back.add(leading(400));
      }
      expect(back, everyElement(greaterThanOrEqualTo(48)));
      for (var i = 1; i < back.length; i++) {
        expect(back[i], lessThanOrEqualTo(back[i - 1] + 0.5));
      }
      expect(back.last, 48 + 16);
    });
  }
}
