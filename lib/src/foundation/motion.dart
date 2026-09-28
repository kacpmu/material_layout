// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// How a value travels from one state to another: on a spring, or along a
/// curve for a fixed duration.
///
/// Material motion is spring-based; [MotionScheme] holds the six
/// Material tokens. A timed curve is accepted as well, for an app that wants
/// the framework's easing instead.
@immutable
final class Motion {
  /// Creates a spring motion from a damping ratio and a stiffness, at unit
  /// mass.
  ///
  /// A ratio below 1 overshoots its target; 1 is critically damped.
  const new spring({
    required double this.dampingRatio,
    required double this.stiffness,
  }) : assert(dampingRatio > 0),
       assert(stiffness > 0),
       _duration = null,
       _curve = null;

  /// Creates a motion that follows [curve] for [duration].
  const new curved({required this._duration, required this._curve})
    : dampingRatio = null,
      stiffness = null;

  /// Creates a motion that reaches its target at once.
  ///
  /// Used where the platform asks for reduced motion.
  const new none() : this.curved(duration: Duration.zero, curve: Curves.linear);

  /// The damping ratio of this spring, or null if this motion is a curve.
  final double? dampingRatio;

  /// The stiffness of this spring, or null if this motion is a curve.
  final double? stiffness;

  final Duration? _duration;

  final Curve? _curve;

  static final Map<Motion, Duration> _settleDurations = <Motion, Duration>{};

  /// Whether this motion is a spring.
  bool get isSpring => dampingRatio != null;

  /// Whether this motion reaches its target at once.
  bool get isNone => !isSpring && _duration == Duration.zero;

  /// The time this motion takes to settle over a unit distance from rest.
  ///
  /// For a spring, the time until it comes to rest within the default
  /// simulation tolerance; for a curve, its duration.
  Duration get duration {
    if (!isSpring) return _duration!;
    return _settleDurations.putIfAbsent(this, () {
      final simulation = this.simulation(0, 1);
      const step = 1 / 1000;
      var time = 0.0;
      while (!simulation.isDone(time) && time < 10) {
        time += step;
      }
      return Duration(
        microseconds: (time * Duration.microsecondsPerSecond).round(),
      );
    });
  }

  /// This motion as a curve over [duration], for animations that run on a
  /// fixed timeline such as route transitions.
  ///
  /// A spring that overshoots produces a curve whose values leave the range
  /// from 0 to 1.
  Curve get curve => isSpring ? _SpringCurve(this) : _curve!;

  /// A simulation that moves from [from] to [to], starting at [velocity].
  ///
  /// A curve ignores [velocity].
  Simulation simulation(double from, double to, {double velocity = 0}) {
    if (isSpring) {
      return SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: stiffness!,
          ratio: dampingRatio!,
        ),
        from,
        to,
        velocity,
      );
    }
    return _CurvedSimulation(from, to, _duration!, _curve!);
  }

  /// A copy of this motion with the given values replaced.
  ///
  /// A spring takes [dampingRatio] and [stiffness]; a curve takes [duration]
  /// and [curve].
  Motion copyWith({
    double? dampingRatio,
    double? stiffness,
    Duration? duration,
    Curve? curve,
  }) {
    if (isSpring) {
      assert(
        duration == null && curve == null,
        'A spring has no duration or curve.',
      );
      return Motion.spring(
        dampingRatio: dampingRatio ?? this.dampingRatio!,
        stiffness: stiffness ?? this.stiffness!,
      );
    }
    assert(
      dampingRatio == null && stiffness == null,
      'A curve has no damping ratio or stiffness.',
    );
    return Motion.curved(
      duration: duration ?? _duration!,
      curve: curve ?? _curve!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Motion &&
      other.dampingRatio == dampingRatio &&
      other.stiffness == stiffness &&
      other._duration == _duration &&
      other._curve == _curve;

  @override
  int get hashCode => Object.hash(dampingRatio, stiffness, _duration, _curve);

  @override
  String toString() => isSpring
      ? 'Motion.spring(dampingRatio: $dampingRatio, stiffness: $stiffness)'
      : 'Motion.curved(duration: $_duration, curve: $_curve)';
}

class _CurvedSimulation extends Simulation {
  new(this._from, this._to, Duration duration, this._curve)
    : _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final double _from;
  final double _to;
  final double _seconds;
  final Curve _curve;

  @override
  double x(double time) {
    if (time >= _seconds) return _to;
    final t = clampDouble(time / _seconds, 0, 1);
    return _from + (_to - _from) * _curve.transform(t);
  }

  @override
  double dx(double time) {
    if (time >= _seconds) return 0;
    const delta = 1e-3;
    final before = math.max(0.0, time - delta);
    final after = time + delta;
    return (x(after) - x(before)) / (after - before);
  }

  @override
  bool isDone(double time) => time >= _seconds;
}

class _SpringCurve extends Curve {
  new(this._motion)
    : _seconds =
          _motion.duration.inMicroseconds / Duration.microsecondsPerSecond,
      _simulation = _motion.simulation(0, 1);

  final Motion _motion;
  final double _seconds;
  final Simulation _simulation;

  @override
  double transformInternal(double t) => _simulation.x(t * _seconds);

  @override
  bool operator ==(Object other) =>
      other is _SpringCurve && other._motion == _motion;

  @override
  int get hashCode => _motion.hashCode;
}

/// The six Material motion tokens of one scheme.
///
/// Spatial tokens move and resize things and may overshoot; effects tokens
/// change opacity and colour and never overshoot. Each comes in fast,
/// default and slow, chosen by the size of what moves: fast for small
/// components, default for surfaces that cover part of the screen, such as
/// panes, sheets and rails, and slow for full-screen changes.
@immutable
final class MotionScheme with Diagnosticable {
  /// The expressive scheme: springs with a slight overshoot.
  ///
  /// The default scheme.
  const new expressive()
    : fastSpatial = const Motion.spring(dampingRatio: 0.6, stiffness: 800),
      defaultSpatial = const Motion.spring(dampingRatio: 0.8, stiffness: 380),
      slowSpatial = const Motion.spring(dampingRatio: 0.8, stiffness: 200),
      fastEffects = const Motion.spring(dampingRatio: 1, stiffness: 3800),
      defaultEffects = const Motion.spring(dampingRatio: 1, stiffness: 1600),
      slowEffects = const Motion.spring(dampingRatio: 1, stiffness: 800);

  /// The standard scheme: springs that are close to critically damped.
  const new standard()
    : fastSpatial = const Motion.spring(dampingRatio: 0.9, stiffness: 1400),
      defaultSpatial = const Motion.spring(dampingRatio: 0.9, stiffness: 700),
      slowSpatial = const Motion.spring(dampingRatio: 0.9, stiffness: 300),
      fastEffects = const Motion.spring(dampingRatio: 1, stiffness: 3800),
      defaultEffects = const Motion.spring(dampingRatio: 1, stiffness: 1600),
      slowEffects = const Motion.spring(dampingRatio: 1, stiffness: 800);

  const new _({
    required this.fastSpatial,
    required this.defaultSpatial,
    required this.slowSpatial,
    required this.fastEffects,
    required this.defaultEffects,
    required this.slowEffects,
  });

  /// The motion scheme in effect for [context].
  ///
  /// Set through `MaterialLayoutThemeData.motionScheme`; expressive when
  /// nothing sets it.
  static MotionScheme of(BuildContext context) =>
      MaterialLayoutTheme.of(context).motionScheme;

  /// Moves small components, such as the drag handle as it is pressed.
  final Motion fastSpatial;

  /// Moves surfaces that cover part of the screen: panes, sheets and rails.
  final Motion defaultSpatial;

  /// Moves surfaces that cover the whole screen.
  final Motion slowSpatial;

  /// Changes the opacity or colour of small components.
  final Motion fastEffects;

  /// Changes the opacity or colour of surfaces that cover part of the screen,
  /// such as a sheet's scrim.
  final Motion defaultEffects;

  /// Changes the opacity or colour of surfaces that cover the whole screen.
  final Motion slowEffects;

  /// Creates a copy of this scheme with the given tokens replaced.
  MotionScheme copyWith({
    Motion? fastSpatial,
    Motion? defaultSpatial,
    Motion? slowSpatial,
    Motion? fastEffects,
    Motion? defaultEffects,
    Motion? slowEffects,
  }) => MotionScheme._(
    fastSpatial: fastSpatial ?? this.fastSpatial,
    defaultSpatial: defaultSpatial ?? this.defaultSpatial,
    slowSpatial: slowSpatial ?? this.slowSpatial,
    fastEffects: fastEffects ?? this.fastEffects,
    defaultEffects: defaultEffects ?? this.defaultEffects,
    slowEffects: slowEffects ?? this.slowEffects,
  );

  @override
  bool operator ==(Object other) =>
      other is MotionScheme &&
      other.fastSpatial == fastSpatial &&
      other.defaultSpatial == defaultSpatial &&
      other.slowSpatial == slowSpatial &&
      other.fastEffects == fastEffects &&
      other.defaultEffects == defaultEffects &&
      other.slowEffects == slowEffects;

  @override
  int get hashCode => Object.hash(
    fastSpatial,
    defaultSpatial,
    slowSpatial,
    fastEffects,
    defaultEffects,
    slowEffects,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Motion>('fastSpatial', fastSpatial))
      ..add(DiagnosticsProperty<Motion>('defaultSpatial', defaultSpatial))
      ..add(DiagnosticsProperty<Motion>('slowSpatial', slowSpatial))
      ..add(DiagnosticsProperty<Motion>('fastEffects', fastEffects))
      ..add(DiagnosticsProperty<Motion>('defaultEffects', defaultEffects))
      ..add(DiagnosticsProperty<Motion>('slowEffects', slowEffects));
  }
}

/// How panes, sheets and navigation enter, leave and resize.
///
/// The two-pane layouts, the sheets and the navigation scaffold take one.
/// By default they use the default spatial token of the scheme in effect,
/// and [PaneMotion.resolve] replaces any motion with [PaneMotion.none] when
/// the platform asks for reduced motion. A navigation bar and rail swap on
/// [enter] and [exit].
///
/// ```dart
/// ListDetailLayout<int>(
///   motion: PaneMotion.from(const MotionScheme.standard()),
///   // …
/// );
/// ```
@immutable
final class PaneMotion with Diagnosticable {
  /// Creates pane motion from its parts.
  ///
  /// [resize] defaults to [enter].
  const new({required this.enter, required this.exit, Motion? resize})
    : resize = resize ?? enter;

  /// Creates pane motion that uses [scheme]'s default spatial token
  /// throughout.
  new from(MotionScheme scheme)
    : enter = scheme.defaultSpatial,
      exit = scheme.defaultSpatial,
      resize = scheme.defaultSpatial;

  /// Creates pane motion in which nothing animates.
  const new none()
    : enter = const Motion.none(),
      exit = const Motion.none(),
      resize = const Motion.none();

  /// The motion of a pane, sheet or navigation component that appears.
  final Motion enter;

  /// The motion of a pane, sheet or navigation component that leaves.
  final Motion exit;

  /// The motion of the spacer settling after a resize, including a pane
  /// collapsing or expanding.
  final Motion resize;

  /// The pane motion in effect for [context].
  ///
  /// Returns [PaneMotion.none] when the platform asks for reduced motion;
  /// otherwise [motion], or motion from the scheme in effect when
  /// [motion] is null.
  static PaneMotion resolve(BuildContext context, PaneMotion? motion) {
    if (MediaQuery.disableAnimationsOf(context)) return const PaneMotion.none();
    return motion ?? PaneMotion.from(MotionScheme.of(context));
  }

  /// A copy of this pane motion with the given motions replaced.
  PaneMotion copyWith({Motion? enter, Motion? exit, Motion? resize}) =>
      PaneMotion(
        enter: enter ?? this.enter,
        exit: exit ?? this.exit,
        resize: resize ?? this.resize,
      );

  @override
  bool operator ==(Object other) =>
      other is PaneMotion &&
      other.enter == enter &&
      other.exit == exit &&
      other.resize == resize;

  @override
  int get hashCode => Object.hash(enter, exit, resize);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Motion>('enter', enter))
      ..add(DiagnosticsProperty<Motion>('exit', exit))
      ..add(DiagnosticsProperty<Motion>('resize', resize));
  }
}

/// Motion as the platform allows it.
extension ReducibleMotion on Motion {
  /// This motion, or [Motion.none] where the platform asks for reduced
  /// motion.
  Motion unlessReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? const Motion.none() : this;
}

/// An animation that moves on a [Motion].
extension MotionAnimation on AnimationController {
  /// Moves to [target] on [motion], from the value and velocity this has,
  /// and ends exactly there: a spring comes to rest within its tolerance, a
  /// fraction short of its target. Where [motion] is none, moves at once.
  TickerFuture animateOn(Motion motion, double target) {
    if (motion.isNone) {
      value = target;
      return TickerFuture.complete();
    }
    final moving = animateWith(
      motion.simulation(value, target, velocity: velocity),
    );
    moving.then((_) => value = target);
    return moving;
  }
}
