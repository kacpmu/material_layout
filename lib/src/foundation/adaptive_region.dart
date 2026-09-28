// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';
import 'margins.dart';
import 'resting_width.dart';
import 'theme.dart';

/// A region that the widgets inside it adapt to.
///
/// A layout resolves against the region it occupies, not the window, so that
/// a layout nested inside a pane adapts to that pane. This widget
/// measures the space it is given and publishes it, with the breakpoints it
/// resolves to, for its descendants. Every pane of this package's layouts is
/// a region; outside any region, the window is.
///
/// ```dart
/// final breakpoint = AdaptiveRegion.breakpointOf(context);
/// if (breakpoint >= Breakpoint.medium) return const WideHeader();
/// return const Header();
/// ```
///
/// A widget that reads only the breakpoint rebuilds only when the breakpoint
/// changes, not on every change of size.
///
/// While a pane enters or leaves beside the region's pane, the region grows
/// or shrinks with it, and its breakpoint is that of the width it will rest
/// at: content arranges itself once, for where its pane is going, rather
/// than on its way there.
class AdaptiveRegion extends StatelessWidget {
  /// Creates a region around [child].
  const new({super.key, required this.child});

  /// The widget below this widget in the tree.
  final Widget child;

  /// The size of the region enclosing [context], or of the window when no
  /// region encloses it.
  static Size sizeOf(BuildContext context) =>
      _scopeOf(context, _RegionAspect.size)?.size ?? MediaQuery.sizeOf(context);

  /// The width breakpoint of the region enclosing [context], or of the window
  /// when no region encloses it.
  ///
  /// While the region grows or shrinks for a pane that enters or leaves
  /// beside it, the breakpoint of the width it will rest at.
  static Breakpoint breakpointOf(BuildContext context) =>
      _scopeOf(context, _RegionAspect.breakpoint)?.breakpoint ??
      MaterialLayoutTheme.of(context).breakpoints
          .forWidth(MediaQuery.sizeOf(context).width);

  /// The height breakpoint of the region enclosing [context], or of the
  /// window when no region encloses it.
  static HeightBreakpoint heightBreakpointOf(BuildContext context) =>
      _scopeOf(context, _RegionAspect.heightBreakpoint)?.heightBreakpoint ??
      MaterialLayoutTheme.of(context).breakpoints
          .forHeight(MediaQuery.sizeOf(context).height);

  /// The margins that content in the region enclosing [context] keeps
  /// itself from the edges of the layout around it.
  ///
  /// In a pane whose layout keeps its margins around the panes
  /// ([MarginPlacement.outside]), none: the pane is already set in. In a pane
  /// whose layout keeps them within the panes ([MarginPlacement.inside]), the
  /// margins on the sides where the pane meets the edges; they follow the
  /// pane as panes enter or leave beside it. Outside every layout, the
  /// margins of the region's breakpoint, beyond any safe-area inset on either
  /// side, with none beside a navigation rail, which takes the leading
  /// margin's place.
  ///
  /// Content pads itself by these margins: a page's body by a [Padding], a
  /// list item by its content padding. Material's components keep a 16dp
  /// inset of their own, so where these margins are 16dp, as in a compact
  /// window, they line up with the content as they are. A component that
  /// keeps clear of the safe area itself, as an app bar does, takes only the
  /// part of these margins beyond the safe-area padding
  /// ([MediaQueryData.padding]).
  static EdgeInsetsDirectional marginsOf(BuildContext context) =>
      PaneMargins.maybeOf(context) ??
      windowMargins(context, breakpointOf(context));

  static _RegionScope? _scopeOf(BuildContext context, _RegionAspect aspect) =>
      InheritedModel.inheritFrom<_RegionScope>(context, aspect: aspect);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final window = MediaQuery.sizeOf(context);
      final size = Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : window.width,
        constraints.hasBoundedHeight ? constraints.maxHeight : window.height,
      );
      return _RegionScope(
        size: size,
        breakpoint: PaneRestingWidth.breakpointOf(context, size.width),
        heightBreakpoint: MaterialLayoutTheme.of(context).breakpoints
            .forHeight(size.height),
        child: child,
      );
    },
  );
}

enum _RegionAspect { size, breakpoint, heightBreakpoint }

class _RegionScope extends InheritedModel<_RegionAspect> {
  const new({
    required this.size,
    required this.breakpoint,
    required this.heightBreakpoint,
    required super.child,
  });

  final Size size;
  final Breakpoint breakpoint;
  final HeightBreakpoint heightBreakpoint;

  @override
  bool updateShouldNotify(_RegionScope oldWidget) =>
      size != oldWidget.size ||
      breakpoint != oldWidget.breakpoint ||
      heightBreakpoint != oldWidget.heightBreakpoint;

  @override
  bool updateShouldNotifyDependent(
    _RegionScope oldWidget,
    Set<_RegionAspect> dependencies,
  ) =>
      (dependencies.contains(_RegionAspect.size) && size != oldWidget.size) ||
      (dependencies.contains(_RegionAspect.breakpoint) &&
          breakpoint != oldWidget.breakpoint) ||
      (dependencies.contains(_RegionAspect.heightBreakpoint) &&
          heightBreakpoint != oldWidget.heightBreakpoint);
}
