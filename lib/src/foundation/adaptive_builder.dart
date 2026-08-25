import 'package:flutter/widgets.dart';

import 'adaptive_layout_theme.dart';
import 'breakpoints.dart';
import 'window_size.dart';
import 'window_size_class.dart';

/// Signature for building a widget from the current [WindowSize].
typedef AdaptiveWidgetBuilder = Widget Function(
  BuildContext context,
  WindowSize windowSize,
);

/// Signature for building a widget from the current [WindowSizeClass].
typedef WindowSizeClassWidgetBuilder = Widget Function(
  BuildContext context,
  WindowSizeClass sizeClass,
);

/// Rebuilds its [builder] whenever the resolved [WindowSize] changes.
///
/// By default the size is the **window** size ([MediaQuery]); set
/// [useLocalSize] to classify against the nearest enclosing box instead — use
/// this for a *nested* region (e.g. a pane) that can be narrower than the
/// window.
///
/// [breakpoints] overrides the ones from the ambient [AdaptiveLayoutTheme].
class AdaptiveBuilder extends StatelessWidget {
  /// Creates an adaptive builder.
  const AdaptiveBuilder({
    super.key,
    required this.builder,
    this.useLocalSize = false,
    this.breakpoints,
  });

  /// Builds the subtree from the current [WindowSize].
  final AdaptiveWidgetBuilder builder;

  /// When `true`, classify against the local box constraints rather than the
  /// window size. Defaults to `false`.
  final bool useLocalSize;

  /// Overrides the breakpoints from the ambient [AdaptiveLayoutTheme].
  final Breakpoints? breakpoints;

  @override
  Widget build(BuildContext context) {
    final bp = breakpoints ?? AdaptiveLayoutTheme.of(context).breakpoints;

    if (!useLocalSize) {
      return builder(context, WindowSize.fromSize(MediaQuery.sizeOf(context), bp));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Height from constraints may be unbounded (e.g. inside a scrollable);
        // fall back to the window height for the height class in that case.
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final size = Size(constraints.maxWidth, height);
        return builder(context, WindowSize.fromSize(size, bp));
      },
    );
  }
}

/// A thin variant of [AdaptiveBuilder] that exposes only the [WindowSizeClass].
class WindowSizeClassBuilder extends StatelessWidget {
  /// Creates a window size class builder.
  const WindowSizeClassBuilder({
    super.key,
    required this.builder,
    this.useLocalSize = false,
    this.breakpoints,
  });

  /// Builds the subtree from the current [WindowSizeClass].
  final WindowSizeClassWidgetBuilder builder;

  /// See [AdaptiveBuilder.useLocalSize].
  final bool useLocalSize;

  /// See [AdaptiveBuilder.breakpoints].
  final Breakpoints? breakpoints;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      useLocalSize: useLocalSize,
      breakpoints: breakpoints,
      builder: (context, windowSize) =>
          builder(context, windowSize.widthClass),
    );
  }
}
