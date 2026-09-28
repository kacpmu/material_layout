// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_layout/src/navigation/navigation_scaffold.dart';
import 'package:material_layout/src/panes/pane_geometry.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Breakpoints', () {
    const breakpoints = Breakpoints();

    test('resolve at 600, 840, 1200 and 1600dp, half-open', () {
      expect(breakpoints.forWidth(0), Breakpoint.compact);
      expect(breakpoints.forWidth(599.9), Breakpoint.compact);
      expect(breakpoints.forWidth(600), Breakpoint.medium);
      expect(breakpoints.forWidth(839.9), Breakpoint.medium);
      expect(breakpoints.forWidth(840), Breakpoint.expanded);
      expect(breakpoints.forWidth(1199.9), Breakpoint.expanded);
      expect(breakpoints.forWidth(1200), Breakpoint.large);
      expect(breakpoints.forWidth(1599.9), Breakpoint.large);
      expect(breakpoints.forWidth(1600), Breakpoint.extraLarge);
      expect(breakpoints.forWidth(double.infinity), Breakpoint.extraLarge);
    });

    test('classify height independently, at 480 and 900dp', () {
      expect(breakpoints.forHeight(479.9), HeightBreakpoint.compact);
      expect(breakpoints.forHeight(480), HeightBreakpoint.medium);
      expect(breakpoints.forHeight(899.9), HeightBreakpoint.medium);
      expect(breakpoints.forHeight(900), HeightBreakpoint.expanded);
      // A wide, short window is extra-large and compact at once.
      expect(breakpoints.forWidth(1700), Breakpoint.extraLarge);
      expect(breakpoints.forHeight(400), HeightBreakpoint.compact);
    });

    test('can be retuned without changing the enum', () {
      const retuned = Breakpoints(
        mediumMinWidth: 500,
        expandedMinWidth: 800,
        largeMinWidth: 1100,
        extraLargeMinWidth: 1500,
        mediumMinHeight: 400,
        expandedMinHeight: 800,
      );
      expect(retuned.forWidth(499), Breakpoint.compact);
      expect(retuned.forWidth(500), Breakpoint.medium);
      expect(retuned.forWidth(800), Breakpoint.expanded);
      expect(retuned.forWidth(1100), Breakpoint.large);
      expect(retuned.forWidth(1500), Breakpoint.extraLarge);
      expect(retuned.forHeight(399), HeightBreakpoint.compact);
      expect(retuned.forHeight(400), HeightBreakpoint.medium);
      expect(retuned.forHeight(800), HeightBreakpoint.expanded);
      expect(
        const Breakpoints(mediumMinWidth: 640, expandedMinWidth: 900),
        const Breakpoints().copyWith(
          mediumMinWidth: 640,
          expandedMinWidth: 900,
        ),
      );
    });

    test('refuse thresholds out of order', () {
      // Values the compiler cannot fold, so that the asserts run now.
      final zero = 0.0 * DateTime.now().day;
      for (final build in <Breakpoints Function()>[
        () => Breakpoints(mediumMinWidth: zero),
        () => Breakpoints(mediumMinWidth: 900 + zero),
        () => Breakpoints(expandedMinWidth: 1300 + zero),
        () => Breakpoints(largeMinWidth: 1700 + zero),
        () => Breakpoints(mediumMinHeight: zero),
        () => Breakpoints(expandedMinHeight: 400 + zero),
      ]) {
        expect(build, throwsAssertionError);
      }
    });
  });

  group('Measurements', () {
    test('margins are 16dp at compact and 24dp above', () {
      expect(Breakpoint.compact.margin, 16);
      for (final breakpoint in Breakpoint.values.skip(1)) {
        expect(breakpoint.margin, 24, reason: '$breakpoint');
      }
    });

    test('a fixed pane is 360dp at expanded, 412dp at large and above', () {
      expect(Breakpoint.compact.fixedPaneWidth, isNull);
      expect(Breakpoint.medium.fixedPaneWidth, isNull);
      expect(Breakpoint.expanded.fixedPaneWidth, 360);
      expect(Breakpoint.large.fixedPaneWidth, 412);
      expect(Breakpoint.extraLarge.fixedPaneWidth, 412);
    });
  });

  group('Navigation placement', () {
    NavigationPlacement placement(Breakpoint breakpoint, int panes) =>
        navigationPlacementFor(
          breakpoint: breakpoint,
          paneCount: panes,
          hasBar: true,
          hasRail: true,
          rule: NavigationPlacementRule.material,
        );

    test('compact uses a bar', () {
      expect(placement(Breakpoint.compact, 1), NavigationPlacement.bar);
    });

    test('medium uses a rail beside one pane and a bar below two', () {
      expect(placement(Breakpoint.medium, 1), NavigationPlacement.rail);
      expect(placement(Breakpoint.medium, 2), NavigationPlacement.bar);
    });

    test('expanded and above use a rail, whatever the panes', () {
      for (final breakpoint in Breakpoint.values.skip(2)) {
        expect(placement(breakpoint, 1), NavigationPlacement.rail);
        expect(placement(breakpoint, 2), NavigationPlacement.rail);
      }
    });

    test('shows nothing rather than the component not prescribed', () {
      NavigationPlacement only(
        Breakpoint breakpoint,
        int panes, {
        required bool bar,
      }) => navigationPlacementFor(
        breakpoint: breakpoint,
        paneCount: panes,
        hasBar: bar,
        hasRail: !bar,
        rule: NavigationPlacementRule.material,
      );
      // A compact app may keep a modal rail in its drawer instead of a bar.
      expect(only(Breakpoint.compact, 1, bar: false), NavigationPlacement.none);
      expect(only(Breakpoint.medium, 2, bar: false), NavigationPlacement.none);
      expect(only(Breakpoint.medium, 1, bar: true), NavigationPlacement.none);
      expect(only(Breakpoint.large, 1, bar: true), NavigationPlacement.none);
      expect(
        navigationPlacementFor(
          breakpoint: Breakpoint.large,
          paneCount: 1,
          hasBar: false,
          hasRail: false,
          rule: NavigationPlacementRule.material,
        ),
        NavigationPlacement.none,
      );
    });

    test("Material's rule is the default", () {
      for (final breakpoint in Breakpoint.values) {
        for (final panes in [1, 2]) {
          expect(
            placement(breakpoint, panes),
            NavigationPlacementRule.material.placementFor(breakpoint, panes),
          );
        }
      }
    });

    NavigationPlacement under(
      NavigationPlacementRule rule,
      Breakpoint breakpoint, {
      int panes = 1,
      bool hasBar = true,
      bool hasRail = true,
    }) => navigationPlacementFor(
      breakpoint: breakpoint,
      paneCount: panes,
      hasBar: hasBar,
      hasRail: hasRail,
      rule: rule,
    );

    test(
      'only shows one placement at every breakpoint, whatever the panes',
      () {
        for (final chosen in NavigationPlacement.values) {
          final rule = NavigationPlacementRule.only(chosen);
          for (final breakpoint in Breakpoint.values) {
            expect(under(rule, breakpoint), chosen);
            expect(under(rule, breakpoint, panes: 2), chosen);
          }
        }
      },
    );

    test('from decides by the breakpoint and the pane count', () {
      final railFirst = NavigationPlacementRule.from(
        (breakpoint, paneCount) => breakpoint < Breakpoint.expanded
            ? NavigationPlacement.rail
            : NavigationPlacement.bar,
      );
      expect(
        [
          for (final breakpoint in Breakpoint.values)
            under(railFirst, breakpoint),
        ],
        [
          NavigationPlacement.rail,
          NavigationPlacement.rail,
          NavigationPlacement.bar,
          NavigationPlacement.bar,
          NavigationPlacement.bar,
        ],
      );

      final told = <(Breakpoint, int)>[];
      under(
        NavigationPlacementRule.from((breakpoint, paneCount) {
          told.add((breakpoint, paneCount));
          return NavigationPlacement.rail;
        }),
        Breakpoint.large,
        panes: 2,
      );
      expect(told, [(Breakpoint.large, 2)]);
    });

    test('another rule shows nothing rather than a component not given', () {
      expect(
        under(
          const NavigationPlacementRule.only(NavigationPlacement.rail),
          Breakpoint.compact,
          hasRail: false,
        ),
        NavigationPlacement.none,
      );
      expect(
        under(
          const NavigationPlacementRule.only(NavigationPlacement.bar),
          Breakpoint.large,
          hasBar: false,
        ),
        NavigationPlacement.none,
      );
    });
  });

  group('Pane geometry', () {
    test('two visible panes and the spacer fill the space exactly', () {
      final geometry = resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        spacer: 24,
        firstExtent: 360,
      );
      expect(geometry.first.start, 24);
      expect(geometry.first.extent, 360);
      expect(geometry.spacerExtent, 24);
      expect(geometry.second.start, 24 + 360 + 24);
      expect(geometry.second.end, 24 + 1000);
    });

    test('a fixed pane keeps its width; the flexible one takes the rest', () {
      for (final available in [800.0, 1000.0, 1400.0]) {
        final geometry = resolvePaneGeometry(
          available: available,
          outerStart: 0,
          spacer: 24,
          secondExtent: 412,
        );
        expect(geometry.second.extent, 412);
        expect(geometry.first.extent, available - 24 - 412);
      }
    });

    test('a leaving pane slides out at its natural width while the other '
        'absorbs the space', () {
      final geometry = resolvePaneGeometry(
        available: 1000,
        outerStart: 0,
        spacer: 24,
        firstExtent: 400,
        secondVisibility: 0.5,
      );
      final natural = 1000 - 24 - 400;
      expect(geometry.second.extent, closeTo(natural / 2, 1e-9));
      expect(geometry.second.contentExtent, natural);
      expect(geometry.spacerExtent, 12);
      expect(geometry.first.end + 12 + geometry.second.extent, 1000);
      // The absorbing pane stretches rather than leaving a gap.
      expect(geometry.first.contentExtent, geometry.first.extent);
    });

    test('a hidden pane occupies nothing, and the spacer closes', () {
      final geometry = resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        spacer: 24,
        firstExtent: 360,
        firstVisibility: 0,
      );
      expect(geometry.first.isVisible, isFalse);
      expect(geometry.spacerExtent, 0);
      expect(geometry.second.start, 24);
      expect(geometry.second.extent, 1000);
    });

    test('beside a pane its drag handle hides, the handle rests in the '
        'margin, and the other pane takes the whole space', () {
      final geometry = resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        spacer: 24,
        hasHandle: true,
        firstExtent: 360,
        firstVisibility: 0,
      );
      expect(geometry.first.isVisible, isFalse);
      expect(geometry.spacerExtent, 0);
      expect(geometry.second.start, 24);
      expect(geometry.second.end, 24 + 1000);
      expect(geometry.handleCenter, 12);

      // With no margin beside it, as beside a navigation rail, the pane
      // takes the whole space too, and the handle rests half a spacer in,
      // over it.
      final edge = resolvePaneGeometry(
        available: 1000,
        outerStart: 0,
        spacer: 24,
        hasHandle: true,
        firstExtent: 360,
        firstVisibility: 0,
      );
      expect(edge.spacerExtent, 0);
      expect(edge.second.start, 0);
      expect(edge.handleCenter, 12);

      // In a margin wider than a spacer, as with a safe-area inset beside
      // it, the handle rests in its middle.
      final inset = resolvePaneGeometry(
        available: 1000,
        outerStart: 24 + 44,
        spacer: 24,
        hasHandle: true,
        firstExtent: 360,
        firstVisibility: 0,
      );
      expect(inset.second.start, 24 + 44);
      expect(inset.handleCenter, (24 + 44) / 2);
    });

    test('the handle rests in the middle of the margin beside a hidden pane '
        'whether the margins are kept around the panes or within them', () {
      PaneGeometry hidden({required bool inside, bool first = true}) =>
          resolvePaneGeometry(
            available: inside ? 1000 : 1000 - 24 - 24,
            outerStart: inside ? 0 : 24,
            outerEnd: inside ? 0 : 24,
            innerStart: inside ? 24 : 0,
            innerEnd: inside ? 24 : 0,
            spacer: 24,
            hasHandle: true,
            firstExtent: inside ? 24 + 360 : 360,
            firstVisibility: first ? 0 : 1,
            secondVisibility: first ? 1 : 0,
          );
      final outside = hidden(inside: false);
      final inside = hidden(inside: true);
      expect(outside.handleCenter, 12);
      expect(inside.handleCenter, 12);
      // Within the panes, the other pane reaches the edge, and keeps the
      // margin inside it.
      expect(outside.second.start, 24);
      expect(inside.second.start, 0);
      expect(inside.second.end, 1000);
      expect(hidden(inside: false, first: false).handleCenter, 1000 - 12);
      expect(hidden(inside: true, first: false).handleCenter, 1000 - 12);
    });

    test('the handle keeps to a pane the handle hides as it goes', () {
      // Linear in how much of the pane shows, so that it keeps to a pointer
      // that drags the pane away.
      double at(double visibility) => resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        outerEnd: 24,
        spacer: 24,
        hasHandle: true,
        firstExtent: 360,
        firstVisibility: visibility,
      ).handleCenter;
      expect(at(1), 24 + 360 + 12);
      expect(at(0), 12);
      expect(at(0.5), closeTo((at(0) + at(1)) / 2, 1e-9));
      expect(at(0.25), closeTo(at(0) + (at(1) - at(0)) / 4, 1e-9));
    });

    test('moves continuously when one pane replaces the other', () {
      PaneGeometry at(double first, double second) => resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        outerEnd: 24,
        spacer: 24,
        hasHandle: true,
        firstExtent: 360,
        firstVisibility: first,
        secondVisibility: second,
      );
      var previous = at(0, 1).handleCenter;
      expect(previous, 12);
      for (var step = 1; step <= 100; step++) {
        final progress = step / 100;
        final center = at(progress, 1 - progress).handleCenter;
        expect(center, greaterThanOrEqualTo(previous), reason: '$progress');
        expect(center - previous, lessThan(20), reason: '$progress');
        previous = center;
      }
      // The middle of the trailing margin.
      expect(previous, 24 + 1000 + 12);
      // Where the visibilities cross, the geometry does not jump: a tenth of
      // the step there moves the panes about a tenth as far.
      double across(double step) =>
          (at(0.5 - step, 0.5 + step).first.extent -
                  at(0.5 + step, 0.5 - step).first.extent)
              .abs();
      expect(across(0.001), lessThan(across(0.01) / 5));
    });

    test('a spring overshoot takes space from the other pane, but not past '
        'the edge', () {
      final overshoot = resolvePaneGeometry(
        available: 1000,
        outerStart: 0,
        spacer: 24,
        firstExtent: 400,
        firstVisibility: 1.05,
      );
      expect(overshoot.first.extent, closeTo(420, 1e-9));
      expect(overshoot.second.extent, closeTo(1000 - 24 - 420, 1e-9));

      final alone = resolvePaneGeometry(
        available: 1000,
        outerStart: 24,
        outerEnd: 24,
        spacer: 24,
        hasHandle: true,
        firstExtent: 400,
        firstVisibility: 1.05,
        secondVisibility: 0,
      );
      expect(alone.first.extent, 1000);
      expect(alone.second.extent, 0);
    });

    test('flexible panes share by flex', () {
      final geometry = resolvePaneGeometry(
        available: 624,
        outerStart: 0,
        spacer: 24,
        firstFlex: 2,
      );
      expect(geometry.first.extent, 400);
      expect(geometry.second.extent, 200);
    });
  });

  group('Motion tokens', () {
    void expectSpring(Motion motion, double ratio, double stiffness) {
      expect(motion.isSpring, isTrue);
      expect(motion.dampingRatio, ratio);
      expect(motion.stiffness, stiffness);
    }

    test("the expressive scheme has Material's expressive springs", () {
      const scheme = MotionScheme.expressive();
      expectSpring(scheme.fastSpatial, 0.6, 800);
      expectSpring(scheme.defaultSpatial, 0.8, 380);
      expectSpring(scheme.slowSpatial, 0.8, 200);
      expectSpring(scheme.fastEffects, 1, 3800);
      expectSpring(scheme.defaultEffects, 1, 1600);
      expectSpring(scheme.slowEffects, 1, 800);
    });

    test("the standard scheme has Material's standard springs", () {
      const scheme = MotionScheme.standard();
      expectSpring(scheme.fastSpatial, 0.9, 1400);
      expectSpring(scheme.defaultSpatial, 0.9, 700);
      expectSpring(scheme.slowSpatial, 0.9, 300);
      expectSpring(scheme.fastEffects, 1, 3800);
      expectSpring(scheme.defaultEffects, 1, 1600);
      expectSpring(scheme.slowEffects, 1, 800);
    });

    test('a spring settles, and its curve runs from 0 to 1', () {
      final motion = const MotionScheme.expressive().defaultSpatial;
      expect(motion.duration, greaterThan(Duration.zero));
      expect(motion.duration, lessThan(const Duration(seconds: 2)));
      expect(motion.curve.transform(0), 0);
      expect(motion.curve.transform(1), 1);
    });

    test('a curve motion uses its duration and curve', () {
      const motion = Motion.curved(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      expect(motion.isSpring, isFalse);
      expect(motion.duration, const Duration(milliseconds: 300));
      expect(motion.curve, Curves.easeOut);
      final simulation = motion.simulation(10, 20);
      final halfway = 10 + 10 * Curves.easeOut.transform(0.5);
      expect(simulation.x(0.15), closeTo(halfway, 1e-9));
      expect(simulation.isDone(0.3), isTrue);
      expect(const Motion.none().isNone, isTrue);

      // Its velocity, which a motion that interrupts it starts from: steady
      // along a linear curve, and none once it has ended.
      final linear = const Motion.curved(
        duration: Duration(milliseconds: 200),
        curve: Curves.linear,
      ).simulation(0, 100);
      expect(linear.dx(0.1), closeTo(500, 1e-6));
      expect(linear.dx(0.2), 0);
    });

    test('copyWith replaces only the values it is given', () {
      const spring = Motion.spring(dampingRatio: 0.8, stiffness: 380);
      const curve = Motion.curved(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      const pane = PaneMotion(enter: spring, exit: spring);
      // Each copy is its original with one value replaced, and so no longer
      // equal to it.
      for (final (original, copy, expected) in <(Object, Object, Object)>[
        (
          spring,
          spring.copyWith(dampingRatio: 0.6),
          const Motion.spring(dampingRatio: 0.6, stiffness: 380),
        ),
        (
          spring,
          spring.copyWith(stiffness: 500),
          const Motion.spring(dampingRatio: 0.8, stiffness: 500),
        ),
        (
          curve,
          curve.copyWith(duration: const Duration(milliseconds: 200)),
          const Motion.curved(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        ),
        (
          curve,
          curve.copyWith(curve: Curves.linear),
          const Motion.curved(
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
          ),
        ),
        (
          pane,
          pane.copyWith(enter: curve),
          const PaneMotion(enter: curve, exit: spring, resize: spring),
        ),
        (
          pane,
          pane.copyWith(exit: curve),
          const PaneMotion(enter: spring, exit: curve, resize: spring),
        ),
        (
          pane,
          pane.copyWith(resize: curve),
          const PaneMotion(enter: spring, exit: spring, resize: curve),
        ),
      ]) {
        expect(copy, expected);
        expect(copy, isNot(original));
      }
      const scheme = MotionScheme.expressive();
      final copy = scheme.copyWith(defaultSpatial: spring);
      expect(copy.defaultSpatial, spring);
      expect(copy.fastSpatial, scheme.fastSpatial);
      expect(copy.defaultEffects, scheme.defaultEffects);
    });

    test('pane motion defaults to the default spatial token', () {
      const scheme = MotionScheme.standard();
      final motion = PaneMotion.from(scheme);
      expect(motion.enter, scheme.defaultSpatial);
      expect(motion.exit, scheme.defaultSpatial);
      expect(motion.resize, scheme.defaultSpatial);
      expect(
        const PaneMotion(enter: Motion.none(), exit: Motion.none()).resize,
        const Motion.none(),
      );
    });
  });

  group('PaneSplit', () {
    test('round-trips through JSON', () {
      for (final split in [
        PaneSplit.automatic,
        PaneSplit.centered,
        PaneSplit.collapsed,
        PaneSplit.expanded,
        const PaneSplit.width(360),
      ]) {
        expect(PaneSplit.fromJson(split.toJson()), split);
      }
      expect(() => PaneSplit.fromJson('sideways'), throwsFormatException);
      expect(() => PaneSplit.fromJson(null), throwsFormatException);
    });

    test('the controller toggles back to the last open split', () {
      final controller = PaneSplitController(split: const PaneSplit.width(400));
      addTearDown(controller.dispose);
      controller.toggle();
      expect(controller.value, PaneSplit.collapsed);
      controller.toggle();
      expect(controller.value, const PaneSplit.width(400));
      controller
        ..value = PaneSplit.expanded
        ..toggle();
      expect(controller.value, const PaneSplit.width(400));
    });
  });
}
