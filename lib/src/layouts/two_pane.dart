import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../foundation/adaptive_layout_theme.dart';
import '../foundation/window_size_class.dart';
import 'foldable.dart';
import 'pane_controller.dart';
import 'pane_drag_handle.dart';

/// How long a pane takes to leave ([TwoPane.exitDuration]).
///
/// Shorter than the entrance: the pane is on its way out, so it should get out
/// of the way rather than perform.
const Duration kPaneExitDuration = Duration(milliseconds: 300);

/// The curve a leaving pane travels on ([TwoPane.exitCurve]).
///
/// Material 3 *emphasized* easing. Deliberately **not** a spring — an exit that
/// overshoots reads as a bounce back into view, which is the opposite of what a
/// dismissal should say.
///
/// Note this is emphasized *easing* and not emphasized *accelerate*: the pane's
/// width is also the primary pane's width (they always sum to the region), so
/// the curve's tail is not just the leaving pane's business. Accelerate spends
/// ~30% of the distance in its final frames, which lands as a visible jump in
/// the pane that is staying. Emphasized easing settles instead.
const Curve kPaneExitCurve = Curves.easeInOutCubicEmphasized;

/// The pane widths Material 3 recommends a resize snap to, at expanded and
/// wider: "The recommended custom widths are: 360dp, 412dp".
const List<double> kRecommendedSnapWidths = <double>[360, 412];

/// The Material 3 default width for a **fixed** pane at [sizeClass].
///
/// 360dp through expanded, 412dp at large and extra-large — the spec steps it
/// up once there is room ("the fixed pane should have a width of 412dp by
/// default" at large/extra-large). Pass an explicit width to override.
double kFixedPaneWidthFor(WindowSizeClass sizeClass) =>
    sizeClass.isAtLeast(WindowSizeClass.large) ? 412 : 360;

/// How a [TwoPane] divides its width between the two panes.
enum TwoPaneStrategy {
  /// Pick automatically from the window's *capabilities*: a vertical
  /// fold/hinge spanning the pane selects [splitPane] (foldables); otherwise
  /// [fixedFlexible]. This is the default — robust because Flutter cannot
  /// reliably tell a tablet from a desktop, but it *can* see a hinge.
  auto,

  /// Both panes are flexible. The divider rests at the window's centre (the
  /// second pane stays at 50% of the **window** width; an outer navigation
  /// inset reduces only the first pane), and snaps onto a foldable hinge when
  /// the pane fills the window. Best for foldables.
  splitPane,

  /// One pane is a fixed width ([fixedPaneWidth] on [TwoPane.fixedSide]) and the
  /// other absorbs the rest. The drag handle can fully collapse/expand the
  /// fixed pane (toggling one-pane ↔ two-pane). Best for expanded+ windows.
  fixedFlexible,
}

/// Identifies one pane of a [TwoPane].
enum PaneSide {
  /// The leading pane (left in LTR, right in RTL).
  primary,

  /// The trailing pane.
  secondary,
}

/// A low-level, raw two-pane layout: two panes side by side separated by a
/// gutter, sized from the **local** constraints (split-pane additionally reads
/// the window width to anchor the divider), with negative widths clamped away.
///
/// This is the engine under [ListDetailLayout] and [SupportingPaneLayout], and
/// is exported for direct use. It owns the resize/collapse interaction (drag,
/// magnet-snap, double-tap, spring) and the **reveal**: when [secondary] goes
/// from null to non-null its width animates in (and back out on null) without
/// the content reflowing. Deciding *whether* a secondary should exist (vs
/// collapsing to one pane, pushing a route, or showing a sheet) is the job of
/// the higher-level layouts.
///
/// Features:
/// * [strategy] — [TwoPaneStrategy.auto] (default), [TwoPaneStrategy.splitPane],
///   or [TwoPaneStrategy.fixedFlexible].
/// * RTL-aware — [primary] occupies the leading edge.
/// * Optional [resizable] dragging via a [PaneDragHandle] in the gutter,
///   driven by a shared, persistable [PaneController].
/// * Optional null [secondary] → the [primary] fills the region (the secondary
///   reveals/collapses with an expressive [spring]).
class TwoPane extends StatefulWidget {
  /// Creates a two-pane layout.
  const TwoPane({
    super.key,
    required this.primary,
    this.secondary,
    this.strategy = TwoPaneStrategy.auto,
    this.fixedPaneWidth,
    this.fixedSide = PaneSide.primary,
    this.ratio,
    this.gutter,
    this.minPaneWidth = 360,
    this.resizable = false,
    this.snap = true,
    this.snapStops,
    this.spring = kExpressiveSpring,
    this.controller,
    this.onSecondaryDismissed,
    this.respectDisplayFeatures = true,
    this.temporaryResize = false,
    this.handleBuilder,
    this.exitDuration = kPaneExitDuration,
    this.exitCurve = kPaneExitCurve,
  })  : assert(ratio == null || (ratio > 0 && ratio < 1)),
        assert(fixedPaneWidth == null || fixedPaneWidth >= 0),
        assert(minPaneWidth >= 0);

  /// The leading pane (e.g. a list).
  final Widget primary;

  /// The trailing pane (e.g. a detail). When null the [primary] fills the
  /// region; a non-null → null transition animates the reveal out.
  final Widget? secondary;

  /// How the width is divided. Defaults to [TwoPaneStrategy.auto].
  final TwoPaneStrategy strategy;

  /// The fixed pane's width in [TwoPaneStrategy.fixedFlexible] (on [fixedSide]),
  /// used unless [ratio] is given.
  ///
  /// Defaults to [kFixedPaneWidthFor] the current breakpoint — 360dp through
  /// expanded, 412dp at large and extra-large, as Material 3 specifies.
  final double? fixedPaneWidth;

  /// Which pane is the fixed one in [TwoPaneStrategy.fixedFlexible]. Material 3
  /// allows either order (fixed/flexible or flexible/fixed). Defaults to
  /// [PaneSide.primary].
  final PaneSide fixedSide;

  /// If set, the resting split is proportional — [ratio] is the primary's share
  /// of the splittable width — instead of a fixed pane width.
  final double? ratio;

  /// The gap between panes (and the drag-handle hit area when [resizable]).
  ///
  /// Defaults to the ambient [AdaptiveLayoutThemeData.spacing]'s
  /// `paneGutter` (24 out of the box), so setting it once on an
  /// [AdaptiveLayoutTheme] retunes every pane gap in the subtree.
  final double? gutter;

  /// The minimum width each pane keeps at the *default* split when there is room
  /// for both. A resize can still drag past it (to collapse). Defaults to 360.
  final double minPaneWidth;

  /// Whether the user can drag the gutter ([PaneDragHandle]) to resize.
  final bool resizable;

  /// Whether a resize magnet-snaps, on release, to nearby stops. Double-tapping
  /// the handle toggles the layout (collapse/expand the fixed pane, or centre a
  /// split pane). Defaults to `true`.
  final bool snap;

  /// Custom snap stops as fractions (`0..1`) of the splittable width. When null,
  /// stops are derived from the [strategy]. Ignored when [snap] is false.
  final List<double>? snapStops;

  /// The spring that drives reveal/collapse/snap/toggle animations. Defaults to
  /// an expressive spring with mild overshoot ([kExpressiveSpring]).
  final SpringDescription spring;

  /// The shared, persistable split state. When null an internal one is used.
  /// Provide your own to persist the user's pane-width preference.
  final PaneController? controller;

  /// Called when the user drags/collapses the [secondary] fully away. The owner
  /// typically responds by setting [secondary] to null (which reveals it out).
  /// When null, the secondary cannot be dragged off — it parks at the edge.
  final VoidCallback? onSecondaryDismissed;

  /// Whether to snap the split onto a vertical foldable hinge when a split pane
  /// fills the window. Defaults to `true`.
  final bool respectDisplayFeatures;

  /// Whether resizing is **temporary** (Material 3): the divider follows the
  /// handle while dragging but **springs back to the breakpoint's default split
  /// on release** instead of being remembered. Dragging the secondary (near)
  /// off still dismisses it (when [onSecondaryDismissed] is set). Double-tap is
  /// disabled in this mode. Defaults to `false` (persistent resizing). Used by
  /// `SupportingPaneLayout`; `ListDetailLayout` keeps persistent resizing.
  final bool temporaryResize;

  /// Builds custom gutter content when [resizable] (replaces the default
  /// [PaneDragHandle]). It is sized to the gutter width.
  final WidgetBuilder? handleBuilder;

  /// How long the secondary takes to leave. Defaults to [kPaneExitDuration].
  ///
  /// The *entrance* is driven by [spring] (with its expressive overshoot); the
  /// exit deliberately is not — see [exitCurve].
  final Duration exitDuration;

  /// The curve the secondary leaves on. Defaults to [kPaneExitCurve].
  final Curve exitCurve;

  @override
  State<TwoPane> createState() => _TwoPaneState();
}

class _TwoPaneState extends State<TwoPane> with TickerProviderStateMixin {
  // The live split fraction (primary's share of splittable) while a snap/toggle
  // spring runs. Outside an animation the split comes from the controller (or
  // the region-derived default) — see [_liveSplit].
  late final AnimationController _splitAnim;

  // How "revealed" the secondary is: 0 = hidden (primary fills), 1 = fully
  // shown. Drives the width wipe-in/out. Spring-driven; the raw (unclamped)
  // value is used for the secondary's width so an overshoot bounces visibly.
  late final AnimationController _revealAnim;

  // The secondary currently shown; retained while collapsing so the pane can
  // animate closed without the content vanishing first.
  Widget? _shownSecondary;

  // Latched true the moment the reveal first reaches full width and held through
  // the spring's settle oscillation, so the handle stays interactive without
  // flicker; reset when the secondary is hidden.
  bool _revealed = false;

  // True while the secondary is on its way out. The exit is the only phase that
  // slides and fades — an entrance reveals width in place, so fading it too
  // would read as a second, competing animation.
  bool _leaving = false;

  // The controller is the source of truth for the split; an internal one is
  // created when the caller doesn't supply one.
  PaneController? _internalController;
  PaneController get _controller => widget.controller ?? _internalController!;

  // Cached from the last layout so gesture callbacks (which run between builds)
  // resolve against the current region.
  double _splittable = 0;
  double _defaultSplit = 0.5;
  double _renderedSplit = 0.5; // the split used in the last build
  TwoPaneStrategy _resolvedStrategy = TwoPaneStrategy.fixedFlexible;

  // True while TwoPane itself is writing to the controller (drag/snap), so the
  // controller listener renders directly instead of starting a spring.
  bool _selfUpdate = false;

  static const double _snapRadius = 40; // magnet radius (logical px)
  static const double _eps = 0.001;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _internalController = PaneController();
    _controller.addListener(_onControllerChanged);
    _shownSecondary = widget.secondary;
    _revealed = widget.secondary != null;
    _revealAnim = AnimationController.unbounded(
      vsync: this,
      value: widget.secondary != null ? 1.0 : 0.0,
    )..addListener(_onRevealTick);
    _splitAnim = AnimationController.unbounded(vsync: this, value: 0.5)
      ..addListener(_onSplitTick);
  }

  @override
  void didUpdateWidget(TwoPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      } else {
        _internalController ??= PaneController();
      }
      _controller.addListener(_onControllerChanged);
    }

    final has = widget.secondary != null;
    final had = oldWidget.secondary != null;
    if (has) {
      _shownSecondary = widget.secondary; // instant content swap
      if (!had || _revealAnim.value < 1.0) _revealIn();
    } else if (had) {
      _revealed = false;
      _revealOut();
    }
  }

  @override
  void dispose() {
    _splitAnim.dispose();
    _revealAnim.dispose();
    widget.controller?.removeListener(_onControllerChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Self-induced changes (drag/snap) render directly. For *external* changes
    // — a temporary reset, or a programmatically set / restored fraction —
    // animate the divider to the new resting split so it glides, not jumps.
    if (_selfUpdate) {
      setState(() {});
      return;
    }
    final target = _restingSplit;
    if (_splittable <= 0 || (target - _renderedSplit).abs() < _eps) {
      setState(() {});
      return;
    }
    _splitAnim
      ..stop()
      ..value = _renderedSplit;
    _splitAnim.animateWith(SpringSimulation(
        widget.spring, _renderedSplit, target, _splitAnim.velocity));
  }

  void _onSplitTick() => setState(() {});

  void _onRevealTick() {
    setState(() {
      // Latch on "close enough to 1" rather than ">= 1": a spring settles on a
      // tolerance, so a critically damped one supplied via [spring] would never
      // reach exactly 1 and the handle would stay inert for the pane's life.
      if (widget.secondary != null && _revealAnim.value >= 1.0 - _eps) {
        _revealed = true;
      }
      if (widget.secondary == null &&
          !_revealAnim.isAnimating &&
          _revealAnim.value <= _eps) {
        _shownSecondary = null;
        _leaving = false;
      }
    });
  }

  /// Springs the secondary in, overshoot and all.
  void _revealIn() {
    _leaving = false;
    _revealAnim.animateWith(SpringSimulation(
        widget.spring, _revealAnim.value, 1.0, _revealAnim.velocity));
  }

  /// Drives the secondary out on a curve — no spring, so it never bounces back
  /// into view on its way off the edge.
  void _revealOut() {
    _leaving = true;
    _revealAnim.animateTo(
      0,
      duration: widget.exitDuration,
      curve: widget.exitCurve,
    );
  }

  // The split the controller currently rests at (collapse/fraction/default).
  double get _restingSplit {
    switch (_controller.collapse) {
      case PaneCollapse.primary:
        return 0.0;
      case PaneCollapse.secondary:
        return 1.0;
      case PaneCollapse.none:
        return _controller.fraction ?? _defaultSplit;
    }
  }

  // The split fraction in effect right now: the running animation if any, else
  // the resting split.
  double get _liveSplit =>
      _splitAnim.isAnimating ? _splitAnim.value : _restingSplit;

  // --- gestures ----------------------------------------------------------

  void _onDrag(double dx) {
    if (_splittable <= 0) return;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    _splitAnim.stop();
    final next = (_liveSplit + (ltr ? dx : -dx) / _splittable).clamp(0.0, 1.0);
    _selfUpdate = true;
    _controller.resizeTo(next);
    _selfUpdate = false;
  }

  void _onDragEnd() {
    if (_splittable <= 0) return;
    if (widget.temporaryResize) {
      final current = _liveSplit;
      // Dragging the secondary (near) off dismisses it when allowed; otherwise
      // the temporary split springs straight back to the breakpoint's default.
      if (widget.onSecondaryDismissed != null &&
          (1.0 - current) * _splittable <= _snapRadius) {
        widget.onSecondaryDismissed!();
        return;
      }
      _selfUpdate = true;
      _controller.reset(); // forget the width; rest at the live default
      _selfUpdate = false;
      _splitAnim
        ..stop()
        ..value = current;
      _splitAnim.animateWith(SpringSimulation(
          widget.spring, current, _defaultSplit, _splitAnim.velocity));
      return;
    }
    if (!widget.snap) return;
    final current = _liveSplit;
    final (stop, dist) = _nearestStop(current);
    if (dist * _splittable > _snapRadius) return; // released free
    _settleTo(stop, allowDismiss: true);
  }

  // Double-tap toggles the layout: collapse/expand the fixed pane in
  // fixed-flexible, or centre ↔ default in split-pane.
  void _onToggle() {
    if (_splittable <= 0) return;
    if (_resolvedStrategy == TwoPaneStrategy.splitPane) {
      final centred = (_liveSplit - 0.5).abs() < 0.02;
      _settleTo(centred ? _defaultSplit : 0.5);
    } else {
      final collapse = widget.fixedSide == PaneSide.primary ? 0.0 : 1.0;
      final isCollapsed = (_liveSplit - collapse).abs() < 0.02;
      _settleTo(isCollapsed ? _defaultSplit : collapse);
    }
  }

  void _settleTo(double target, {bool allowDismiss = false}) {
    if (allowDismiss &&
        target >= 1.0 - _eps &&
        widget.onSecondaryDismissed != null) {
      widget.onSecondaryDismissed!(); // owner nulls secondary → reveal out
      return;
    }
    final start = _liveSplit;
    // Commit the destination to the controller up front; the spring is rendered
    // via _splitAnim while it runs, then _liveSplit falls back to the committed
    // value (so an interrupted spring still lands in a consistent state). Mark
    // it self-induced so the listener doesn't start a second spring.
    _selfUpdate = true;
    if (target <= _eps) {
      _controller.collapseTo(PaneCollapse.primary);
    } else if (target >= 1.0 - _eps) {
      _controller.collapseTo(PaneCollapse.secondary);
    } else {
      _controller.resizeTo(target);
    }
    _selfUpdate = false;
    _splitAnim
      ..stop()
      ..value = start;
    _splitAnim.animateWith(
        SpringSimulation(widget.spring, start, target, _splitAnim.velocity));
  }

  (double, double) _nearestStop(double current) {
    var best = current;
    var bestDist = double.infinity;
    for (final s in _snapStops()) {
      final d = (s - current).abs();
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return (best, bestDist);
  }

  List<double> _snapStops() {
    if (widget.snapStops != null) return widget.snapStops!;
    if (_splittable <= 0) return const [0.5];
    final minF = (widget.minPaneWidth / _splittable).clamp(0.0, 1.0);
    if (_resolvedStrategy == TwoPaneStrategy.splitPane) {
      // Both flexible: centre + the default, kept off the hard edges.
      return [
        for (final f in [_defaultSplit, 0.5])
          if (f >= minF && f <= 1 - minF) f,
      ];
    }
    // Fixed-flexible: the fixed pane fully collapses/expands (M3 one↔two-pane
    // toggle); the other pane only collapses (dismisses) when dismissal is
    // allowed. Interior stops keep both panes >= minPaneWidth.
    final fixedCollapse = widget.fixedSide == PaneSide.primary ? 0.0 : 1.0;
    final otherCollapse = widget.fixedSide == PaneSide.primary ? 1.0 : 0.0;
    return [
      fixedCollapse,
      if (widget.onSecondaryDismissed != null) otherCollapse,
      // The dp widths M3 names for the fixed pane, expressed as fractions of
      // the current splittable width. These are absolute, so they land at the
      // same physical width whatever the region — which is the point of them.
      ..._recommendedStops(minF),
      for (final f in [_defaultSplit, 0.5, minF, 1 - minF])
        if (f > minF - _eps && f < 1 - minF + _eps) f,
    ];
  }

  /// [kRecommendedSnapWidths] converted to split fractions for the fixed side,
  /// dropped when they would push either pane below [TwoPane.minPaneWidth].
  ///
  /// Only offered at expanded and wider: the spec scopes the recommendation to
  /// "expanded, large, and extra-large breakpoints", and at medium a two-pane
  /// layout is supposed to sit at 50/50 rather than a custom width.
  Iterable<double> _recommendedStops(double minF) sync* {
    if (_splittable <= 0) return;
    final sizeClass = AdaptiveLayoutTheme.of(context)
        .breakpoints
        .resolve(MediaQuery.sizeOf(context).width);
    if (!sizeClass.isExpandedOrWider) return;
    for (final w in kRecommendedSnapWidths) {
      final fixed = w / _splittable;
      if (fixed <= 0 || fixed >= 1) continue;
      final f = widget.fixedSide == PaneSide.primary ? fixed : 1 - fixed;
      if (f > minF - _eps && f < 1 - minF + _eps) yield f;
    }
  }

  // --- geometry ----------------------------------------------------------

  TwoPaneStrategy _resolveStrategy(double region, MediaQueryData mq) {
    if (widget.strategy != TwoPaneStrategy.auto) return widget.strategy;
    if (widget.respectDisplayFeatures &&
        (region - mq.size.width).abs() < 1.0 &&
        verticalFoldFor(mq.displayFeatures, mq.size) != null) {
      return TwoPaneStrategy.splitPane;
    }
    return TwoPaneStrategy.fixedFlexible;
  }

  double _computeDefaultSplit(
      TwoPaneStrategy strategy, double region, double splittable, MediaQueryData mq) {
    if (splittable <= 0) return 0.5;
    double frac;
    if (strategy == TwoPaneStrategy.splitPane) {
      // The second pane stays at 50% of the window; an outer nav inset
      // (window - region) reduces only the first pane.
      final secondary = (0.5 * mq.size.width).clamp(0.0, splittable);
      frac = (splittable - secondary) / splittable;
    } else if (widget.ratio != null) {
      frac = widget.ratio!;
    } else {
      final fixed = (_fixedPaneWidth(mq) / splittable).clamp(0.0, 1.0);
      frac = widget.fixedSide == PaneSide.primary ? fixed : 1 - fixed;
    }
    // Keep both panes >= minPaneWidth at rest when there's room for both.
    final minF = widget.minPaneWidth / splittable;
    if (2 * minF <= 1) return frac.clamp(minF, 1 - minF);
    return frac.clamp(0.0, 1.0);
  }

  /// The fixed pane's resting width, resolved against the **window** class —
  /// the 360/412 step is a breakpoint rule, not a property of the local region.
  double _fixedPaneWidth(MediaQueryData mq) {
    if (widget.fixedPaneWidth != null) return widget.fixedPaneWidth!;
    final breakpoints = AdaptiveLayoutTheme.of(context).breakpoints;
    return kFixedPaneWidthFor(breakpoints.resolve(mq.size.width));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final region = constraints.maxWidth;
        final strategy = _resolveStrategy(region, mq);
        _resolvedStrategy = strategy;

        var gutter = widget.gutter ??
            AdaptiveLayoutTheme.of(context).spacing.paneGutter;
        // Foldable hinge: snap the divider onto a vertical hinge when a split
        // pane fills the window and isn't being resized.
        VerticalFold? fold;
        if (strategy == TwoPaneStrategy.splitPane &&
            widget.respectDisplayFeatures &&
            !widget.resizable &&
            (region - mq.size.width).abs() < 1.0) {
          fold = verticalFoldFor(mq.displayFeatures, mq.size);
        }
        if (fold != null) gutter = math.max(gutter, fold.size);

        final splittable = math.max(0.0, region - gutter);
        _splittable = splittable;
        _defaultSplit = fold != null && splittable > 0
            ? (fold.start / splittable).clamp(0.0, 1.0)
            : _computeDefaultSplit(strategy, region, splittable, mq);

        final secondary = _shownSecondary;
        if (secondary == null) {
          return SizedBox(width: region, child: widget.primary);
        }

        final split = _liveSplit.clamp(0.0, 1.0);
        _renderedSplit = split;
        final reveal = _revealAnim.value.clamp(0.0, 1.0);

        // The gutter and the secondary travel as ONE block, so the drag handle
        // leaves with the pane it belongs to instead of shrinking in place and
        // blinking out at the end.
        //
        // The block is laid out at its resting width and anchored to its own
        // leading edge inside a box that shrinks to `blockRest * reveal`. That
        // single relationship does all the work: at reveal 1 the block sits at
        // rest; at reveal 0 the box has collapsed at x == region, which puts the
        // block's leading edge exactly on the trailing edge of the region — the
        // handle included — so the whole thing is off screen rather than
        // clipped away in place. The RAW (unclamped) value drives the box so a
        // spring overshoot over-stretches past the content; that gap is filled
        // with the surface colour so the bounce reads as a rubber-band.
        final secondaryRest = (splittable * (1 - split)).clamp(0.0, splittable);
        final blockRest = secondaryRest + gutter;
        final blockVisible = (blockRest * _revealAnim.value).clamp(0.0, region);
        final primaryVisible = (region - blockVisible).clamp(0.0, region);

        final Widget gutterChild = widget.resizable
            ? IgnorePointer(
                // Interactive only once the reveal has settled, so a drag can't
                // fight the in-flight animation.
                ignoring: !_revealed,
                child: SizedBox(
                  width: gutter,
                  child: widget.handleBuilder?.call(context) ??
                      PaneDragHandle(
                        gutterWidth: gutter,
                        onDragUpdate: _onDrag,
                        onDragEnd: _onDragEnd,
                        onDoubleTap: widget.temporaryResize ? null : _onToggle,
                      ),
                ),
              )
            : SizedBox(width: gutter);

        Widget block = SizedBox(
          width: blockRest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              gutterChild,
              SizedBox(width: secondaryRest, child: secondary),
            ],
          ),
        );
        // Only the exit fades. On the way in the pane reveals its width in
        // place, and fading that too would read as a second animation fighting
        // the first. Ease the opacity ahead of the travel so the pane has
        // finished fading a little before it finishes moving — the last sliver
        // of it slips away invisibly instead of winking out at the edge.
        if (_leaving) {
          block = Opacity(
            opacity: Curves.easeIn.transform(reveal),
            child: block,
          );
        }

        return SizedBox(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          // Clip at the region, not around each pane: the block has to be free
          // to overhang the trailing edge on its way out, and be cut off there.
          child: ClipRect(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: primaryVisible, child: widget.primary),
                SizedBox(
                  width: blockVisible,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: OverflowBox(
                      minWidth: blockRest,
                      maxWidth: blockRest,
                      alignment: AlignmentDirectional.centerStart,
                      child: block,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
