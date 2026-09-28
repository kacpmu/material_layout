// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_layout/src/panes/pane_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const listKey = ValueKey('list');
const detailKey = ValueKey('detail');
const focusKey = ValueKey('focus');
const supportingKey = ValueKey('supporting');

Widget listDetail({
  MarginPlacement? placement,
  int? selectedId,
  ValueChanged<int?>? onSelectionChanged,
  ListDetailEmptyBehavior<int> emptyBehavior =
      const ListDetailEmptyBehavior.placeholder(),
  bool resizable = false,
  PaneSplitController? splitController,
  PaneCollapse? detailCollapse,
  WidgetBuilder? listBuilder,
  TextDirection textDirection = TextDirection.ltr,
}) => app(
  Scaffold(
    body: ListDetailLayout<int>(
      marginPlacement: placement,
      selectedId: selectedId,
      onSelectionChanged: onSelectionChanged,
      emptyBehavior: emptyBehavior,
      resizable: resizable,
      splitController: splitController,
      detailCollapse: detailCollapse,
      listBuilder:
          listBuilder ?? (context) => const SizedBox.expand(key: listKey),
      detailBuilder: (context, id, placement) => switch (placement) {
        DetailPlacement.pane => const SizedBox.expand(key: detailKey),
        DetailPlacement.page => Scaffold(
          appBar: AppBar(title: Text('Item $id')),
          body: const SizedBox.expand(key: detailKey),
        ),
      },
    ),
  ),
  textDirection: textDirection,
);

EdgeInsetsDirectional marginsIn(WidgetTester tester, Finder finder) =>
    AdaptiveRegion.marginsOf(tester.element(finder));

EdgeInsets paddingIn(WidgetTester tester, Finder finder) =>
    MediaQuery.paddingOf(tester.element(finder));

EdgeInsetsDirectional margins({double start = 0, double end = 0}) =>
    EdgeInsetsDirectional.only(start: start, end: end);

/// Gives the test window safe-area insets, in logical pixels.
void setWindowPadding(
  WidgetTester tester, {
  double left = 0,
  double top = 0,
  double right = 0,
  double bottom = 0,
}) {
  final padding = FakeViewPadding(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
  tester.view
    ..padding = padding
    ..viewPadding = padding;
}

/// Drags the drag handle by [steps] moves of [dx], after one that clears the
/// touch slop, and returns how far the handle's centre was from the pointer
/// after each move.
Future<List<double>> dragGaps(WidgetTester tester, double dx, int steps) async {
  final handle = find.byType(PaneDragHandle);
  var pointer = tester.getCenter(handle);
  final gesture = await tester.startGesture(pointer);
  final gaps = <double>[];
  Future<void> move(double by) async {
    await gesture.moveBy(Offset(by, 0));
    pointer += Offset(by, 0);
    await tester.pump();
    gaps.add(tester.getCenter(handle).dx - pointer.dx);
  }

  await move(dx.sign * 20);
  for (var i = 0; i < steps; i++) {
    await move(dx);
  }
  await gesture.up();
  await settle(tester);
  return gaps;
}

void expectSteady(List<double> gaps, String reason) {
  for (final gap in gaps) {
    expect(gap, moreOrLessEquals(gaps.first, epsilon: 0.5), reason: reason);
  }
}

void main() {
  group('Margins around the panes', () {
    testWidgets('set the panes in, and their content keeps no margins', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(listDetail(selectedId: 1));

      final list = tester.getRect(find.byKey(listKey));
      final detail = tester.getRect(find.byKey(detailKey));
      expect(list.left, 24);
      expect(list.width, 360);
      expect(detail.left, 24 + 360 + 24);
      expect(detail.right, 1000 - 24);
      expect(marginsIn(tester, find.byKey(listKey)), margins());
      expect(marginsIn(tester, find.byKey(detailKey)), margins());
    });

    testWidgets('set the detail page in as the pane it replaces', (
      tester,
    ) async {
      setWindowSize(tester, const Size(400, 800));
      setWindowPadding(tester, left: 20);
      await tester.pumpWidget(listDetail(selectedId: 1));

      final page = tester.getRect(find.byType(AppBar));
      expect(page.left, 16 + 20);
      expect(page.right, 400 - 16);
      // The margins keep the page clear of the inset, so its app bar does
      // not keep clear of it again.
      expect(paddingIn(tester, find.byKey(detailKey)).left, 0);
      expect(marginsIn(tester, find.byKey(detailKey)), margins());
    });

    testWidgets('keep the panes clear of the safe-area insets', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, left: 40);
      await tester.pumpWidget(listDetail(selectedId: 1));

      expect(tester.getRect(find.byKey(listKey)).left, 24 + 40);
      expect(paddingIn(tester, find.byKey(listKey)).left, 0);
      expect(paddingIn(tester, find.byKey(detailKey)).left, 0);
    });
  });

  group('Margins within the panes', () {
    testWidgets('let the panes reach the edges, with their content where it '
        'sits with the margins outside', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        listDetail(placement: MarginPlacement.inside, selectedId: 1),
      );

      final list = tester.getRect(find.byKey(listKey));
      final detail = tester.getRect(find.byKey(detailKey));
      expect(list.left, 0);
      expect(list.width, 24 + 360);
      expect(detail.left, 24 + 360 + 24);
      expect(detail.right, 1000);
      expect(marginsIn(tester, find.byKey(listKey)), margins(start: 24));
      expect(marginsIn(tester, find.byKey(detailKey)), margins(end: 24));
    });

    testWidgets('follow a pane as the other leaves, without a jump', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      Widget build(int? selectedId) => listDetail(
        placement: MarginPlacement.inside,
        selectedId: selectedId,
        onSelectionChanged: (_) {},
        emptyBehavior: const ListDetailEmptyBehavior.hidePane(),
      );
      await tester.pumpWidget(build(1));
      expect(marginsIn(tester, find.byKey(listKey)), margins(start: 24));

      await tester.pumpWidget(build(null));
      // The list takes on as much of the trailing margin as its edge reaches
      // into, frame by frame.
      final ends = <double>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final edge = tester.getRect(find.byKey(listKey)).right;
        final end = marginsIn(tester, find.byKey(listKey)).end;
        expect(end, moreOrLessEquals(clampDouble(edge - (1000 - 24), 0, 24)));
        ends.add(end);
      }
      expect(ends.any((end) => end > 0 && end < 24), isTrue);
      await settle(tester);
      expect(
        tester.getRect(find.byKey(listKey)),
        const Rect.fromLTWH(0, 0, 1000, 800),
      );
      expect(
        marginsIn(tester, find.byKey(listKey)),
        margins(start: 24, end: 24),
      );
    });

    testWidgets('let the detail page reach the edges, keeping the margins', (
      tester,
    ) async {
      setWindowSize(tester, const Size(400, 800));
      setWindowPadding(tester, left: 20);
      await tester.pumpWidget(
        listDetail(placement: MarginPlacement.inside, selectedId: 1),
      );

      final page = tester.getRect(find.byType(AppBar));
      expect(page.left, 0);
      expect(page.right, 400);
      // The app bar keeps clear of the inset itself, at its own padding.
      expect(paddingIn(tester, find.byKey(detailKey)).left, 20);
      expect(
        tester.getCenter(find.byType(BackButton)).dx,
        20 + kToolbarHeight / 2,
      );
      expect(
        marginsIn(tester, find.byKey(detailKey)),
        margins(start: 16 + 20, end: 16),
      );
    });

    testWidgets('keep the detail page, and its state, when the placement '
        'changes', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      var created = 0;
      Widget build(MarginPlacement placement) => app(
        Scaffold(
          body: ListDetailLayout<int>(
            marginPlacement: placement,
            selectedId: 1,
            listBuilder: (context) => const SizedBox.expand(key: listKey),
            detailBuilder: (context, id, placement) =>
                _Counted(key: detailKey, onCreate: () => created++),
          ),
        ),
      );
      await tester.pumpWidget(build(MarginPlacement.inside));
      await settle(tester);
      expect(tester.getRect(find.byKey(detailKey)).left, 0);

      await tester.pumpWidget(build(MarginPlacement.outside));
      await settle(tester);
      expect(tester.getRect(find.byKey(detailKey)).left, 16);
      expect(created, 1);
    });

    testWidgets('give the safe-area insets to the panes that reach them', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, left: 40);
      await tester.pumpWidget(
        listDetail(placement: MarginPlacement.inside, selectedId: 1),
      );

      final list = tester.getRect(find.byKey(listKey));
      expect(list.left, 0);
      expect(list.width, 40 + 24 + 360);
      expect(paddingIn(tester, find.byKey(listKey)).left, 40);
      expect(marginsIn(tester, find.byKey(listKey)), margins(start: 40 + 24));
      expect(paddingIn(tester, find.byKey(detailKey)).left, 0);
    });

    testWidgets('are directional', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, right: 40);
      await tester.pumpWidget(
        listDetail(
          placement: MarginPlacement.inside,
          selectedId: 1,
          textDirection: TextDirection.rtl,
        ),
      );

      final list = tester.getRect(find.byKey(listKey));
      expect(list.right, 1000);
      expect(list.width, 40 + 24 + 360);
      expect(paddingIn(tester, find.byKey(listKey)).right, 40);
      expect(marginsIn(tester, find.byKey(listKey)), margins(start: 40 + 24));
      expect(tester.getRect(find.byKey(detailKey)).left, 0);
      expect(marginsIn(tester, find.byKey(detailKey)), margins(end: 24));
    });

    testWidgets('keep split widths as the widths of the panes\' content', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: const PaneSplit.width(380));
      addTearDown(split.dispose);
      final semantics = tester.ensureSemantics();
      String share() => find.semantics
          .byLabel('Resize panes')
          .evaluate()
          .single
          .getSemanticsData()
          .value;

      await tester.pumpWidget(
        listDetail(selectedId: 1, resizable: true, splitController: split),
      );
      expect(tester.getRect(find.byKey(listKey)).width, 380);
      final outside = share();

      await tester.pumpWidget(
        listDetail(
          placement: MarginPlacement.inside,
          selectedId: 1,
          resizable: true,
          splitController: split,
        ),
      );
      await settle(tester);
      expect(tester.getRect(find.byKey(listKey)).width, 24 + 380);
      expect(share(), outside);

      // A drag settles on the stop nearest the content's width.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneDragHandle)),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));
      expect(tester.getRect(find.byKey(listKey)).width, 24 + 360);
      semantics.dispose();
    });

    testWidgets('leave the handle and the other pane where they sit with the '
        'margins outside when a pane collapses', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController(split: PaneSplit.collapsed);
      addTearDown(split.dispose);
      Future<(Offset, double)> collapsed(MarginPlacement placement) async {
        await tester.pumpWidget(
          listDetail(
            placement: placement,
            selectedId: 1,
            resizable: true,
            splitController: split,
          ),
        );
        await settle(tester);
        final detail = find.byKey(detailKey);
        return (
          tester.getCenter(find.byType(PaneDragHandle)),
          tester.getRect(detail).left + marginsIn(tester, detail).start,
        );
      }

      final (outsideHandle, outsideContent) = await collapsed(
        MarginPlacement.outside,
      );
      final (insideHandle, insideContent) = await collapsed(
        MarginPlacement.inside,
      );
      expect(insideHandle, outsideHandle);
      expect(insideContent, outsideContent);
    });

    testWidgets('stack panes across the whole width, each keeping the insets '
        'at its own edges', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      setWindowPadding(tester, top: 24, bottom: 16);
      await tester.pumpWidget(
        app(
          const SupportingPaneLayout(
            marginPlacement: MarginPlacement.inside,
            focus: SizedBox.expand(key: focusKey),
            supporting: SizedBox.expand(key: supportingKey),
          ),
        ),
      );

      final focus = find.byKey(focusKey);
      final supporting = find.byKey(supportingKey);
      expect(tester.getRect(focus).left, 0);
      expect(tester.getRect(focus).right, 400);
      expect(tester.getRect(supporting).left, 0);
      expect(marginsIn(tester, focus), margins(start: 16, end: 16));
      expect(marginsIn(tester, supporting), margins(start: 16, end: 16));
      expect(paddingIn(tester, focus), const EdgeInsets.only(top: 24));
      expect(paddingIn(tester, supporting), const EdgeInsets.only(bottom: 16));
    });
  });

  group('Resizing', () {
    testWidgets('keeps the handle under the pointer as a drag hides or shows '
        'a pane, wherever the margins are', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      for (final placement in MarginPlacement.values) {
        Future<void> drag(PaneSplit from, double dx, int steps) async {
          split.value = from;
          await tester.pumpWidget(
            listDetail(
              placement: placement,
              selectedId: 1,
              resizable: true,
              splitController: split,
              detailCollapse: PaneCollapse.collapse,
            ),
          );
          await settle(tester);
          expectSteady(await dragGaps(tester, dx, steps), '$placement $from');
        }

        // Collapsing the list, hiding the detail, and showing the list again.
        await drag(PaneSplit.automatic, -30, 11);
        await drag(PaneSplit.automatic, 30, 25);
        await drag(PaneSplit.collapsed, 30, 11);
      }
    });

    testWidgets('keeps the handle under the pointer as a drag hides a side '
        'sheet at an inset', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      setWindowPadding(tester, right: 30);
      for (final placement in MarginPlacement.values) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SupportingPaneLayout(
                key: ValueKey(placement),
                marginPlacement: placement,
                resizable: true,
                onSupportingDismissed: () {},
                focus: const SizedBox.expand(key: focusKey),
                supporting: const SideSheet(child: SizedBox(height: 10)),
              ),
            ),
          ),
        );
        await settle(tester);
        expectSteady(await dragGaps(tester, 30, 11), '$placement');
      }
    });

    testWidgets('keeps the handle in place when the placement changes during '
        'a drag', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      Widget build(MarginPlacement placement) => listDetail(
        placement: placement,
        selectedId: 1,
        resizable: true,
        splitController: split,
      );
      await tester.pumpWidget(build(MarginPlacement.outside));
      final handle = find.byType(PaneDragHandle);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      final before = tester.getCenter(handle).dx;

      await tester.pumpWidget(build(MarginPlacement.inside));
      expect(tester.getCenter(handle).dx, moreOrLessEquals(before));
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump();
      expect(tester.getCenter(handle).dx, moreOrLessEquals(before - 10));
      await gesture.up();
      await settle(tester);
      expect(split.value, const PaneSplit.width(360));
    });
  });

  group('A side sheet as a pane', () {
    Widget sheetLayout(
      MarginPlacement placement, {
      TextDirection textDirection = TextDirection.ltr,
    }) => app(
      Scaffold(
        body: SupportingPaneLayout(
          marginPlacement: placement,
          focus: const SizedBox.expand(key: focusKey),
          supporting: SideSheet(
            onClose: () {},
            child: const SizedBox(key: supportingKey, height: 10),
          ),
        ),
      ),
      textDirection: textDirection,
    );

    testWidgets('within the panes, reaches the trailing edge at its own '
        'width, keeping its content clear of the inset', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, right: 30);
      await tester.pumpWidget(sheetLayout(MarginPlacement.inside));

      final sheet = tester.getRect(find.byType(SideSheet));
      expect(sheet.right, 1000);
      expect(sheet.width, 360 + 30);
      expect(tester.getRect(find.byKey(supportingKey)).right, 1000 - 30 - 24);
      expect(marginsIn(tester, find.byKey(supportingKey)), margins());
      final focus = find.byKey(focusKey);
      expect(tester.getRect(focus).left, 0);
      expect(tester.getRect(focus).right, sheet.left - 24);
      expect(marginsIn(tester, focus), margins(start: 24));
    });

    testWidgets('within the panes of a right-to-left layout, reaches the '
        'left edge, keeping its content clear of the inset there', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, left: 30);
      await tester.pumpWidget(
        sheetLayout(MarginPlacement.inside, textDirection: TextDirection.rtl),
      );

      final sheet = tester.getRect(find.byType(SideSheet));
      expect(sheet.left, 0);
      expect(sheet.width, 360 + 30);
      expect(tester.getRect(find.byKey(supportingKey)).left, 30 + 24);
      final focus = find.byKey(focusKey);
      expect(tester.getRect(focus).right, 1000);
      expect(tester.getRect(focus).left, sheet.right + 24);
    });

    testWidgets('within the panes, leaves the focus pane at least half the '
        'room for content', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      setWindowPadding(tester, right: 30);
      await tester.pumpWidget(sheetLayout(MarginPlacement.inside));

      final focus = find.byKey(focusKey);
      final focusContent =
          tester.getRect(focus).width - marginsIn(tester, focus).start;
      final sheetContent = tester.getRect(find.byType(SideSheet)).width - 30;
      expect(focusContent, moreOrLessEquals(sheetContent));
      expect(focusContent + sheetContent, 700 - 24 - 24 - 30);
    });

    testWidgets('around the panes, is set in by the margin', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      setWindowPadding(tester, right: 30);
      await tester.pumpWidget(sheetLayout(MarginPlacement.outside));

      final sheet = tester.getRect(find.byType(SideSheet));
      expect(sheet.right, 1000 - 24 - 30);
      expect(sheet.width, 360);
      expect(tester.getRect(find.byKey(supportingKey)).right, sheet.right - 24);
    });
  });

  group('The theme', () {
    Widget themed(Widget child) => MaterialLayoutTheme(
      data: const MaterialLayoutThemeData(
        marginPlacement: MarginPlacement.inside,
      ),
      child: child,
    );

    testWidgets('says where layouts keep their margins', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(themed(listDetail(selectedId: 1)));

      final list = find.byKey(listKey);
      expect(tester.getRect(list).left, 0);
      expect(marginsIn(tester, list), margins(start: 24));
    });

    testWidgets("gives way to a layout's own placement", (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        themed(listDetail(placement: MarginPlacement.outside, selectedId: 1)),
      );

      expect(tester.getRect(find.byKey(listKey)).left, 24);
    });

    testWidgets('gives way to the placement of the layout around a nested '
        'one', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        themed(
          app(
            Scaffold(
              body: SupportingPaneLayout(
                marginPlacement: MarginPlacement.outside,
                focus: ListDetailLayout<int>(
                  listBuilder: (context) => const SizedBox.expand(key: listKey),
                  detailBuilder: (context, id, placement) =>
                      const SizedBox.expand(),
                ),
                supporting: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final list = find.byKey(listKey);
      expect(tester.getRect(list).left, 24);
      expect(marginsIn(tester, list), margins());
    });

    test('switches placement halfway through an animation', () {
      const around = MaterialLayoutThemeData();
      final within = around.copyWith(marginPlacement: MarginPlacement.inside);
      expect(around.marginPlacement, MarginPlacement.outside);
      expect(within, isNot(around));
      expect(around.lerp(within, 0.4).marginPlacement, MarginPlacement.outside);
      expect(around.lerp(within, 0.6).marginPlacement, MarginPlacement.inside);
    });
  });

  group('Corners', () {
    Widget rounded(Widget child) => MaterialLayoutTheme(
      data: MaterialLayoutThemeData(
        paneBorderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );

    RenderPaneLayout panes(WidgetTester tester) =>
        tester.renderObject<RenderPaneLayout>(find.byType(PaneLayout));

    testWidgets('a pane keeps the corners the theme gives it while it '
        'enters', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      Widget layout({required bool open}) => rounded(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: const SizedBox.expand(key: focusKey),
              supporting: open
                  ? const SizedBox.expand(key: supportingKey)
                  : null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(layout(open: false));
      expect(panes(tester), isNot(paints..clipRRect()));

      await tester.pumpWidget(layout(open: true));
      // The clip is the space the pane occupies, rounded where it cuts into
      // the content still sliding in beyond it; the content's own corners
      // show on the other edge.
      RRect cut() {
        final span = panes(tester).geometry!.second;
        final occupied = Rect.fromLTRB(span.start, 0, span.end, 800);
        expect(occupied.right, 1300 - 24);
        expect(
          tester.getRect(find.byKey(supportingKey)).right,
          greaterThan(occupied.right),
        );
        final corner = Radius.elliptical(math.min(16, occupied.width), 16);
        return RRect.fromRectAndCorners(
          occupied,
          topRight: corner,
          bottomRight: corner,
        );
      }

      // A sliver narrower than the corners keeps their full height.
      await tester.pump(const Duration(milliseconds: 8));
      expect(panes(tester).geometry!.second.extent, inExclusiveRange(0, 16));
      expect(panes(tester), paints..clipRRect(rrect: cut()));
      await tester.pump(const Duration(milliseconds: 60));
      expect(panes(tester), paints..clipRRect(rrect: cut()));

      await settle(tester);
      expect(panes(tester), isNot(paints..clipRRect()));
    });

    testWidgets('a side sheet has the corners of the panes, and keeps them '
        'while it enters', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      Widget layout({required bool open}) => rounded(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: const SizedBox.expand(key: focusKey),
              supporting: open
                  ? SideSheet(onClose: () {}, child: const SizedBox())
                  : null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(layout(open: false));
      await tester.pumpWidget(layout(open: true));
      await tester.pump(const Duration(milliseconds: 60));
      // Clipped to the space it occupies, rounded where it cuts into the
      // sheet still sliding in beyond it.
      final span = panes(tester).geometry!.second;
      final occupied = Rect.fromLTRB(span.start, 0, span.end, 800);
      expect(occupied.width, inExclusiveRange(0, 400));
      final corner = Radius.elliptical(math.min(16, occupied.width), 16);
      expect(
        panes(tester),
        paints..clipRRect(
          rrect: RRect.fromRectAndCorners(
            occupied,
            topRight: corner,
            bottomRight: corner,
          ),
        ),
      );
      await settle(tester);
      final sheet = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SideSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        (sheet.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
    });

    testWidgets("at one pane, the pages take the pane's place, with its "
        'corners', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      final pages = find.descendant(
        of: find.byType(ListDetailLayout<int>),
        matching: find.byType(Navigator),
      );
      await tester.pumpWidget(rounded(listDetail(selectedId: 1)));
      final place = tester.getRect(pages);
      expect(place.left, 24);
      expect(place.right, 700 - 24);
      final clip = tester.widget<ClipRRect>(
        find.ancestor(of: pages, matching: find.byType(ClipRRect)).first,
      );
      expect(clip.borderRadius, BorderRadius.circular(16));
      expect(clip.clipBehavior, Clip.antiAlias);
      expect(marginsIn(tester, find.byKey(detailKey)), margins());

      // Reaching the edges, the pages take the whole region.
      await tester.pumpWidget(
        rounded(listDetail(placement: MarginPlacement.inside, selectedId: 1)),
      );
      expect(tester.getRect(pages).left, 0);
      expect(
        marginsIn(tester, find.byKey(detailKey)),
        margins(start: 24, end: 24),
      );
    });
  });

  group('Nested layouts', () {
    Widget nested({MarginPlacement? inner}) => app(
      Scaffold(
        body: SupportingPaneLayout(
          marginPlacement: MarginPlacement.inside,
          focus: ListDetailLayout<int>(
            marginPlacement: inner,
            listBuilder: (context) => const SizedBox.expand(key: listKey),
            detailBuilder: (context, id, placement) =>
                const SizedBox.expand(key: detailKey),
          ),
          supporting: const SizedBox.expand(key: supportingKey),
        ),
      ),
    );

    testWidgets('keep their margins where the layout around them does, with '
        'the margins its pane keeps', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(nested());

      final list = find.byKey(listKey);
      expect(tester.getRect(list).left, 0);
      expect(marginsIn(tester, list), margins(start: 24));
    });

    testWidgets('may keep them elsewhere', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(nested(inner: MarginPlacement.outside));

      final list = find.byKey(listKey);
      expect(tester.getRect(list).left, 24);
      expect(marginsIn(tester, list), margins());
    });

    Widget around(Widget focus, {Widget? supporting}) => app(
      Scaffold(
        body: SupportingPaneLayout(focus: focus, supporting: supporting),
      ),
    );

    Widget inner({int? selectedId = 1}) => ListDetailLayout<int>(
      selectedId: selectedId,
      listBuilder: (context) => const SizedBox.expand(key: listKey),
      detailBuilder: (context, id, placement) =>
          const SizedBox.expand(key: detailKey),
    );

    testWidgets('given as a pane, keep the margins that pane meets, where '
        'the layout around them sets its panes in', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        around(
          inner(selectedId: null),
          supporting: const SizedBox.expand(key: supportingKey),
        ),
      );
      // The nested layout sets its own pane in by the window's margin, and
      // the supporting pane beside it is set in as before.
      final list = find.byKey(listKey);
      expect(tester.getRect(list).left, 24);
      expect(tester.getRect(list).right, 1300 - 24 - 412 - 24);
      expect(marginsIn(tester, list), margins());
      expect(tester.getRect(find.byKey(supportingKey)).right, 1300 - 24);
      expect(
        AdaptiveRegion.sizeOf(
          tester.element(find.byType(ListDetailLayout<int>)),
        ).width,
        // The pane reaches the leading edge, the margin included.
        1300 - 412 - 24 - 24,
      );
    });

    testWidgets('given as a pane, resolve against the width they would have '
        'if not nested', (tester) async {
      // 860dp is expanded, and 860dp less the margins is medium: two panes
      // show the list beside the detail, and one the detail's page alone.
      setWindowSize(tester, const Size(860, 800));
      await tester.pumpWidget(around(inner()));
      expect(find.byKey(listKey), findsOneWidget);

      // Wrapped in another widget, a layout is not recognised, and its pane
      // is set in as any other.
      await tester.pumpWidget(around(Builder(builder: (context) => inner())));
      expect(find.byKey(listKey), findsNothing);
    });

    testWidgets('given as a pane, keep the margin that a pane hidden beside '
        'them leaves them', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      final split = PaneSplitController();
      addTearDown(split.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: TwoPaneLayout(
              arrangement: const PaneArrangement.fixedAndFlexible(
                fixed: PaneSlot.second,
              ),
              resizable: true,
              splitController: split,
              first: inner(selectedId: null),
              second: const SizedBox.expand(key: supportingKey),
            ),
          ),
        ),
      );
      split.value = PaneSplit.collapsed;
      await settle(tester);
      // The nested layout reaches the trailing edge, and keeps the margin
      // there; the outer handle rests in it.
      expect(find.byKey(supportingKey), findsNothing);
      final nested = tester.element(find.byType(ListDetailLayout<int>));
      expect(AdaptiveRegion.sizeOf(nested).width, 1300);
      expect(AdaptiveRegion.marginsOf(nested), margins(start: 24, end: 24));
      expect(tester.getRect(find.byKey(listKey)).right, 1300 - 24);
      expect(tester.getCenter(find.byType(PaneResizer)).dx, 1300 - 12);
    });

    testWidgets('given as a stacked pane, keep the margins across it', (
      tester,
    ) async {
      setWindowSize(tester, const Size(500, 824));
      await tester.pumpWidget(
        around(
          inner(selectedId: null),
          supporting: const SizedBox.expand(key: supportingKey),
        ),
      );
      final list = find.byKey(listKey);
      final nested = tester.element(find.byType(ListDetailLayout<int>));
      expect(AdaptiveRegion.sizeOf(nested).width, 500);
      expect(AdaptiveRegion.marginsOf(nested), margins(start: 16, end: 16));
      expect(tester.getRect(list).left, 16);
      expect(tester.getRect(list).right, 500 - 16);
      expect(marginsIn(tester, list), margins());
      expect(tester.getRect(find.byKey(supportingKey)).left, 16);
      expect(tester.getRect(find.byKey(supportingKey)).right, 500 - 16);
    });

    testWidgets('a feed keeps the margins of the pane it is in', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        listDetail(
          placement: MarginPlacement.inside,
          selectedId: 1,
          listBuilder: (context) => FeedLayout(
            minItemWidth: 200,
            itemCount: 3,
            itemBuilder: (context, index) =>
                SizedBox(key: ValueKey('item $index'), height: 100),
          ),
        ),
      );

      final item = find.byKey(const ValueKey('item 0'));
      expect(tester.getRect(item).left, 24);
      expect(tester.getRect(item).right, 24 + 360);
      expect(marginsIn(tester, item), margins());
    });
  });

  group('A keyboard sliding in', () {
    Future<void> slideKeyboard(WidgetTester tester) async {
      for (var inset = 50.0; inset <= 300; inset += 50) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();
      }
    }

    testWidgets("rebuilds none of a feed's items", (tester) async {
      setWindowSize(tester, const Size(400, 800));
      final built = <int>[];
      await tester.pumpWidget(
        app(
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: FeedLayout(
              minItemWidth: 200,
              itemCount: 4,
              itemBuilder: (context, index) {
                built.add(index);
                return const SizedBox(height: 100);
              },
            ),
          ),
        ),
      );
      built.clear();
      await slideKeyboard(tester);
      expect(built, isEmpty);
    });

    testWidgets('does not build the detail page again', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      for (final placement in MarginPlacement.values) {
        var built = 0;
        await tester.pumpWidget(
          app(
            Scaffold(
              resizeToAvoidBottomInset: false,
              body: ListDetailLayout<int>(
                key: ValueKey(placement),
                marginPlacement: placement,
                selectedId: 1,
                listBuilder: (context) => const SizedBox.expand(),
                detailBuilder: (context, id, placement) {
                  built++;
                  return const SizedBox.expand(key: detailKey);
                },
              ),
            ),
          ),
        );
        await settle(tester);
        built = 0;
        await slideKeyboard(tester);
        expect(built, 0, reason: '$placement');
        tester.view.resetViewInsets();
      }
    });
  });

  testWidgets('outside every layout, content keeps the margins of the '
      'window, beyond its insets', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    setWindowPadding(tester, left: 20);
    await tester.pumpWidget(app(const SizedBox.expand(key: focusKey)));
    expect(
      marginsIn(tester, find.byKey(focusKey)),
      margins(start: 16 + 20, end: 16),
    );
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
