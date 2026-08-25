import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import 'breakpoints.dart';
import 'window_size_class.dart';

/// An immutable snapshot of the current window size together with its resolved
/// width and height size classes.
///
/// Obtain one from [BuildContext.windowSize], an [AdaptiveBuilder], or
/// [WindowSize.fromSize].
@immutable
class WindowSize {
  /// Creates a window size with explicit classes (mainly for tests).
  const WindowSize({
    required this.size,
    required this.widthClass,
    required this.heightClass,
  });

  /// Resolves [size] against [breakpoints] to produce a [WindowSize].
  factory WindowSize.fromSize(Size size, Breakpoints breakpoints) {
    return WindowSize(
      size: size,
      widthClass: breakpoints.resolve(size.width),
      heightClass: breakpoints.resolveHeight(size.height),
    );
  }

  /// The raw size (logical pixels) this snapshot was resolved from.
  final Size size;

  /// The resolved width size class.
  final WindowSizeClass widthClass;

  /// The resolved height size class.
  final WindowHeightSizeClass heightClass;

  /// The width in logical pixels.
  double get width => size.width;

  /// The height in logical pixels.
  double get height => size.height;

  /// Whether the width class is at least [other] (inclusive).
  bool isAtLeast(WindowSizeClass other) => widthClass.isAtLeast(other);

  /// Whether the width class is [WindowSizeClass.compact].
  bool get isCompact => widthClass.isCompact;

  /// Whether the width class is [WindowSizeClass.medium].
  bool get isMedium => widthClass.isMedium;

  /// Whether the width class is [WindowSizeClass.expanded].
  bool get isExpanded => widthClass.isExpanded;

  /// Whether the width class is [WindowSizeClass.large].
  bool get isLarge => widthClass.isLarge;

  /// Whether the width class is [WindowSizeClass.extraLarge].
  bool get isExtraLarge => widthClass.isExtraLarge;

  /// Whether the height class is [WindowHeightSizeClass.compact] — e.g. a
  /// phone held in landscape. Useful for forcing a bottom bar over a tall rail.
  bool get isCompactHeight => heightClass.isCompact;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowSize &&
          other.size == size &&
          other.widthClass == widthClass &&
          other.heightClass == heightClass;

  @override
  int get hashCode => Object.hash(size, widthClass, heightClass);

  @override
  String toString() =>
      'WindowSize(${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}, '
      'width: ${widthClass.name}, height: ${heightClass.name})';
}
