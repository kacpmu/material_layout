// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Where one pane sits along the main axis of a two-pane layout.
///
/// Positions are measured from the leading edge of the region, so they hold
/// for either text direction.
@immutable
class PaneSpan {
  /// Creates a pane span.
  const new({
    required this.start,
    required this.extent,
    required this.contentStart,
    required this.contentExtent,
  });

  /// The start of the space the pane occupies.
  final double start;

  /// The extent of the space the pane occupies; 0 when the pane is hidden.
  final double extent;

  /// The start of the pane's content.
  ///
  /// Differs from [start] while the pane enters or leaves: its content keeps
  /// its natural extent and slides, clipped to the occupied space.
  final double contentStart;

  /// The extent the pane's content is laid out at.
  final double contentExtent;

  /// The end of the space the pane occupies.
  double get end => start + extent;

  /// Whether the pane occupies any space.
  bool get isVisible => extent > 0;
}

/// The main-axis geometry of a two-pane layout.
@immutable
class PaneGeometry {
  /// Creates pane geometry.
  const new({
    required this.first,
    required this.second,
    required this.spacerStart,
    required this.spacerExtent,
    required this.handleCenter,
  });

  /// The leading, or top, pane.
  final PaneSpan first;

  /// The trailing, or bottom, pane.
  final PaneSpan second;

  /// The start of the spacer between the panes.
  final double spacerStart;

  /// The visible extent of the spacer; 0 when either pane is hidden.
  final double spacerExtent;

  /// The centre of the drag handle: the centre of the spacer while both
  /// panes show, and in the margin beside a pane the handle has hidden.
  final double handleCenter;
}

/// Resolves where two panes sit along the main axis.
///
/// A layout keeps its margins outside the panes or inside them. [outerStart]
/// and [outerEnd] are margins outside the panes, before the first and after
/// the second; the panes share [available], the space between the two.
/// [innerStart] and [innerEnd] are margins inside the panes, at the start of
/// the first and the end of the second, which the panes' extents already
/// include. A margin lies outside or inside, or partly each while a pane
/// that keeps the margins itself, holding a layout, comes or goes.
///
/// A pane with an extent is fixed; a pane without one is flexible and shares
/// the space left by [spacer] and the fixed pane by flex. With both
/// visibilities at 1, the panes and the spacer fill [available] exactly.
/// A visibility below 1 means the pane is entering or leaving: it
/// occupies that fraction of its natural extent, its content keeps the
/// natural extent and is aligned to the pane's edge beside the spacer, and
/// the other pane absorbs the difference. When both panes move at once, as
/// when one replaces the other, they share the difference, so the geometry
/// changes continuously. A visibility above 1 is a spring's overshoot and
/// grows the pane past its natural extent.
///
/// The spacer closes as either pane leaves, and the pane that stays takes
/// the whole space. A layout with a drag handle ([hasHandle]) rests the
/// handle in the middle of the margin beside a pane it hides, from where it
/// shows the pane again, or half a spacer from the edge where the margin is
/// narrower, over the pane that stays: the handle moves there from the middle
/// of the spacer as the pane leaves. It moves as far as [handlePresence]
/// says: fully while the handle shows, and as far as a pane that brings the
/// handle in with it has come.
PaneGeometry resolvePaneGeometry({
  required double available,
  required double outerStart,
  double outerEnd = 0,
  double innerStart = 0,
  double innerEnd = 0,
  required double spacer,
  bool hasHandle = false,
  double handlePresence = 1,
  double? firstExtent,
  double? secondExtent,
  double firstFlex = 1,
  double secondFlex = 1,
  double firstVisibility = 1,
  double secondVisibility = 1,
}) {
  final space = math.max(0.0, available);
  final va = math.max(0.0, firstVisibility);
  final vb = math.max(0.0, secondVisibility);
  final shared = math.max(0.0, space - spacer);

  // Natural extents: what each pane gets when both are fully shown.
  double na;
  double nb;
  if (firstExtent != null) {
    na = clampDouble(firstExtent, 0, shared);
    nb = shared - na;
  } else if (secondExtent != null) {
    nb = clampDouble(secondExtent, 0, shared);
    na = shared - nb;
  } else {
    final totalFlex = firstFlex + secondFlex;
    na = totalFlex > 0 ? shared * firstFlex / totalFlex : shared / 2;
    nb = shared - na;
  }

  // How much of each pane shows, and how far a spring carries it past that.
  final pa = math.min(va, 1.0);
  final pb = math.min(vb, 1.0);

  // The spacer closes as either pane leaves.
  final spacerExtent = math.min(spacer * math.min(pa, pb), space);
  final fill = space - spacerExtent;
  // How far the handle rests from the middle of the spacer. Beside a pane it
  // hides, it rests in the middle of the margin, or half a spacer from the
  // edge where the margin is narrower, and it moves there in step with the
  // pane, so that it keeps to a pointer that drags the pane away.
  var handleShift = 0.0;
  if (hasHandle) {
    final restStart = math.max(outerStart + innerStart, spacer) / 2;
    final restEnd = math.max(outerEnd + innerEnd, spacer) / 2;
    handleShift =
        ((1 - pa) * (restStart - outerStart) +
            (1 - pb) * (outerEnd - restEnd)) *
        clampDouble(handlePresence, 0, 1);
  }

  final overA = va - pa;
  final overB = vb - pb;
  double oa;
  double ob;
  if (pa <= 0 && pb <= 0) {
    oa = 0;
    ob = 0;
  } else {
    // Each pane occupies its share of its natural extent, and the space left
    // over goes to the panes by how settled they are: all of it to a pane
    // that shows fully beside one that is entering or leaving, and shared
    // while both move, so that the spacer moves continuously when one pane
    // replaces the other.
    final rest = fill - pa * na - pb * nb;
    final weightA = pa * (1 - pb);
    final weightB = pb * (1 - pa);
    final shareA = weightA + weightB > 0 ? weightA / (weightA + weightB) : 0.5;
    oa = pa * na + rest * shareA;
    // A pane carried past its natural extent takes the excess from the
    // other, in proportion to how much of the other shows.
    oa += overA * na * pb - overB * nb * pa;
    oa = clampDouble(oa, 0, fill);
    ob = fill - oa;
  }

  final ca = math.max(na, oa);
  final cb = math.max(nb, ob);
  final aStart = outerStart;
  final aEnd = aStart + oa;
  final bStart = aEnd + spacerExtent;

  return PaneGeometry(
    first: PaneSpan(
      start: aStart,
      extent: oa,
      contentStart: aEnd - ca,
      contentExtent: ca,
    ),
    second: PaneSpan(
      start: bStart,
      extent: ob,
      contentStart: bStart,
      contentExtent: cb,
    ),
    spacerStart: aEnd,
    spacerExtent: spacerExtent,
    handleCenter: clampDouble(
      aEnd + spacerExtent / 2 + handleShift,
      0,
      outerStart + space + outerEnd,
    ),
  );
}
