import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';

/// The damping ratio a [SpringDescription] describes: `damping / 2√(k·m)`.
double dampingRatio(SpringDescription spring) =>
    spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));

void main() {
  group('MaterialSprings carries the Material 3 motion tokens', () {
    // Damping ratio and stiffness as the spec states them. The constants store
    // a precomputed damping instead, so this pins the conversion.
    const tokens = <String, (SpringDescription, double, double)>{
      'expressive fast spatial': (
        MaterialSprings.expressiveFastSpatial,
        0.6,
        800,
      ),
      'expressive default spatial': (
        MaterialSprings.expressiveDefaultSpatial,
        0.8,
        380,
      ),
      'expressive slow spatial': (
        MaterialSprings.expressiveSlowSpatial,
        0.8,
        200,
      ),
      'standard fast spatial': (MaterialSprings.standardFastSpatial, 0.9, 1400),
      'standard default spatial': (
        MaterialSprings.standardDefaultSpatial,
        0.9,
        700,
      ),
      'standard slow spatial': (MaterialSprings.standardSlowSpatial, 0.9, 300),
    };

    for (final MapEntry(key: name, value: (spring, ratio, stiffness))
        in tokens.entries) {
      test(name, () {
        expect(spring.mass, 1);
        expect(spring.stiffness, stiffness);
        expect(dampingRatio(spring), closeTo(ratio, 0.0005));
      });
    }
  });

  test(
    'the default pane transition is the expressive default spatial spring',
    () {
      const transition = PaneTransition.spring();
      expect(transition.enterSpring, MaterialSprings.expressiveDefaultSpatial);
      expect(transition.exitSpring, MaterialSprings.expressiveDefaultSpatial);
      expect(transition.fadesOnExit, isFalse);
    },
  );

  test('a curved exit leaves on emphasized easing and fades', () {
    const transition = PaneTransition.curvedExit();
    expect(transition.enterSpring, MaterialSprings.expressiveDefaultSpatial);
    expect(transition.exitCurve, kPaneExitCurve);
    expect(transition.exitDuration, kPaneExitDuration);
    expect(transition.fadesOnExit, isTrue);
  });
}
