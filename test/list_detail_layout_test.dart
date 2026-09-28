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

const compact = Size(400, 800);
const medium = Size(700, 800);
const expanded = Size(1000, 800);
const large = Size(1300, 800);

const placeholder = ListDetailEmptyBehavior<int>.placeholder(
  child: Text('Nothing selected'),
);

Widget detailContent(int id) => ListView(
  key: ValueKey('detail $id'),
  children: [
    for (var line = 0; line < 40; line++)
      SizedBox(height: 100, child: Text('Detail $id line $line')),
  ],
);

Widget listDetail({
  int? selectedId,
  ValueChanged<int?>? onSelectionChanged,
  ListDetailEmptyBehavior<int> emptyBehavior = placeholder,
  Breakpoint twoPaneBreakpoint = Breakpoint.expanded,
  PaneSplitController? splitController,
  List<DetailPlacement>? placements,
}) => ListDetailLayout<int>(
  selectedId: selectedId,
  onSelectionChanged: onSelectionChanged,
  emptyBehavior: emptyBehavior,
  twoPaneBreakpoint: twoPaneBreakpoint,
  splitController: splitController,
  listBuilder: (context) {
    final layout = ListDetailLayout.of<int>(context);
    return ListView(
      key: const ValueKey('list'),
      children: [
        for (var i = 0; i < 20; i++)
          ListTile(
            key: ValueKey('item $i'),
            title: Text('Item $i'),
            selected: layout.isSelected(i),
            onTap: () => layout.select(i),
          ),
      ],
    );
  },
  detailBuilder: (context, id, placement) {
    placements?.add(placement);
    return switch (placement) {
      DetailPlacement.pane => detailContent(id),
      DetailPlacement.page => Scaffold(
        key: const ValueKey('page'),
        appBar: AppBar(title: Text('Item $id')),
        body: detailContent(id),
      ),
    };
  },
);

Widget host(Widget layout) => app(Scaffold(body: layout));

bool itemSelected(WidgetTester tester, int id) => tester
    .widget<ListTile>(find.byKey(ValueKey('item $id'), skipOffstage: false))
    .selected;

double scrollOffset(WidgetTester tester, int id) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(ValueKey('detail $id')),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .pixels;

Future<void> resize(WidgetTester tester, Size size) async {
  setWindowSize(tester, size);
  await tester.pump();
  await settle(tester);
}

void main() {
  group('Pane counts', () {
    testWidgets('compact shows one pane', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Nothing selected'), findsNothing);
    });

    testWidgets('medium shows one pane by default', (tester) async {
      setWindowSize(tester, medium);
      await tester.pumpWidget(host(listDetail()));
      expect(find.text('Nothing selected'), findsNothing);
    });

    testWidgets('medium may show two panes', (tester) async {
      setWindowSize(tester, medium);
      await tester.pumpWidget(
        host(listDetail(twoPaneBreakpoint: Breakpoint.medium)),
      );
      expect(find.text('Nothing selected'), findsOneWidget);
    });

    for (final size in [expanded, large, const Size(1700, 800)]) {
      testWidgets('${size.width}dp shows two panes', (tester) async {
        setWindowSize(tester, size);
        await tester.pumpWidget(host(listDetail()));
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Nothing selected'), findsOneWidget);
      });
    }
  });

  group('Measurements', () {
    testWidgets('margins are 16dp at compact', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.left, 16);
      expect(list.right, 400 - 16);
    });

    testWidgets('the list is 360dp at expanded, with 24dp margins and '
        'spacer', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.left, 24);
      expect(list.width, 360);
      expect(detail.left - list.right, 24);
      expect(detail.right, 1000 - 24);
    });

    testWidgets('the list is 412dp at large', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.left, 24);
      expect(list.width, 412);
    });

    testWidgets('two panes at medium split evenly whatever width the split '
        'asks for', (tester) async {
      setWindowSize(tester, medium);
      final split = PaneSplitController(split: const PaneSplit.width(500));
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            twoPaneBreakpoint: Breakpoint.medium,
            splitController: split,
          ),
        ),
      );
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.width, detail.width);
      expect((list.right + detail.left) / 2, medium.width / 2);
      // The width is kept, for a breakpoint that allows it.
      expect(split.value, const PaneSplit.width(500));
    });

    testWidgets('two panes at medium split evenly around the window centre, '
        'and refuse custom widths', (tester) async {
      setWindowSize(tester, medium);
      final split = PaneSplitController(split: const PaneSplit.width(500));
      addTearDown(split.dispose);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 1,
            twoPaneBreakpoint: Breakpoint.medium,
            splitController: split,
          ),
        ),
      );
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.left, 24);
      expect(detail.right, 700 - 24);
      expect((list.right + detail.left) / 2, 350);
      expect(detail.left - list.right, 24);
    });
  });

  testWidgets('a nested split centres on the window too', (tester) async {
    // Beside an 80dp rail and inside another layout's margins, the nested
    // list-detail layout has 800 - 80 - 48 = 672dp: a medium region.
    setWindowSize(tester, const Size(800, 800));
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: SupportingPaneLayout(
                  focus: listDetail(
                    selectedId: 1,
                    twoPaneBreakpoint: Breakpoint.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final list = tester.getRect(find.byKey(const ValueKey('list')));
    final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
    // The rail narrows only the leading pane.
    expect((list.right + detail.left) / 2, 400);
    expect(list.left, 80 + 24);
    expect(detail.right, 800 - 24);
  });

  for (final (width, extended) in [(1300.0, false), (1700.0, true)]) {
    testWidgets('a centred split stays centred in the window beside a '
        '${extended ? 'n expanded' : ''} rail at ${width}dp', (tester) async {
      setWindowSize(tester, Size(width, 800));
      final split = PaneSplitController(split: PaneSplit.centered);
      addTearDown(split.dispose);
      await tester.pumpWidget(
        app(
          NavigationScaffold(
            navigationRail: NavigationRail(
              selectedIndex: 0,
              extended: extended,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.article),
                  label: Text('Articles'),
                ),
              ],
            ),
            body: listDetail(selectedId: 1, splitController: split),
          ),
        ),
      );
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      // The rail takes the margin's place.
      expect(list.left, tester.getRect(find.byType(NavigationRail)).right);
      expect((list.right + detail.left) / 2, width / 2);
    });
  }

  testWidgets('a centred split stays centred in the window beside room the '
      'layout leaves on its trailing side', (tester) async {
    setWindowSize(tester, large);
    final split = PaneSplitController(split: PaneSplit.centered);
    addTearDown(split.dispose);
    await tester.pumpWidget(
      host(
        Row(
          children: [
            Expanded(child: listDetail(selectedId: 1, splitController: split)),
            const SizedBox(width: 100),
          ],
        ),
      ),
    );
    await settle(tester);
    final list = tester.getRect(find.byKey(const ValueKey('list')));
    final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
    expect((list.right + detail.left) / 2, large.width / 2);
    expect(detail.right, large.width - 100 - 24);
  });

  group('Hinges', () {
    // A hinge off the window's centre, and wider than the spacer, which a
    // plain even split would not match.
    const hinge = Rect.fromLTWH(380, 0, 40, 800);

    void setHinge(WidgetTester tester, Rect bounds) {
      tester.view.displayFeatures = [
        DisplayFeature(
          bounds: bounds,
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
    }

    testWidgets('a vertical hinge puts the list and the detail on either '
        'side of it', (tester) async {
      setWindowSize(tester, medium);
      setHinge(tester, hinge);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.left, 24);
      expect(list.right, 380);
      expect(detail.left, 420);
      expect(detail.right, 700 - 24);
    });

    testWidgets('a vertical hinge splits a right-to-left layout too, the '
        'list on the right', (tester) async {
      setWindowSize(tester, medium);
      setHinge(tester, hinge);
      await tester.pumpWidget(
        app(
          Scaffold(body: listDetail(selectedId: 1)),
          textDirection: TextDirection.rtl,
        ),
      );
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.left, 420);
      expect(list.right, 700 - 24);
      expect(detail.left, 24);
      expect(detail.right, 380);
    });

    testWidgets('a layout that slides in with its page is placed where the '
        'page rests', (tester) async {
      setWindowSize(tester, medium);
      setHinge(tester, hinge);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder: (context, animation, secondary) =>
                          Scaffold(body: listDetail(selectedId: 1)),
                      transitionsBuilder:
                          (context, animation, secondary, child) =>
                              SlideTransition(
                                position: Tween(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      // While the page slides in, the layout is already arranged for where
      // the page rests: two panes, on either side of the hinge.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final sliding = tester.getRect(find.byKey(const ValueKey('list')));
      expect(sliding.left, greaterThan(24));
      expect(sliding.width, 380 - 24);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.right, 380);
      expect(detail.left, 420);
    });

    testWidgets('a layout scrolled into view is placed where it rests', (
      tester,
    ) async {
      setWindowSize(tester, medium);
      setHinge(tester, hinge);
      await tester.pumpWidget(
        app(
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'First'),
                    Tab(text: 'Second'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [const SizedBox.expand(), listDetail(selectedId: 1)],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Second'));
      await settle(tester);
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.right, 380);
      expect(detail.left, 420);
    });

    testWidgets('a layout scrolled partly out of view keeps its hinge', (
      tester,
    ) async {
      setWindowSize(tester, medium);
      setHinge(tester, hinge);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        host(
          ListView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(width: 700, child: listDetail(selectedId: 1)),
              const SizedBox(width: 800),
            ],
          ),
        ),
      );
      await settle(tester);
      scroll.jumpTo(100);
      await settle(tester);
      // The hinge stays where it is on the screen, which is further into
      // the layout now.
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      final detail = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(list.left, -100 + 24);
      expect(list.right, 380);
      expect(detail.left, 420);
      expect(find.byKey(const ValueKey('page')), findsNothing);
    });

    testWidgets('a compact window keeps to one pane, hinge or not', (
      tester,
    ) async {
      setWindowSize(tester, compact);
      setHinge(tester, const Rect.fromLTWH(190, 0, 20, 800));
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      await settle(tester);
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
    });
  });

  group('Closing the detail beside the list', () {
    Widget closable({
      ListDetailEmptyBehavior<int> emptyBehavior = placeholder,
      int? selectedId,
      ValueChanged<int?>? onSelectionChanged,
    }) => ListDetailLayout<int>(
      selectedId: selectedId,
      onSelectionChanged: onSelectionChanged,
      emptyBehavior: emptyBehavior,
      listBuilder: (context) {
        final layout = ListDetailLayout.of<int>(context);
        return ListView(
          key: const ValueKey('list'),
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
      detailBuilder: (context, id, placement) {
        final layout = ListDetailLayout.of<int>(context);
        return Column(
          children: [
            if (layout.canClose)
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: layout.close,
              ),
            Text('Detail $id'),
          ],
        );
      },
    );

    FocusNode focusOf(WidgetTester tester, Finder finder) =>
        Focus.of(tester.element(finder));

    final close = find.byTooltip('Close');

    testWidgets('closes to the placeholder', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(host(closable()));
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(find.text('Detail 2'), findsOneWidget);
      expect(itemSelected(tester, 2), isTrue);

      await tester.tap(close);
      await tester.pump();
      // The detail pane stays and its content changes at once.
      expect(find.text('Nothing selected'), findsOneWidget);
      expect(find.text('Detail 2'), findsNothing);
      expect(itemSelected(tester, 2), isFalse);
    });

    testWidgets('closes the pane of a layout that hides it', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(
        host(closable(emptyBehavior: const ListDetailEmptyBehavior.hidePane())),
      );
      expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 1252);
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(find.text('Detail 2'), findsOneWidget);

      await tester.tap(close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // The pane leaves with the detail it showed.
      expect(find.text('Detail 2'), findsOneWidget);
      await settle(tester);
      expect(find.text('Detail 2'), findsNothing);
      expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 1252);
    });

    testWidgets('tells a caller that owns the selection', (tester) async {
      final changes = <int?>[];
      setWindowSize(tester, large);
      await tester.pumpWidget(
        host(closable(selectedId: 3, onSelectionChanged: changes.add)),
      );
      await tester.tap(close);
      expect(changes, [null]);
    });

    testWidgets('is not offered on a page, where back leads to the list', (
      tester,
    ) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(closable()));
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(find.text('Detail 2'), findsOneWidget);
      expect(close, findsNothing);
    });

    testWidgets('is not offered where a detail always shows', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(
        host(closable(emptyBehavior: const ListDetailEmptyBehavior.select(0))),
      );
      expect(find.text('Detail 0'), findsOneWidget);
      expect(close, findsNothing);
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(find.text('Detail 2'), findsOneWidget);
      expect(close, findsNothing);
    });

    testWidgets('returns focus to the item that opened the detail', (
      tester,
    ) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(host(closable()));
      final item = focusOf(tester, find.text('Item 2'))..requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Detail 2'), findsOneWidget);
      // Another item has focus last in the list, which Flutter would return
      // focus to by itself.
      focusOf(tester, find.text('Item 4')).requestFocus();
      await tester.pump();

      final button = focusOf(
        tester,
        find.descendant(of: close, matching: find.byIcon(Icons.close)),
      )..requestFocus();
      await tester.pump();
      expect(button.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('Detail 2'), findsNothing);
      expect(item.hasFocus, isTrue);
    });

    testWidgets('moves focus into the list when the item did not have it', (
      tester,
    ) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(host(closable()));
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      focusOf(
        tester,
        find.descendant(of: close, matching: find.byIcon(Icons.close)),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(focusOf(tester, find.text('Item 0')).hasFocus, isTrue);
    });

    testWidgets('leaves focus outside the detail where it is', (tester) async {
      setWindowSize(tester, large);
      final elsewhere = FocusNode();
      addTearDown(elsewhere.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  focusNode: elsewhere,
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            body: closable(),
          ),
        ),
      );
      await tester.tap(find.text('Item 2'));
      await settle(tester);
      elsewhere.requestFocus();
      await tester.pump();
      await tester.tap(close);
      await settle(tester);
      expect(elsewhere.hasFocus, isTrue);
    });
  });

  testWidgets('a detail pane that enters beside a resizable list brings the '
      'spacer and the handle, which takes input once the pane has come', (
    tester,
  ) async {
    Widget layout(int? selectedId) => host(
      ListDetailLayout<int>(
        selectedId: selectedId,
        onSelectionChanged: (_) {},
        emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
        resizable: true,
        listBuilder: (context) => const SizedBox.expand(key: ValueKey('list')),
        detailBuilder: (context, id, placement) =>
            SizedBox.expand(key: ValueKey('detail $id')),
      ),
    );
    setWindowSize(tester, large);
    await tester.pumpWidget(layout(null));
    final alone = tester.getRect(find.byKey(const ValueKey('list')));

    // Whether a pointer at the handle reaches it.
    bool takesInput() {
      final handle = find.byType(PaneResizer);
      return tester
          .hitTestOnBinding(tester.getCenter(handle))
          .path
          .any((entry) => entry.target == tester.renderObject(handle));
    }

    await tester.pumpWidget(layout(1));
    // The list does not jump aside for a handle before the detail comes.
    expect(tester.getRect(find.byKey(const ValueKey('list'))), alone);
    expect(find.byType(PaneDragHandle), findsOneWidget);
    expect(takesInput(), isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester.getRect(find.byKey(const ValueKey('list'))).right,
      lessThan(alone.right),
    );
    expect(takesInput(), isFalse);

    await settle(tester);
    expect(takesInput(), isTrue);
    expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 412);
  });

  group('Room lost to another pane', () {
    Widget inbox({required bool sheet}) => host(
      SupportingPaneLayout(
        focus: listDetail(selectedId: 1, onSelectionChanged: (_) {}),
        supporting: sheet
            ? SideSheet(onClose: () {}, child: const Text('Details'))
            : null,
      ),
    );

    testWidgets('a list shown for a kept selection whose page was closed '
        'stays as the room goes', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(inbox(sheet: false));
      // At one pane, the page of the selection the caller keeps is closed,
      // back to the list.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      setWindowSize(tester, large);
      await tester.pump();
      await settle(tester);
      expect(find.byKey(const ValueKey('detail 1')), findsOneWidget);

      // The sheet takes the room for two panes: one pane shows the list
      // again, which stays where it is rather than leave and come back.
      await tester.pumpWidget(inbox(sheet: true));
      final lefts = <double?>[];
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final list = find.byKey(const ValueKey('list'));
        lefts.add(list.evaluate().isEmpty ? null : tester.getRect(list).left);
      }
      // It never leaves: only the detail's spring, overshooting as the
      // detail goes, moves it a little.
      expect(lefts, everyElement(isNotNull));
      expect(lefts.map((left) => left!), everyElement(greaterThan(12)));
      expect(lefts.last, 24);
      expect(find.byKey(const ValueKey('page')), findsNothing);
    });

    testWidgets('the list slides out as a side sheet opens, then the detail '
        'becomes a page', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(inbox(sheet: false));
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.width, 412);

      await tester.pumpWidget(inbox(sheet: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // Leaving, the list keeps its width and slides out; the detail is
      // still a pane, without the page's app bar.
      final leaving = tester.getRect(find.byKey(const ValueKey('list')));
      expect(leaving.width, 412);
      expect(leaving.left, lessThan(list.left));
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Detail 1 line 0'), findsOneWidget);

      await settle(tester);
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('the list slides back as the side sheet closes, and the page '
        'turns back into the detail pane where it stands', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(inbox(sheet: false));
      await tester.pumpWidget(inbox(sheet: true));
      await settle(tester);
      final page = tester.getRect(find.byKey(const ValueKey('detail 1')));
      expect(find.byKey(const ValueKey('page')), findsOneWidget);

      await tester.pumpWidget(inbox(sheet: false));
      // The layout is arranged for the room it rests at once the sheet has
      // gone, so the page turns back into the detail pane where it stands
      // as the sheet starts to leave, with the list still to come.
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('detail 1'))).left,
        page.left,
      );

      final rights = <double>[];
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        final list = find.byKey(const ValueKey('list'));
        if (list.evaluate().isNotEmpty) rights.add(tester.getRect(list).right);
      }
      // The list enters from the leading edge, growing into its place.
      expect(rights.length, greaterThan(2));
      for (var i = 1; i < rights.length; i++) {
        expect(rights[i], greaterThanOrEqualTo(rights[i - 1]));
      }
      expect(rights.first, lessThan(24 + 412));
      await settle(tester);
      expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 412);
    });

    testWidgets('the detail keeps its state as it becomes a page and a pane '
        'again', (tester) async {
      var created = 0;
      Widget layout({required bool sheet}) => host(
        SupportingPaneLayout(
          focus: ListDetailLayout<int>(
            selectedId: 1,
            onSelectionChanged: (_) {},
            listBuilder: (context) => const SizedBox.expand(),
            detailBuilder: (context, id, placement) =>
                _Created(onCreate: () => created++),
          ),
          supporting: sheet
              ? SideSheet(onClose: () {}, child: const Text('Details'))
              : null,
        ),
      );
      setWindowSize(tester, large);
      await tester.pumpWidget(layout(sheet: false));
      await tester.pumpWidget(layout(sheet: true));
      await settle(tester);
      await tester.pumpWidget(layout(sheet: false));
      await settle(tester);
      // A resize moves it between the pane and the page at once.
      setWindowSize(tester, compact);
      await settle(tester);
      setWindowSize(tester, large);
      await settle(tester);
      expect(created, 1);
    });

    testWidgets('a page that leaves keeps its detail while a pane shows the '
        'item again', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(
        host(listDetail(selectedId: 1, onSelectionChanged: (_) {})),
      );
      await tester.pump();
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 60));
      // The window widens while the page is still on its way out.
      setWindowSize(tester, large);
      await tester.pump();
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Detail 1 line 0'), findsOneWidget);
    });

    testWidgets('a detail beside a collapsed list becomes a page in its '
        'place, and a pane again', (tester) async {
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      Widget layout({required bool sheet}) => host(
        SupportingPaneLayout(
          focus: listDetail(
            selectedId: 1,
            onSelectionChanged: (_) {},
            splitController: split,
          ),
          supporting: sheet
              ? SideSheet(onClose: () {}, child: const Text('Details'))
              : null,
        ),
      );
      setWindowSize(tester, large);
      await tester.pumpWidget(layout(sheet: false));
      final pane = tester.getRect(find.byKey(const ValueKey('detail 1')));

      await tester.pumpWidget(layout(sheet: true));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('detail 1'))).left,
        pane.left,
      );
      await settle(tester);

      await tester.pumpWidget(layout(sheet: false));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Detail 1 line 0'), findsOneWidget);
    });

    // The sheet shows the selected item's details, and closes with the
    // selection, so that going back from the page brings back the room for
    // two panes.
    Widget detailsOfSelection(ValueNotifier<int?> selection) => host(
      ValueListenableBuilder<int?>(
        valueListenable: selection,
        builder: (context, selectedId, _) => SupportingPaneLayout(
          focus: listDetail(
            selectedId: selectedId,
            onSelectionChanged: (id) => selection.value = id,
            emptyBehavior: const ListDetailEmptyBehavior.placeholder(
              child: SizedBox.expand(
                key: ValueKey('placeholder'),
                child: Text('Nothing selected'),
              ),
            ),
          ),
          supporting: selectedId == null
              ? null
              : SideSheet(onClose: () {}, child: const Text('Details')),
        ),
      ),
    );

    testWidgets('back that brings the room back turns the page into the '
        'detail pane where it stands, and the list enters beside it', (
      tester,
    ) async {
      final selection = ValueNotifier<int?>(1);
      addTearDown(selection.dispose);
      setWindowSize(tester, large);
      await tester.pumpWidget(detailsOfSelection(selection));
      await settle(tester);
      final page = tester.getRect(find.byKey(const ValueKey('page')));

      await tester.pageBack();
      await tester.pump();
      await tester.pump();
      // The page is done rather than leaving on its transition, and the
      // detail pane stands where it stood, showing what two panes show with
      // nothing selected.
      expect(find.byKey(const ValueKey('page')), findsNothing);
      final pane = find.byKey(const ValueKey('placeholder'));
      expect(tester.getRect(pane), page);
      expect(tester.takeException(), isNull);

      // The pane then moves to its place beside the list, which enters from
      // the leading edge, as the sheet leaves.
      final lefts = <double>[];
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 32));
        lefts.add(tester.getRect(pane).left);
      }
      expect(lefts.first, greaterThan(page.left));
      expect(lefts.last, greaterThan(lefts.first));
      await settle(tester);
      expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 412);
      expect(tester.getRect(pane).left, 24 + 412 + 24);
      expect(find.text('Details'), findsNothing);
    });

    testWidgets("a page a back gesture takes away leaves in its pane's "
        'place, and the panes rearrange once it has gone', (tester) async {
      final selection = ValueNotifier<int?>(1);
      addTearDown(selection.dispose);
      setWindowSize(tester, large);
      await tester.pumpWidget(detailsOfSelection(selection));
      await settle(tester);
      final page = find.byKey(const ValueKey('page'));
      expect(page, findsOneWidget);

      // The predictive back gesture shows the list at one pane beneath the
      // page as it goes.
      Future<void> gesture(MethodCall call) =>
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            'flutter/backgesture',
            const StandardMethodCodec().encodeMethodCall(call),
            (_) {},
          );
      await gesture(
        const MethodCall('startBackGesture', <String, Object?>{
          'touchOffset': <double>[5, 300],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
      );
      await tester.pump();
      await gesture(
        const MethodCall('updateBackGestureProgress', <String, Object?>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0,
        }),
      );
      await tester.pump();
      expect(find.text('Item 0'), findsOneWidget);
      await gesture(const MethodCall('commitBackGesture'));

      var frames = 0;
      while (page.evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 16));
        // The detail pane beside the list waits for the page to go.
        expect(find.text('Nothing selected'), findsNothing);
        expect(++frames, lessThan(60));
      }
      expect(frames, greaterThan(1));
      await settle(tester);
      expect(find.text('Nothing selected'), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('room lost again the frame after it came back leaves the '
        'detail on a page', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(inbox(sheet: false));
      await tester.pumpWidget(inbox(sheet: true));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);

      // The page turns into the pane, with the list still to come, and the
      // sheet takes the room back before the list has begun to enter.
      await tester.pumpWidget(inbox(sheet: false));
      await tester.pumpWidget(inbox(sheet: true));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('a window resize while the list leaves rearranges at once', (
      tester,
    ) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(inbox(sheet: false));
      await tester.pumpWidget(inbox(sheet: true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byKey(const ValueKey('list')), findsOneWidget);
      setWindowSize(tester, compact);
      await tester.pump();
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
    });

    testWidgets('room back while the list leaves takes the list back with '
        'motion', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(inbox(sheet: false));
      final resting = tester.getRect(find.byKey(const ValueKey('list')));
      await tester.pumpWidget(inbox(sheet: true));
      await tester.pump(const Duration(milliseconds: 100));
      final leaving = tester.getRect(find.byKey(const ValueKey('list')));
      expect(leaving.left, lessThan(resting.left));

      await tester.pumpWidget(inbox(sheet: false));
      await tester.pump(const Duration(milliseconds: 16));
      // The list turns back from where it was, rather than jumping home.
      final returning = tester.getRect(find.byKey(const ValueKey('list')));
      expect(returning.left, lessThan(resting.left - 1));
      await settle(tester);
      expect(tester.getRect(find.byKey(const ValueKey('list'))), resting);
    });

    testWidgets('a closed detail keeps its content while it leaves, as '
        'room is given up meanwhile', (tester) async {
      Widget layout({int? selectedId, required bool sheet}) => host(
        SupportingPaneLayout(
          focus: listDetail(
            selectedId: selectedId,
            onSelectionChanged: (_) {},
            emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
          ),
          supporting: sheet
              ? SideSheet(onClose: () {}, child: const Text('Details'))
              : null,
        ),
      );
      setWindowSize(tester, large);
      await tester.pumpWidget(layout(selectedId: 1, sheet: false));
      await settle(tester);
      await tester.pumpWidget(layout(sheet: false));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Detail 1 line 0'), findsOneWidget);

      await tester.pumpWidget(layout(sheet: true));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Detail 1 line 0'), findsOneWidget);
      await settle(tester);
      expect(find.text('Detail 1 line 0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a window resize still rearranges the panes at once', (
      tester,
    ) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      setWindowSize(tester, compact);
      await tester.pump();
      expect(find.byKey(const ValueKey('list')), findsNothing);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
    });
  });

  testWidgets('a page transition does not rebuild the layout', (tester) async {
    var builds = 0;
    setWindowSize(tester, large);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => Scaffold(
                      body: ListDetailLayout<int>(
                        selectedId: 1,
                        listBuilder: (context) {
                          builds++;
                          return const SizedBox.expand();
                        },
                        detailBuilder: (context, id, placement) =>
                            const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await settle(tester);
    expect(builds, 1);
  });

  group('Behaviour', () {
    testWidgets('selecting at one pane pushes the detail as a page with a '
        'back affordance', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      await tester.tap(find.text('Item 3'));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(find.text('Detail 3 line 0'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Item 0'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('the back affordance shows only at one pane', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 2)));
      expect(find.byType(BackButton), findsNothing);
      final context = tester.element(find.byKey(const ValueKey('detail 2')));
      expect(ModalRoute.of(context)!.canPop, isFalse);
    });

    testWidgets('the selected state shows only at two panes', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 4)));
      expect(itemSelected(tester, 4), isTrue);
      expect(itemSelected(tester, 3), isFalse);

      await resize(tester, compact);
      expect(itemSelected(tester, 4), isFalse);
    });

    testWidgets('with nothing selected, one pane shows the list and two a '
        'placeholder', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Nothing selected'), findsNothing);

      await resize(tester, expanded);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Nothing selected'), findsOneWidget);
      expect(find.byKey(const ValueKey('page')), findsNothing);
    });

    testWidgets('one pane to two with a selection shows both panes and the '
        'detail', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail(selectedId: 3)));
      expect(find.byKey(const ValueKey('page')), findsOneWidget);

      await resize(tester, expanded);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Detail 3 line 0'), findsOneWidget);
      expect(itemSelected(tester, 3), isTrue);
    });

    testWidgets('two panes to one with a selection shows the detail with an '
        'app bar, without a transition', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 3)));

      setWindowSize(tester, compact);
      await tester.pump();
      final page = find.byKey(const ValueKey('page'));
      expect(page, findsOneWidget);
      expect(ModalRoute.of(tester.element(page))!.animation!.value, 1);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('returning to one pane restores the view shown before', (
      tester,
    ) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      await resize(tester, expanded);
      await resize(tester, compact);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);

      await tester.tap(find.text('Item 5'));
      await settle(tester);
      await resize(tester, expanded);
      await resize(tester, compact);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(find.text('Detail 5 line 0'), findsOneWidget);
    });

    testWidgets('each detail keeps its scroll position across selections', (
      tester,
    ) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail()));
      await tester.tap(find.text('Item 1'));
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('detail 1')),
        const Offset(0, -500),
      );
      await settle(tester);
      final offset = scrollOffset(tester, 1);
      expect(offset, greaterThan(0));

      await tester.tap(find.text('Item 2'));
      await tester.pump();
      expect(scrollOffset(tester, 2), 0);
      await tester.tap(find.text('Item 1'));
      await tester.pump();
      expect(scrollOffset(tester, 1), offset);
    });

    testWidgets('a detail built as documented keeps its state and focus '
        'from pane to page', (tester) async {
      setWindowSize(tester, large);
      await tester.pumpWidget(
        host(
          ListDetailLayout<int>(
            selectedId: 1,
            onSelectionChanged: (_) {},
            listBuilder: (context) => const SizedBox.expand(),
            detailBuilder: (context, id, placement) => Scaffold(
              appBar: placement == DetailPlacement.page ? AppBar() : null,
              body: const TextField(key: ValueKey('reply')),
            ),
          ),
        ),
      );
      final field = find.byKey(const ValueKey('reply'));
      await tester.enterText(field, 'draft');
      await tester.pump();
      for (final size in [compact, large]) {
        await resize(tester, size);
        expect(find.text('draft'), findsOneWidget, reason: '$size');
        final focused = FocusManager.instance.primaryFocus?.context;
        expect(
          focused != null &&
              find
                  .descendant(
                    of: field,
                    matching: find.byWidget(focused.widget),
                  )
                  .evaluate()
                  .isNotEmpty,
          isTrue,
          reason: '$size',
        );
      }
    });

    testWidgets('a detail keeps its scroll position from pane to page', (
      tester,
    ) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      await tester.drag(
        find.byKey(const ValueKey('detail 1')),
        const Offset(0, -500),
      );
      await settle(tester);
      final offset = scrollOffset(tester, 1);
      expect(offset, greaterThan(0));

      await resize(tester, compact);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      expect(scrollOffset(tester, 1), offset);

      // And back from the page to the pane.
      await tester.drag(
        find.byKey(const ValueKey('detail 1')),
        const Offset(0, -300),
      );
      await settle(tester);
      final further = scrollOffset(tester, 1);
      expect(further, greaterThan(offset));
      await resize(tester, expanded);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(scrollOffset(tester, 1), further);
    });

    testWidgets('changing the detail at two panes does not animate', (
      tester,
    ) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      final before = tester.getRect(find.byKey(const ValueKey('detail 1')));

      await tester.tap(find.text('Item 2'));
      await tester.pump();
      expect(find.byKey(const ValueKey('detail 1')), findsNothing);
      expect(tester.getRect(find.byKey(const ValueKey('detail 2'))), before);
    });

    testWidgets('the detail builder learns its placement', (tester) async {
      final placements = <DetailPlacement>[];
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(listDetail(selectedId: 1, placements: placements)),
      );
      expect(placements.toSet(), {DetailPlacement.pane});

      placements.clear();
      await resize(tester, compact);
      expect(placements.toSet(), {DetailPlacement.page});
    });

    testWidgets('a deep link at one pane shows the detail at once, with a '
        'working back affordance', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail(selectedId: 7)));
      final page = find.byKey(const ValueKey('page'));
      expect(page, findsOneWidget);
      // The page is in the list pane's place, set in by the margin as the
      // pane is, and not on its way there.
      expect(tester.getRect(page).left, 16);
      expect(ModalRoute.of(tester.element(page))!.animation!.value, 1);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('the system back button returns to the list', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail(selectedId: 2)));
      // The navigator reports that it can pop after its first frame.
      await tester.pump();
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });
  });

  group('Routes over the detail page', () {
    testWidgets('a dialog over the detail page leaves with it when two panes '
        'return', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail()));
      await tester.tap(find.text('Item 1'));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      // Pushed from the page onto the layout's navigator, above the page.
      final result = showDialog<String>(
        context: tester.element(find.byKey(const ValueKey('detail 1'))),
        useRootNavigator: false,
        builder: (context) => const AlertDialog(content: Text('Delete?')),
      );
      await settle(tester);
      expect(find.text('Delete?'), findsOneWidget);

      setWindowSize(tester, expanded);
      await tester.pump();
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Delete?'), findsNothing);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.byKey(const ValueKey('detail 1')), findsOneWidget);
      expect(await result, isNull);
    });
  });

  group('Guarantees', () {
    testWidgets('returning to one pane shows the list where the caller kept '
        'the selection its page was closed with', (tester) async {
      setWindowSize(tester, compact);
      // A caller that keeps the selection when its page is closed.
      await tester.pumpWidget(
        host(listDetail(selectedId: 4, onSelectionChanged: (_) {})),
      );
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsNothing);

      await resize(tester, expanded);
      expect(find.text('Detail 4 line 0'), findsOneWidget);
      await resize(tester, compact);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('close does nothing where the detail cannot be closed', (
      tester,
    ) async {
      final changes = <int?>[];
      setWindowSize(tester, compact);
      await tester.pumpWidget(
        host(listDetail(selectedId: 2, onSelectionChanged: changes.add)),
      );
      // On a page, back leads to the list.
      final page = ListDetailLayout.of<int>(
        tester.element(find.byKey(const ValueKey('detail 2'))),
      );
      expect(page.canClose, isFalse);
      page.close();
      await settle(tester);
      expect(changes, isEmpty);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);

      // Beside the list, an item always shows.
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(
          listDetail(
            selectedId: 2,
            onSelectionChanged: changes.add,
            emptyBehavior: const ListDetailEmptyBehavior.select(0),
          ),
        ),
      );
      await settle(tester);
      final pane = ListDetailLayout.of<int>(
        tester.element(find.byKey(const ValueKey('detail 2'))),
      );
      expect(pane.canClose, isFalse);
      pane.close();
      await settle(tester);
      expect(changes, isEmpty);
      expect(find.text('Detail 2 line 0'), findsOneWidget);
    });

    testWidgets('an item shown in place of a selection is marked, not '
        'selected', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(
          listDetail(emptyBehavior: const ListDetailEmptyBehavior.select(0)),
        ),
      );
      final scope = ListDetailLayout.of<int>(
        tester.element(find.byKey(const ValueKey('list'))),
      );
      expect(scope.selectedId, isNull);
      expect(scope.isSelected(0), isTrue);
      expect(scope.isSelected(1), isFalse);
      expect(itemSelected(tester, 0), isTrue);
    });

    testWidgets('a selection the layout owns starts at selectedId, and is '
        'then its own', (tester) async {
      setWindowSize(tester, expanded);
      Widget owned(int id) => host(
        ListDetailLayout<int>(
          selectedId: id,
          listBuilder: (context) => const SizedBox.expand(),
          detailBuilder: (context, id, placement) => Text('Detail $id'),
        ),
      );
      await tester.pumpWidget(owned(1));
      expect(find.text('Detail 1'), findsOneWidget);
      await tester.pumpWidget(owned(2));
      await settle(tester);
      expect(find.text('Detail 1'), findsOneWidget);
      expect(find.text('Detail 2'), findsNothing);
    });

    testWidgets('widening takes the page away at once', (tester) async {
      setWindowSize(tester, compact);
      await tester.pumpWidget(host(listDetail(selectedId: 1)));
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      setWindowSize(tester, expanded);
      await tester.pump();
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.byKey(const ValueKey('list')), findsOneWidget);
      expect(find.byKey(const ValueKey('detail 1')), findsOneWidget);
    });

    testWidgets("never navigates the caller's navigator", (tester) async {
      final observer = _RecordingObserver();
      setWindowSize(tester, compact);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(body: listDetail()),
        ),
      );
      observer.events.clear();
      await tester.tap(find.text('Item 3'));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsOneWidget);
      await resize(tester, expanded);
      await resize(tester, compact);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(observer.events, isEmpty);
    });

    testWidgets('refuses what cannot be shown', (tester) async {
      // Values the compiler cannot fold, so that the asserts run now.
      final compactBreakpoint = Breakpoint.values.first;
      final dismiss = PaneCollapse.values.last;
      Widget list(BuildContext context) => const SizedBox();
      expect(
        () => ListDetailLayout<int>(
          twoPaneBreakpoint: compactBreakpoint,
          listBuilder: list,
          detailBuilder: (context, id, placement) => const SizedBox(),
        ),
        throwsAssertionError,
      );
      expect(
        () => ListDetailLayout<int>(
          listCollapse: dismiss,
          listBuilder: list,
          detailBuilder: (context, id, placement) => const SizedBox(),
        ),
        throwsAssertionError,
      );
      expect(
        () => ListDetailLayout<int>.custom(
          listCollapse: dismiss,
          listBuilder: list,
          detail: const SizedBox(),
        ),
        throwsAssertionError,
      );

      // A layout given its detail cannot build one to show in place of a
      // selection, nor dismiss a detail that shows a placeholder.
      setWindowSize(tester, expanded);
      for (final (emptyBehavior, detailCollapse) in [
        (const ListDetailEmptyBehavior<int>.select(0), null),
        (const ListDetailEmptyBehavior<int>.placeholder(), dismiss),
      ]) {
        await tester.pumpWidget(
          host(
            ListDetailLayout<int>.custom(
              selectedId: 1,
              emptyBehavior: emptyBehavior,
              detailCollapse: detailCollapse,
              listBuilder: list,
              detail: const SizedBox(),
            ),
          ),
        );
        expect(tester.takeException(), isAssertionError);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('Selection owned by the caller', () {
    testWidgets('a resize never changes the selection', (tester) async {
      final changes = <int?>[];
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(listDetail(selectedId: 3, onSelectionChanged: changes.add)),
      );
      await resize(tester, compact);
      await resize(tester, large);
      await resize(tester, medium);
      expect(changes, isEmpty);
    });

    testWidgets('selecting and navigating back are reported', (tester) async {
      int? selected;
      setWindowSize(tester, compact);
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
      await tester.tap(find.text('Item 4'));
      await settle(tester);
      expect(selected, 4);
      expect(find.text('Detail 4 line 0'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(selected, isNull);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('a selection kept after going back opens again when chosen', (
      tester,
    ) async {
      int? selected;
      setWindowSize(tester, compact);
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            listDetail(
              selectedId: selected,
              // Selection without deep navigation: going back keeps it.
              onSelectionChanged: (id) {
                if (id != null) setState(() => selected = id);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Item 4'));
      await settle(tester);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(selected, 4);
      expect(find.text('Detail 4 line 0'), findsNothing);

      await tester.tap(find.text('Item 4'));
      await settle(tester);
      expect(find.text('Detail 4 line 0'), findsOneWidget);
    });
  });

  group('Empty behaviours', () {
    testWidgets('hidePane lets the detail leave with its content', (
      tester,
    ) async {
      setWindowSize(tester, large);
      Widget selecting(int? id) => host(
        listDetail(
          selectedId: id,
          onSelectionChanged: (_) {},
          emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
        ),
      );
      await tester.pumpWidget(selecting(1));
      await tester.pumpWidget(selecting(null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Detail 1 line 0'), findsOneWidget);
      await settle(tester);
      expect(find.text('Detail 1 line 0'), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('list'))).width,
        1300 - 48,
      );
    });

    testWidgets('hidePane does not build the detail of an item that has '
        'gone', (tester) async {
      final items = {1: 'One', 2: 'Two'};
      Widget selecting(int? id) => host(
        ListDetailLayout<int>(
          selectedId: id,
          onSelectionChanged: (_) {},
          emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
          listBuilder: (context) => const SizedBox.expand(),
          detailBuilder: (context, id, placement) => Text(items[id]!),
        ),
      );
      setWindowSize(tester, large);
      await tester.pumpWidget(selecting(1));
      items.remove(1);
      await tester.pumpWidget(selecting(null));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('One'), findsNothing);
    });

    testWidgets('hidePane does not rebuild the detail of an item that has '
        'gone while it leaves', (tester) async {
      final store = ValueNotifier<Map<int, String>>({1: 'One', 2: 'Two'});
      addTearDown(store.dispose);
      Widget selecting(int? id) => host(
        ValueListenableBuilder<Map<int, String>>(
          valueListenable: store,
          builder: (context, items, _) => _Store(
            items: items,
            child: ListDetailLayout<int>(
              selectedId: id,
              onSelectionChanged: (_) {},
              emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
              listBuilder: (context) => const SizedBox.expand(),
              detailBuilder: (context, id, placement) =>
                  Text(_Store.of(context)[id]!),
            ),
          ),
        ),
      );
      setWindowSize(tester, large);
      await tester.pumpWidget(selecting(1));
      await tester.pumpWidget(selecting(null));
      await tester.pump(const Duration(milliseconds: 20));
      store.value = {2: 'Two'};
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('One'), findsNothing);
    });

    testWidgets('hidePane gives the list the whole layout', (tester) async {
      setWindowSize(tester, expanded);
      const hidePane = ListDetailEmptyBehavior<int>.hidePane();
      await tester.pumpWidget(host(listDetail(emptyBehavior: hidePane)));
      final list = tester.getRect(find.byKey(const ValueKey('list')));
      expect(list.left, 24);
      expect(list.right, 1000 - 24);

      await tester.tap(find.text('Item 2'));
      await settle(tester);
      expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 360);
      expect(find.text('Detail 2 line 0'), findsOneWidget);
    });

    testWidgets('select shows an item without selecting it', (tester) async {
      final changes = <int?>[];
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(
          listDetail(
            onSelectionChanged: changes.add,
            emptyBehavior: const ListDetailEmptyBehavior.select(0),
          ),
        ),
      );
      expect(find.text('Detail 0 line 0'), findsOneWidget);
      expect(itemSelected(tester, 0), isTrue);
      expect(changes, isEmpty);

      await resize(tester, compact);
      expect(find.byKey(const ValueKey('page')), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
    });
  });

  group('Custom detail', () {
    Widget custom({required int? selectedId}) => ListDetailLayout<int>.custom(
      selectedId: selectedId,
      listBuilder: (context) => const Text('The list'),
      detail: const _Counter(),
    );

    testWidgets('places the detail beside the list, or in its place at one '
        'pane, without a navigator', (tester) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(custom(selectedId: 1)));
      expect(find.text('The list'), findsOneWidget);
      expect(find.text('Count 0'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListDetailLayout<int>),
          matching: find.byType(Navigator),
        ),
        findsNothing,
      );

      await resize(tester, compact);
      expect(find.text('The list'), findsNothing);
      expect(find.text('Count 0'), findsOneWidget);

      await tester.pumpWidget(host(custom(selectedId: null)));
      await settle(tester);
      expect(find.text('The list'), findsOneWidget);
    });

    testWidgets('keeps the detail mounted as the layout changes', (
      tester,
    ) async {
      setWindowSize(tester, expanded);
      await tester.pumpWidget(host(custom(selectedId: 1)));
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      expect(find.text('Count 1'), findsOneWidget);

      await resize(tester, compact);
      expect(find.text('Count 1'), findsOneWidget);
      await resize(tester, large);
      expect(find.text('Count 1'), findsOneWidget);
    });

    testWidgets('states the detail placement in the scope', (tester) async {
      DetailPlacement? placement;
      setWindowSize(tester, expanded);
      await tester.pumpWidget(
        host(
          ListDetailLayout<int>.custom(
            selectedId: 1,
            listBuilder: (context) => const SizedBox(),
            detail: Builder(
              builder: (context) {
                placement = ListDetailLayout.of<int>(context).placement;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(placement, DetailPlacement.pane);
      await resize(tester, compact);
      expect(placement, DetailPlacement.page);
    });
  });
}

class _Counter extends StatefulWidget {
  const new();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _count++),
    child: Text('Count $_count'),
  );
}

class _Store extends InheritedWidget {
  const new({required this.items, required super.child});

  final Map<int, String> items;

  static Map<int, String> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Store>()!.items;

  @override
  bool updateShouldNotify(_Store oldWidget) => items != oldWidget.items;
}

// Reports each state it creates.
class _Created extends StatefulWidget {
  const new({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_Created> createState() => _CreatedState();
}

class _CreatedState extends State<_Created> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _RecordingObserver extends NavigatorObserver {
  final events = <String>[];

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('push');

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('pop');

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('remove');

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) =>
      events.add('replace');
}
