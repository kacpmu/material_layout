// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../foundation/localizations.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import 'pane_split.dart';

/// The layout a drag handle resizes.
///
/// Distances and velocities are measured along the layout's axis, positive
/// in the direction that widens the resizable pane.
abstract interface class PaneResizeTarget {
  /// Whether the resizable pane is the leading one.
  bool get resizableIsLeading;

  /// Starts a drag.
  void beginResize();

  /// Moves the spacer by [delta].
  void updateResize(double delta);

  /// Ends a drag at [velocity], settling on the nearest of [snapStops], or
  /// on the layout's default stops when [snapStops] is null.
  void endResize(double velocity, List<PaneSplit>? snapStops);

  /// Abandons a drag, returning to the split it started from.
  ///
  /// A handle calls it when its drag is cancelled, and when it is removed
  /// during one.
  void cancelResize();

  /// The stops a resize settles on, feasible at the current size and ordered
  /// from the narrowest resizable pane to the widest.
  List<PaneSplit> stopsFor(List<PaneSplit>? snapStops);

  /// The adjacent stop that widens the resizable pane when [direction] is
  /// positive, or narrows it when negative; null when there is none that way.
  PaneSplit? adjacentStop(int direction, List<PaneSplit>? snapStops);

  /// Moves to [split], and announces it.
  ///
  /// Hiding a pane that the handle dismisses dismisses it instead, and
  /// hiding one that it may not hide does nothing.
  void moveTo(PaneSplit split);

  /// Hides the pane the handle hides first, or shows both panes again when
  /// one is hidden, and announces it.
  void toggle();

  /// The split [toggle] hides a pane with while both panes show, or null
  /// where the handle may hide neither.
  PaneSplit? get hideTarget;

  /// Whether moving to [split] dismisses the pane it hides.
  bool dismisses(PaneSplit split);

  /// The resizable pane's share of the space under [split], in percent.
  int percentFor(PaneSplit split);
}

/// Publishes a [PaneResizeTarget] to the drag handle of a layout.
class PaneResizeScope extends InheritedWidget {
  /// Publishes [target] to [child].
  const new({
    super.key,
    required this.target,
    required this.split,
    required this.space,
    required this.percent,
    required this.collapse,
    required super.child,
  });

  /// The layout to resize.
  final PaneResizeTarget target;

  /// The current split.
  final PaneSplit split;

  /// The space the panes share, which the stops and the resizable pane's
  /// share are measured against.
  final double space;

  /// The resizable pane's current share of the space, in percent.
  final int percent;

  /// What the handle may do to the resizable pane and to the other one.
  final (PaneCollapse, PaneCollapse) collapse;

  /// The scope enclosing [context], or null.
  static PaneResizeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneResizeScope>();

  @override
  bool updateShouldNotify(PaneResizeScope oldWidget) =>
      target != oldWidget.target ||
      split != oldWidget.split ||
      space != oldWidget.space ||
      percent != oldWidget.percent ||
      collapse != oldWidget.collapse;
}

/// Called by a gesture on a drag handle, with the [handle] it was made on.
typedef PaneHandleCallback = void Function(PaneHandle handle);

/// The drag handle of a two-pane layout, as its gestures and its grip see
/// it: the split it sets, the stops it settles on, and what it can do.
///
/// A [PaneResizer] passes one to its gesture callbacks, and a grip inside it
/// reads one with [PaneHandle.maybeOf]:
///
/// ```dart
/// PaneResizer(
///   // A tap moves on to the next stop, and from the last back to the first.
///   onTap: (handle) {
///     final stops = handle.stops;
///     final next = stops.indexOf(handle.split) + 1;
///     handle.moveTo(stops[next % stops.length]);
///   },
/// )
/// ```
///
/// Its values are those of the frame it was obtained in.
abstract final class PaneHandle {
  const new _();

  /// The split the layout is at.
  PaneSplit get split;

  /// The splits the handle settles on at the layout's current size, ordered
  /// from the narrowest resizable pane to the widest.
  ///
  /// [PaneSplit.collapsed] and [PaneSplit.expanded] are among them where the
  /// layout lets the handle hide the pane they hide.
  List<PaneSplit> get stops;

  /// Hides the pane the handle hides first, or shows both panes again when
  /// one is hidden, as a double tap does by default.
  ///
  /// The handle hides the resizable pane first, where the layout lets it,
  /// and the other pane otherwise. Showing both panes again returns to the
  /// split they last had, or to the default where the layout forgets
  /// resizes.
  void toggle();

  /// Moves to [split], announcing it to assistive technology.
  ///
  /// Hiding a pane that the layout dismisses rather than collapses
  /// dismisses it, and hiding one that the layout does not let the handle
  /// hide does nothing (see [PaneCollapse]).
  void moveTo(PaneSplit split);

  /// The drag handle enclosing [context], or null outside one.
  ///
  /// Inside a [PaneResizer], the handle with its [PaneResizer.snapStops].
  static PaneHandle? maybeOf(BuildContext context) {
    final resizer = context
        .dependOnInheritedWidgetOfExactType<_PaneResizerScope>();
    if (resizer != null) return resizer.handle;
    final scope = PaneResizeScope.maybeOf(context);
    return scope == null ? null : _PaneHandle(scope, null);
  }
}

final class _PaneHandle extends PaneHandle {
  const new(this._scope, this._snapStops) : super._();

  final PaneResizeScope _scope;
  final List<PaneSplit>? _snapStops;

  @override
  PaneSplit get split => _scope.split;

  @override
  List<PaneSplit> get stops => _scope.target.stopsFor(_snapStops);

  @override
  void toggle() => _scope.target.toggle();

  @override
  void moveTo(PaneSplit split) => _scope.target.moveTo(split);
}

/// A drag handle that resizes the panes of the layout it is placed in, around
/// a grip that only draws.
///
/// A layout shows the default handle when it is resizable: a
/// [PaneResizer] around a [PaneDragHandle]. To change the grip's appearance
/// while keeping the behaviour, give the layout a [PaneResizer] with another
/// child; the grip can read the handle's interaction states from
/// [PaneResizer.statesOf], and the handle itself from [PaneHandle.maybeOf].
///
/// ```dart
/// ListDetailLayout<int>(
///   resizable: true,
///   dragHandle: const PaneResizer(child: MyGrip()),
///   // …
/// );
/// ```
///
/// A [PaneResizer] supplies what the handle must do whatever it looks like:
///
///  * a target of at least 48 by 48dp around the grip, extending beyond it,
///    and the spacer's full height as a drag area — and no more,
///    so that the panes beside it keep their input;
///  * dragging, which settles on the nearest of [snapStops];
///  * by default, a tap, which returns to the default split, a double tap,
///    which hides a pane or shows both again, as Enter and Space do, and a
///    long press, which splits the panes evenly; [onTap], [onDoubleTap] and
///    [onLongPress] choose what each gesture does;
///  * the arrow keys, which move to the adjacent stop, and Home and End,
///    which move to the first and last;
///  * slider semantics with the resizable pane's share as the value, an
///    action per stop, and an announcement when a gesture, a key or an
///    action moves the split; a drag, which shows where it leaves the
///    panes as it goes, announces nothing.
///
/// A drag handle that is not a [PaneResizer] receives none of this, and is
/// then responsible for meeting those rules itself.
class PaneResizer extends StatefulWidget {
  /// Creates a drag handle around [child].
  const new({
    super.key,
    this.snapStops,
    this.onTap = restore,
    this.onDoubleTap = toggle,
    this.onLongPress = splitEvenly,
    this.child = const PaneDragHandle(),
  });

  /// The splits a resize settles on, or null for the layout's defaults.
  ///
  /// The defaults are the stops Material allows: from expanded upwards
  /// 360dp, 412dp and the centred split, and the even split where the panes
  /// split evenly, at medium; the layout's default split, as a side sheet's
  /// own width; and, on either side, the end where the layout lets the handle
  /// hide the pane there ([PaneCollapse]). Stops that do not
  /// fit the current size are left out, as are those that would hide a pane
  /// that the layout does not let the handle hide. An empty list lets a drag
  /// rest anywhere between the panes' minimum widths.
  final List<PaneSplit>? snapStops;

  /// Called when the handle is tapped: by default [restore], which returns
  /// to the default split. Null does nothing on a tap.
  final PaneHandleCallback? onTap;

  /// Called when the handle is tapped twice in quick succession: by default
  /// [toggle], which hides a pane or shows both again.
  ///
  /// Listening for a second tap delays a single one, so null, which switches
  /// double taps off, lets [onTap] respond at once.
  final PaneHandleCallback? onDoubleTap;

  /// Called when the handle is pressed, held still and let go: by default
  /// [splitEvenly]. Null listens for no long press, and a press held still
  /// is then a tap.
  ///
  /// A handle that is held and then moved is dragged instead.
  final PaneHandleCallback? onLongPress;

  /// The grip.
  final Widget child;

  /// Hides the pane the handle hides first, or shows both panes again: the
  /// default [onDoubleTap], and what Enter, Space and the handle's
  /// accessibility action always do.
  static void toggle(PaneHandle handle) => handle.toggle();

  /// Returns to the layout's default split, showing both panes: the default
  /// [onTap].
  static void restore(PaneHandle handle) => handle.moveTo(PaneSplit.automatic);

  /// Divides the space evenly, with the spacer in the middle of the window,
  /// showing both panes: the default [onLongPress].
  ///
  /// A pane with a maximum width, as a side sheet, keeps to it.
  static void splitEvenly(PaneHandle handle) =>
      handle.moveTo(PaneSplit.centered);

  /// The interaction states of the drag handle enclosing [context]: hovered,
  /// focused, pressed and dragged.
  ///
  /// Empty outside a [PaneResizer].
  static Set<WidgetState> statesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PaneResizerStates>()
          ?.states ??
      const <WidgetState>{};

  @override
  State<PaneResizer> createState() => _PaneResizerState();
}

class _PaneResizerState extends State<PaneResizer> {
  final _states = <WidgetState>{};
  PaneResizeTarget? _dragging;
  // The pointers down on the handle, and those moving it, a trackpad's
  // included.
  final _pressing = <int>{};
  final _pointers = <int>{};
  bool _pointerCancelled = false;
  // Where the pointer that holds the handle after a long press was last,
  // across the screen, and whether it has moved the handle since. A handle
  // held and then moved is dragged; one let go where it was held is
  // long-pressed.
  double? _heldAt;
  bool _heldMoves = false;

  @override
  void dispose() {
    _dragging?.cancelResize();
    super.dispose();
  }

  // A pointer lifted after the handle has gone, as when a drag removes it,
  // still reaches it.
  void _setState(WidgetState state, bool active) {
    final changed = active ? _states.add(state) : _states.remove(state);
    if (changed && mounted) setState(() {});
  }

  PaneResizeScope get _scope {
    final scope = PaneResizeScope.maybeOf(context);
    assert(
      scope != null,
      'A PaneResizer resizes the layout it is placed in. Give it to a '
      "layout's dragHandle.",
    );
    return scope!;
  }

  // Positive when a movement to the right widens the resizable pane.
  double get _rightward {
    final leading = _scope.target.resizableIsLeading ? 1.0 : -1.0;
    return Directionality.of(context) == TextDirection.rtl ? -leading : leading;
  }

  void _step(int direction) {
    final split = _scope.target.adjacentStop(direction, widget.snapStops);
    if (split != null) _scope.target.moveTo(split);
  }

  void _stepRight(int direction) => _step(direction * _rightward.toInt());

  void _toEnd({required bool widest}) {
    final stops = _scope.target.stopsFor(widget.snapStops);
    if (stops.isEmpty) return;
    _scope.target.moveTo(widest ? stops.last : stops.first);
  }

  void _pointerDown(PointerEvent event, {required bool press}) {
    _pointers.add(event.pointer);
    _pointerCancelled = false;
    if (press && _pressing.add(event.pointer)) {
      _setState(WidgetState.pressed, true);
    }
  }

  void _pointerUp(PointerEvent event, {bool cancelled = false}) {
    _pointers.remove(event.pointer);
    // A drag ends on a cancel only when the platform cancels the last pointer
    // that was moving it.
    if (cancelled && _pointers.isEmpty) _pointerCancelled = true;
    if (_pressing.remove(event.pointer) && _pressing.isEmpty) {
      _setState(WidgetState.pressed, false);
    }
  }

  void _startDrag() {
    _pointerCancelled = false;
    _setState(WidgetState.dragged, true);
    _dragging = _scope.target..beginResize();
  }

  void _holdStart(LongPressStartDetails details) {
    _heldAt = details.globalPosition.dx;
    _heldMoves = false;
  }

  void _holdMove(LongPressMoveUpdateDetails details) {
    final last = _heldAt;
    if (last == null) return;
    final x = details.globalPosition.dx;
    if (!_heldMoves) {
      // A hand that trembles a little still lets go of a long press. Past
      // the slop, the drag starts where the pointer is, as any drag does.
      if (details.offsetFromOrigin.dx.abs() <= kTouchSlop) return;
      _heldMoves = true;
      _heldAt = x;
      _startDrag();
      return;
    }
    _heldAt = x;
    _dragging?.updateResize((x - last) * _rightward);
  }

  void _holdEnd(LongPressEndDetails details, PaneHandle handle) {
    if (_heldAt == null) return;
    _heldAt = null;
    if (_heldMoves) {
      _heldMoves = false;
      _endDrag(velocity: details.velocity.pixelsPerSecond.dx);
    } else {
      widget.onLongPress?.call(handle);
    }
  }

  void _holdCancel() {
    if (_heldAt == null) return;
    _heldAt = null;
    if (_heldMoves) {
      _heldMoves = false;
      _endDrag();
    }
  }

  // Ends a drag: settles, or returns to where it started when the drag or
  // its pointer was cancelled.
  void _endDrag({double? velocity}) {
    _setState(WidgetState.dragged, false);
    final target = _dragging;
    _dragging = null;
    final cancelled = _pointerCancelled;
    _pointerCancelled = false;
    if (velocity == null || cancelled) {
      target?.cancelResize();
    } else {
      target?.endResize(velocity * _rightward, widget.snapStops);
    }
  }

  static String _label(
    MaterialLayoutLocalizations strings,
    PaneResizeTarget target,
    PaneSplit split,
  ) {
    if (target.dismisses(split)) {
      return strings.closePaneAction;
    }
    if (split.isCollapsed) return strings.collapsePaneAction;
    if (split.isExpanded) return strings.expandPaneAction;
    if (split == PaneSplit.centered) return strings.splitPanesEvenlyAction;
    if (split == PaneSplit.automatic) return strings.restorePaneAction;
    return strings.setPaneWidthAction(split.width!.round());
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final target = scope.target;
    final strings = MaterialLayoutLocalizations.of(context);
    final stops = target.stopsFor(widget.snapStops);
    final wider = target.adjacentStop(1, widget.snapStops);
    final narrower = target.adjacentStop(-1, widget.snapStops);
    // A toggle shows both panes again, or hides the pane the handle hides
    // first, where there is one.
    final hides = scope.split.showsBothPanes ? target.hideTarget : null;
    final toggles = !scope.split.showsBothPanes || hides != null;
    final handle = _PaneHandle(scope, widget.snapStops);
    String valueOf(PaneSplit split) =>
        strings.paneResizerValue(target.percentFor(split));
    VoidCallback? gesture(PaneHandleCallback? callback) =>
        callback == null ? null : () => callback(handle);
    final longPress = widget.onLongPress != null;

    return _PaneResizerScope(
      handle: handle,
      child: _PaneResizerStates(
        states: Set<WidgetState>.of(_states),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.resizeColumn,
          onShowFocusHighlight: (value) =>
              _setState(WidgetState.focused, value),
          onShowHoverHighlight: (value) =>
              _setState(WidgetState.hovered, value),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(
              -1,
              visual: true,
            ),
            SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(
              1,
              visual: true,
            ),
            SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
            SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
            SingleActivator(LogicalKeyboardKey.home): _EndIntent(widest: false),
            SingleActivator(LogicalKeyboardKey.end): _EndIntent(widest: true),
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            _StepIntent: CallbackAction<_StepIntent>(
              // Left and right follow the screen; up and down follow the
              // value, as on a slider.
              onInvoke: (intent) => intent.visual
                  ? _stepRight(intent.direction)
                  : _step(intent.direction),
            ),
            _EndIntent: CallbackAction<_EndIntent>(
              onInvoke: (intent) => _toEnd(widest: intent.widest),
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => target.toggle(),
            ),
          },
          child: Semantics(
            slider: true,
            label: strings.paneResizerLabel,
            value: strings.paneResizerValue(scope.percent),
            increasedValue: wider == null ? null : valueOf(wider),
            decreasedValue: narrower == null ? null : valueOf(narrower),
            onIncrease: wider == null ? null : () => target.moveTo(wider),
            onDecrease: narrower == null ? null : () => target.moveTo(narrower),
            onTap: toggles ? target.toggle : null,
            onTapHint: !toggles
                ? null
                : hides == null
                ? strings.restorePaneAction
                : _label(strings, target, hides),
            customSemanticsActions: {
              for (final stop in stops)
                CustomSemanticsAction(
                  label: _label(strings, target, stop),
                ): () =>
                    target.moveTo(stop),
            },
            child: Listener(
              onPointerDown: (event) => _pointerDown(event, press: true),
              onPointerUp: _pointerUp,
              onPointerCancel: (event) => _pointerUp(event, cancelled: true),
              onPointerPanZoomStart: (event) =>
                  _pointerDown(event, press: false),
              onPointerPanZoomEnd: _pointerUp,
              child: GestureDetector(
                // The layout limits the handle's input to its target.
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                // Only the gestures in use are listened for, so that a tap
                // is not held back to see whether a second one follows.
                onTap: gesture(widget.onTap),
                onDoubleTap: gesture(widget.onDoubleTap),
                onLongPressStart: longPress ? _holdStart : null,
                onLongPressMoveUpdate: longPress ? _holdMove : null,
                onLongPressEnd: longPress
                    ? (details) => _holdEnd(details, handle)
                    : null,
                onLongPressCancel: longPress ? _holdCancel : null,
                onHorizontalDragStart: (_) => _startDrag(),
                onHorizontalDragUpdate: (details) =>
                    _dragging?.updateResize(details.primaryDelta! * _rightward),
                // A drag whose pointer the platform cancels ends here too.
                onHorizontalDragEnd: (details) =>
                    _endDrag(velocity: details.primaryVelocity),
                onHorizontalDragCancel: _endDrag,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIntent extends Intent {
  const new(this.direction, {this.visual = false});

  final int direction;
  final bool visual;
}

class _EndIntent extends Intent {
  const new({required this.widest});

  final bool widest;
}

class _PaneResizerScope extends InheritedWidget {
  const new({required this.handle, required super.child});

  final PaneHandle handle;

  // The handle is made anew with each build of its resizer, from the values
  // of that frame.
  @override
  bool updateShouldNotify(_PaneResizerScope oldWidget) => true;
}

class _PaneResizerStates extends InheritedWidget {
  const new({required this.states, required super.child});

  final Set<WidgetState> states;

  @override
  bool updateShouldNotify(_PaneResizerStates oldWidget) =>
      !setEquals(states, oldWidget.states);
}

/// The grip of a drag handle: a pill that grows while it is pressed or
/// dragged.
///
/// Its size and colours are [style]'s, then those of
/// `MaterialLayoutThemeData.dragHandleStyle`, then Material's. It grows on
/// the fast spatial spring, and shows a focus ring when focused from the
/// keyboard. It has no behaviour of its own: place it in a [PaneResizer].
class PaneDragHandle extends StatefulWidget {
  /// Creates a drag handle grip.
  const new({super.key, this.style});

  /// The grip's size and colours, or null for the theme's.
  ///
  /// A value it leaves null is the theme's, and then Material's.
  final DragHandleStyle? style;

  @override
  State<PaneDragHandle> createState() => _PaneDragHandleState();
}

class _PaneDragHandleState extends State<PaneDragHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool? _pressed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final states = PaneResizer.statesOf(context);
    final pressed =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.dragged);
    if (pressed == _pressed) return;
    final first = _pressed == null;
    _pressed = pressed;
    final target = pressed ? 1.0 : 0.0;
    final motion = MotionScheme.of(context).fastSpatial.unlessReduced(context);
    _press.animateOn(first ? const Motion.none() : motion, target);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MaterialLayoutTheme.of(context).dragHandleStyle;
    final own = widget.style;
    final colors = Theme.of(context).colorScheme;
    final focused = PaneResizer.statesOf(context).contains(WidgetState.focused);
    return CustomPaint(
      size: Size.infinite,
      painter: _GripPainter(
        press: _press,
        thickness: own?.thickness ?? theme.thickness ?? 4,
        length: own?.length ?? theme.length ?? 48,
        pressedThickness: own?.pressedThickness ?? theme.pressedThickness ?? 12,
        pressedLength: own?.pressedLength ?? theme.pressedLength ?? 52,
        color: own?.color ?? theme.color ?? colors.outline,
        pressedColor:
            own?.pressedColor ?? theme.pressedColor ?? colors.onSurface,
        focusColor: focused ? colors.secondary : null,
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  new({
    required this.press,
    required this.thickness,
    required this.length,
    required this.pressedThickness,
    required this.pressedLength,
    required this.color,
    required this.pressedColor,
    required this.focusColor,
  }) : super(repaint: press);

  final Animation<double> press;
  final double thickness;
  final double length;
  final double pressedThickness;
  final double pressedLength;
  final Color color;
  final Color pressedColor;
  final Color? focusColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = press.value;
    final width = math.max(0.0, lerpDouble(thickness, pressedThickness, t)!);
    final height = math.max(0.0, lerpDouble(length, pressedLength, t)!);
    final grip = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(grip, Radius.circular(width / 2)),
      Paint()..color = Color.lerp(color, pressedColor, clampDouble(t, 0, 1))!,
    );
    final focus = focusColor;
    if (focus != null) {
      const gap = 2.0;
      const stroke = 3.0;
      final ring = grip.inflate(gap + stroke / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ring, Radius.circular(ring.width / 2)),
        Paint()
          ..color = focus
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
  }

  // The grip is only drawn; the resizer decides where the handle takes
  // input.
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_GripPainter oldDelegate) =>
      press != oldDelegate.press ||
      thickness != oldDelegate.thickness ||
      length != oldDelegate.length ||
      pressedThickness != oldDelegate.pressedThickness ||
      pressedLength != oldDelegate.pressedLength ||
      color != oldDelegate.color ||
      pressedColor != oldDelegate.pressedColor ||
      focusColor != oldDelegate.focusColor;
}
