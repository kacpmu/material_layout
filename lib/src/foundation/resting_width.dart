// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';
import 'theme.dart';

/// Publishes to a pane's content the width the pane's content will have
/// once the pane comes to rest, as while a pane beside it enters or leaves,
/// and to a navigation scaffold's body the width it will have once a
/// navigation rail has come or gone.
///
/// Layouts and regions as wide as the pane resolve their breakpoints against
/// the width they will rest at, so that they arrange themselves once, for
/// where the pane is going, rather than as it passes breakpoints on its way.
/// Narrower ones, which need not grow or shrink with the pane, resolve
/// against their width.
class PaneRestingWidth extends InheritedWidget {
  /// Publishes [width] and [restingWidth] to [child].
  const new({
    super.key,
    required this.width,
    required this.restingWidth,
    required super.child,
  });

  /// The width of the pane's content now.
  final double width;

  /// The width of the pane's content once the pane comes to rest.
  final double restingWidth;

  /// The width that [width], inside the pane enclosing [context], rests at:
  /// the pane's resting width where [width] is the pane's, and [width]
  /// itself otherwise, and outside every pane.
  static double resolve(BuildContext context, double width) {
    final pane = context.dependOnInheritedWidgetOfExactType<PaneRestingWidth>();
    if (pane == null || (width - pane.width).abs() > _tolerance) return width;
    return pane.restingWidth;
  }

  /// The breakpoint of the width that [width], inside the pane enclosing
  /// [context], rests at ([resolve]).
  static Breakpoint breakpointOf(BuildContext context, double width) =>
      MaterialLayoutTheme.of(context).breakpoints
          .forWidth(resolve(context, width));

  // A region that fills its pane is laid out at exactly the pane's width;
  // a narrower one matches it only by chance, and by less than this.
  static const double _tolerance = 0.01;

  @override
  bool updateShouldNotify(PaneRestingWidth oldWidget) =>
      width != oldWidget.width || restingWidth != oldWidget.restingWidth;
}
