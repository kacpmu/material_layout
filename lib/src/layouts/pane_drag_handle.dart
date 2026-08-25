import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Moves the divider by one step. [direction] is -1 toward the leading edge and
/// +1 toward the trailing edge, before text direction is applied.
class _NudgeIntent extends Intent {
  const _NudgeIntent(this.direction, {this.big = false});

  final double direction;

  /// A coarse jump (Home/End) rather than a single step.
  final bool big;
}

/// A soft, loosely-damped spring with a gentle overshoot, used as the default
/// motion for the pane reveal/resize/snap in `ListDetailLayout` and `TwoPane`.
///
/// Tuning (mass 1): the natural frequency ω₀ = √stiffness ≈ 13.4 rad/s sets the
/// speed (lower = looser/slower); the damping ratio ζ = damping / (2·√stiffness)
/// ≈ 0.60 sets the settle (≈ 9% overshoot — a clear, soft bounce). Raise
/// [SpringDescription.damping] (≈ 27 ⇒ critically damped) to remove the bounce,
/// or lower it for a bigger one.
const SpringDescription kExpressiveSpring = SpringDescription(
  mass: 1,
  stiffness: 180,
  damping: 16,
);

/// A draggable grip shown in the gutter between two resizable panes.
///
/// The grip animates **wider while pressed/held** and back to its resting width
/// on release, and shows a left/right resize cursor on the desktop/web. It
/// reports raw horizontal drag deltas via [onDragUpdate]; the parent decides
/// how a delta maps onto the split (and handles text direction).
class PaneDragHandle extends StatefulWidget {
  /// Creates a pane drag handle.
  const PaneDragHandle({
    super.key,
    required this.onDragUpdate,
    this.onDragEnd,
    this.onDoubleTap,
    this.gutterWidth = 24,
    this.thickness = 4,
    this.pressedThickness = 8,
    this.indicatorHeight = 48,
    this.color,
    this.duration = const Duration(milliseconds: 150),
    this.semanticLabel = 'Resize panes',
    this.keyboardStep = 24,
  });

  /// The label a screen reader announces for the handle.
  ///
  /// Defaults to English; pass a localized string. The handle reports itself as
  /// a slider with increase/decrease actions, so assistive tech can move the
  /// divider without a pointer.
  final String semanticLabel;

  /// How far one arrow-key press (or one semantic increase/decrease) moves the
  /// divider, in logical pixels. Home/End move ten steps. Defaults to 24.
  final double keyboardStep;

  /// Called with the horizontal drag delta (logical pixels) during a drag.
  final ValueChanged<double> onDragUpdate;

  /// Called when a drag ends or is cancelled.
  final VoidCallback? onDragEnd;

  /// Called when the handle is double-tapped — e.g. to collapse/expand a pane
  /// (toggle between a one-pane and two-pane layout).
  final VoidCallback? onDoubleTap;

  /// The width of the hit area / gutter the handle occupies.
  final double gutterWidth;

  /// The resting width of the visible grip.
  final double thickness;

  /// The width of the grip while pressed/held.
  final double pressedThickness;

  /// The height of the visible grip.
  final double indicatorHeight;

  /// The grip color. Defaults to the theme's outline variant.
  final Color? color;

  /// The width animation duration.
  final Duration duration;

  @override
  State<PaneDragHandle> createState() => _PaneDragHandleState();
}

class _PaneDragHandleState extends State<PaneDragHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() => _controller.forward();
  void _release() {
    _controller.reverse();
    widget.onDragEnd?.call();
  }

  /// Nudges the split by [keyboardStep], in the same units the drag reports, so
  /// the divider is reachable without a pointer.
  ///
  /// Deliberately does **not** fire [PaneDragHandle.onDragEnd]. That is the
  /// release-snap, and its magnet radius is wider than a single step — running
  /// it after every nudge would drag the divider straight back to the stop it
  /// just left, so the keyboard could never move it at all. A drag reports many
  /// deltas and then one release; a nudge is already a finished, committed move.
  void _nudge(double delta) => widget.onDragUpdate(delta);

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.outlineVariant;
    final bool ltr = Directionality.of(context) == TextDirection.ltr;
    final double step = widget.keyboardStep;
    // "Increase" means giving the leading pane more room, which is a positive
    // delta in LTR and a negative one in RTL — the parent maps raw deltas onto
    // the split and handles direction, so mirror here to match.
    final double grow = ltr ? step : -step;

    return Semantics(
      // Announced and operable as a slider-like control: assistive tech gets a
      // labelled target with working increase/decrease actions instead of an
      // unlabelled box that only answers to a drag it cannot perform.
      label: widget.semanticLabel,
      slider: true,
      onIncrease: () => _nudge(grow),
      onDecrease: () => _nudge(-grow),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.resizeLeftRight,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft): _NudgeIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowRight): _NudgeIntent(1),
          SingleActivator(LogicalKeyboardKey.home): _NudgeIntent(-1, big: true),
          SingleActivator(LogicalKeyboardKey.end): _NudgeIntent(1, big: true),
        },
        actions: <Type, Action<Intent>>{
          _NudgeIntent: CallbackAction<_NudgeIntent>(
            onInvoke: (intent) {
              final double magnitude = intent.big ? step * 10 : step;
              _nudge((ltr ? 1 : -1) * intent.direction * magnitude);
              return null;
            },
          ),
        },
        child: _buildHandle(context, color),
      ),
    );
  }

  Widget _buildHandle(BuildContext context, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTap,
        onHorizontalDragDown: (_) => _press(),
        onHorizontalDragStart: (_) => _press(),
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        onHorizontalDragEnd: (_) => _release(),
        onHorizontalDragCancel: _release,
        child: SizedBox(
          width: widget.gutterWidth,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final grip = Tween<double>(
                  begin: widget.thickness,
                  end: widget.pressedThickness,
                ).transform(Curves.easeOut.transform(_controller.value));
                // Never exceed the gutter, so the grip can't bleed onto the
                // panes when the gutter is narrow — e.g. while a pane-reveal
                // animation is opening the gutter from zero width.
                final width = math.min(grip, widget.gutterWidth);
                return Container(
                  width: width,
                  height: widget.indicatorHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(width / 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
