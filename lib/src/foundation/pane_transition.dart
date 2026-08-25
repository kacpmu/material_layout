import 'package:flutter/material.dart';

/// Describes how a pane's content animates when it changes — for example the
/// detail pane appearing in a [ListDetailLayout], or the detail content being
/// swapped in two-pane mode.
///
/// A [PaneTransition] is consumed by an [AnimatedSwitcher]: it supplies the
/// [duration], the in/out [Curve]s, and a [buildTransition] builder.
///
/// Presets:
/// * [PaneTransition.standard] — emphasized fade + subtle scale (the default).
/// * [PaneTransition.bounce] — an expressive springy overshoot (Material 3
///   Expressive flavour).
/// * [PaneTransition.none] — no animation (instant swap).
/// * [PaneTransition.custom] — provide your own [AnimatedSwitcherTransitionBuilder].
sealed class PaneTransition {
  const PaneTransition();

  /// Emphasized fade + subtle scale-in. The default pane transition.
  const factory PaneTransition.standard({Duration? duration}) =
      StandardPaneTransition;

  /// An expressive springy overshoot, in the spirit of Material 3 Expressive
  /// spatial motion.
  const factory PaneTransition.bounce({Duration? duration}) =
      BouncePaneTransition;

  /// No animation; content swaps instantly.
  const factory PaneTransition.none() = NonePaneTransition;

  /// A fully custom transition.
  const factory PaneTransition.custom({
    required AnimatedSwitcherTransitionBuilder builder,
    Duration duration,
    Curve switchInCurve,
    Curve switchOutCurve,
  }) = CustomPaneTransition;

  /// How long the transition runs.
  Duration get duration;

  /// The curve applied to the incoming child.
  Curve get switchInCurve;

  /// The curve applied to the outgoing child.
  Curve get switchOutCurve;

  /// Wraps [child] with the transition driven by [animation]. Matches the
  /// [AnimatedSwitcherTransitionBuilder] signature.
  Widget buildTransition(Widget child, Animation<double> animation);
}

/// The default emphasized fade + subtle scale transition.
class StandardPaneTransition extends PaneTransition {
  /// Creates a standard pane transition.
  // The field is private but the parameter is public; an initializing
  // formal would rename the parameter and change the public API.
  // ignore: prefer_initializing_formals
  const StandardPaneTransition({Duration? duration}) : _duration = duration;

  final Duration? _duration;

  @override
  Duration get duration => _duration ?? const Duration(milliseconds: 400);

  @override
  Curve get switchInCurve => Curves.easeInOutCubicEmphasized;

  @override
  Curve get switchOutCurve => const Threshold(0); // fade the old child out fast

  @override
  Widget buildTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
        child: child,
      ),
    );
  }
}

/// An expressive springy transition with a little overshoot.
class BouncePaneTransition extends PaneTransition {
  /// Creates a bouncy pane transition.
  // The field is private but the parameter is public; an initializing
  // formal would rename the parameter and change the public API.
  // ignore: prefer_initializing_formals
  const BouncePaneTransition({Duration? duration}) : _duration = duration;

  final Duration? _duration;

  @override
  Duration get duration => _duration ?? const Duration(milliseconds: 520);

  // Keep the switcher animation within [0, 1] (opacity-safe); the springy
  // overshoot is applied to the scale only.
  @override
  Curve get switchInCurve => Curves.easeOut;

  @override
  Curve get switchOutCurve => const Threshold(0);

  @override
  Widget buildTransition(Widget child, Animation<double> animation) {
    final scale = animation
        .drive(CurveTween(curve: Curves.elasticOut))
        .drive(Tween<double>(begin: 0.85, end: 1));
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

/// A transition that swaps content instantly.
class NonePaneTransition extends PaneTransition {
  /// Creates a no-op transition.
  const NonePaneTransition();

  @override
  Duration get duration => Duration.zero;

  @override
  Curve get switchInCurve => Curves.linear;

  @override
  Curve get switchOutCurve => Curves.linear;

  @override
  Widget buildTransition(Widget child, Animation<double> animation) => child;
}

/// A transition backed by a user-supplied builder.
class CustomPaneTransition extends PaneTransition {
  /// Creates a custom transition.
  const CustomPaneTransition({
    required this.builder,
    this.duration = const Duration(milliseconds: 400),
    this.switchInCurve = Curves.easeInOut,
    this.switchOutCurve = Curves.easeInOut,
  });

  /// The transition builder, matching [AnimatedSwitcher.transitionBuilder].
  final AnimatedSwitcherTransitionBuilder builder;

  @override
  final Duration duration;

  @override
  final Curve switchInCurve;

  @override
  final Curve switchOutCurve;

  @override
  Widget buildTransition(Widget child, Animation<double> animation) =>
      builder(child, animation);
}
