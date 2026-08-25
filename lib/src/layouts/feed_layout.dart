import 'package:flutter/widgets.dart';

import '../foundation/adaptive_layout_theme.dart';

/// The Material 3 feed canonical layout: a single scrolling container laid out
/// as a responsive grid of equivalently-weighted items.
///
/// The feed reflows by **column count**, not by swapping panes — the column
/// count is derived from the available width and [maxItemWidth] (so it adapts
/// to the window, split-screen, and foldables). It is self-contained and does
/// not depend on [AdaptiveGrid].
///
/// At **compact** widths the grid collapses to [compactColumns] (1 by default),
/// because Material 3 specifies that "in compact windows, the cards in a feed
/// stack vertically, filling the full width". Deriving the count purely from
/// [maxItemWidth] would put two narrow columns on a phone.
///
/// An optional [header] sliver is rendered above the grid.
class FeedLayout extends StatelessWidget {
  /// Creates a feed layout.
  const FeedLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxItemWidth = 300,
    this.compactColumns = 1,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1,
    this.padding = const EdgeInsets.all(16),
    this.header,
    this.controller,
    this.physics,
  });

  /// The number of feed items.
  final int itemCount;

  /// Builds the item at [index].
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// The maximum cross-axis extent of a tile; the column count grows as the
  /// available width exceeds multiples of this. Defaults to 300.
  final double maxItemWidth;

  /// The column count at compact widths, where Material 3 stacks feed cards
  /// full-width. Defaults to 1. Raise it only if your tiles are genuinely
  /// narrow; above compact the count comes from [maxItemWidth] as usual.
  final int compactColumns;

  /// Cross-axis spacing between tiles. Defaults to 16.
  final double spacing;

  /// Main-axis spacing between rows. Defaults to 16.
  final double runSpacing;

  /// The tile aspect ratio. Defaults to 1.
  final double childAspectRatio;

  /// Padding around the grid. Defaults to 16 on all sides.
  final EdgeInsetsGeometry padding;

  /// An optional header rendered above the grid.
  final Widget? header;

  /// An optional scroll controller.
  final ScrollController? controller;

  /// Optional scroll physics.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final breakpoints = AdaptiveLayoutTheme.of(context).breakpoints;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Classified against the *pane*, not the window: a feed inside a narrow
        // pane of a wide window should still stack.
        final sizeClass = breakpoints.resolve(constraints.maxWidth);
        final SliverGridDelegate delegate = sizeClass.isCompact
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: compactColumns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: runSpacing,
                childAspectRatio: childAspectRatio,
              )
            : SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxItemWidth,
                crossAxisSpacing: spacing,
                mainAxisSpacing: runSpacing,
                childAspectRatio: childAspectRatio,
              );
        return _buildScrollView(delegate);
      },
    );
  }

  Widget _buildScrollView(SliverGridDelegate delegate) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            gridDelegate: delegate,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
