// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A width at which a layout changes to match the space available.
///
/// Five exist. [Breakpoints.forWidth] resolves a width to one of them using
/// half-open intervals: the lower bound is inclusive, the upper exclusive.
/// The widths below are the defaults; [Breakpoints] retunes them.
///
/// Breakpoints compare in size order, so a layout can test a range:
///
/// ```dart
/// if (breakpoint >= Breakpoint.expanded) {
///   // Two panes are the default here.
/// }
/// ```
enum Breakpoint implements Comparable<Breakpoint> {
  /// Narrower than 600dp: a phone in portrait.
  compact,

  /// From 600dp up to 840dp: a tablet or foldable in portrait.
  medium,

  /// From 840dp up to 1200dp: a phone or tablet in landscape, or a desktop.
  expanded,

  /// From 1200dp up to 1600dp: a desktop.
  large,

  /// 1600dp and wider: a desktop or an ultra-wide monitor.
  extraLarge;

  /// The margin between the edge of the window and its content, applied on
  /// the leading and trailing edges.
  ///
  /// 16dp at [compact] and 24dp at every other breakpoint.
  double get margin => this == compact ? 16 : 24;

  /// The default width of a fixed pane, or null where no fixed pane exists.
  ///
  /// 360dp at [expanded] and 412dp at [large] and [extraLarge]. A compact
  /// layout has one pane, and a medium layout with two panes splits
  /// them evenly, so neither has a fixed pane.
  double? get fixedPaneWidth => switch (this) {
    compact || medium => null,
    expanded => 360,
    large || extraLarge => 412,
  };

  @override
  int compareTo(Breakpoint other) => index - other.index;

  /// Whether this breakpoint is narrower than [other].
  bool operator <(Breakpoint other) => index < other.index;

  /// Whether this breakpoint is narrower than or the same as [other].
  bool operator <=(Breakpoint other) => index <= other.index;

  /// Whether this breakpoint is wider than [other].
  bool operator >(Breakpoint other) => index > other.index;

  /// Whether this breakpoint is wider than or the same as [other].
  bool operator >=(Breakpoint other) => index >= other.index;
}

/// A height at which a layout may change.
///
/// Height is classified independently of width. It rarely drives a layout,
/// because most content scrolls vertically; use it only where vertical space
/// is unusually small or large. The heights below are the defaults;
/// [Breakpoints] retunes them.
enum HeightBreakpoint implements Comparable<HeightBreakpoint> {
  /// Shorter than 480dp: a phone in landscape.
  compact,

  /// From 480dp up to 900dp.
  medium,

  /// 900dp and taller.
  expanded;

  @override
  int compareTo(HeightBreakpoint other) => index - other.index;

  /// Whether this breakpoint is shorter than [other].
  bool operator <(HeightBreakpoint other) => index < other.index;

  /// Whether this breakpoint is shorter than or the same as [other].
  bool operator <=(HeightBreakpoint other) => index <= other.index;

  /// Whether this breakpoint is taller than [other].
  bool operator >(HeightBreakpoint other) => index > other.index;

  /// Whether this breakpoint is taller than or the same as [other].
  bool operator >=(HeightBreakpoint other) => index >= other.index;
}

/// The widths and heights at which one breakpoint gives way to the next.
///
/// Each value is the inclusive lower bound of its breakpoint.
/// The defaults are the Material 3 values; an app retunes them for a subtree
/// through `MaterialLayoutThemeData.breakpoints`:
///
/// ```dart
/// const Breakpoints(mediumMinWidth: 640, expandedMinWidth: 900)
/// ```
@immutable
final class Breakpoints with Diagnosticable {
  /// Creates breakpoint thresholds, in logical pixels.
  ///
  /// Width thresholds must be positive and ascending, as must the height
  /// thresholds.
  const new({
    this.mediumMinWidth = 600,
    this.expandedMinWidth = 840,
    this.largeMinWidth = 1200,
    this.extraLargeMinWidth = 1600,
    this.mediumMinHeight = 480,
    this.expandedMinHeight = 900,
  }) : assert(0 < mediumMinWidth),
       assert(mediumMinWidth < expandedMinWidth),
       assert(expandedMinWidth < largeMinWidth),
       assert(largeMinWidth < extraLargeMinWidth),
       assert(0 < mediumMinHeight),
       assert(mediumMinHeight < expandedMinHeight);

  /// The narrowest width that resolves to [Breakpoint.medium].
  final double mediumMinWidth;

  /// The narrowest width that resolves to [Breakpoint.expanded].
  final double expandedMinWidth;

  /// The narrowest width that resolves to [Breakpoint.large].
  final double largeMinWidth;

  /// The narrowest width that resolves to [Breakpoint.extraLarge].
  final double extraLargeMinWidth;

  /// The shortest height that resolves to [HeightBreakpoint.medium].
  final double mediumMinHeight;

  /// The shortest height that resolves to [HeightBreakpoint.expanded].
  final double expandedMinHeight;

  /// The breakpoint that [width] falls in.
  Breakpoint forWidth(double width) {
    if (width < mediumMinWidth) return Breakpoint.compact;
    if (width < expandedMinWidth) return Breakpoint.medium;
    if (width < largeMinWidth) return Breakpoint.expanded;
    if (width < extraLargeMinWidth) return Breakpoint.large;
    return Breakpoint.extraLarge;
  }

  /// The height breakpoint that [height] falls in.
  HeightBreakpoint forHeight(double height) {
    if (height < mediumMinHeight) return HeightBreakpoint.compact;
    if (height < expandedMinHeight) return HeightBreakpoint.medium;
    return HeightBreakpoint.expanded;
  }

  /// Creates a copy of these breakpoints with the given fields replaced.
  Breakpoints copyWith({
    double? mediumMinWidth,
    double? expandedMinWidth,
    double? largeMinWidth,
    double? extraLargeMinWidth,
    double? mediumMinHeight,
    double? expandedMinHeight,
  }) => Breakpoints(
    mediumMinWidth: mediumMinWidth ?? this.mediumMinWidth,
    expandedMinWidth: expandedMinWidth ?? this.expandedMinWidth,
    largeMinWidth: largeMinWidth ?? this.largeMinWidth,
    extraLargeMinWidth: extraLargeMinWidth ?? this.extraLargeMinWidth,
    mediumMinHeight: mediumMinHeight ?? this.mediumMinHeight,
    expandedMinHeight: expandedMinHeight ?? this.expandedMinHeight,
  );

  @override
  bool operator ==(Object other) =>
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mediumMinWidth', mediumMinWidth))
      ..add(DoubleProperty('expandedMinWidth', expandedMinWidth))
      ..add(DoubleProperty('largeMinWidth', largeMinWidth))
      ..add(DoubleProperty('extraLargeMinWidth', extraLargeMinWidth))
      ..add(DoubleProperty('mediumMinHeight', mediumMinHeight))
      ..add(DoubleProperty('expandedMinHeight', expandedMinHeight));
  }
}
