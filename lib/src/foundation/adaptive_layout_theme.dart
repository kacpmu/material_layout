import 'package:flutter/widgets.dart';

import '../spacing/spacing.dart';
import 'breakpoints.dart';

/// The resolved configuration for the adaptive layout package: [breakpoints],
/// [spacing], and the [bodyMaxWidth] content cap.
///
/// Provide one above your app with [AdaptiveLayoutTheme] to customise defaults
/// for an entire subtree. When none is provided, [AdaptiveLayoutThemeData.material]
/// is used.
@immutable
class AdaptiveLayoutThemeData {
  /// Creates a configuration. Any omitted field falls back to its Material 3
  /// default.
  const AdaptiveLayoutThemeData({
    this.breakpoints = const Breakpoints.material(),
    this.spacing = const AdaptiveSpacing.material(),
    this.bodyMaxWidth = 720,
  });

  /// The Material 3 defaults.
  const AdaptiveLayoutThemeData.material()
      : breakpoints = const Breakpoints.material(),
        spacing = const AdaptiveSpacing.material(),
        bodyMaxWidth = 720;

  /// The window size class breakpoints.
  final Breakpoints breakpoints;

  /// Spacing tokens and size-class margins.
  final AdaptiveSpacing spacing;

  /// The maximum width (logical pixels) that an [AdaptiveBody] constrains its
  /// content to before centering it. Keeps content readable on wide displays.
  ///
  /// Defaults to 720. Material 3 states the goal as a measure, not a width —
  /// "adjust margins and type styles to keep text between 40–60 characters per
  /// line" — and the right dp value therefore depends on your type scale. 720
  /// is a deliberate compromise: comfortable for mixed content (text beside
  /// media, grids, forms), while far closer to a readable measure than a
  /// full-bleed body. **For pages that are mostly prose, pass a narrower
  /// `maxWidth` to [AdaptiveBody]** — around 500–600 lands inside 40–60
  /// characters at the default body style.
  final double bodyMaxWidth;

  /// Returns a copy with the given fields replaced.
  AdaptiveLayoutThemeData copyWith({
    Breakpoints? breakpoints,
    AdaptiveSpacing? spacing,
    double? bodyMaxWidth,
  }) {
    return AdaptiveLayoutThemeData(
      breakpoints: breakpoints ?? this.breakpoints,
      spacing: spacing ?? this.spacing,
      bodyMaxWidth: bodyMaxWidth ?? this.bodyMaxWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveLayoutThemeData &&
          other.breakpoints == breakpoints &&
          other.spacing == spacing &&
          other.bodyMaxWidth == bodyMaxWidth;

  @override
  int get hashCode => Object.hash(breakpoints, spacing, bodyMaxWidth);
}

/// Provides an [AdaptiveLayoutThemeData] to its subtree.
///
/// Read it with `AdaptiveLayoutTheme.of(context)` or the
/// `context.adaptiveTheme` extension. If no ancestor is present, a default
/// Material 3 configuration is returned.
class AdaptiveLayoutTheme extends InheritedWidget {
  /// Creates an adaptive layout theme.
  const AdaptiveLayoutTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The configuration exposed to descendants.
  final AdaptiveLayoutThemeData data;

  /// The default configuration used when no [AdaptiveLayoutTheme] is in scope.
  static const AdaptiveLayoutThemeData fallback = AdaptiveLayoutThemeData.material();

  /// Returns the nearest [AdaptiveLayoutThemeData], or [fallback] if none.
  static AdaptiveLayoutThemeData of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<AdaptiveLayoutTheme>();
    return widget?.data ?? fallback;
  }

  /// Returns the nearest [AdaptiveLayoutThemeData], or `null` if none.
  static AdaptiveLayoutThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveLayoutTheme>()
        ?.data;
  }

  @override
  bool updateShouldNotify(AdaptiveLayoutTheme oldWidget) =>
      data != oldWidget.data;
}
