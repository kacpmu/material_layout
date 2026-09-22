import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// The Material 3 spatial spring tokens, for motion that moves or resizes
/// something on screen.
///
/// Each is given as a damping ratio and a stiffness (mass 1), as the tokens
/// are specified; the [SpringDescription.damping] below is
/// `2 · ratio · √stiffness`, precomputed so the constants can be `const`.
///
/// The *expressive* scheme overshoots slightly (ratio < 0.9); the *standard*
/// scheme is close to critically damped. [expressiveDefaultSpatial] is the
/// default for pane motion in this package.
abstract final class MaterialSprings {
  /// Expressive fast spatial: damping ratio 0.6, stiffness 800.
  static const SpringDescription expressiveFastSpatial = SpringDescription(
    mass: 1,
    stiffness: 800,
    damping: 33.941,
  );

  /// Expressive default spatial: damping ratio 0.8, stiffness 380.
  static const SpringDescription expressiveDefaultSpatial = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 31.19,
  );

  /// Expressive slow spatial: damping ratio 0.8, stiffness 200.
  static const SpringDescription expressiveSlowSpatial = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 22.627,
  );

  /// Standard fast spatial: damping ratio 0.9, stiffness 1400.
  static const SpringDescription standardFastSpatial = SpringDescription(
    mass: 1,
    stiffness: 1400,
    damping: 67.35,
  );

  /// Standard default spatial: damping ratio 0.9, stiffness 700.
  static const SpringDescription standardDefaultSpatial = SpringDescription(
    mass: 1,
    stiffness: 700,
    damping: 47.624,
  );

  /// Standard slow spatial: damping ratio 0.9, stiffness 300.
  static const SpringDescription standardSlowSpatial = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 31.177,
  );
}

/// How long a pane takes to leave under [PaneTransition.curvedExit].
const Duration kPaneExitDuration = Duration(milliseconds: 300);

/// The curve a pane leaves on under [PaneTransition.curvedExit].
///
/// Material 3 *emphasized* easing, not emphasized *accelerate*: the leaving
/// pane's width is also the staying pane's width (they always sum to the
/// region), so the curve's tail is not just the leaving pane's business.
/// Accelerate spends ~30% of the distance in its final frames, which lands as a
/// visible jump in the pane that is staying. Emphasized easing settles instead.
const Curve kPaneExitCurve = Curves.easeInOutCubicEmphasized;

/// How a pane **enters and leaves** — the detail pane of a `ListDetailLayout`,
/// the supporting pane of a `SupportingPaneLayout`, or the secondary of a
/// `TwoPane`.
///
/// The pane's width is what moves: entering, it grows from nothing to its
/// resting width without its content reflowing; leaving, it and its gutter
/// travel off the trailing edge. The content inside the pane is not animated:
/// a pane that stays open replaces its content in place.
///
/// Presets:
/// * [PaneTransition.spring] — enter and leave on one spring. The default,
///   on [MaterialSprings.expressiveDefaultSpatial].
/// * [PaneTransition.curvedExit] — enter on a spring, leave on a curve with a
///   fade.
/// * [PaneTransition.none] — the pane appears and disappears at once.
@immutable
class PaneTransition {
  /// Enters and leaves on [spring].
  ///
  /// Defaults to [MaterialSprings.expressiveDefaultSpatial], the spring
  /// Material 3 Expressive specifies for spatial motion.
  const PaneTransition.spring([
    SpringDescription spring = MaterialSprings.expressiveDefaultSpatial,
  ]) : enterSpring = spring,
       exitSpring = spring,
       exitCurve = null,
       exitDuration = Duration.zero;

  /// Enters on [enterSpring] and leaves on [exitCurve] over [exitDuration],
  /// fading as it goes.
  ///
  /// The fade runs ahead of the travel, so the last sliver of the pane slips
  /// away invisibly instead of winking out at the edge.
  const PaneTransition.curvedExit({
    this.enterSpring = MaterialSprings.expressiveDefaultSpatial,
    this.exitDuration = kPaneExitDuration,
    Curve this.exitCurve = kPaneExitCurve,
  }) : exitSpring = null;

  /// No animation: the pane appears and disappears at once.
  const PaneTransition.none()
    : enterSpring = null,
      exitSpring = null,
      exitCurve = null,
      exitDuration = Duration.zero;

  /// The spring the pane enters on, or null to appear at once.
  final SpringDescription? enterSpring;

  /// The spring the pane leaves on, or null when it leaves on [exitCurve] (or
  /// at once).
  final SpringDescription? exitSpring;

  /// The curve the pane leaves on, or null when it leaves on [exitSpring] (or
  /// at once).
  final Curve? exitCurve;

  /// How long a [exitCurve] exit takes. Unused by a spring exit.
  final Duration exitDuration;

  /// Whether the pane fades as it leaves. Only a curved exit fades; a spring
  /// exit slides without fading.
  bool get fadesOnExit => exitCurve != null;
}
