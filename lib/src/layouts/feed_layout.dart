// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../foundation/breakpoints.dart';
import '../foundation/margins.dart';
import '../foundation/resting_width.dart';
import '../panes/pane_scope.dart';
import 'layout_support.dart';

/// Returns how many columns the item at [index] spans when the feed has
/// [columnCount] columns.
typedef FeedSpanBuilder = int Function(int index, int columnCount);

/// A scrolling feed of items that reflows by column count.
///
/// At compact the feed is a single column, each item filling the width.
/// Above compact, the column count grows with the width available:
/// as many columns as fit at [minItemWidth] each. Material publishes
/// no column counts, so the minimum item width is the caller's.
///
/// Items may differ in size: [spanBuilder] lets an item span
/// several columns, and each item takes the height it needs. Items are
/// placed in order, row by row, so that position follows order, and reflow
/// when the width changes. An item keeps its state while it stays in
/// its row; one that moves to another row as the feed reflows is built
/// afresh, so keep state an item must not lose outside it.
///
/// ```dart
/// FeedLayout(
///   minItemWidth: 280,
///   itemCount: articles.length,
///   // The first article spans two columns wherever there are two.
///   spanBuilder: (index, columns) => index == 0 ? 2 : 1,
///   itemBuilder: (context, index) => ArticleCard(articles[index]),
/// );
/// ```
///
/// The feed is one pane that scrolls across its whole region, while its
/// items keep the margins of its breakpoint from the window's edges;
/// nested in another layout's pane, they keep the margins that pane keeps.
/// Its first and last items start clear of the safe area at the top and
/// bottom of the window, and scroll into it.
class FeedLayout extends StatelessWidget {
  /// Creates a feed.
  const new({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.minItemWidth,
    this.spanBuilder,
    this.gap = 8,
    this.padding = EdgeInsets.zero,
    this.controller,
  }) : assert(itemCount >= 0),
       assert(minItemWidth > 0),
       assert(gap >= 0);

  /// The number of items in the feed.
  final int itemCount;

  /// Builds the item at an index, which is also its place in the order of
  /// the feed.
  final IndexedWidgetBuilder itemBuilder;

  /// The narrowest an item may be, which decides the column count above
  /// compact.
  final double minItemWidth;

  /// How many columns each item spans, or null for one column each.
  ///
  /// Spans are clamped to the column count.
  final FeedSpanBuilder? spanBuilder;

  /// The space between items, across and down.
  ///
  /// One step of the 8dp spacing scale by default.
  final double gap;

  /// Space around the items inside the scrolling area, in addition to the
  /// margins.
  final EdgeInsets padding;

  /// Controls the feed's scroll position, or null for the default of
  /// [ScrollView.controller].
  final ScrollController? controller;

  // The number of columns of a feed [width] wide at [breakpoint]: one at
  // compact, and otherwise as many as fit.
  int _columnCountFor(double width, Breakpoint breakpoint) {
    if (breakpoint == Breakpoint.compact) return 1;
    return math.max(1, ((width + gap) / (minItemWidth + gap)).floor());
  }

  @override
  Widget build(BuildContext context) {
    final nested = PaneScope.maybeOf(context) != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The feed is arranged for the width its region rests at.
        final breakpoint = PaneRestingWidth.breakpointOf(context, width);
        final margins = layoutMargins(context, breakpoint, nested: nested);
        final contentWidth = math.max(
          0.0,
          width - margins.start - margins.end - padding.horizontal,
        );
        final columns = _columnCountFor(contentWidth, breakpoint);
        final rows = _rows(columns);
        final columnWidth = math.max(
          0.0,
          (contentWidth - gap * (columns - 1)) / columns,
        );
        final list = CustomScrollView(
          controller: controller,
          slivers: [
            // The horizontal insets are in the margins.
            SliverSafeArea(
              left: false,
              right: false,
              sliver: SliverPadding(
                padding: margins.add(padding),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, row) => Padding(
                    padding: EdgeInsets.only(
                      bottom: row == rows.length - 1 ? 0 : gap,
                    ),
                    child: _row(context, rows[row], columnWidth),
                  ),
                ),
              ),
            ),
          ],
        );
        // The items are set in by the margins, so they keep none of their
        // own.
        return RemoveHorizontalPadding(
          child: PaneMargins(margins: EdgeInsetsDirectional.zero, child: list),
        );
      },
    );
  }

  List<List<(int, int)>> _rows(int columns) {
    final rows = <List<(int, int)>>[];
    var row = <(int, int)>[];
    var used = 0;
    for (var index = 0; index < itemCount; index++) {
      final span = columns == 1
          ? 1
          : (spanBuilder?.call(index, columns) ?? 1).clamp(1, columns);
      if (used + span > columns) {
        rows.add(row);
        row = <(int, int)>[];
        used = 0;
      }
      row.add((index, span));
      used += span;
    }
    if (row.isNotEmpty) rows.add(row);
    return rows;
  }

  Widget _row(BuildContext context, List<(int, int)> items, double column) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (index, span)) in items.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            // Keyed by its index, so that an item that moves to another
            // row as the feed reflows never takes over the state of the
            // item that was in its place.
            SizedBox(
              key: ValueKey<int>(index),
              width: column * span + gap * (span - 1),
              child: itemBuilder(context, index),
            ),
          ],
        ],
      );
}
