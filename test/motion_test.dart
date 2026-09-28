// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const focusKey = ValueKey('focus');

Widget layout({
  required bool open,
  MotionScheme scheme = const MotionScheme.expressive(),
  PaneMotion? motion,
  bool disableAnimations = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Scaffold(
    body: MaterialLayoutTheme(
      data: MaterialLayoutThemeData(motionScheme: scheme),
      child: SupportingPaneLayout(
        motion: motion,
        focus: const SizedBox.expand(key: focusKey),
        supporting: open ? const SizedBox.expand() : null,
      ),
    ),
  ),
);

// The focus pane's width while a 360dp supporting pane enters a 1000dp
// window at [visibility]: the pane and its spacer grow with it.
double focusWidth(double visibility) {
  const available = 1000 - 48.0;
  final spacer = 24 * visibility.clamp(0, 1);
  return available - spacer - 360 * visibility;
}

Future<double> widthAfter(
  WidgetTester tester,
  Duration elapsed, {
  required Widget closed,
  required Widget open,
}) async {
  await tester.pumpWidget(closed);
  await tester.pumpWidget(open);
  // The animation's clock starts at the first frame after it begins.
  await tester.pump();
  await tester.pump(elapsed);
  return tester.getRect(find.byKey(focusKey)).width;
}

void main() {
  group('Pane motion', () {
    for (final scheme in const [
      MotionScheme.expressive(),
      MotionScheme.standard(),
    ]) {
      testWidgets('a pane enters on the default spatial spring of the '
          'scheme: ${scheme.defaultSpatial}', (tester) async {
        setWindowSize(tester, const Size(1000, 800));
        const elapsed = Duration(milliseconds: 100);
        final width = await widthAfter(
          tester,
          elapsed,
          closed: layout(open: false, scheme: scheme),
          open: layout(open: true, scheme: scheme),
        );
        final visibility = scheme.defaultSpatial.simulation(0, 1).x(0.1);
        expect(width, closeTo(focusWidth(visibility), 0.5));
        await settle(tester);
      });
    }

    testWidgets('a pane moves on the scheme it is given, standard or '
        'expressive', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      const elapsed = Duration(milliseconds: 60);
      final expressive = await widthAfter(
        tester,
        elapsed,
        closed: layout(open: false),
        open: layout(open: true),
      );
      await settle(tester);
      final standard = await widthAfter(
        tester,
        elapsed,
        closed: layout(open: false, scheme: const MotionScheme.standard()),
        open: layout(open: true, scheme: const MotionScheme.standard()),
      );
      await settle(tester);
      expect(expressive, isNot(closeTo(standard, 1)));
    });

    testWidgets('a pane accepts a curve instead of a spring', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      const motion = PaneMotion(
        enter: Motion.curved(
          duration: Duration(milliseconds: 200),
          curve: Curves.linear,
        ),
        exit: Motion.none(),
      );
      final width = await widthAfter(
        tester,
        const Duration(milliseconds: 100),
        closed: layout(open: false, motion: motion),
        open: layout(open: true, motion: motion),
      );
      expect(width, closeTo(focusWidth(0.5), 0.5));
      await settle(tester);
    });

    testWidgets('panes do not animate when the platform reduces motion', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      final width = await widthAfter(
        tester,
        Duration.zero,
        closed: layout(open: false, disableAnimations: true),
        open: layout(open: true, disableAnimations: true),
      );
      expect(width, focusWidth(1));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('PaneMotion.none skips the animation', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final width = await widthAfter(
        tester,
        Duration.zero,
        closed: layout(open: false, motion: const PaneMotion.none()),
        open: layout(open: true, motion: const PaneMotion.none()),
      );
      expect(width, focusWidth(1));
    });

    testWidgets('reduced motion wins over an explicit motion', (tester) async {
      final context = await _contextWith(tester, disableAnimations: true);
      final standard = PaneMotion.from(const MotionScheme.standard());
      expect(PaneMotion.resolve(context, standard), const PaneMotion.none());
      expect(PaneMotion.resolve(context, null), const PaneMotion.none());
    });

    testWidgets('without an explicit motion, the theme scheme applies', (
      tester,
    ) async {
      final context = await _contextWith(tester);
      expect(
        PaneMotion.resolve(context, null),
        PaneMotion.from(const MotionScheme.expressive()),
      );
      final themed = await _contextWith(
        tester,
        scheme: const MotionScheme.standard(),
      );
      expect(
        PaneMotion.resolve(themed, null),
        PaneMotion.from(const MotionScheme.standard()),
      );
    });

    testWidgets('a pane enters on the enter motion, leaves on the exit '
        'motion, and a split settles on the resize motion', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      Motion linear(int milliseconds) => Motion.curved(
        duration: Duration(milliseconds: milliseconds),
        curve: Curves.linear,
      );
      final motion = PaneMotion(
        enter: linear(200),
        exit: linear(400),
        resize: linear(800),
      );
      final split = PaneSplitController();
      addTearDown(split.dispose);
      Widget panes({required bool open}) => MaterialApp(
        home: Scaffold(
          body: SupportingPaneLayout(
            motion: motion,
            resizable: true,
            onSupportingDismissed: () {},
            splitController: split,
            resizeMemory: PaneResizeMemory.persistent,
            focus: const SizedBox.expand(key: focusKey),
            supporting: open ? const SizedBox.expand() : null,
          ),
        ),
      );
      double focus() => tester.getRect(find.byKey(focusKey)).width;

      // Half way through the 200ms entrance.
      await tester.pumpWidget(panes(open: false));
      await tester.pumpWidget(panes(open: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(focus(), closeTo(focusWidth(0.5), 0.5));
      await settle(tester);

      // A quarter of the 800ms settle from 360dp to 300dp.
      split.value = const PaneSplit.width(300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(focus(), closeTo(focusWidth(1) + 15, 0.5));
      await settle(tester);

      // A quarter of the 400ms exit of the 300dp pane.
      await tester.pumpWidget(panes(open: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      const available = 1000 - 48.0;
      expect(focus(), closeTo(available - (24 + 300) * 0.75, 0.5));
      await settle(tester);
    });
  });

  testWidgets('navigation swaps without animating under reduced motion', (
    tester,
  ) async {
    Widget scaffold() => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: NavigationScaffold(
        navigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(icon: Icon(Icons.inbox), label: 'A'),
            NavigationDestination(icon: Icon(Icons.article), label: 'B'),
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'C'),
          ],
        ),
        navigationRail: NavigationRail(
          selectedIndex: 0,
          destinations: [
            for (final (icon, label) in const [
              (Icons.inbox, 'A'),
              (Icons.article, 'B'),
              (Icons.dashboard, 'C'),
            ])
              NavigationRailDestination(icon: Icon(icon), label: Text(label)),
          ],
        ),
        body: const SizedBox.expand(),
      ),
    );
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(scaffold());
    setWindowSize(tester, const Size(1000, 800));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

Future<BuildContext> _contextWith(
  WidgetTester tester, {
  bool disableAnimations = false,
  MotionScheme? scheme,
}) async {
  late BuildContext captured;
  final probe = Builder(
    builder: (context) {
      captured = context;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: scheme == null
          ? probe
          : MaterialLayoutTheme(
              data: MaterialLayoutThemeData(motionScheme: scheme),
              child: probe,
            ),
    ),
  );
  return captured;
}
