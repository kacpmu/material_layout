// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// @docImport '../layouts/list_detail_layout.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../foundation/adaptive_region.dart';
import '../foundation/margins.dart';
import '../foundation/theme.dart';
import 'pane_scope.dart';

/// The surface a pane's content sits on, painted to match where its layout
/// keeps the margins.
///
/// Material groups a pane's content in one of two ways. Where the layout
/// keeps its margins around the panes ([MarginPlacement.outside]), the
/// surface is a card, set in from the edges by the margins, and its content
/// keeps Material's 16dp card padding. Where the layout keeps them within the
/// panes ([MarginPlacement.inside]), the surface is flat: it reaches the
/// edges, and its content keeps the margins the layout reports. Either way,
/// content that pads itself by [PaneSurface.paddingOf] starts 16dp in where
/// Material's app bars, list items and tabs start their own, in a card and
/// in a compact window alike.
///
/// ```dart
/// ListDetailLayout<int>(
///   listBuilder: (context) => const PaneSurface(child: MessageList()),
///   detailBuilder: (context, id, placement) =>
///       PaneSurface(child: MessageView(id: id)),
/// );
/// ```
///
/// The surface has the corners of
/// [MaterialLayoutThemeData.paneBorderRadius], which the layouts keep while
/// panes and pages move, and clips its content to them. Its colour and
/// outline are its own, then [MaterialLayoutThemeData.paneSurfaceStyle]'s,
/// then the colour scheme's surface colour and none. A surface in the
/// background's colour groups content implicitly; a distinct colour or an
/// outline groups it explicitly. It follows the placement of the layout
/// whose pane it is in, and outside every layout the theme's.
///
/// Painting panes stays the app's choice: a pane may hold any widget, and
/// this one only saves an app from matching the painting to the margins by
/// hand.
class PaneSurface extends StatelessWidget {
  /// Creates a pane surface around [child].
  const new({super.key, this.color, this.outline, required this.child});

  /// The surface's colour, or null for the theme's, and then the colour
  /// scheme's surface colour.
  final Color? color;

  /// The line around the surface, or null for the theme's, and then none.
  final BorderSide? outline;

  /// The pane's content.
  final Widget child;

  /// Whether [context] is inside a pane surface painted as a card.
  static bool inCard(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Surface>()?.card ?? false;

  /// The space content keeps from the sides of what it sits on: in a card,
  /// Material's 16dp card padding; in a flat pane, or on the background, the
  /// margins the layout reports ([AdaptiveRegion.marginsOf]).
  static EdgeInsetsDirectional paddingOf(BuildContext context) =>
      inCard(context)
      ? const EdgeInsetsDirectional.symmetric(horizontal: 16)
      : AdaptiveRegion.marginsOf(context);

  @override
  Widget build(BuildContext context) {
    final layout = MaterialLayoutTheme.of(context);
    final style = layout.paneSurfaceStyle;
    final placement =
        PaneScope.maybeOf(context)?.marginPlacement ?? layout.marginPlacement;
    final corners = layout.paneBorderRadius;
    final rounded =
        corners.resolve(Directionality.of(context)) != BorderRadius.zero;
    return Material(
      color: color ?? style.color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: corners,
        side: outline ?? style.outline ?? BorderSide.none,
      ),
      clipBehavior: rounded ? Clip.antiAlias : Clip.none,
      // The content stays where it is in the tree, and keeps its state, as
      // the surface changes between a card and a flat pane.
      child: _Surface(card: placement == MarginPlacement.outside, child: child),
    );
  }
}

class _Surface extends InheritedWidget {
  const new({required this.card, required super.child});

  final bool card;

  @override
  bool updateShouldNotify(_Surface oldWidget) => card != oldWidget.card;
}
