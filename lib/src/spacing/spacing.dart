import 'package:flutter/foundation.dart';

import '../foundation/window_size_class.dart';

/// Material 3 spacing tokens and size-class-aware margins.
///
/// Layout spacing in Material 3 aligns to an 8dp grid (with a finer 4dp grid
/// for icon/typography alignment). The static `space*` constants expose that
/// scale; the instance fields ([compactMargin], [mediumMargin], [paneGutter])
/// carry the values an [AdaptiveLayoutThemeData] uses for body margins and the
/// gap between panes.
@immutable
class AdaptiveSpacing {
  /// Creates a custom spacing configuration.
  const AdaptiveSpacing({
    this.compactMargin = 16,
    this.mediumMargin = 24,
    this.paneGutter = 24,
  });

  /// The Material 3 defaults: 16dp compact margin, 24dp medium+ margin, 24dp
  /// pane gutter.
  const AdaptiveSpacing.material()
    : compactMargin = 16,
      mediumMargin = 24,
      paneGutter = 24;

  // --- 8dp baseline grid (4dp fine grid) ---

  /// 4dp — fine alignment (icon padding, type baselines).
  static const double space1 = 4;

  /// 8dp — the baseline grid unit.
  static const double space2 = 8;

  /// 12dp.
  static const double space3 = 12;

  /// 16dp.
  static const double space4 = 16;

  /// 24dp.
  static const double space6 = 24;

  /// 32dp.
  static const double space8 = 32;

  /// 48dp.
  static const double space12 = 48;

  /// Body edge margin for [WindowSizeClass.compact]. Defaults to 16dp.
  final double compactMargin;

  /// Body edge margin for [WindowSizeClass.medium] and wider. Defaults to 24dp.
  final double mediumMargin;

  /// The gap placed between two adjacent panes. Defaults to 24dp.
  final double paneGutter;

  /// Returns the recommended body edge margin for [sizeClass]:
  /// [compactMargin] for compact, otherwise [mediumMargin].
  double marginFor(WindowSizeClass sizeClass) =>
      sizeClass.isCompact ? compactMargin : mediumMargin;

  /// Returns a copy with the given fields replaced.
  AdaptiveSpacing copyWith({
    double? compactMargin,
    double? mediumMargin,
    double? paneGutter,
  }) {
    return AdaptiveSpacing(
      compactMargin: compactMargin ?? this.compactMargin,
      mediumMargin: mediumMargin ?? this.mediumMargin,
      paneGutter: paneGutter ?? this.paneGutter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveSpacing &&
          other.compactMargin == compactMargin &&
          other.mediumMargin == mediumMargin &&
          other.paneGutter == paneGutter;

  @override
  int get hashCode => Object.hash(compactMargin, mediumMargin, paneGutter);
}
