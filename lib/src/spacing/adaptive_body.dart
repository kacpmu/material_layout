import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/adaptive_layout_theme.dart';

/// Wraps body content with Material 3 size-class edge margins and a centered
/// max-width cap so content does not stretch uncomfortably wide on large
/// displays.
///
/// * Applies `16dp` margins in compact widths and `24dp` in medium and wider
///   (from [AdaptiveSpacing]); override the base with [margin].
/// * Beyond [maxWidth] (defaults to [AdaptiveLayoutThemeData.bodyMaxWidth]),
///   the extra space becomes centering padding rather than wider content.
/// * The cap scales with the ambient text scale so line length stays readable
///   when the user enlarges text — and content is never clipped (it just fills
///   the available width once the scaled cap exceeds it).
/// * Optionally wraps in a [SafeArea].
///
/// Classification uses the **local** constraints, so an [AdaptiveBody] inside a
/// pane uses the pane's width, not the window's.
class AdaptiveBody extends StatelessWidget {
  /// Creates an adaptive body wrapper.
  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.margin,
    this.center = true,
    this.safeArea = false,
  });

  /// The content to constrain and center.
  final Widget child;

  /// The maximum content width before centering. Defaults to the ambient
  /// [AdaptiveLayoutThemeData.bodyMaxWidth].
  final double? maxWidth;

  /// Overrides the computed size-class edge margin.
  final double? margin;

  /// Whether to center content (distribute extra space as padding) once the
  /// available width exceeds the cap. Defaults to `true`.
  final bool center;

  /// Whether to wrap the result in a [SafeArea]. Defaults to `false`.
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final theme = AdaptiveLayoutTheme.of(context);
    final baseCap = maxWidth ?? theme.bodyMaxWidth;
    // Grow the cap with text scale so the same line length remains readable
    // (and content is never clipped — see [center] handling below).
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cap = baseCap * textScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final sizeClass = theme.breakpoints.resolve(available);
        final baseMargin = margin ?? theme.spacing.marginFor(sizeClass);

        var horizontal = baseMargin;
        if (center && available.isFinite && available - 2 * baseMargin > cap) {
          horizontal = math.max(baseMargin, (available - cap) / 2);
        }

        Widget result = Padding(
          padding: EdgeInsetsDirectional.only(start: horizontal, end: horizontal),
          child: child,
        );
        if (safeArea) result = SafeArea(child: result);
        return result;
      },
    );
  }
}
