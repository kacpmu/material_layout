// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

import '../foundation/adaptive_region.dart';
import '../foundation/breakpoints.dart';
import '../foundation/margins.dart';
import '../foundation/resting_width.dart';
import '../foundation/theme.dart';
import '../panes/pane_scope.dart';
import 'list_detail_layout.dart';
import 'supporting_pane_layout.dart';
import 'two_pane_layout.dart';

/// The margins a layout keeps at the edges of its region.
///
/// A layout that is not inside another layout's pane keeps 16dp (compact) or
/// 24dp at its edges, beyond any safe-area inset there, and none on
/// the edge a navigation rail borders, whose place the rail takes. A nested
/// layout keeps the margins its pane reports: none in a pane
/// that is set in, and the margins on the sides where the pane meets the
/// edges of the outer layout when that layout keeps them within its panes.
EdgeInsetsDirectional layoutMargins(
  BuildContext context,
  Breakpoint breakpoint, {
  required bool nested,
}) => nested
    ? AdaptiveRegion.marginsOf(context)
    : windowMargins(context, breakpoint);

/// Removes the horizontal safe-area insets that [layoutMargins] has already
/// kept its child clear of.
///
/// It reads the media query in a build of its own, so that the layout above
/// it does not rebuild with every change to the media query, such as each
/// frame of a keyboard sliding in.
class RemoveHorizontalPadding extends StatelessWidget {
  /// Removes the horizontal insets from the media query [child] sees.
  const new({super.key, required this.child});

  /// The widget below this one.
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .removePadding(removeLeft: true, removeRight: true),
    child: child,
  );
}

// Where the region of a layout sits in the window.
//
// [offset] is the region's measured position, or null before its first
// frame; the region is then assumed to be flush with the trailing edge of
// the window, as it is beside a navigation rail on the leading edge.
Rect _regionInWindow(BuildContext context, Size regionSize, Offset? offset) {
  if (offset != null) return offset & regionSize;
  final window = MediaQuery.sizeOf(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final left = rtl ? 0.0 : window.width - regionSize.width;
  return Offset(left, window.height - regionSize.height) & regionSize;
}

// The centre of the window, measured from the leading edge of [region].
//
// The split-pane spacer stays centred in the window, so a navigation
// rail or drawer beside the layout narrows only the leading pane. Null
// when the centre falls outside the region, where centring on the window
// cannot apply.
double? _windowCenterInRegion(BuildContext context, Rect region) {
  final window = MediaQuery.sizeOf(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final fromLeft = window.width / 2 - region.left;
  if (fromLeft <= 0 || fromLeft >= region.width) return null;
  return rtl ? region.width - fromLeft : fromLeft;
}

/// A band across a region where a fold or hinge separates the display.
typedef SeparatingBand = ({Axis axis, double start, double end});

// The fold or hinge that separates the display across [region], if any.
//
// A hinge always separates content. A fold separates it when it is half
// open, or has a width of its own; a flat fold does not. The band is in the
// region's coordinates, measured from its leading edge for a vertical band
// (whose `axis` is [Axis.horizontal], the axis it divides) and from its top
// for a horizontal one.
SeparatingBand? _separatingBand(BuildContext context, Rect region) {
  final rtl = Directionality.of(context) == TextDirection.rtl;
  // Only the part of the region on screen can be separated, as when the
  // region is scrolled partly out of view.
  final shown = region.intersect(Offset.zero & MediaQuery.sizeOf(context));
  if (shown.isEmpty) return null;
  for (final feature in MediaQuery.displayFeaturesOf(context)) {
    if (!_separates(feature)) continue;
    final bounds = feature.bounds;
    final vertical = bounds.height >= bounds.width;
    if (vertical) {
      if (bounds.top > shown.top || bounds.bottom < shown.bottom) continue;
      if (bounds.right <= shown.left || bounds.left >= shown.right) continue;
      final left = math.max(bounds.left, region.left) - region.left;
      final right = math.min(bounds.right, region.right) - region.left;
      return (
        axis: Axis.horizontal,
        start: rtl ? region.width - right : left,
        end: rtl ? region.width - left : right,
      );
    }
    if (bounds.left > shown.left || bounds.right < shown.right) continue;
    if (bounds.bottom <= shown.top || bounds.top >= shown.bottom) continue;
    return (
      axis: Axis.vertical,
      start: math.max(bounds.top, region.top) - region.top,
      end: math.min(bounds.bottom, region.bottom) - region.top,
    );
  }
  return null;
}

bool _separates(DisplayFeature feature) => switch (feature.type) {
  DisplayFeatureType.hinge => true,
  DisplayFeatureType.fold =>
    feature.state == DisplayFeatureState.postureHalfOpened ||
        feature.bounds.shortestSide > 0,
  _ => false,
};

// What a layout takes from where its region sits in the window: the
// window's centre, where the layout splits around it, and a fold or hinge
// that separates the display. A layout rebuilds when its region moves only
// if this changes, so that a layout whose split does not follow the
// window's centre stays as it is.
typedef _WindowPlacement = ({double? center, SeparatingBand? band});

// The placement of [region], with the window's centre only where the
// layout [usesCenter].
_WindowPlacement _windowPlacement(
  BuildContext context,
  Rect region, {
  required bool usesCenter,
}) => (
  center: usesCenter ? _windowCenterInRegion(context, region) : null,
  band: _separatingBand(context, region),
);

/// The spacer and its centre for a split held on [band]: the band's width,
/// and never less than the standard spacer.
({double spacer, double center}) bandSpacer(SeparatingBand band) => (
  spacer: math.max(paneSpacer, band.end - band.start),
  center: (band.start + band.end) / 2,
);

/// The region a two-pane layout occupies, as it arranges its panes there.
class LayoutRegion {
  new _({
    required this._context,
    required this.breakpoint,
    required this.scope,
    required this.marginPlacement,
    required this._rect,
  }) : band = _separatingBand(_context, _rect);

  final BuildContext _context;
  final Rect _rect;
  bool _usesCenter = false;

  /// The breakpoint of the width the region rests at, which the layout is
  /// arranged for.
  final Breakpoint breakpoint;

  /// The pane of another layout that the region is in, or null.
  final PaneScope? scope;

  /// Where the layout keeps its margins: where it is told to, or where the
  /// layout it is nested in keeps its own, or where the theme says.
  final MarginPlacement marginPlacement;

  /// The fold or hinge that separates the display across the region, if any.
  final SeparatingBand? band;

  /// Whether the layout is nested in another layout's pane.
  bool get nested => scope != null;

  /// The panes the layout may show.
  PaneBudget get budget => PaneScope.budgetOf(
    scope,
    extraLarge: breakpoint == Breakpoint.extraLarge,
  );

  /// The margins the layout keeps at the edges of the region.
  EdgeInsetsDirectional get margins =>
      layoutMargins(_context, breakpoint, nested: nested);

  /// The centre of the window, measured from the region's leading edge, or
  /// null where it falls outside the region.
  ///
  /// A layout that reads it follows the window's centre: it is built again
  /// when the region moves in the window so that the centre moves in it.
  double? get windowCenter {
    _usesCenter = true;
    return _windowCenterInRegion(_context, _rect);
  }
}

/// Resolves the region a two-pane layout occupies, and builds the layout
/// again when a move of the region in the window changes what it takes from
/// the window: the window's centre, where the layout follows it, and a fold
/// or hinge.
mixin LayoutRegionState<T extends StatefulWidget> on State<T> {
  Offset? _regionOffset;
  Size? _regionSize;
  bool _usesCenter = false;
  _WindowPlacement? _placement;

  /// Builds the layout with [builder] for the region it occupies, keeping its
  /// margins where [marginPlacement] says, or where the layout it is nested
  /// in or the theme does when that is null.
  Widget buildRegion({
    required MarginPlacement? marginPlacement,
    required Widget Function(BuildContext context, LayoutRegion region) builder,
  }) {
    final scope = PaneScope.maybeOf(context);
    final placement =
        marginPlacement ??
        scope?.marginPlacement ??
        MaterialLayoutTheme.of(context).marginPlacement;
    return RegionOffsetReporter(
      onChanged: _handleRegionOffset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          _regionSize = size;
          final rect = _regionInWindow(context, size, _regionOffset);
          final region = LayoutRegion._(
            context: context,
            // The panes are arranged for the width the region rests at.
            breakpoint: PaneRestingWidth.breakpointOf(context, size.width),
            scope: scope,
            marginPlacement: placement,
            rect: rect,
          );
          final layout = builder(context, region);
          _usesCenter = region._usesCenter;
          _placement = (
            center: _usesCenter ? _windowCenterInRegion(context, rect) : null,
            band: region.band,
          );
          return layout;
        },
      ),
    );
  }

  // The layout assumes where it sits until it is measured, and rebuilds when
  // a measurement changes what it takes from the window.
  void _handleRegionOffset(Offset offset) {
    _regionOffset = offset;
    final size = _regionSize;
    if (!mounted || size == null) return;
    final region = _regionInWindow(context, size, offset);
    final placement = _windowPlacement(
      context,
      region,
      usesCenter: _usesCenter,
    );
    if (placement != _placement) setState(() {});
  }
}

/// The content of one pane of a layout: a region of its own, keeping its
/// page storage in [bucket] under [storageKey], and telling the layouts
/// nested in it the panes they may show and where to keep their margins.
Widget paneContent({
  required PageStorageBucket bucket,
  required Object storageKey,
  required PaneBudget budget,
  required MarginPlacement marginPlacement,
  VoidCallback? onDismiss,
  required Widget child,
}) => PaneScope(
  budget: budget,
  marginPlacement: marginPlacement,
  onDismiss: onDismiss,
  child: AdaptiveRegion(
    child: PaneStorage(bucket: bucket, storageKey: storageKey, child: child),
  ),
);

/// Whether [widget] is a two-pane layout, which keeps the margins of the pane
/// it is given as, itself, where another layout gives it one: a pane holding
/// it reaches the edges it meets, and the layout keeps the margins there,
/// around its own panes or within them, so that its drag handle can rest in
/// them.
///
/// Only a layout given as the pane itself is recognised, not one that another
/// widget wraps.
bool isPaneLayout(Widget? widget) =>
    widget is ListDetailLayout ||
    widget is SupportingPaneLayout ||
    widget is TwoPaneLayout;
