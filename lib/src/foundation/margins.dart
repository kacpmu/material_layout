// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// @docImport 'adaptive_region.dart';
library;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Where a layout keeps the margins between the edges of its region and the
/// content inside it.
///
/// Choose the placement that matches how the app paints its panes.
enum MarginPlacement {
  /// Around the panes: the panes are set in from the edges, as cards on a
  /// background, and their content keeps no margin of its own.
  ///
  /// A page that shows the detail of a list-detail layout at one pane takes
  /// the pane's place, and is set in as well. A pane that is itself a
  /// two-pane layout, given as the pane rather than wrapped in another
  /// widget, is not set in: the layout in it keeps the margins it meets, and
  /// sets its own panes in by them.
  outside,

  /// Within the panes: the panes reach the edges, and their content keeps
  /// the margins, which [AdaptiveRegion.marginsOf] reports.
  ///
  /// Suits panes painted flat, where app bars, tab bars and list items span
  /// the whole width: their own padding already keeps their content at the
  /// margin. Other content pads itself by the reported margins, which the
  /// layout cannot do for it; the margins Material requires depend on it.
  /// A pane beside an edge is widened by the margin there, so its
  /// content keeps the width and place it has with the margins outside.
  inside,
}

/// Publishes to a pane's content the margins it keeps itself.
///
/// [AdaptiveRegion.marginsOf] reads it.
class PaneMargins extends InheritedWidget {
  /// Publishes [margins] to [child].
  const new({super.key, required this.margins, required super.child});

  /// The margins the content keeps: none on a side where the pane is set in
  /// from the edge.
  final EdgeInsetsDirectional margins;

  /// The margins published above [context], or null outside every pane.
  static EdgeInsetsDirectional? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneMargins>()?.margins;

  @override
  bool updateShouldNotify(PaneMargins oldWidget) =>
      margins != oldWidget.margins;
}

/// How much of the leading edge of the content below a navigation rail
/// borders: 1 where the rail sits against it, 0 without one, and in between
/// while the rail comes or goes.
///
/// The rail is the perimeter on its edge, so it takes the place of
/// the leading margin there, and the first pane starts where the rail ends.
class RailPresence extends InheritedWidget {
  /// Publishes [value] to [child].
  const new({super.key, required this.value, required super.child});

  /// How much of the leading edge the rail borders, from 0 to 1.
  final double value;

  /// The presence published above [context], or 0 without a rail.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RailPresence>()?.value ?? 0;

  @override
  bool updateShouldNotify(RailPresence oldWidget) => value != oldWidget.value;
}

/// The margins between the edges of the window and the content in it at
/// [breakpoint], beyond any safe-area inset, less the leading
/// margin that a navigation rail takes the place of.
EdgeInsetsDirectional windowMargins(
  BuildContext context,
  Breakpoint breakpoint,
) {
  final padding = MediaQuery.paddingOf(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final rail = RailPresence.of(context);
  return EdgeInsetsDirectional.only(
    start:
        breakpoint.margin * (1 - rail) + (rtl ? padding.right : padding.left),
    end: breakpoint.margin + (rtl ? padding.left : padding.right),
  );
}
