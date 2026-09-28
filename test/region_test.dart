// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Widget listDetail({String prefix = ''}) => ListDetailLayout<int>(
  selectedId: 1,
  listBuilder: (context) => SizedBox.expand(key: ValueKey('${prefix}list')),
  detailBuilder: (context, id, placement) =>
      SizedBox.expand(key: ValueKey('${prefix}detail')),
);

bool shows(String key) => find.byKey(ValueKey(key)).evaluate().isNotEmpty;

void main() {
  group('Regions', () {
    testWidgets('a layout resolves against its region, not the window', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 700, height: 800, child: listDetail()),
            ),
          ),
        ),
      );
      // The window is large, but the 700dp region is medium: one pane.
      expect(shows('list'), isFalse);
      expect(shows('detail'), isTrue);
    });

    testWidgets('a pane is a region for the widgets inside it', (tester) async {
      final breakpoints = <String, Breakpoint>{};
      final sizes = <String, Size>{};
      Widget probe(String name) => Builder(
        builder: (context) {
          breakpoints[name] = AdaptiveRegion.breakpointOf(context);
          sizes[name] = AdaptiveRegion.sizeOf(context);
          return const SizedBox.expand();
        },
      );
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: probe('focus'),
              supporting: probe('supporting'),
            ),
          ),
        ),
      );
      expect(sizes['supporting']!.width, 412);
      expect(breakpoints['supporting'], Breakpoint.compact);
      // 1300 - 48 - 24 - 412 = 816dp: a medium region.
      expect(sizes['focus']!.width, 816);
      expect(breakpoints['focus'], Breakpoint.medium);
    });

    testWidgets('outside every region, the window is the region', (
      tester,
    ) async {
      Breakpoint? breakpoint;
      HeightBreakpoint? height;
      Size? size;
      setWindowSize(tester, const Size(1300, 400));
      await tester.pumpWidget(
        app(
          Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: Builder(
                builder: (context) {
                  breakpoint = AdaptiveRegion.breakpointOf(context);
                  height = AdaptiveRegion.heightBreakpointOf(context);
                  size = AdaptiveRegion.sizeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(breakpoint, Breakpoint.large);
      expect(height, HeightBreakpoint.compact);
      expect(size, const Size(1300, 400));
    });

    testWidgets('breakpoints come from the theme', (tester) async {
      setWindowSize(tester, const Size(900, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: MaterialLayoutTheme(
              data: const MaterialLayoutThemeData(
                breakpoints: Breakpoints(expandedMinWidth: 1000),
              ),
              child: listDetail(),
            ),
          ),
        ),
      );
      // 900dp would be expanded; with the threshold moved it is medium.
      expect(shows('list'), isFalse);
    });

    testWidgets('a theme extension sets the tokens too', (tester) async {
      setWindowSize(tester, const Size(900, 800));
      await tester.pumpWidget(
        app(
          Scaffold(body: listDetail()),
          theme: ThemeData(
            extensions: const [
              MaterialLayoutThemeData(
                breakpoints: Breakpoints(expandedMinWidth: 1000),
              ),
            ],
          ),
        ),
      );
      expect(shows('list'), isFalse);
    });
  });

  group('Dependents', () {
    testWidgets('rebuild only for what they read: the height breakpoint '
        'when the height crosses one', (tester) async {
      var widthBuilds = 0;
      var heightBuilds = 0;
      HeightBreakpoint? height;
      // The same widgets each time, which rebuild only when what they read
      // changes.
      final readers = Column(
        children: [
          Builder(
            builder: (context) {
              AdaptiveRegion.breakpointOf(context);
              widthBuilds++;
              return const SizedBox();
            },
          ),
          Builder(
            builder: (context) {
              height = AdaptiveRegion.heightBreakpointOf(context);
              heightBuilds++;
              return const SizedBox();
            },
          ),
        ],
      );
      Widget region(double regionHeight) => app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 700,
            height: regionHeight,
            child: AdaptiveRegion(child: readers),
          ),
        ),
      );
      setWindowSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(region(500));
      expect(height, HeightBreakpoint.medium);
      final (widths, heights) = (widthBuilds, heightBuilds);

      await tester.pumpWidget(region(600));
      expect((widthBuilds, heightBuilds), (widths, heights));

      await tester.pumpWidget(region(400));
      expect(height, HeightBreakpoint.compact);
      expect(heightBuilds, heights + 1);
      expect(widthBuilds, widths);
    });
  });

  group('Nesting', () {
    Widget nested({bool sheet = true}) => app(
      Scaffold(
        body: SupportingPaneLayout(
          focus: listDetail(prefix: 'inner '),
          supporting: sheet
              ? SideSheet(
                  onClose: () {},
                  child: const SizedBox(key: ValueKey('sheet'), height: 100),
                )
              : const SizedBox.expand(key: ValueKey('sheet')),
        ),
      ),
    );

    testWidgets('a nested layout applies no margins of its own', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(nested());
      final list = tester.getRect(find.byKey(const ValueKey('inner list')));
      expect(list.left, 24);
    });

    testWidgets('three panes show side by side only at extra-large, the '
        'third a side sheet', (tester) async {
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(nested());
      expect(shows('inner list'), isTrue);
      expect(shows('inner detail'), isTrue);
      expect(shows('sheet'), isTrue);

      // At large the inner region is expanded, which alone would show two
      // panes; the outer layout leaves it room for one.
      setWindowSize(tester, const Size(1500, 800));
      await tester.pump();
      await settle(tester);
      expect(shows('inner list'), isFalse);
      expect(shows('inner detail'), isTrue);
      expect(shows('sheet'), isTrue);
    });

    testWidgets('a third pane that is not a side sheet is refused', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(nested(sheet: false));
      expect(shows('sheet'), isTrue);
      expect(shows('inner list'), isFalse);
      expect(shows('inner detail'), isTrue);
    });

    testWidgets('beside a list, the detail pane has the panes left, and the '
        'list keeps to one', (tester) async {
      Widget withSheet(String name) => SupportingPaneLayout(
        focus: SizedBox.expand(key: ValueKey('$name focus')),
        supporting: SideSheet(
          onClose: () {},
          child: SizedBox(key: ValueKey('$name sheet'), height: 100),
        ),
      );
      setWindowSize(tester, const Size(1800, 800));
      final split = PaneSplitController(split: PaneSplit.centered);
      addTearDown(split.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListDetailLayout<int>(
              selectedId: 1,
              splitController: split,
              listBuilder: (context) => withSheet('list'),
              detailBuilder: (context, id, placement) => withSheet('detail'),
            ),
          ),
        ),
      );
      expect(shows('list focus'), isTrue);
      expect(shows('list sheet'), isFalse);
      expect(shows('detail focus'), isTrue);
      expect(shows('detail sheet'), isTrue);
    });

    testWidgets('a nested layout may use the panes the outer one does not '
        'show', (tester) async {
      setWindowSize(tester, const Size(1100, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(focus: listDetail(prefix: 'inner ')),
          ),
        ),
      );
      expect(shows('inner list'), isTrue);
      expect(shows('inner detail'), isTrue);
    });

    testWidgets('never more than three panes', (tester) async {
      setWindowSize(tester, const Size(2400, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: SupportingPaneLayout(
                focus: listDetail(prefix: 'inner '),
                supporting: const SizedBox.expand(key: ValueKey('middle')),
              ),
              supporting: const SizedBox.expand(key: ValueKey('outer')),
            ),
          ),
        ),
      );
      final visible = [
        'inner list',
        'inner detail',
        'middle',
        'outer',
      ].where(shows).length;
      expect(visible, 3);
    });
  });

  group('Feed', () {
    Widget feed({FeedSpanBuilder? spanBuilder}) => app(
      Scaffold(
        body: FeedLayout(
          minItemWidth: 200,
          itemCount: 12,
          spanBuilder: spanBuilder,
          itemBuilder: (context, index) =>
              SizedBox(key: ValueKey('item $index'), height: 100 + index * 5),
        ),
      ),
    );

    Rect item(WidgetTester tester, int index) =>
        tester.getRect(find.byKey(ValueKey('item $index')));

    testWidgets('is one column at compact, items filling the width', (
      tester,
    ) async {
      setWindowSize(tester, const Size(500, 2000));
      await tester.pumpWidget(feed());
      expect(item(tester, 0).left, 16);
      expect(item(tester, 0).right, 500 - 16);
      expect(item(tester, 1).top, greaterThan(item(tester, 0).bottom));
    });

    testWidgets('grows columns with the width and reflows in order', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 2000));
      await tester.pumpWidget(feed());
      // 1300 - 48 = 1252dp fits six 200dp columns with 8dp gaps.
      expect(item(tester, 5).top, item(tester, 0).top);
      expect(item(tester, 6).top, greaterThan(item(tester, 0).bottom));
      expect(item(tester, 1).left - item(tester, 0).right, 8);

      setWindowSize(tester, const Size(700, 2000));
      await tester.pump();
      // 700 - 48 = 652dp fits three.
      expect(item(tester, 2).top, item(tester, 0).top);
      expect(item(tester, 3).top, greaterThan(item(tester, 0).bottom));
    });

    testWidgets('starts its items clear of the insets, and ends them clear '
        'of the bottom one', (tester) async {
      setWindowSize(tester, const Size(500, 600));
      tester.view.padding = const FakeViewPadding(
        top: 40,
        bottom: 20,
        left: 30,
      );
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(feed());
      expect(item(tester, 0).top, 40);
      // The margin lies beyond the inset.
      expect(item(tester, 0).left, 30 + 16);
      expect(item(tester, 0).right, 500 - 16);
      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(FeedLayout),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      // The extent is known once the end has been laid out.
      for (var i = 0; i < 5; i++) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }
      expect(item(tester, 11).bottom, 600 - 20);
    });

    testWidgets('keeps its gap, its padding and the margins of its '
        'breakpoint, and tells the span builder its columns', (tester) async {
      final columns = <int>{};
      setWindowSize(tester, const Size(1300, 2000));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: FeedLayout(
              minItemWidth: 200,
              gap: 16,
              padding: const EdgeInsets.only(top: 10),
              itemCount: 12,
              // The first spans more columns than there are: all of them.
              spanBuilder: (index, columnCount) {
                columns.add(columnCount);
                return index == 0 ? 99 : 1;
              },
              itemBuilder: (context, index) =>
                  SizedBox(key: ValueKey('item $index'), height: 100),
            ),
          ),
        ),
      );
      // 1252dp between 24dp margins fits five 200dp columns with 16dp gaps.
      expect(columns, {5});
      expect(item(tester, 0).left, 24);
      expect(item(tester, 0).right, 1300 - 24);
      expect(item(tester, 0).top, 10);
      expect(item(tester, 1).top, item(tester, 0).bottom + 16);
      expect(item(tester, 2).left - item(tester, 1).right, 16);
      expect(item(tester, 5).right, 1300 - 24);
    });

    testWidgets("never gives an item another item's state as it reflows", (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 2000));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: FeedLayout(
              minItemWidth: 200,
              itemCount: 12,
              itemBuilder: (context, index) => _Born(index: index),
            ),
          ),
        ),
      );
      for (final width in [700.0, 1000.0, 500.0, 1300.0]) {
        setWindowSize(tester, Size(width, 2000));
        await tester.pump();
        for (final born in tester.stateList<_BornState>(find.byType(_Born))) {
          expect(born.index, born.widget.index, reason: '$width');
        }
      }
    });

    testWidgets('lets items differ in size', (tester) async {
      setWindowSize(tester, const Size(700, 2000));
      await tester.pumpWidget(
        feed(spanBuilder: (index, _) => index == 0 ? 2 : 1),
      );
      final first = item(tester, 0);
      final second = item(tester, 1);
      expect(first.width, second.width * 2 + 8);
      expect(second.top, first.top);
      expect(first.height, isNot(second.height));
    });
  });
}

// Remembers the index of the item it was first built for.
class _Born extends StatefulWidget {
  const new({required this.index});

  final int index;

  @override
  State<_Born> createState() => _BornState();
}

class _BornState extends State<_Born> {
  late final int index = widget.index;

  @override
  Widget build(BuildContext context) => SizedBox(height: 100.0 + index);
}
