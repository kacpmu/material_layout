import 'package:flutter/foundation.dart';

import 'window_size_class.dart';

/// The set of width/height thresholds that map a window size onto a
/// [WindowSizeClass] / [WindowHeightSizeClass].
///
/// This is the **single, overridable source of truth** for breakpoints in the
/// package. The defaults ([Breakpoints.material]) match the Material 3 window
/// size classes (600 / 840 / 1200 / 1600 dp for width; 480 / 900 dp for
/// height). Override them with [copyWith] or by constructing your own.
///
/// Each value is the *inclusive lower bound* of the class it names — e.g.
/// [mediumMinWidth] is the smallest width considered [WindowSizeClass.medium].
/// Resolution uses half-open intervals (lower inclusive, upper exclusive).
@immutable
class Breakpoints {
  /// Creates a custom set of breakpoints.
  ///
  /// Thresholds must be strictly ascending; this is asserted in debug builds.
  const Breakpoints({
    this.mediumMinWidth = 600,
    this.expandedMinWidth = 840,
    this.largeMinWidth = 1200,
    this.extraLargeMinWidth = 1600,
    this.mediumMinHeight = 480,
    this.expandedMinHeight = 900,
  })  : assert(
          0 < mediumMinWidth &&
              mediumMinWidth < expandedMinWidth &&
              expandedMinWidth < largeMinWidth &&
              largeMinWidth < extraLargeMinWidth,
          'Width breakpoints must be strictly ascending and positive.',
        ),
        assert(
          0 < mediumMinHeight && mediumMinHeight < expandedMinHeight,
          'Height breakpoints must be strictly ascending and positive.',
        );

  /// The Material 3 default breakpoints: 600 / 840 / 1200 / 1600 dp (width) and
  /// 480 / 900 dp (height).
  const Breakpoints.material()
      : mediumMinWidth = 600,
        expandedMinWidth = 840,
        largeMinWidth = 1200,
        extraLargeMinWidth = 1600,
        mediumMinHeight = 480,
        expandedMinHeight = 900;

  /// Smallest width (inclusive) classified as [WindowSizeClass.medium]. `600`.
  final double mediumMinWidth;

  /// Smallest width (inclusive) classified as [WindowSizeClass.expanded]. `840`.
  final double expandedMinWidth;

  /// Smallest width (inclusive) classified as [WindowSizeClass.large]. `1200`.
  final double largeMinWidth;

  /// Smallest width (inclusive) classified as [WindowSizeClass.extraLarge].
  /// `1600`.
  final double extraLargeMinWidth;

  /// Smallest height (inclusive) classified as [WindowHeightSizeClass.medium].
  /// `480`.
  final double mediumMinHeight;

  /// Smallest height (inclusive) classified as
  /// [WindowHeightSizeClass.expanded]. `900`.
  final double expandedMinHeight;

  /// Classifies a [width] (in logical pixels) into a [WindowSizeClass].
  WindowSizeClass resolve(double width) {
    if (width < mediumMinWidth) return WindowSizeClass.compact;
    if (width < expandedMinWidth) return WindowSizeClass.medium;
    if (width < largeMinWidth) return WindowSizeClass.expanded;
    if (width < extraLargeMinWidth) return WindowSizeClass.large;
    return WindowSizeClass.extraLarge;
  }

  /// Classifies a [height] (in logical pixels) into a [WindowHeightSizeClass].
  WindowHeightSizeClass resolveHeight(double height) {
    if (height < mediumMinHeight) return WindowHeightSizeClass.compact;
    if (height < expandedMinHeight) return WindowHeightSizeClass.medium;
    return WindowHeightSizeClass.expanded;
  }

  /// Returns the inclusive lower-bound width for a given [sizeClass].
  double minWidthOf(WindowSizeClass sizeClass) => switch (sizeClass) {
        WindowSizeClass.compact => 0,
        WindowSizeClass.medium => mediumMinWidth,
        WindowSizeClass.expanded => expandedMinWidth,
        WindowSizeClass.large => largeMinWidth,
        WindowSizeClass.extraLarge => extraLargeMinWidth,
      };

  /// Returns a copy with the given fields replaced.
  Breakpoints copyWith({
    double? mediumMinWidth,
    double? expandedMinWidth,
    double? largeMinWidth,
    double? extraLargeMinWidth,
    double? mediumMinHeight,
    double? expandedMinHeight,
  }) {
    return Breakpoints(
      mediumMinWidth: mediumMinWidth ?? this.mediumMinWidth,
      expandedMinWidth: expandedMinWidth ?? this.expandedMinWidth,
      largeMinWidth: largeMinWidth ?? this.largeMinWidth,
      extraLargeMinWidth: extraLargeMinWidth ?? this.extraLargeMinWidth,
      mediumMinHeight: mediumMinHeight ?? this.mediumMinHeight,
      expandedMinHeight: expandedMinHeight ?? this.expandedMinHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Breakpoints &&
          other.mediumMinWidth == mediumMinWidth &&
          other.expandedMinWidth == expandedMinWidth &&
          other.largeMinWidth == largeMinWidth &&
          other.extraLargeMinWidth == extraLargeMinWidth &&
          other.mediumMinHeight == mediumMinHeight &&
          other.expandedMinHeight == expandedMinHeight;

  @override
  int get hashCode => Object.hash(
        mediumMinWidth,
        expandedMinWidth,
        largeMinWidth,
        extraLargeMinWidth,
        mediumMinHeight,
        expandedMinHeight,
      );

  @override
  String toString() => 'Breakpoints(width: $mediumMinWidth/$expandedMinWidth/'
      '$largeMinWidth/$extraLargeMinWidth, height: $mediumMinHeight/'
      '$expandedMinHeight)';
}
