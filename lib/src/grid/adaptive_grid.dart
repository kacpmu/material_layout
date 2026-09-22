import 'package:flutter/widgets.dart';

import '../foundation/adaptive_layout_theme.dart';
import '../foundation/adaptive_value.dart';

/// An optional, standalone responsive grid.
///
/// This is a convenience helper — the canonical layouts do **not** depend on
/// it. Use it directly when you want a grid whose column count adapts to the
/// window size class, or whose tiles keep a maximum extent.
///
/// Two modes:
/// * [AdaptiveGrid.count] — a column count per [WindowSizeClass]
///   (defaults: 1 / 2 / 3 / 4 / 5 from compact → extraLarge, with
///   nearest-smaller fallback via [adaptiveValue]).
/// * [AdaptiveGrid.extent] — a maximum tile cross-axis extent; the column count
///   is derived from the available width (Material's recommended approach).
///
/// Classification uses the **local** constraints (the grid's own box).
class AdaptiveGrid extends StatelessWidget {
  /// A grid whose column count adapts to the window size class.
  const AdaptiveGrid.count({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.largeColumns = 4,
    this.extraLargeColumns = 5,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  }) : maxItemExtent = null,
       _useExtent = false;

  /// A grid whose column count is derived from a maximum tile extent.
  const AdaptiveGrid.extent({
    super.key,
    required this.children,
    required double this.maxItemExtent,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  }) : compactColumns = 1,
       mediumColumns = 2,
       expandedColumns = 3,
       largeColumns = 4,
       extraLargeColumns = 5,
       _useExtent = true;

  /// The grid items.
  final List<Widget> children;

  /// Column count for [WindowSizeClass.compact] (count mode).
  final int compactColumns;

  /// Column count for [WindowSizeClass.medium] (count mode).
  final int mediumColumns;

  /// Column count for [WindowSizeClass.expanded] (count mode).
  final int expandedColumns;

  /// Column count for [WindowSizeClass.large] (count mode).
  final int largeColumns;

  /// Column count for [WindowSizeClass.extraLarge] (count mode).
  final int extraLargeColumns;

  /// Maximum tile cross-axis extent (extent mode).
  final double? maxItemExtent;

  /// Cross-axis spacing between tiles.
  final double spacing;

  /// Main-axis spacing between rows.
  final double runSpacing;

  /// The tile aspect ratio.
  final double childAspectRatio;

  /// Padding around the grid.
  final EdgeInsetsGeometry padding;

  /// Whether the grid should shrink-wrap its content.
  final bool shrinkWrap;

  /// The scroll physics.
  final ScrollPhysics? physics;

  final bool _useExtent;

  @override
  Widget build(BuildContext context) {
    final breakpoints = AdaptiveLayoutTheme.of(context).breakpoints;

    return LayoutBuilder(
      builder: (context, constraints) {
        final SliverGridDelegate delegate;
        if (_useExtent) {
          delegate = SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemExtent!,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          );
        } else {
          final sizeClass = breakpoints.resolve(constraints.maxWidth);
          final columns = adaptiveValue<int>(
            sizeClass,
            compact: compactColumns,
            medium: mediumColumns,
            expanded: expandedColumns,
            large: largeColumns,
            extraLarge: extraLargeColumns,
          );
          delegate = SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          );
        }

        return GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: delegate,
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
