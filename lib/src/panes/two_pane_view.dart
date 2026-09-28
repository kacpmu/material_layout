// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/rendering.dart' show SemanticsService;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../foundation/localizations.dart';
import '../foundation/margins.dart';
import '../foundation/motion.dart';
import '../foundation/resting_width.dart';
import '../foundation/theme.dart';
import 'pane_geometry.dart';
import 'pane_layout.dart';
import 'pane_resizer.dart';
import 'pane_split.dart';

/// One pane of a [TwoPaneView].
@immutable
class PaneConfig {
  /// Describes a pane showing [child].
  const new({
    required this.child,
    this.id,
    this.visible = true,
    this.maintainState = true,
    this.flex = 1,
    this.keepsMargins = true,
    this.holdsLayout = false,
  });

  /// The pane's content.
  final Widget child;

  /// Whether the pane holds a layout of this package, given as the pane
  /// itself, which keeps the margins the pane meets.
  ///
  /// Wherever the view keeps its margins, the pane then reaches the edges it
  /// meets, and its content is told the margins there, as within the panes:
  /// the layout inside keeps them itself, around its own panes or within
  /// them, and its drag handle can rest in them.
  final bool holdsLayout;

  /// Whether the pane's content keeps the margins when the view keeps them
  /// within the panes: false for a pane whose own padding keeps its content
  /// clear of the edges, such as a side sheet, which then reaches the edge
  /// at its own width.
  final bool keepsMargins;

  /// Identifies the pane, so that its content keeps its state when the panes
  /// change places; null to identify the pane by its place.
  final Object? id;

  /// Whether the pane shows. A change animates the pane in or out.
  final bool visible;

  /// Whether the content stays mounted while the pane is hidden.
  final bool maintainState;

  /// The pane's share of the space when neither pane is resizable.
  final double flex;
}

/// How a [TwoPaneView] divides its space between a resizable pane and the
/// other one.
///
/// Extents are the widths of the panes' content: a pane that keeps a margin
/// within it is wider by the margin.
@immutable
class SplitConfig {
  /// Describes the split.
  const new({
    required this.resizable,
    required this.stops,
    this.defaultExtent,
    this.even = false,
    this.minExtent = 0,
    this.maxExtent = double.infinity,
    this.otherMinExtent = 0,
    this.otherMinShare = 0,
    this.center,
    this.locked = false,
    this.handle,
    this.controller,
    this.memory = PaneResizeMemory.persistent,
    this.resetToken,
    this.collapse = PaneCollapse.never,
    this.otherCollapse = PaneCollapse.never,
    this.onDismissed,
    this.onOtherDismissed,
    this.hidesPanes = true,
  }) : assert(resizable != PaneLayoutSlot.handle),
       assert(collapse != PaneCollapse.dismiss || onDismissed != null),
       assert(
         otherCollapse != PaneCollapse.dismiss || onOtherDismissed != null,
       );

  /// The pane the split describes.
  final PaneLayoutSlot resizable;

  /// The stops a resize settles on by default while both panes show. The
  /// default split is always one, and so is the end on either side where the
  /// handle may hide the pane there.
  final List<PaneSplit> stops;

  /// The resizable pane's extent under [PaneSplit.automatic], or null for
  /// the centred split.
  final double? defaultExtent;

  /// Whether both panes take half the space whatever the split, which may
  /// then only hide one of them.
  final bool even;

  /// The narrowest the resizable pane may be resized to.
  final double minExtent;

  /// The widest the resizable pane may be, as for a side sheet.
  ///
  /// The pane then cannot take the whole width either.
  final double maxExtent;

  /// The narrowest the other pane may be resized to.
  final double otherMinExtent;

  /// The smallest share of the space the panes' content shares that the
  /// other pane keeps, as a focus pane keeps half beside a supporting pane.
  ///
  /// Where the share leaves the resizable pane less than [minExtent], the
  /// share wins.
  final double otherMinShare;

  /// The centre of the spacer under the centred split, measured from the
  /// region's leading edge; null for the centre of the space between the
  /// margins.
  final double? center;

  /// Whether the spacer is held at [center], as on a hinge.
  final bool locked;

  /// The drag handle, or null when the layout is not resizable.
  final Widget? handle;

  /// Holds the split, or null for one the view owns.
  final PaneSplitController? controller;

  /// Whether the split is remembered.
  final PaneResizeMemory memory;

  /// A value whose change resets a split that is not remembered, such as the
  /// breakpoint.
  final Object? resetToken;

  /// What the handle may do to the resizable pane.
  final PaneCollapse collapse;

  /// What the handle may do to the other pane.
  final PaneCollapse otherCollapse;

  /// Dismisses the resizable pane, which [collapse] says the handle does in
  /// place of hiding it.
  final VoidCallback? onDismissed;

  /// Dismisses the other pane, which [otherCollapse] says the handle does in
  /// place of hiding it.
  final VoidCallback? onOtherDismissed;

  /// Whether a split that hides a pane, [PaneSplit.collapsed] or
  /// [PaneSplit.expanded], hides it.
  ///
  /// False for a layout whose panes the split only resizes, as where a pane
  /// is only ever dismissed: such a split then keeps both panes at the
  /// default split.
  final bool hidesPanes;
}

/// Two panes with animated visibility and an optional resizable split.
///
/// Changing a pane's [PaneConfig.visible] animates it in or out with the
/// enter or exit motion; changing the split, by drag, keyboard or
/// controller, settles on the resize motion. Neither rebuilds the
/// panes' content: the render object follows the animations directly.
/// A pane that moves is clipped to the space it occupies with the corners
/// of [MaterialLayoutThemeData.paneBorderRadius], which the app paints its
/// panes with.
///
/// The drag handle comes in with a pane that enters, fading in, and takes
/// input once the pane has arrived. As a pane goes, the handle fades out
/// where it is, taking no input.
class TwoPaneView extends StatefulWidget {
  /// Creates a two-pane view.
  const new({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    required this.marginStart,
    required this.marginEnd,
    required this.marginPlacement,
    required this.spacer,
    this.split,
    required this.motion,
    required this.animate,
    this.onPaneSettled,
  });

  /// The leading, or top, pane.
  final PaneConfig first;

  /// The trailing, or bottom, pane.
  final PaneConfig second;

  /// The direction the panes are arranged in.
  final Axis axis;

  /// The margin on the leading edge.
  final double marginStart;

  /// The margin on the trailing edge.
  final double marginEnd;

  /// Whether the margins are kept around the panes or within them.
  ///
  /// Within them, the panes reach the edges, a pane beside an edge is
  /// widened by its margin, and each pane's content learns the margins it
  /// keeps from [PaneMargins]. Split widths are the widths of the panes'
  /// content either way.
  final MarginPlacement marginPlacement;

  /// The space between the panes.
  final double spacer;

  /// The split, or null for two flexible panes shared by flex.
  final SplitConfig? split;

  /// The motion panes enter, leave and resize with.
  final PaneMotion motion;

  /// Whether a change of [PaneConfig.visible] animates.
  final bool animate;

  /// Called with a pane's slot and whether it shows, when the pane finishes
  /// animating in or out.
  ///
  /// Not called for a pane that shows or hides without animating.
  final void Function(PaneLayoutSlot slot, {required bool visible})?
  onPaneSettled;

  @override
  State<TwoPaneView> createState() => _TwoPaneViewState();
}

class _TwoPaneViewState extends State<TwoPaneView>
    with TickerProviderStateMixin
    implements PaneResizeTarget {
  late final AnimationController _firstVisibility;
  late final AnimationController _secondVisibility;
  late final AnimationController _settle;
  // How much of the drag handle shows. It fades in once it shows and out
  // once it goes, and takes no input while it is not shown.
  late final AnimationController _handleFade;
  double _handleFadeTarget = 0;
  final _extentOverride = ValueNotifier<double?>(null);
  late final Listenable _relayout;

  PaneSplitController? _ownController;
  late PaneSplitController _controller;

  BoxConstraints _constraints = const BoxConstraints();
  double _restingWidth = 0;
  double? _target;
  // The width of the resizable pane's content when both panes last showed,
  // which it opens at again.
  double? _lastOpenWidth;
  double _settleFrom = 0;
  bool _settling = false;
  double? _dragPosition;
  // Where the drag started, which it may return to although a pane the
  // handle may not hide was hidden there, as by the app.
  double _dragOrigin = 0;
  bool _resetPending = false;
  // The resizable pane's extent when it began to leave, which it keeps as it
  // goes, whatever happens to the space around it.
  double? _leavingExtent;
  // The resizable pane's extent as last built.
  double? _builtExtent;
  // The panes on their way in because they were shown. The drag handle comes
  // in with them, and takes input once they have arrived; its room opens as
  // far as they have come, so that it does not push the other pane aside
  // before the pane comes.
  final _entering = <PaneLayoutSlot>{};
  // What the view's region keeps clear of, as of the last build.
  bool _rtl = false;
  EdgeInsets _padding = EdgeInsets.zero;
  EdgeInsets _viewPadding = EdgeInsets.zero;
  EdgeInsets _viewInsets = EdgeInsets.zero;
  final _firstEdges = ValueNotifier(_noEdges);
  final _secondEdges = ValueNotifier(_noEdges);

  bool get _inside => widget.marginPlacement == MarginPlacement.inside;

  bool get _horizontal => widget.axis == Axis.horizontal;

  PaneConfig _configOf(PaneLayoutSlot slot) =>
      slot == PaneLayoutSlot.first ? widget.first : widget.second;

  // Whether the pane in [slot] reaches the edges it meets: every pane where
  // the view keeps its margins within the panes, and one holding a layout,
  // which keeps them itself, wherever the view keeps them.
  bool _reachesEdge(PaneLayoutSlot slot) =>
      _inside || _configOf(slot).holdsLayout;

  // The margins the panes are set in by while both show: none beside a pane
  // that reaches the edge.
  double get _outerStart =>
      _reachesEdge(PaneLayoutSlot.first) ? 0 : widget.marginStart;

  double get _outerEnd =>
      _reachesEdge(PaneLayoutSlot.second) ? 0 : widget.marginEnd;

  // How much wider than its content a pane that reaches the edge is: by the
  // margin on its edge, or by the safe-area inset there for a pane that
  // keeps no margin.
  double _insetOf(PaneLayoutSlot slot) {
    if (!_reachesEdge(slot) || !_horizontal) return 0;
    final first = slot == PaneLayoutSlot.first;
    final keeps = _configOf(slot).keepsMargins;
    final left = first != _rtl;
    return keeps
        ? (first ? widget.marginStart : widget.marginEnd)
        : (left ? _padding.left : _padding.right);
  }

  double get _resizableInset =>
      _insetOf(_resizableFirst ? PaneLayoutSlot.first : PaneLayoutSlot.second);

  double get _otherInset =>
      _insetOf(_resizableFirst ? PaneLayoutSlot.second : PaneLayoutSlot.first);

  PaneSplitController _resolveController() =>
      widget.split?.controller ?? (_ownController ??= PaneSplitController());

  // The split in effect: the controller's, unless a split that is not
  // remembered has just been forgotten and the controller is yet to hear,
  // or it would hide a pane that the split may not hide.
  PaneSplit get _split {
    final value = _resetPending ? PaneSplit.automatic : _controller.value;
    if (value.showsBothPanes || (widget.split?.hidesPanes ?? true)) {
      return value;
    }
    return PaneSplit.automatic;
  }

  bool get _resizableFirst => widget.split?.resizable == PaneLayoutSlot.first;

  bool get _forgetful => widget.split?.memory == PaneResizeMemory.temporary;

  AnimationController get _resizableVisibility =>
      _resizableFirst ? _firstVisibility : _secondVisibility;

  AnimationController get _otherVisibility =>
      _resizableFirst ? _secondVisibility : _firstVisibility;

  PaneConfig _resizableConfig(TwoPaneView view) =>
      view.split?.resizable == PaneLayoutSlot.first ? view.first : view.second;

  // Whether the drag handle shows: while both panes are to show, as one
  // comes in, too.
  bool get _handleVisible =>
      _hasHandle && widget.first.visible && widget.second.visible;

  // Whether the drag handle takes input: while both panes show, and no pane
  // is on its way in.
  bool get _showsHandle => _handleVisible && _entering.isEmpty;

  static final Object _noSplit = Object();

  // The margin a view sets its resizable pane in by.
  static double _outerMarginOf(TwoPaneView view) {
    final first = view.split?.resizable == PaneLayoutSlot.first;
    if (view.marginPlacement == MarginPlacement.inside ||
        (first ? view.first : view.second).holdsLayout) {
      return 0;
    }
    return first ? view.marginStart : view.marginEnd;
  }

  static Object? _resetTokenOf(TwoPaneView view) =>
      view.split == null ? _noSplit : view.split!.resetToken;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController()..addListener(_handleSplitChanged);
    final (first, second) = _visibleTargets();
    _firstVisibility = AnimationController.unbounded(
      vsync: this,
      value: first ? 1 : 0,
    );
    _secondVisibility = AnimationController.unbounded(
      vsync: this,
      value: second ? 1 : 0,
    );
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(_handleSettleTick);
    _handleFadeTarget = _handleVisible ? 1 : 0;
    _handleFade = AnimationController(vsync: this, value: _handleFadeTarget);
    _relayout = Listenable.merge([
      _firstVisibility,
      _secondVisibility,
      _extentOverride,
    ])..addListener(_updateEdges);
  }

  @override
  void didUpdateWidget(TwoPaneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _resolveController();
    if (controller != _controller) {
      _controller.removeListener(_handleSplitChanged);
      _controller = controller..addListener(_handleSplitChanged);
      _resetPending = false;
    }

    // Panes that change places take how much of them shows along.
    final firstId = oldWidget.first.id;
    if (firstId != null &&
        firstId == widget.second.id &&
        oldWidget.second.id == widget.first.id) {
      final shown = _firstVisibility.value;
      _firstVisibility.value = _secondVisibility.value;
      _secondVisibility.value = shown;
    }

    // A split that is not remembered is forgotten when the layout changes
    // arrangement or breakpoint, and when its pane is closed and reopened.
    final changedArrangement =
        _resetTokenOf(widget) != _resetTokenOf(oldWidget);
    final wasVisible = _resizableConfig(oldWidget).visible;
    final visible = _resizableConfig(widget).visible;
    if (wasVisible && !visible) _leavingExtent = _target;
    if (visible) _leavingExtent = null;
    final reopened = !wasVisible && visible;
    if (_forgetful && (changedArrangement || reopened)) {
      _forgetSplit(
        motion: reopened && _resizableVisibility.value > 0
            ? widget.motion.resize
            : const Motion.none(),
      );
    }

    // A drag keeps the handle where it is when the margins beside the
    // resizable pane move, as when they move into the panes.
    final drag = _dragPosition;
    final shift = _outerMarginOf(oldWidget) - _outerMarginOf(widget);
    if (drag != null && shift != 0 && _showsHandle) {
      _dragOrigin += shift;
      _dragPosition = drag + shift;
      _applyDragPosition(_dragPosition!);
    }

    if (widget.animate) {
      if (!oldWidget.first.visible && widget.first.visible) {
        _entering.add(PaneLayoutSlot.first);
      }
      if (!oldWidget.second.visible && widget.second.visible) {
        _entering.add(PaneLayoutSlot.second);
      }
    }

    // A drag ends with its handle.
    if (_dragPosition != null && !_showsHandle) {
      _dragPosition = null;
      _startSettle(widget.motion.resize);
    }
    if (_dragPosition != null) return;
    final (first, second) = _visibleTargets();
    Motion motionFor({required bool visible}) => !widget.animate
        ? const Motion.none()
        : visible
        ? widget.motion.enter
        : widget.motion.exit;
    _animateVisibility(_firstVisibility, first, motionFor(visible: first));
    _animateVisibility(_secondVisibility, second, motionFor(visible: second));
  }

  @override
  void dispose() {
    _relayout.removeListener(_updateEdges);
    _firstEdges.dispose();
    _secondEdges.dispose();
    _controller.removeListener(_handleSplitChanged);
    _ownController?.dispose();
    _firstVisibility.dispose();
    _secondVisibility.dispose();
    _settle.dispose();
    _handleFade.dispose();
    _extentOverride.dispose();
    super.dispose();
  }

  // Fades the handle in as it comes, with a pane that enters too, and out
  // as it goes, on the fast effects token, where the panes move at all.
  void _syncHandleFade(BuildContext context) {
    final target = _handleVisible ? 1.0 : 0.0;
    if (target == _handleFadeTarget) return;
    _handleFadeTarget = target;
    final motion = widget.motion.enter.isNone && widget.motion.exit.isNone
        ? const Motion.none()
        : MotionScheme.of(context).fastEffects.unlessReduced(context);
    _handleFade.animateOn(motion, target).then((_) {
      // A handle that has faded out leaves the tree.
      if (mounted && target == 0) setState(() {});
    });
  }

  // Returns to the default split. The layout uses it at once; the
  // controller is told after the frame, because its listeners may rebuild
  // widgets that cannot be rebuilt while this one builds.
  void _forgetSplit({required Motion motion}) {
    _lastOpenWidth = null;
    if (_split == PaneSplit.automatic) return;
    _resetPending = true;
    _startSettle(motion);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_resetPending) return;
      _resetPending = false;
      _controller
        ..removeListener(_handleSplitChanged)
        ..value = PaneSplit.automatic
        ..addListener(_handleSplitChanged);
    });
  }

  (bool, bool) _visibleTargets() {
    var first = widget.first.visible;
    var second = widget.second.visible;
    final split = widget.split;
    if (split != null && !split.locked && first && second) {
      final value = _split;
      if (_resizableFirst) {
        first = !value.isCollapsed;
        second = !value.isExpanded;
      } else {
        second = !value.isCollapsed;
        first = !value.isExpanded;
      }
    }
    return (first, second);
  }

  void _animateVisibility(
    AnimationController controller,
    bool visible,
    Motion motion,
  ) {
    final slot = controller == _firstVisibility
        ? PaneLayoutSlot.first
        : PaneLayoutSlot.second;
    final target = visible ? 1.0 : 0.0;
    if (!visible) _entering.remove(slot);
    if (!controller.isAnimating && controller.value == target) {
      _entering.remove(slot);
      return;
    }
    if (motion.isNone) {
      controller.value = target;
      _entering.remove(slot);
      _handleVisibilitySettled();
      return;
    }
    controller.animateOn(motion, target).then((_) {
      if (!mounted) return;
      _entering.remove(slot);
      _handleVisibilitySettled();
      widget.onPaneSettled?.call(slot, visible: visible);
    });
  }

  void _handleVisibilitySettled() {
    if (mounted) setState(() {});
  }

  void _handleSplitChanged() {
    _resetPending = false;
    if (_dragPosition != null) return;
    _animateToSplit(widget.motion.resize);
  }

  void _animateToSplit(Motion motion) {
    final (first, second) = _visibleTargets();
    _animateVisibility(_firstVisibility, first, motion);
    _animateVisibility(_secondVisibility, second, motion);
    _startSettle(motion);
    setState(() {});
  }

  void _startSettle(Motion motion) {
    final from = _extentOverride.value ?? _target;
    final to = _target = _resolveExtent(_split);
    if (from == null ||
        to == null ||
        motion.isNone ||
        (from - to).abs() < 0.5) {
      _settle.stop();
      _settling = false;
      _extentOverride.value = null;
      return;
    }
    _settleFrom = from;
    _settling = true;
    _settle.value = 0;
    _settle.animateWith(motion.simulation(0, 1)).then((_) {
      if (!mounted) return;
      _settling = false;
      _extentOverride.value = null;
      setState(() {});
    });
  }

  void _handleSettleTick() {
    final target = _target;
    if (!_settling || target == null) return;
    final extent = lerpDouble(_settleFrom, target, _settle.value)!;
    // A spring that overshoots may carry the pane past its target, but not
    // past its range, as a side sheet's width.
    final (lo, hi) = widget.split == null ? (extent, extent) : _range;
    _extentOverride.value = clampDouble(
      extent,
      math.min(lo, target),
      math.max(hi, target),
    );
  }

  double get _available {
    final width = _constraints.hasBoundedWidth ? _constraints.maxWidth : 0.0;
    final height = _constraints.hasBoundedHeight ? _constraints.maxHeight : 0.0;
    return _horizontal
        ? math.max(0.0, width - _outerStart - _outerEnd)
        : height;
  }

  double get _shared => math.max(0.0, _available - widget.spacer);

  // The space the panes' content shares: the space the panes share, less
  // the margins they keep within them.
  double get _contentShared =>
      math.max(0.0, _shared - _resizableInset - _otherInset);

  // The extents the resizable pane may be resized between while both panes
  // show. An even or held split admits only its own extent: the panes'
  // minimum widths bound resizing, not the split Material requires.
  (double, double) get _range {
    final split = widget.split!;
    final shared = _shared;
    if (split.even || split.locked) {
      final extent = clampDouble(_centeredExtent(), 0, shared);
      return (extent, extent);
    }
    final max = _maxExtent;
    final otherMin = math.max(
      split.otherMinExtent,
      split.otherMinShare * _contentShared,
    );
    var lo = math.min(math.min(split.minExtent + _resizableInset, shared), max);
    final hi = math.min(shared - otherMin - _otherInset, max);
    // The other pane's share outranks the resizable pane's minimum width.
    if (split.otherMinShare > 0) lo = math.min(lo, math.max(0.0, hi));
    return (lo, math.max(lo, hi));
  }

  double _centeredExtent() {
    final split = widget.split!;
    // The centre of the space between the margins, wherever they are kept,
    // so that the panes' content sits alike either way.
    final center = split.center ?? _marginsCenter;
    final leading = _horizontal ? _outerStart : 0.0;
    final leadingExtent = center - leading - widget.spacer / 2;
    return _resizableFirst ? leadingExtent : _shared - leadingExtent;
  }

  double get _marginsCenter {
    final width = _constraints.hasBoundedWidth ? _constraints.maxWidth : 0.0;
    final between = math.max(
      0.0,
      width - widget.marginStart - widget.marginEnd,
    );
    return widget.marginStart + between / 2;
  }

  // The widest the resizable pane may be, margin included.
  double get _maxExtent => widget.split!.maxExtent + _resizableInset;

  // Whether the resizable pane may not take the whole space, as a side sheet
  // may not.
  bool get _capped => _maxExtent < _shared;

  // The resizable pane's extent under [value] when both panes show, before
  // it is kept within the panes' minimum widths.
  double _openExtent(PaneSplit value) {
    final split = widget.split!;
    if (split.locked || split.even || value == PaneSplit.centered) {
      return _centeredExtent();
    }
    final defaultExtent = split.defaultExtent == null
        ? null
        : split.defaultExtent! + _resizableInset;
    if (value == PaneSplit.automatic) {
      return defaultExtent ?? _centeredExtent();
    }
    final width = value.width ?? _lastOpenWidth;
    if (width != null) return width + _resizableInset;
    return defaultExtent ?? _centeredExtent();
  }

  double? _resolveExtent(PaneSplit value) {
    if (widget.split == null) return null;
    final (lo, hi) = _range;
    return clampDouble(_openExtent(value), lo, hi);
  }

  // A drag position is where the handle is: how far its centre is from the
  // resizable pane's edge of the space the panes share, less half the
  // spacer, which is the pane's extent while both panes show. Beyond the
  // pane's range, one pane hides as the handle nears where it rests once
  // that pane has gone, so that the handle keeps to the pointer.
  //
  // The positions of the handle once the resizable pane, and once the other
  // pane, has gone.
  (double, double) get _dragEnds {
    final size = _constraints.biggest;
    double at({required double resizable, required double other}) {
      final center = _geometryWith(
        size,
        first: _resizableFirst ? resizable : other,
        second: _resizableFirst ? other : resizable,
      ).handleCenter;
      // Only panes side by side have a handle to drag.
      final along = _resizableFirst
          ? center - _outerStart
          : size.width - _outerEnd - center;
      return along - widget.spacer / 2;
    }

    return (at(resizable: 0, other: 1), at(resizable: 1, other: 0));
  }

  // Where a drag starts: the position the panes show now, read back from
  // their visibilities the way [_applyDragPosition] sets them, so that the
  // first movement continues from there.
  double get _dragStart {
    final (lo, hi) = _range;
    final (gone, full) = _dragEnds;
    final extent = clampDouble(_extentOverride.value ?? _target ?? lo, lo, hi);
    final resizable = clampDouble(_resizableVisibility.value, 0, 1);
    final other = clampDouble(_otherVisibility.value, 0, 1);
    if (resizable < 1) return gone + resizable * (extent - gone);
    if (other < 1) return full - other * (full - extent);
    return extent;
  }

  // The position of the handle once the split has settled, at the current
  // size: what the handle reports, and what a step starts from.
  double get _restingPosition {
    final value = _split;
    if (value.isCollapsed) return _dragEnds.$1;
    if (value.isExpanded) return _dragEnds.$2;
    return _resolveExtent(value)!;
  }

  List<(PaneSplit, double)> _stopPositions(List<PaneSplit>? snapStops) {
    final split = widget.split;
    if (split == null || split.locked) return const [];
    final (lo, hi) = _range;
    final (gone, full) = _dragEnds;
    final result = <(PaneSplit, double)>[];
    // Among the layout's own stops, the default always is one, so that a
    // resize can return to it, as to a side sheet's own width; and so is the
    // end on either side where the handle may hide the pane there.
    final stops =
        snapStops ??
        [
          PaneSplit.collapsed,
          ...split.stops,
          PaneSplit.automatic,
          PaneSplit.expanded,
        ];
    for (final stop in stops) {
      double position;
      if (stop.isCollapsed) {
        if (split.collapse == PaneCollapse.never) continue;
        position = gone;
      } else if (stop.isExpanded) {
        if (split.otherCollapse == PaneCollapse.never || _capped) continue;
        position = full;
      } else {
        // Custom widths are not allowed where the panes split evenly.
        if (split.even && stop.width != null) continue;
        // The default is wherever the split resolves it; other stops that do
        // not fit are left out.
        position = stop == PaneSplit.automatic
            ? _resolveExtent(stop)!
            : _openExtent(stop);
        if (position < lo - 0.5 || position > hi + 0.5) continue;
      }
      if (result.any((entry) => (entry.$2 - position).abs() < 1)) continue;
      result.add((stop, position));
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result;
  }

  // Settles on [target], and returns it; or dismisses the pane it hides,
  // where the handle dismisses that pane, and returns null.
  PaneSplit? _commit(PaneSplit target) {
    final split = widget.split!;
    // A split that gives the pane its default width is the default, which
    // then follows the breakpoint.
    if (target.showsBothPanes &&
        target != PaneSplit.automatic &&
        (_resolveExtent(target)! - _resolveExtent(PaneSplit.automatic)!).abs() <
            1) {
      target = PaneSplit.automatic;
    }
    if (dismisses(target)) {
      // The pane returns to its place, from where the app takes it away.
      _animateToSplit(widget.motion.resize);
      (target.isCollapsed ? split.onDismissed : split.onOtherDismissed)!();
      return null;
    }
    if (_split == target) {
      _animateToSplit(widget.motion.resize);
    } else {
      _controller.value = target;
    }
    return target;
  }

  // What the handle does to the pane [target] hides: null for a split that
  // shows both panes.
  PaneCollapse? _collapseFor(PaneSplit target) {
    final split = widget.split!;
    if (target.isCollapsed) return split.collapse;
    if (target.isExpanded) return split.otherCollapse;
    return null;
  }

  void _announce(PaneSplit split) {
    final strings = MaterialLayoutLocalizations.of(context);
    final message = split.isCollapsed
        ? strings.paneCollapsedAnnouncement
        : split.isExpanded
        ? strings.paneExpandedAnnouncement
        : strings.paneResizerValue(percentFor(split));
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  // The stops past [position] that way, nearest first.
  static Iterable<(PaneSplit, double)> _ahead(
    List<(PaneSplit, double)> stops,
    double position, {
    required bool wider,
  }) => wider
      ? stops.where((stop) => stop.$2 > position + 0.5)
      : stops.reversed.where((stop) => stop.$2 < position - 0.5);

  void _applyDragPosition(double position) {
    final (lo, hi) = _range;
    final (gone, full) = _dragEnds;
    // A pane with a maximum width stops there rather than pushing the other
    // pane out.
    if (_capped) position = math.min(position, hi);
    if (position < lo) {
      _extentOverride.value = lo;
      _resizableVisibility.value = lo > gone
          ? clampDouble((position - gone) / (lo - gone), 0, 1)
          : 0;
      _otherVisibility.value = 1;
    } else if (position > hi) {
      // Past the widest the resizable pane may be, the other pane slides out
      // of the space the panes share, as the handle nears where it rests
      // once that pane has gone.
      _extentOverride.value = hi;
      _resizableVisibility.value = 1;
      _otherVisibility.value = full > hi
          ? clampDouble((full - position) / (full - hi), 0, 1)
          : 0;
    } else {
      _extentOverride.value = position;
      _resizableVisibility.value = 1;
      _otherVisibility.value = 1;
    }
  }

  @override
  bool get resizableIsLeading => _resizableFirst;

  @override
  void beginResize() {
    _settle.stop();
    _settling = false;
    _firstVisibility.stop();
    _secondVisibility.stop();
    // Both panes are built while a drag lasts, as it may bring either into
    // view.
    setState(() => _dragPosition = _dragOrigin = _dragStart);
  }

  @override
  void updateResize(double delta) {
    final position = _dragPosition;
    if (position == null) return;
    // The position stays within what the panes can show, so that reversing
    // a drag past either end moves the panes at once. A pane the handle may
    // not hide keeps its minimum width, as a pane with a maximum width keeps
    // to it.
    final split = widget.split!;
    final (lo, hi) = _range;
    final (gone, full) = _dragEnds;
    final hidesOther = split.otherCollapse != PaneCollapse.never && !_capped;
    final end = math.max(hidesOther ? full : hi, _dragOrigin);
    final start = math.min(
      split.collapse != PaneCollapse.never ? gone : lo,
      _dragOrigin,
    );
    _dragPosition = clampDouble(position + delta, math.min(start, end), end);
    _applyDragPosition(_dragPosition!);
  }

  @override
  void endResize(double velocity, List<PaneSplit>? snapStops) {
    final position = _dragPosition;
    if (position == null) return;
    _dragPosition = null;
    final stops = _stopPositions(snapStops);
    PaneSplit target;
    if (stops.isEmpty) {
      final (lo, hi) = _range;
      // A split holds the width of the pane's content.
      final extent = clampDouble(position, lo, hi);
      target = PaneSplit.width(math.max(0.0, extent - _resizableInset));
    } else if (velocity.abs() >= kMinFlingVelocity) {
      final ahead = _ahead(stops, position, wider: velocity > 0);
      target = ahead.isEmpty
          ? (velocity > 0 ? stops.last : stops.first).$1
          : ahead.first.$1;
    } else {
      target = stops
          .reduce(
            (a, b) =>
                (a.$2 - position).abs() <= (b.$2 - position).abs() ? a : b,
          )
          .$1;
    }
    _commit(target);
  }

  @override
  void cancelResize() {
    if (_dragPosition == null) return;
    _dragPosition = null;
    // A handle that is removed cancels its drag while the tree is locked;
    // the split is restored once the frame is done.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dragPosition == null) {
          _animateToSplit(widget.motion.resize);
        }
      });
    } else {
      _animateToSplit(widget.motion.resize);
    }
  }

  @override
  List<PaneSplit> stopsFor(List<PaneSplit>? snapStops) => [
    for (final (split, _) in _stopPositions(snapStops)) split,
  ];

  @override
  PaneSplit? adjacentStop(int direction, List<PaneSplit>? snapStops) {
    final ahead = _ahead(
      _stopPositions(snapStops),
      _restingPosition,
      wider: direction > 0,
    );
    return ahead.isEmpty ? null : ahead.first.$1;
  }

  @override
  void moveTo(PaneSplit target) {
    final split = widget.split;
    if (split == null || split.locked) return;
    if (_collapseFor(target) == PaneCollapse.never) return;
    final settled = _commit(target);
    if (settled != null) _announce(settled);
  }

  @override
  PaneSplit? get hideTarget {
    final split = widget.split;
    if (split == null || split.locked) return null;
    if (split.collapse != PaneCollapse.never) return PaneSplit.collapsed;
    if (split.otherCollapse != PaneCollapse.never) return PaneSplit.expanded;
    return null;
  }

  @override
  void toggle() {
    final split = widget.split;
    if (split == null || split.locked) return;
    if (_split.showsBothPanes) {
      final hide = hideTarget;
      if (hide != null) moveTo(hide);
      return;
    }
    // A split that is not remembered reopens at the default.
    if (_forgetful) {
      _controller.value = PaneSplit.automatic;
    } else {
      _controller.toggle();
    }
    _announce(_controller.value);
  }

  @override
  bool dismisses(PaneSplit split) =>
      widget.split != null && _collapseFor(split) == PaneCollapse.dismiss;

  // Shares are measured against the space the panes' content shares, so
  // that a collapsed pane has none of it, an expanded one all of it, and a
  // pane has the same share wherever the margins are kept.
  @override
  int percentFor(PaneSplit split) {
    if (split.isCollapsed) return 0;
    if (split.isExpanded) return 100;
    final shared = _contentShared;
    if (shared <= 0) return 0;
    final share = (_resolveExtent(split)! - _resizableInset) / shared;
    return clampDouble(share * 100, 0, 100).round();
  }

  // Whether the layout has a drag handle, which shows while both panes do.
  bool get _hasHandle {
    final split = widget.split;
    return split != null && split.handle != null && !split.locked;
  }

  PaneLayoutSettings get _settings => (
    axis: widget.axis,
    marginStart: widget.marginStart,
    marginEnd: widget.marginEnd,
    marginPlacement: widget.marginPlacement,
    spacer: widget.spacer,
    hasHandle: _hasHandle,
  );

  // Whether the drag handle comes in with the pane in [slot], which enters.
  // One that goes leaves the handle where it is.
  bool _bringsHandle(PaneLayoutSlot slot) => _entering.contains(slot);

  // How far the handle's room is open with the panes at the visibilities
  // given, as the render object works it out.
  double _handlePresence({required double first, required double second}) {
    double of(PaneLayoutSlot slot, double visibility) =>
        _bringsHandle(slot) ? visibility : 1;
    return math.min(
      of(PaneLayoutSlot.first, first),
      of(PaneLayoutSlot.second, second),
    );
  }

  // The geometry the layout resolves with the given visibilities, with the
  // resizable pane's [extent] where it differs from the one it has now.
  PaneGeometry _geometryWith(
    Size size, {
    required double first,
    required double second,
    double? extent,
  }) {
    extent ??= _extentOverride.value ?? _builtExtent;
    final split = widget.split;
    return resolvePaneLayout(
      _settings,
      size: size,
      handlePresence: _handlePresence(first: first, second: second),
      firstExtent: split != null && _resizableFirst ? extent : null,
      secondExtent: split != null && !_resizableFirst ? extent : null,
      firstFlex: widget.first.flex,
      secondFlex: widget.second.flex,
      firstHoldsLayout: widget.first.holdsLayout,
      secondHoldsLayout: widget.second.holdsLayout,
      firstVisibility: first,
      secondVisibility: second,
    );
  }

  // Tells each pane's content what it keeps clear of, from where the pane
  // rests: shown, beside the other pane as it now shows. A pane that enters
  // or leaves keeps what it has when shown, as its content slides; the other
  // takes on the margins and insets its edges reach as it grows or shrinks.
  void _updateEdges() {
    if (!_constraints.hasBoundedWidth || !_constraints.hasBoundedHeight) {
      return;
    }
    final size = _constraints.biggest;
    final first = _geometryWith(
      size,
      first: 1,
      second: _secondVisibility.value,
    ).first;
    final second = _geometryWith(
      size,
      first: _firstVisibility.value,
      second: 1,
    ).second;
    // The width each pane's content has now, and once the panes settle,
    // shown beside the other as it is heading, in the view as wide as it
    // rests, as in a pane that is itself still moving. A drag has no
    // destination but where the pointer is.
    final now = _geometryWith(
      size,
      first: _firstVisibility.value,
      second: _secondVisibility.value,
    );
    double firstWidth;
    double secondWidth;
    double firstResting;
    double secondResting;
    if (_horizontal) {
      firstWidth = firstResting = now.first.contentExtent;
      secondWidth = secondResting = now.second.contentExtent;
      if (_dragPosition == null) {
        final (showFirst, showSecond) = _visibleTargets();
        (firstResting, secondResting) = _atWidth(_restingWidth, () {
          final resting = Size(_restingWidth, size.height);
          final extent = widget.split == null
              ? null
              : _leavingExtent ?? _resolveExtent(_split);
          return (
            _geometryWith(
              resting,
              first: 1,
              second: showSecond ? 1 : 0,
              extent: extent,
            ).first.contentExtent,
            _geometryWith(
              resting,
              first: showFirst ? 1 : 0,
              second: 1,
              extent: extent,
            ).second.contentExtent,
          );
        });
      }
    } else {
      // Stacked panes are as wide as the view, less the margins they are
      // set in by.
      double setIn(PaneLayoutSlot slot) =>
          _reachesEdge(slot) ? 0.0 : widget.marginStart + widget.marginEnd;
      firstWidth = math.max(0.0, size.width - setIn(PaneLayoutSlot.first));
      secondWidth = math.max(0.0, size.width - setIn(PaneLayoutSlot.second));
      firstResting = math.max(0.0, _restingWidth - setIn(PaneLayoutSlot.first));
      secondResting = math.max(
        0.0,
        _restingWidth - setIn(PaneLayoutSlot.second),
      );
    }
    _firstEdges.value = _edgesOf(
      PaneLayoutSlot.first,
      first,
      size,
      width: firstWidth,
      restingWidth: firstResting,
    );
    _secondEdges.value = _edgesOf(
      PaneLayoutSlot.second,
      second,
      size,
      width: secondWidth,
      restingWidth: secondResting,
    );
  }

  // Works [compute] out as though the view were [width] wide.
  T _atWidth<T>(double width, T Function() compute) {
    final constraints = _constraints;
    if ((width - constraints.maxWidth).abs() < 0.5) return compute();
    _constraints = constraints.copyWith(minWidth: width, maxWidth: width);
    try {
      return compute();
    } finally {
      _constraints = constraints;
    }
  }

  _PaneEdges _edgesOf(
    PaneLayoutSlot slot,
    PaneSpan span,
    Size size, {
    required double width,
    required double restingWidth,
  }) {
    final reaches = _reachesEdge(slot);
    final mainExtent = _horizontal ? size.width : size.height;
    // How far the pane is from each edge of the region.
    final before = span.start;
    final after = math.max(0.0, mainExtent - span.end);
    final double start;
    final double end;
    final double top;
    final double bottom;
    if (_horizontal) {
      (start, end, top, bottom) = (before, after, 0.0, 0.0);
    } else {
      start = reaches ? 0.0 : widget.marginStart;
      end = reaches ? 0.0 : widget.marginEnd;
      (top, bottom) = (before, after);
    }
    final (left, right) = _rtl ? (end, start) : (start, end);
    EdgeInsets reach(EdgeInsets insets) => EdgeInsets.fromLTRB(
      math.max(0.0, insets.left - left),
      math.max(0.0, insets.top - top),
      math.max(0.0, insets.right - right),
      math.max(0.0, insets.bottom - bottom),
    );

    var margins = EdgeInsetsDirectional.zero;
    if (reaches && _configOf(slot).keepsMargins) {
      if (_horizontal) {
        // The part of each margin the pane reaches into.
        final marginStart = widget.marginStart;
        final marginEnd = widget.marginEnd;
        margins = EdgeInsetsDirectional.only(
          start: math.max(0.0, math.min(span.end, marginStart) - span.start),
          end: math.max(
            0.0,
            span.end - math.max(span.start, mainExtent - marginEnd),
          ),
        );
      } else {
        margins = EdgeInsetsDirectional.only(
          start: widget.marginStart,
          end: widget.marginEnd,
        );
      }
    }
    return (
      margins: margins,
      padding: reach(_padding),
      viewPadding: reach(_viewPadding),
      viewInsets: reach(_viewInsets),
      width: width,
      restingWidth: restingWidth,
    );
  }

  Widget _pane(
    PaneConfig config,
    bool visible,
    AnimationController visibility,
    ValueListenable<_PaneEdges> edges,
  ) {
    final showing =
        visible ||
        _dragPosition != null ||
        visibility.value > 0 ||
        visibility.isAnimating;
    if (!config.maintainState && !showing) return const SizedBox.shrink();
    return Offstage(
      offstage: !showing,
      child: FocusTraversalGroup(
        child: ExcludeFocus(
          excluding: !visible,
          child: IgnorePointer(
            ignoring: !visible,
            child: ExcludeSemantics(
              excluding: !visible,
              child: TickerMode(
                enabled: showing,
                // Each pane is an ink surface of its own, so that ink effects
                // in it are not hidden by anything painted between the pane
                // and the nearest Material above the layout.
                child: Material(
                  type: MaterialType.transparency,
                  child: _PaneEdgesScope(edges: edges, child: config.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncHandleFade(context);
    return _buildPanes();
  }

  Widget _buildPanes() => LayoutBuilder(
    builder: (context, constraints) {
      _constraints = constraints;
      // As wide as the view rests, in a pane that is still moving.
      _restingWidth = constraints.hasBoundedWidth
          ? PaneRestingWidth.resolve(context, constraints.maxWidth)
          : 0;
      _rtl = Directionality.of(context) == TextDirection.rtl;
      _padding = MediaQuery.paddingOf(context);
      _viewPadding = MediaQuery.viewPaddingOf(context);
      _viewInsets = MediaQuery.viewInsetsOf(context);
      final split = widget.split;
      final (showFirst, showSecond) = _visibleTargets();
      final value = _split;
      double? extent;
      if (split != null) {
        final resolved = extent = _target = _resolveExtent(value)!;
        // A split held on a hinge is not the user's to open at again.
        if (value.showsBothPanes && !split.locked) {
          _lastOpenWidth = resolved - _resizableInset;
        }
        extent = _leavingExtent ?? extent;
      }
      _builtExtent = extent;
      _updateEdges();
      final corners = MaterialLayoutTheme.of(context).paneBorderRadius;
      return PaneLayout(
        settings: _settings,
        relayout: _relayout,
        children: [
          PaneLayoutChild(
            key: ValueKey<Object>(widget.first.id ?? PaneLayoutSlot.first),
            slot: PaneLayoutSlot.first,
            extent: _resizableFirst ? extent : null,
            extentOverride: _resizableFirst ? _extentOverride : null,
            flex: widget.first.flex,
            visibility: _firstVisibility,
            borderRadius: corners,
            bringsHandle: _bringsHandle(PaneLayoutSlot.first),
            holdsLayout: widget.first.holdsLayout,
            child: _pane(
              widget.first,
              showFirst,
              _firstVisibility,
              _firstEdges,
            ),
          ),
          PaneLayoutChild(
            key: ValueKey<Object>(widget.second.id ?? PaneLayoutSlot.second),
            slot: PaneLayoutSlot.second,
            extent: split != null && !_resizableFirst ? extent : null,
            extentOverride: split != null && !_resizableFirst
                ? _extentOverride
                : null,
            flex: widget.second.flex,
            visibility: _secondVisibility,
            borderRadius: corners,
            bringsHandle: _bringsHandle(PaneLayoutSlot.second),
            holdsLayout: widget.second.holdsLayout,
            child: _pane(
              widget.second,
              showSecond,
              _secondVisibility,
              _secondEdges,
            ),
          ),
          // The handle comes in with a pane that enters, and takes input once
          // the pane has arrived. One that goes fades out where it is,
          // taking no input.
          if (_hasHandle && (_handleVisible || _handleFade.value > 0))
            PaneLayoutChild(
              key: const ValueKey<Object>(PaneLayoutSlot.handle),
              slot: PaneLayoutSlot.handle,
              staysInPlace: !_handleVisible,
              child: FadeTransition(
                opacity: _handleFade,
                child: IgnorePointer(
                  ignoring: !_showsHandle,
                  child: ExcludeFocus(
                    excluding: !_showsHandle,
                    child: ExcludeSemantics(
                      excluding: !_showsHandle,
                      child: PaneResizeScope(
                        target: this,
                        split: value,
                        space: _contentShared,
                        percent: percentFor(value),
                        collapse: (split!.collapse, split.otherCollapse),
                        child: split.handle!,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

// What a pane's content keeps clear of: the margins it keeps itself, and the
// parts of the region's insets it reaches.
typedef _PaneEdges = ({
  EdgeInsetsDirectional margins,
  EdgeInsets padding,
  EdgeInsets viewPadding,
  EdgeInsets viewInsets,
  double width,
  double restingWidth,
});

const _PaneEdges _noEdges = (
  margins: EdgeInsetsDirectional.zero,
  padding: EdgeInsets.zero,
  viewPadding: EdgeInsets.zero,
  viewInsets: EdgeInsets.zero,
  width: 0,
  restingWidth: 0,
);

// Publishes a pane's edges to its content, which rebuilds only where what it
// depends on changes.
class _PaneEdgesScope extends StatelessWidget {
  const new({required this.edges, required this.child});

  final ValueListenable<_PaneEdges> edges;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: edges,
    builder: (context, edges, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: edges.padding,
        viewPadding: edges.viewPadding,
        viewInsets: edges.viewInsets,
      ),
      child: PaneMargins(
        margins: edges.margins,
        child: PaneRestingWidth(
          width: edges.width,
          restingWidth: edges.restingWidth,
          child: child!,
        ),
      ),
    ),
    child: child,
  );
}
