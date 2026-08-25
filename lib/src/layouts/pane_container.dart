import 'package:flutter/material.dart';

/// The Material 3 corner radius a [PaneContainer] uses by default.
///
/// 16dp — the shape scale's *large corner value*. The scale runs 4 / 8 / 12 /
/// 16 / 20 / 28 / 32 / 48 / full, so reach for [Radius.circular] with one of
/// those rather than an arbitrary number when overriding.
const double kPaneCornerRadius = 16;

/// [kPaneCornerRadius] on every corner.
const BorderRadius kPaneBorderRadius =
    BorderRadius.all(Radius.circular(kPaneCornerRadius));

/// Which of Material 3's five surface container roles a [PaneContainer] paints.
///
/// Material 3 describes these as "five surface container roles named based on
/// their level of emphasis", and notes that while
/// [PaneLevel.container] is the default, "the others are especially helpful for
/// creating hierarchy and nested containers in layouts for expanded screens" —
/// which is exactly what a multi-pane layout is.
///
/// The body area itself is normally plain `surface`; a pane sitting on it steps
/// up to a container role so its edge reads without a divider.
enum PaneLevel {
  /// `surfaceContainerLowest` — the quietest container.
  lowest,

  /// `surfaceContainerLow`.
  low,

  /// `surfaceContainer` — the default container role.
  container,

  /// `surfaceContainerHigh`.
  high,

  /// `surfaceContainerHighest` — the most emphasised container.
  highest;

  /// The colour this level maps to in [colors].
  Color resolve(ColorScheme colors) => switch (this) {
        PaneLevel.lowest => colors.surfaceContainerLowest,
        PaneLevel.low => colors.surfaceContainerLow,
        PaneLevel.container => colors.surfaceContainer,
        PaneLevel.high => colors.surfaceContainerHigh,
        PaneLevel.highest => colors.surfaceContainerHighest,
      };
}

/// A Material 3 pane surface: a rounded, tinted container to wrap the content
/// of one pane in.
///
/// The canonical layouts ([TwoPane], [ListDetailLayout], [SupportingPaneLayout])
/// decide *where* panes go and how wide they are; they deliberately don't paint
/// them, because what a pane should look like depends on the app. This is the
/// missing piece — wrap a list, a detail, or a supporting pane in one and it
/// picks up the right surface colour and corner radius:
///
/// ```dart
/// ListDetailLayout(
///   listBuilder: (context) => PaneContainer(child: MessageList()),
///   detailBuilder: (context, id) => PaneContainer(
///     level: PaneLevel.low,
///     child: MessageView(id: id as int),
///   ),
/// );
/// ```
///
/// It is a [Material], so it also gives the content an ink surface. That
/// matters more than it sounds: a `ListTile` or `InkWell` paints its splash and
/// selection highlight on the nearest [Material] ancestor, so a pane whose
/// content is placed over a route transition or a coloured box will otherwise
/// have its highlights swallowed.
class PaneContainer extends StatelessWidget {
  /// Creates a pane surface.
  const PaneContainer({
    super.key,
    required this.child,
    this.level = PaneLevel.container,
    this.color,
    this.borderRadius = kPaneBorderRadius,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.elevation = 0,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(elevation >= 0);

  /// The pane's content.
  final Widget child;

  /// Which surface container role to paint. Defaults to [PaneLevel.container].
  ///
  /// Give adjacent panes different levels to establish hierarchy — Material 3
  /// recommends exactly this for nested containers on expanded screens.
  /// Ignored when [color] is set.
  final PaneLevel level;

  /// An explicit surface colour, overriding [level].
  final Color? color;

  /// The corner rounding. Defaults to [kPaneBorderRadius] (16dp).
  ///
  /// Use a [BorderRadiusDirectional] to round only the edge facing the content
  /// — handy for a pane flush against the window, where rounding the outer
  /// corners would leave slivers of background in the screen corners.
  final BorderRadiusGeometry borderRadius;

  /// Space *outside* the surface. Defaults to none, so the pane fills its slot;
  /// give it a margin for a "detached" pane that floats within the region.
  final EdgeInsetsGeometry margin;

  /// Space between the surface edge and [child].
  final EdgeInsetsGeometry? padding;

  /// The surface elevation. Defaults to 0 — panes are co-planar with the body,
  /// not floating above it.
  final double elevation;

  /// How [child] is clipped to [borderRadius]. Defaults to [Clip.antiAlias] so
  /// content cannot paint over the rounded corners.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget surface = Material(
      color: color ?? level.resolve(colors),
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: clipBehavior,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (margin != EdgeInsets.zero) {
      surface = Padding(padding: margin, child: surface);
    }
    return surface;
  }
}
