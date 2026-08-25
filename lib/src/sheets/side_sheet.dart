import 'dart:async';

import 'package:flutter/material.dart';

import 'sheet_drag_handle.dart';
import 'sheet_mode.dart';

/// How long a side sheet takes to arrive.
///
/// 250ms — the same `_kBottomSheetEnterDuration` Flutter's bottom sheet uses,
/// so the two sheet forms move alike.
const Duration kSheetEnterDuration = Duration(milliseconds: 250);

/// How long a side sheet takes to leave.
///
/// 200ms — Flutter's `_kBottomSheetExitDuration`. Exits are shorter than
/// entrances: the sheet is on its way out, not performing.
const Duration kSheetExitDuration = Duration(milliseconds: 200);

/// The curve a side sheet enters and leaves on.
///
/// Flutter's bottom sheet applies `Easing.legacyDecelerate` as *both* its curve
/// and its reverse curve; matching it keeps the two sheets in step.
const Curve kSheetCurve = Easing.legacyDecelerate;

/// The default side sheet surface shape: the two **leading** corners rounded,
/// at the same 28dp radius Flutter's Material 3 bottom sheet uses on its two
/// top corners. Directional, so it mirrors in RTL.
const ShapeBorder kSideSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadiusDirectional.horizontal(start: Radius.circular(28)),
);

/// A handle on the side sheet enclosing a [BuildContext], from
/// [SideSheet.of]. Lets sheet content close itself without knowing whether it
/// was opened modally (a route) or as a standard sheet (an overlay entry).
abstract class SideSheetHandle {
  /// Closes the sheet, completing `showSideSheet`'s future with [result].
  void close([Object? result]);

  /// Whether this sheet is modal — i.e. blocking the content behind it.
  bool get isModal;
}

class _SideSheetScope extends InheritedWidget {
  const _SideSheetScope({required this.handle, required super.child});

  final SideSheetHandle handle;

  @override
  bool updateShouldNotify(_SideSheetScope old) => handle != old.handle;
}

/// A Material 3 side sheet surface anchored to the trailing edge.
///
/// Use this **inline** for a *standard* (persistent) side sheet — for example
/// as the `secondary` of a `TwoPane`, or beside your content. For a *modal*
/// side sheet, use [showSideSheet].
///
/// The default width is 256dp, clamped to [maxWidth] (400dp) and to whatever
/// width is actually available — so it never overflows a narrow window. It
/// fills the height of its container, as Material 3 side sheets do, and it is
/// RTL-aware: "trailing" is the right edge in LTR and the left edge in RTL —
/// including its rounded corners, which sit on the **leading** edge.
class SideSheet extends StatelessWidget {
  /// Returns a handle on the enclosing side sheet, or null when the context is
  /// not inside one (e.g. an inline [SideSheet], which nothing opened).
  static SideSheetHandle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SideSheetScope>()?.handle;

  /// Returns a handle on the enclosing side sheet. Asserts when there is none.
  static SideSheetHandle of(BuildContext context) {
    final handle = maybeOf(context);
    assert(
      handle != null,
      'SideSheet.of() was called outside a sheet opened by showSideSheet(). '
      'An inline SideSheet widget has no handle — it is a plain surface, and '
      'whoever placed it decides when it goes away.',
    );
    return handle!;
  }

  /// Creates an inline side sheet surface.
  const SideSheet({
    super.key,
    required this.child,
    this.width = 256,
    this.maxWidth = 400,
    this.backgroundColor,
    this.elevation = 1,
    this.shape,
  });

  /// The sheet content.
  final Widget child;

  /// The preferred width. Defaults to 256.
  final double width;

  /// The maximum width. Defaults to 400.
  final double maxWidth;

  /// The surface color. Defaults to the theme's surfaceContainerLow.
  final Color? backgroundColor;

  /// The surface elevation. Defaults to 1.
  final double elevation;

  /// The surface shape. Defaults to [kSideSheetShape] — the two **leading**
  /// corners rounded by 28dp, mirroring the way a bottom sheet rounds its two
  /// top corners, so the two sheet forms read as the same surface arriving from
  /// different edges.
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Clamp rather than nest a SizedBox inside a ConstrainedBox: an inner
        // SizedBox pins the width outright, so the cap only ever bound when the
        // caller asked for something wider than it — and nothing stopped the
        // sheet overflowing a window narrower than `width`.
        final double resolved = width
            .clamp(0.0, maxWidth)
            .clamp(
              0.0,
              constraints.maxWidth.isFinite ? constraints.maxWidth : maxWidth,
            );
        return SizedBox(
          width: resolved,
          // Material 3 side sheets are anchored to the full height of their
          // container, not floated at its centre.
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: Material(
            color: backgroundColor ?? colors.surfaceContainerLow,
            elevation: elevation,
            shape: shape ?? kSideSheetShape,
            // So content cannot paint over the rounded corners.
            clipBehavior: Clip.antiAlias,
            child: SafeArea(child: child),
          ),
        );
      },
    );
  }
}

/// Shows a side sheet that slides in from the trailing edge.
///
/// The two modes mirror [showAppBottomSheet]:
///
/// * [SheetMode.modal] (default) — a route over a scrim. It blocks the content
///   behind it and a tap outside dismisses it. Material 3: modal side sheets
///   "must be dismissed in order to interact with the underlying content".
/// * [SheetMode.standard] — **persistent**. No scrim, no barrier: the app stays
///   fully interactive underneath and an outside tap does *not* close the
///   sheet, exactly as a standard bottom sheet behaves. Material 3: standard
///   side sheets "remain visible while people interact with primary content".
///   Close it with `SideSheet.of(context).close()`, by dragging it away, or by
///   completing whatever task it exists for.
///
/// Either way it can be **dragged away to dismiss** ([enableDrag]) — toward the
/// trailing edge, which is right in LTR and left in RTL — and shows a drag
/// handle ([showDragHandle]) advertising that.
///
/// [useRootNavigator] controls **how much of the screen the sheet covers**, and
/// defaults to false to match `showModalBottomSheet`. False scopes the sheet to
/// the nearest [Navigator]/[Overlay] — inside a nav-shell that is the body
/// area, so a modal sheet scrims the content but leaves the surrounding
/// navigation rail or bar live. True scopes it to the root, covering the whole
/// window including the navigation.
///
/// A standard sheet floats above the content rather than shrinking it. For the
/// co-planar behaviour where "entrance of standard side sheets will cause the
/// body area to adjust", place a [SideSheet] inline — e.g. as the `secondary`
/// of a [TwoPane] — which is a layout decision, not an imperative one.
Future<T?> showSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetMode mode = SheetMode.modal,
  double width = 256,
  double maxWidth = 400,
  Color? backgroundColor,
  Color? barrierColor,
  bool enableDrag = true,
  bool showDragHandle = true,
  Widget? dragHandle,
  bool useRootNavigator = false,
  Duration transitionDuration = kSheetEnterDuration,
  Duration reverseTransitionDuration = kSheetExitDuration,
}) {
  if (mode == SheetMode.standard) {
    return _showStandardSideSheet<T>(
      context,
      builder: builder,
      width: width,
      maxWidth: maxWidth,
      backgroundColor: backgroundColor,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      dragHandle: dragHandle,
      useRootOverlay: useRootNavigator,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
  final label = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _SideSheetRoute<T>(
      builder: builder,
      mode: mode,
      width: width,
      maxWidth: maxWidth,
      backgroundColor: backgroundColor,
      requestedBarrierColor: barrierColor,
      barrierLabel: label,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      dragHandle: dragHandle,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    ),
  );
}

class _SideSheetRoute<T> extends PopupRoute<T> {
  _SideSheetRoute({
    required this.builder,
    required this.mode,
    required this.width,
    required this.maxWidth,
    required this.backgroundColor,
    required this.requestedBarrierColor,
    required this.barrierLabel,
    required this.enableDrag,
    required this.showDragHandle,
    required this.dragHandle,
    required Duration transitionDuration,
    required Duration reverseTransitionDuration,
    // ignore: prefer_initializing_formals — private field, public parameter.
  })  : _transitionDuration = transitionDuration,
        // ignore: prefer_initializing_formals — private field, public parameter.
        _reverseTransitionDuration = reverseTransitionDuration;

  final WidgetBuilder builder;
  final SheetMode mode;
  final double width;
  final double maxWidth;
  final Color? backgroundColor;
  final Color? requestedBarrierColor;
  final bool enableDrag;
  final bool showDragHandle;
  final Widget? dragHandle;
  final Duration _transitionDuration;
  final Duration _reverseTransitionDuration;

  // Built once and disposed with the route. buildTransitions runs on every
  // frame of the transition, so constructing a CurvedAnimation in there leaks
  // one listener per frame.
  CurvedAnimation? _curved;

  @override
  final String? barrierLabel;

  @override
  Color? get barrierColor => mode == SheetMode.modal
      ? (requestedBarrierColor ?? Colors.black54)
      : null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration;

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SideSheetScope(
      handle: _ModalSideSheetHandle<T>(this),
      child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: _DismissibleSideSheet(
        controller: controller!,
        enabled: enableDrag,
        onDismiss: () {
          if (isCurrent) navigator?.pop();
        },
        child: SideSheet(
          width: width,
          maxWidth: maxWidth,
          backgroundColor: backgroundColor,
          child: showDragHandle
              ? _WithDragHandle(
                  handle: dragHandle ??
                      const SheetDragHandle(axis: Axis.vertical),
                  child: Builder(builder: builder),
                )
              : Builder(builder: builder),
        ),
      ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final begin = Offset(ltr ? 1 : -1, 0);
    final curved = _curved ??= CurvedAnimation(
      parent: animation,
      curve: kSheetCurve,
      reverseCurve: kSheetCurve,
    );
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
      child: child,
    );
  }
}

/// Below this speed a release is judged by position; above it, by direction.
/// Matches Flutter's bottom-sheet fling threshold.
const double _kMinFlingVelocity = 700;

/// Past this much of the sheet dragged away, a slow release dismisses.
const double _kCloseProgressThreshold = 0.5;

/// Lets the user throw a side sheet off the trailing edge, the way a bottom
/// sheet is thrown downward.
///
/// It drives the route's own transition controller rather than a private
/// animation, so a partial drag hands straight back to the route: releasing
/// settles it open again, and dismissing simply reverses from wherever the
/// finger left it. Direction-aware — "away" is right in LTR, left in RTL.
class _DismissibleSideSheet extends StatefulWidget {
  const _DismissibleSideSheet({
    required this.controller,
    required this.enabled,
    required this.onDismiss,
    required this.child,
  });

  final AnimationController controller;
  final bool enabled;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_DismissibleSideSheet> createState() => _DismissibleSideSheetState();
}

class _DismissibleSideSheetState extends State<_DismissibleSideSheet> {
  bool _dragging = false;

  double get _width {
    final size = context.size;
    return (size == null || size.width <= 0) ? 1 : size.width;
  }

  bool get _ltr => Directionality.of(context) == TextDirection.ltr;

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.controller.isAnimating && !_dragging) return;
    _dragging = true;
    // Positive = moving toward the trailing edge = closing.
    final double away = _ltr ? details.primaryDelta! : -details.primaryDelta!;
    widget.controller.value = (widget.controller.value - away / _width).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final double awayVelocity = _ltr
        ? details.velocity.pixelsPerSecond.dx
        : -details.velocity.pixelsPerSecond.dx;

    if (awayVelocity > _kMinFlingVelocity) {
      // Thrown away hard enough — go, regardless of how far it got.
      widget.onDismiss();
      return;
    }
    if (widget.controller.value < _kCloseProgressThreshold) {
      widget.onDismiss();
      return;
    }
    // Not far enough: settle back open from wherever it is.
    widget.controller.fling(velocity: 1);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      // Opaque so the whole sheet is draggable, not just its painted parts.
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => _dragging = false,
      child: widget.child,
    );
  }
}

/// Places the drag handle on the sheet's leading edge, beside the content.
class _WithDragHandle extends StatelessWidget {
  const _WithDragHandle({required this.handle, required this.child});

  final Widget handle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [handle, Expanded(child: child)],
    );
  }
}

/// Closes a modal side sheet by popping its route.
class _ModalSideSheetHandle<T> implements SideSheetHandle {
  const _ModalSideSheetHandle(this.route);

  final _SideSheetRoute<T> route;

  @override
  bool get isModal => true;

  @override
  void close([Object? result]) {
    if (route.isCurrent) route.navigator?.pop(result as T?);
  }
}

/// Opens a **persistent** side sheet in the overlay.
///
/// Deliberately not a route: a `PopupRoute` installs a full-screen
/// `ModalBarrier` even with a transparent scrim, which swallows every tap meant
/// for the app behind it and dismisses the sheet on an outside tap. That is the
/// modal contract, and the opposite of what a standard sheet promises. An
/// overlay entry whose child only occupies the sheet's own rectangle leaves the
/// rest of the screen hit-testing straight through to the app.
Future<T?> _showStandardSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required double width,
  required double maxWidth,
  required Color? backgroundColor,
  required bool enableDrag,
  required bool showDragHandle,
  required Widget? dragHandle,
  required bool useRootOverlay,
  required Duration transitionDuration,
  required Duration reverseTransitionDuration,
}) {
  // Same scoping as the modal path: the nearest overlay by default, so a
  // standard sheet sits inside the same region a modal one would scrim.
  final overlay = Overlay.of(context, rootOverlay: useRootOverlay);
  final completer = Completer<T?>();
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _StandardSideSheet<T>(
      builder: builder,
      width: width,
      maxWidth: maxWidth,
      backgroundColor: backgroundColor,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      dragHandle: dragHandle,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      onClosed: (result) {
        if (entry.mounted) entry.remove();
        if (!completer.isCompleted) completer.complete(result);
      },
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

/// The persistent side sheet itself: animates in, rides the trailing edge, and
/// hands its own controller to the shared drag-to-dismiss behaviour.
class _StandardSideSheet<T> extends StatefulWidget {
  const _StandardSideSheet({
    required this.builder,
    required this.width,
    required this.maxWidth,
    required this.backgroundColor,
    required this.enableDrag,
    required this.showDragHandle,
    required this.dragHandle,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    required this.onClosed,
  });

  final WidgetBuilder builder;
  final double width;
  final double maxWidth;
  final Color? backgroundColor;
  final bool enableDrag;
  final bool showDragHandle;
  final Widget? dragHandle;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final ValueChanged<T?> onClosed;

  @override
  State<_StandardSideSheet<T>> createState() => _StandardSideSheetState<T>();
}

class _StandardSideSheetState<T> extends State<_StandardSideSheet<T>>
    with SingleTickerProviderStateMixin
    implements SideSheetHandle {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.transitionDuration,
    reverseDuration: widget.reverseTransitionDuration,
  );

  // The controller is what a drag writes to directly, so the *curve* has to
  // live in a separate animation the view reads — the same split Flutter's
  // bottom sheet uses between its raw animationController and its curved
  // sheet animation.
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: kSheetCurve,
    reverseCurve: kSheetCurve,
  );

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get isModal => false;

  @override
  void close([Object? result]) {
    if (_closing) return;
    _closing = true;
    _controller.reverse().whenComplete(() => widget.onClosed(result as T?));
  }

  @override
  Widget build(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return _SideSheetScope(
      handle: this,
      // Align only hit-tests where its child is, so the rest of the overlay
      // stays transparent to pointers and the app underneath keeps working.
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: AnimatedBuilder(
          animation: _curved,
          builder: (context, child) => FractionalTranslation(
            translation: Offset((ltr ? 1 : -1) * (1 - _curved.value), 0),
            child: child,
          ),
          child: _DismissibleSideSheet(
            controller: _controller,
            enabled: widget.enableDrag,
            onDismiss: close,
            child: SideSheet(
              width: widget.width,
              maxWidth: widget.maxWidth,
              backgroundColor: widget.backgroundColor,
              child: widget.showDragHandle
                  ? _WithDragHandle(
                      handle: widget.dragHandle ??
                          const SheetDragHandle(axis: Axis.vertical),
                      child: Builder(builder: widget.builder),
                    )
                  : Builder(builder: widget.builder),
            ),
          ),
        ),
      ),
    );
  }
}
