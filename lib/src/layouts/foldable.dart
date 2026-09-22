import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// A vertical fold/hinge that splits the window into a left and right region.
@immutable
class VerticalFold {
  /// Creates a vertical fold descriptor (coordinates in window logical pixels).
  const VerticalFold({required this.start, required this.size});

  /// The leading edge of the hinge/fold, measured from the window's left.
  final double start;

  /// The thickness of the hinge (0 for a seamless fold).
  final double size;

  /// The trailing edge of the hinge/fold.
  double get end => start + size;
}

/// Returns the first vertical (left/right-splitting) fold or hinge among
/// [features] for a window of [windowSize], or `null` if none applies.
///
/// A feature qualifies when it is a [DisplayFeatureType.hinge] or
/// [DisplayFeatureType.fold] whose bounds run top-to-bottom and sit strictly
/// inside the window width (i.e. it separates a left pane from a right pane).
VerticalFold? verticalFoldFor(List<DisplayFeature> features, Size windowSize) {
  for (final feature in features) {
    final isFoldOrHinge =
        feature.type == DisplayFeatureType.hinge ||
        feature.type == DisplayFeatureType.fold;
    if (!isFoldOrHinge) continue;

    final bounds = feature.bounds;
    final isVertical =
        bounds.height >= windowSize.height * 0.5 &&
        bounds.left > 0 &&
        bounds.right < windowSize.width &&
        bounds.width <= bounds.height;
    if (isVertical) {
      return VerticalFold(start: bounds.left, size: bounds.width);
    }
  }
  return null;
}

/// Reads the ambient display features and returns the active [VerticalFold],
/// or `null`. Convenience wrapper over [verticalFoldFor] + [MediaQuery].
VerticalFold? verticalFoldOf(BuildContext context) {
  final mq = MediaQuery.of(context);
  return verticalFoldFor(mq.displayFeatures, mq.size);
}
