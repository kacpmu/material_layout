// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/margins.dart';
import 'pane_geometry.dart';

/// The place of a child in a [PaneLayout].
enum PaneLayoutSlot {
  /// The leading, or top, pane.
  first,

  /// The trailing, or bottom, pane.
  second,

  /// The drag handle, centred on the spacer.
  handle,
}

/// The extent of the box a drag handle is given across the spacer: the 48dp
/// minimum target.
///
/// The handle takes input only on its target: the spacer, along its whole
/// length, and a square of this extent around the handle's centre.
const double handleTargetExtent = 48;

/// How a [PaneLayout] arranges its panes: along an axis, with margins on
/// the leading and trailing edges kept around the panes or within them, a
/// spacer between the panes, and whether it keeps room for a drag handle on
/// the spacer.
typedef PaneLayoutSettings = ({
  Axis axis,
  double marginStart,
  double marginEnd,
  MarginPlacement marginPlacement,
  double spacer,
  bool hasHandle,
});

/// Resolves where the panes of a [PaneLayout] of [size] sit along its axis.
///
/// The layout resolves its geometry here, and so does a widget that needs to
/// know where the panes rest, so that the two agree.
///
/// A pane that [firstHoldsLayout] or [secondHoldsLayout] says holds a layout
/// keeps the margins it meets within it, for that layout to keep, wherever
/// the settings keep the margins.
PaneGeometry resolvePaneLayout(
  PaneLayoutSettings settings, {
  required Size size,
  double handlePresence = 1,
  double? firstExtent,
  double? secondExtent,
  double firstFlex = 1,
  double secondFlex = 1,
  bool firstHoldsLayout = false,
  bool secondHoldsLayout = false,
  required double firstVisibility,
  required double secondVisibility,
}) {
  final horizontal = settings.axis == Axis.horizontal;
  final mainExtent = horizontal ? size.width : size.height;
  if (!horizontal) {
    // Margins lie along the main axis of a horizontal layout only.
    return resolvePaneGeometry(
      available: mainExtent,
      outerStart: 0,
      spacer: settings.spacer,
      hasHandle: settings.hasHandle,
      handlePresence: handlePresence,
      firstExtent: firstExtent,
      secondExtent: secondExtent,
      firstFlex: firstFlex,
      secondFlex: secondFlex,
      firstVisibility: firstVisibility,
      secondVisibility: secondVisibility,
    );
  }
  // Each margin lies within the pane that meets its edge where that pane
  // keeps the margins within it, and around the panes otherwise. The pane
  // that meets an edge changes as the panes come and go, and the margin
  // moves from around the panes to within them with it.
  final inside = settings.marginPlacement == MarginPlacement.inside;
  final firstWithin = inside || firstHoldsLayout ? 1.0 : 0.0;
  final secondWithin = inside || secondHoldsLayout ? 1.0 : 0.0;
  final shownFirst = clampDouble(firstVisibility, 0, 1);
  final shownSecond = clampDouble(secondVisibility, 0, 1);
  final innerStart =
      settings.marginStart *
      (secondWithin + (firstWithin - secondWithin) * shownFirst);
  final innerEnd =
      settings.marginEnd *
      (firstWithin + (secondWithin - firstWithin) * shownSecond);
  final outerStart = settings.marginStart - innerStart;
  final outerEnd = settings.marginEnd - innerEnd;
  return resolvePaneGeometry(
    available: mainExtent - outerStart - outerEnd,
    outerStart: outerStart,
    outerEnd: outerEnd,
    innerStart: innerStart,
    innerEnd: innerEnd,
    spacer: settings.spacer,
    hasHandle: settings.hasHandle,
    handlePresence: handlePresence,
    firstExtent: firstExtent,
    secondExtent: secondExtent,
    firstFlex: firstFlex,
    secondFlex: secondFlex,
    firstVisibility: firstVisibility,
    secondVisibility: secondVisibility,
  );
}

/// Parent data for the children of a [RenderPaneLayout].
class PaneLayoutParentData extends ContainerBoxParentData<RenderBox> {
  /// The child's place in the layout.
  PaneLayoutSlot slot = PaneLayoutSlot.first;

  /// The natural extent of a fixed pane, or null for a flexible pane.
  double? extent;

  /// Replaces [extent] while it holds a value: during a drag, and while the
  /// spacer settles.
  ValueListenable<double?>? extentOverride;

  /// The share of a flexible pane when both panes are flexible.
  double flex = 1;

  /// How much of the pane shows: 0 hidden, 1 shown.
  Animation<double> visibility = kAlwaysCompleteAnimation;

  /// The corners of the pane as the app paints it, which the pane keeps
  /// while it is clipped to the space it occupies.
  BorderRadiusGeometry borderRadius = BorderRadius.zero;

  /// Whether the drag handle comes in with the pane, which is entering: the
  /// handle moves with the pane as far as it has come. Otherwise the handle
  /// rests beside the pane.
  bool bringsHandle = false;

  /// Whether the pane holds a layout, which keeps the margins the pane meets
  /// itself: the pane then reaches the edges wherever the margins are kept.
  bool holdsLayout = false;

  /// Whether the drag handle keeps the place it last had rather than follow
  /// the panes, as it does while it fades out with a pane that goes.
  bool staysInPlace = false;

  Rect _occupied = Rect.zero;
}

/// Configures a child of a [PaneLayout].
class PaneLayoutChild extends ParentDataWidget<PaneLayoutParentData> {
  /// Places [child] in [slot].
  const new({
    super.key,
    required this.slot,
    this.extent,
    this.extentOverride,
    this.flex = 1,
    this.visibility = kAlwaysCompleteAnimation,
    this.borderRadius = BorderRadius.zero,
    this.bringsHandle = false,
    this.holdsLayout = false,
    this.staysInPlace = false,
    required super.child,
  });

  /// The child's place in the layout.
  final PaneLayoutSlot slot;

  /// The natural extent of a fixed pane, or null for a flexible pane.
  final double? extent;

  /// Replaces [extent] while it holds a value.
  final ValueListenable<double?>? extentOverride;

  /// The share of a flexible pane when both panes are flexible.
  final double flex;

  /// How much of the pane shows.
  final Animation<double> visibility;

  /// The corners of the pane as the app paints it.
  final BorderRadiusGeometry borderRadius;

  /// Whether the drag handle comes in with the pane.
  final bool bringsHandle;

  /// Whether the pane holds a layout, which keeps the margins itself.
  final bool holdsLayout;

  /// Whether the drag handle keeps the place it last had.
  final bool staysInPlace;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as PaneLayoutParentData;
    if (data.borderRadius != borderRadius) {
      data.borderRadius = borderRadius;
      renderObject.parent?.markNeedsPaint();
    }
    if (data.slot == slot &&
        data.extent == extent &&
        data.extentOverride == extentOverride &&
        data.flex == flex &&
        data.visibility == visibility &&
        data.bringsHandle == bringsHandle &&
        data.holdsLayout == holdsLayout &&
        data.staysInPlace == staysInPlace) {
      return;
    }
    data
      ..slot = slot
      ..extent = extent
      ..extentOverride = extentOverride
      ..flex = flex
      ..visibility = visibility
      ..bringsHandle = bringsHandle
      ..holdsLayout = holdsLayout
      ..staysInPlace = staysInPlace;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PaneLayout;
}

/// A widget that lays out two panes along an axis, with margins, a spacer
/// between them and an optional drag handle on the spacer.
///
/// Margins apply to the leading and trailing edges only: along the
/// main axis of a horizontal layout, across it for a vertical one. Kept
/// within the panes, they leave the panes the whole region, and the extents
/// the panes are given include them. The panes animate through their
/// visibility without rebuilding: [relayout] notifies whenever an extent
/// override or a visibility changes.
class PaneLayout extends MultiChildRenderObjectWidget {
  /// Creates a pane layout.
  const new({
    super.key,
    required this.settings,
    required this.relayout,
    super.children,
  });

  /// How the panes are arranged.
  final PaneLayoutSettings settings;

  /// Notifies when an extent or a visibility changes: the same listenable
  /// for as long as the layout lasts.
  final Listenable relayout;

  @override
  RenderPaneLayout createRenderObject(BuildContext context) => RenderPaneLayout(
    settings: settings,
    textDirection: Directionality.of(context),
    relayout: relayout,
  );

  @override
  void updateRenderObject(BuildContext context, RenderPaneLayout renderObject) {
    assert(
      identical(relayout, renderObject.relayout),
      'A pane layout keeps the listenable it was created with.',
    );
    renderObject
      ..settings = settings
      ..textDirection = Directionality.of(context);
  }
}

/// The render object of a [PaneLayout].
class RenderPaneLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, PaneLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, PaneLayoutParentData> {
  /// Creates a pane layout render object.
  new({
    required this._settings,
    required this._textDirection,
    required this.relayout,
  });

  /// How the panes are arranged.
  PaneLayoutSettings get settings => _settings;
  PaneLayoutSettings _settings;
  set settings(PaneLayoutSettings value) {
    if (value == _settings) return;
    _settings = value;
    markNeedsLayout();
  }

  /// The direction that decides which edge is leading.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Notifies when an extent or a visibility changes.
  final Listenable relayout;

  /// The geometry of the last layout.
  PaneGeometry? get geometry => _geometry;
  PaneGeometry? _geometry;

  final _clips = <PaneLayoutSlot, LayerHandle<ClipRRectLayer>>{
    PaneLayoutSlot.first: LayerHandle<ClipRRectLayer>(),
    PaneLayoutSlot.second: LayerHandle<ClipRRectLayer>(),
  };

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    relayout.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    relayout.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void dispose() {
    for (final clip in _clips.values) {
      clip.layer = null;
    }
    super.dispose();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! PaneLayoutParentData) {
      child.parentData = PaneLayoutParentData();
    }
  }

  PaneLayoutParentData? _dataFor(PaneLayoutSlot slot) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as PaneLayoutParentData;
      if (data.slot == slot) return data;
      child = data.nextSibling;
    }
    return null;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth && constraints.hasBoundedHeight,
      'A pane layout needs bounded constraints: it divides the space it is '
      'given between its panes.',
    );
    size = constraints.biggest;
    final settings = _settings;
    final horizontal = settings.axis == Axis.horizontal;

    final first = _dataFor(PaneLayoutSlot.first);
    final second = _dataFor(PaneLayoutSlot.second);
    // The handle's room is open as far as the panes that bring it show.
    double presenceOf(PaneLayoutParentData? data) => data == null
        ? 0
        : data.bringsHandle
        ? data.visibility.value
        : 1;
    final geometry = resolvePaneLayout(
      settings,
      size: size,
      handlePresence: math.min(presenceOf(first), presenceOf(second)),
      firstExtent: first?.extentOverride?.value ?? first?.extent,
      secondExtent: second?.extentOverride?.value ?? second?.extent,
      firstFlex: first?.flex ?? 1,
      secondFlex: second?.flex ?? 1,
      firstHoldsLayout: first?.holdsLayout ?? false,
      secondHoldsLayout: second?.holdsLayout ?? false,
      firstVisibility: first?.visibility.value ?? 0,
      secondVisibility: second?.visibility.value ?? 0,
    );
    _geometry = geometry;

    final rtl = textDirection == TextDirection.rtl;
    // A vertical layout sets its panes in across its axis, unless they keep
    // the margins within them.
    Rect rect(double start, double extent, {bool setIn = false}) {
      if (!horizontal) {
        final crossStart = setIn ? settings.marginStart : 0.0;
        final crossEnd = setIn ? settings.marginEnd : 0.0;
        return Rect.fromLTWH(
          rtl ? crossEnd : crossStart,
          start,
          math.max(0.0, size.width - crossStart - crossEnd),
          extent,
        );
      }
      final left = rtl ? size.width - start - extent : start;
      return Rect.fromLTWH(left, 0, extent, size.height);
    }

    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as PaneLayoutParentData;
      if (data.slot == PaneLayoutSlot.handle &&
          data.staysInPlace &&
          !data._occupied.isEmpty) {
        // Fading out with a pane that goes, the handle stays where it was.
        child.layout(BoxConstraints.tight(data._occupied.size));
      } else if (data.slot == PaneLayoutSlot.handle) {
        // The grip is drawn at the middle of the box. Resting in a margin
        // at the edge, the box reaches past the layout, where it takes no
        // input.
        final box = rect(
          geometry.handleCenter - handleTargetExtent / 2,
          handleTargetExtent,
        );
        child.layout(BoxConstraints.tight(box.size));
        data
          ..offset = box.topLeft
          .._occupied = box;
        final center = rect(geometry.handleCenter, 0).center;
        _handleTarget = (
          spacer: rect(geometry.spacerStart, geometry.spacerExtent),
          square: Rect.fromCenter(
            center: center,
            width: handleTargetExtent,
            height: handleTargetExtent,
          ),
        );
      } else {
        final span = data.slot == PaneLayoutSlot.first
            ? geometry.first
            : geometry.second;
        final setIn =
            settings.marginPlacement == MarginPlacement.outside &&
            !data.holdsLayout;
        final content = rect(
          span.contentStart,
          span.contentExtent,
          setIn: setIn,
        );
        child.layout(BoxConstraints.tight(content.size));
        data
          ..offset = content.topLeft
          .._occupied = span.isVisible
              ? rect(span.start, span.extent, setIn: setIn)
              : Rect.zero;
      }
      child = data.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as PaneLayoutParentData;
      if (data.slot == PaneLayoutSlot.handle) {
        context.paintChild(child, data.offset + offset);
      } else {
        _paintPane(context, offset, child, data);
      }
      child = data.nextSibling;
    }
  }

  void _paintPane(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    PaneLayoutParentData data,
  ) {
    final clip = _clips[data.slot]!;
    final content = data.offset & child.size;
    if (data._occupied.isEmpty ||
        data._occupied.contains(content.topLeft) &&
            data._occupied.contains(content.bottomRight - const Offset(1, 1))) {
      clip.layer = null;
      if (!data._occupied.isEmpty) {
        context.paintChild(child, data.offset + offset);
      }
      return;
    }
    // A pane that enters, leaves or is narrower than its content is clipped
    // to the space it occupies, and keeps its corners where it is cut, so
    // that a card keeps its shape while it moves. The content's own corners
    // show on the edge where it is not cut.
    final rounded = _cutCorners(
      data._occupied,
      content,
      data.borderRadius.resolve(textDirection),
    );
    clip.layer = context.pushClipRRect(
      needsCompositing,
      offset,
      data._occupied,
      rounded ?? RRect.fromRectAndRadius(data._occupied, Radius.zero),
      (context, offset) => context.paintChild(child, data.offset + offset),
      clipBehavior: rounded == null ? Clip.hardEdge : Clip.antiAlias,
      oldLayer: clip.layer,
    );
  }

  // The occupied space with rounded corners on the edges that cut into the
  // content, or null where no corner is rounded. A corner is never narrower
  // than the space allows, so a thin sliver of a pane stays rounded rather
  // than having its corners scaled down.
  static RRect? _cutCorners(Rect occupied, Rect content, BorderRadius radius) {
    if (radius == BorderRadius.zero) return null;
    final left = content.left < occupied.left - 0.5;
    final right = content.right > occupied.right + 0.5;
    final top = content.top < occupied.top - 0.5;
    final bottom = content.bottom > occupied.bottom + 0.5;
    if (!left && !right && !top && !bottom) return null;
    final topLeft = left || top;
    final topRight = right || top;
    final bottomLeft = left || bottom;
    final bottomRight = right || bottom;
    // Two rounded corners share the edge between them.
    final width = occupied.width;
    final height = occupied.height;
    Radius corner(
      Radius radius, {
      required bool rounded,
      required bool sharesRow,
      required bool sharesColumn,
    }) => rounded
        ? Radius.elliptical(
            math.min(radius.x, sharesRow ? width / 2 : width),
            math.min(radius.y, sharesColumn ? height / 2 : height),
          )
        : Radius.zero;
    return RRect.fromRectAndCorners(
      occupied,
      topLeft: corner(
        radius.topLeft,
        rounded: topLeft,
        sharesRow: topRight,
        sharesColumn: bottomLeft,
      ),
      topRight: corner(
        radius.topRight,
        rounded: topRight,
        sharesRow: topLeft,
        sharesColumn: bottomRight,
      ),
      bottomLeft: corner(
        radius.bottomLeft,
        rounded: bottomLeft,
        sharesRow: bottomRight,
        sharesColumn: topLeft,
      ),
      bottomRight: corner(
        radius.bottomRight,
        rounded: bottomRight,
        sharesRow: bottomLeft,
        sharesColumn: topRight,
      ),
    );
  }

  // Where the drag handle takes input: whatever the handle's own
  // widgets claim, the panes beside it keep theirs.
  ({Rect spacer, Rect square}) _handleTarget = (
    spacer: Rect.zero,
    square: Rect.zero,
  );

  bool _hits(PaneLayoutParentData data, Offset position) {
    if (!data._occupied.contains(position)) return false;
    if (data.slot != PaneLayoutSlot.handle) return true;
    return _handleTarget.spacer.contains(position) ||
        _handleTarget.square.contains(position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as PaneLayoutParentData;
      if (_hits(data, position)) {
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) =>
              child!.hitTest(result, position: transformed),
        );
        if (hit) return true;
      }
      child = data.previousSibling;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as PaneLayoutParentData;
      if (!data._occupied.isEmpty) visitor(child);
      child = data.nextSibling;
    }
  }

  @override
  Rect? describeSemanticsClip(RenderObject? child) {
    final data = child?.parentData;
    if (data is! PaneLayoutParentData) return null;
    return data._occupied;
  }
}
