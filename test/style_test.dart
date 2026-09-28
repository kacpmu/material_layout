// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const red = Color(0xFFFF0000);
const green = Color(0xFF00FF00);
const blue = Color(0xFF0000FF);

Widget themed(Widget child, [MaterialLayoutThemeData? data]) => app(
  MaterialLayoutTheme(
    data: data ?? const MaterialLayoutThemeData(),
    child: Scaffold(body: child),
  ),
);

// The material a pane surface paints.
Material surfaceOf(WidgetTester tester, Finder surface) => tester.widget(
  find.descendant(of: surface, matching: find.byType(Material)).first,
);

void main() {
  group('Pane surface', () {
    testWidgets('is a card where its layout keeps the margins around the '
        'panes, and flat where it keeps them within', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      final padding = <EdgeInsetsDirectional>[];
      final cards = <bool>[];
      Widget pane() => PaneSurface(
        child: Builder(
          builder: (context) {
            padding.add(PaneSurface.paddingOf(context));
            cards.add(PaneSurface.inCard(context));
            return const SizedBox.expand();
          },
        ),
      );
      for (final placement in MarginPlacement.values) {
        await tester.pumpWidget(
          themed(
            SupportingPaneLayout(
              marginPlacement: placement,
              focus: pane(),
              supporting: const SizedBox.expand(),
            ),
          ),
        );
      }
      expect(cards, [true, false]);
      // Material's card padding in a card; the margins a flat pane's content
      // keeps, the leading one here, in a flat one.
      expect(padding, const [
        EdgeInsetsDirectional.symmetric(horizontal: 16),
        EdgeInsetsDirectional.only(start: 24),
      ]);
    });

    testWidgets("outside every layout, it follows the theme's placement", (
      tester,
    ) async {
      final cards = <bool>[];
      Widget surface() => PaneSurface(
        child: Builder(
          builder: (context) {
            cards.add(PaneSurface.inCard(context));
            return const SizedBox.expand();
          },
        ),
      );
      await tester.pumpWidget(themed(surface()));
      await tester.pumpWidget(
        themed(
          surface(),
          const MaterialLayoutThemeData(
            marginPlacement: MarginPlacement.inside,
          ),
        ),
      );
      expect(cards, [true, false]);
    });

    testWidgets('is painted as it says, then as the theme says, then as '
        'Material does', (tester) async {
      await tester.pumpWidget(themed(const PaneSurface(child: SizedBox())));
      final surface = find.byType(PaneSurface);
      final colors = Theme.of(tester.element(surface)).colorScheme;
      expect(surfaceOf(tester, surface).color, colors.surface);
      expect(
        (surfaceOf(tester, surface).shape! as RoundedRectangleBorder).side,
        BorderSide.none,
      );

      const outline = BorderSide(color: green, width: 2);
      await tester.pumpWidget(
        themed(
          const PaneSurface(child: SizedBox()),
          const MaterialLayoutThemeData(
            paneSurfaceStyle: PaneSurfaceStyle(color: red, outline: outline),
          ),
        ),
      );
      expect(surfaceOf(tester, surface).color, red);
      expect(
        (surfaceOf(tester, surface).shape! as RoundedRectangleBorder).side,
        outline,
      );

      const own = BorderSide(color: blue);
      await tester.pumpWidget(
        themed(
          const PaneSurface(color: blue, outline: own, child: SizedBox()),
          const MaterialLayoutThemeData(
            paneSurfaceStyle: PaneSurfaceStyle(color: red, outline: outline),
          ),
        ),
      );
      expect(surfaceOf(tester, surface).color, blue);
      expect(
        (surfaceOf(tester, surface).shape! as RoundedRectangleBorder).side,
        own,
      );
    });

    testWidgets("has the panes' corners, and clips its content to them", (
      tester,
    ) async {
      final surface = find.byType(PaneSurface);
      await tester.pumpWidget(themed(const PaneSurface(child: SizedBox())));
      expect(surfaceOf(tester, surface).clipBehavior, Clip.none);

      final corners = BorderRadius.circular(16);
      await tester.pumpWidget(
        themed(
          const PaneSurface(child: SizedBox()),
          MaterialLayoutThemeData(paneBorderRadius: corners),
        ),
      );
      final material = surfaceOf(tester, surface);
      expect(material.clipBehavior, Clip.antiAlias);
      expect((material.shape! as RoundedRectangleBorder).borderRadius, corners);
    });

    testWidgets('keeps its content as it changes between a card and a flat '
        'pane', (tester) async {
      Widget surface(MarginPlacement placement) => themed(
        const PaneSurface(child: _Counted()),
        MaterialLayoutThemeData(marginPlacement: placement),
      );
      await tester.pumpWidget(surface(MarginPlacement.outside));
      final state = tester.state(find.byType(_Counted));
      await tester.pumpWidget(surface(MarginPlacement.inside));
      expect(tester.state(find.byType(_Counted)), same(state));
    });
  });

  group('Side sheet', () {
    Color colorOf(WidgetTester tester) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(SideSheet),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;

    testWidgets('a standard sheet takes its colour from itself, then the '
        'theme, then Material', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      Widget layout({Color? backgroundColor, SideSheetStyle? style}) => themed(
        SupportingPaneLayout(
          focus: const SizedBox.expand(),
          onSupportingDismissed: () {},
          supporting: SideSheet(
            backgroundColor: backgroundColor,
            child: const Text('Sheet'),
          ),
        ),
        MaterialLayoutThemeData(
          sideSheetStyle: style ?? const SideSheetStyle(),
        ),
      );
      await tester.pumpWidget(layout());
      final colors = Theme.of(tester.element(find.text('Sheet'))).colorScheme;
      expect(colorOf(tester), colors.surface);
      await tester.pumpWidget(
        layout(
          style: const SideSheetStyle(
            backgroundColor: red,
            modalBackgroundColor: green,
          ),
        ),
      );
      expect(colorOf(tester), red);
      await tester.pumpWidget(
        layout(
          backgroundColor: blue,
          style: const SideSheetStyle(backgroundColor: red),
        ),
      );
      expect(colorOf(tester), blue);
    });

    testWidgets("a modal sheet takes the theme's colour and scrim, unless "
        'given its own', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      const scrim = Color(0x80112233);
      late BuildContext context;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.expand();
            },
          ),
          const MaterialLayoutThemeData(
            sideSheetStyle: SideSheetStyle(
              backgroundColor: red,
              modalBackgroundColor: green,
              modalBarrierColor: scrim,
            ),
          ),
        ),
      );
      showSideSheet<void>(
        context: context,
        builder: (context) => const SideSheet(child: Text('Sheet')),
      );
      await settle(tester);
      expect(colorOf(tester), green);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == scrim,
        ),
        findsOneWidget,
      );
      Navigator.of(context).pop();
      await settle(tester);

      showSideSheet<void>(
        context: context,
        barrierColor: blue,
        builder: (context) =>
            const SideSheet(backgroundColor: red, child: Text('Sheet')),
      );
      await settle(tester);
      expect(colorOf(tester), red);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == blue,
        ),
        findsOneWidget,
      );
    });
  });

  group('Drag handle', () {
    testWidgets("a grip's style is its own, then the theme's, then "
        "Material's, value by value", (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        themed(
          ListDetailLayout<int>(
            selectedId: 1,
            resizable: true,
            dragHandle: const PaneResizer(
              child: PaneDragHandle(style: DragHandleStyle(thickness: 6)),
            ),
            listBuilder: (context) => const SizedBox.expand(),
            detailBuilder: (context, id, placement) => const SizedBox.expand(),
          ),
          const MaterialLayoutThemeData(
            dragHandleStyle: DragHandleStyle(
              thickness: 2,
              length: 60,
              color: red,
            ),
          ),
        ),
      );
      final paint = find.descendant(
        of: find.byType(PaneDragHandle),
        matching: find.byType(CustomPaint),
      );
      final center = Offset(24, tester.getSize(paint).height / 2);
      expect(
        tester.renderObject(paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 6, height: 60),
            const Radius.circular(3),
          ),
          color: red,
        ),
      );
    });

    Widget handleIn({MaterialLayoutThemeData? theme, DragHandleStyle? style}) =>
        themed(
          ListDetailLayout<int>(
            selectedId: 1,
            resizable: true,
            dragHandle: PaneResizer(child: PaneDragHandle(style: style)),
            listBuilder: (context) => const SizedBox.expand(),
            detailBuilder: (context, id, placement) => const SizedBox.expand(),
          ),
          theme,
        );

    Finder grip() => find.descendant(
      of: find.byType(PaneDragHandle),
      matching: find.byType(CustomPaint),
    );

    RRect pill(WidgetTester tester, double width, double height) =>
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(24, tester.getSize(grip()).height / 2),
            width: width,
            height: height,
          ),
          Radius.circular(width / 2),
        );

    testWidgets("a grip is Material's by default: the outline colour at "
        'rest, and the on-surface colour while pressed', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(handleIn());
      final colors = Theme.of(tester.element(grip())).colorScheme;
      expect(
        tester.renderObject(grip()),
        paints..rrect(rrect: pill(tester, 4, 48), color: colors.outline),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      // The grip grows from the next frame, and rests at its size.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(
        tester.renderObject(grip()),
        paints..rrect(rrect: pill(tester, 12, 52), color: colors.onSurface),
      );
      await gesture.cancel();
      await settle(tester);
    });

    testWidgets("while pressed, a grip's own values come before the "
        "theme's", (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        handleIn(
          theme: const MaterialLayoutThemeData(
            dragHandleStyle: DragHandleStyle(
              pressedThickness: 10,
              pressedLength: 70,
              pressedColor: green,
            ),
          ),
          style: const DragHandleStyle(pressedColor: blue),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PaneResizer)),
      );
      // The grip grows from the next frame, and rests at its size.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(
        tester.renderObject(grip()),
        paints..rrect(rrect: pill(tester, 10, 70), color: blue),
      );
      await gesture.cancel();
      await settle(tester);
    });

    testWidgets('a grip focused from the keyboard shows a ring in the '
        'secondary colour', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(handleIn());
      final colors = Theme.of(tester.element(grip())).colorScheme;
      expect(
        tester.renderObject(grip()),
        isNot(
          paints
            ..rrect()
            ..rrect(),
        ),
      );
      // Tab moves focus from the list to the handle, and shows its ring.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      var tabs = 1;
      while (!PaneResizer.statesOf(tester.element(grip()))
              .contains(WidgetState.focused) &&
          tabs < 10) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        tabs++;
      }
      expect(
        PaneResizer.statesOf(tester.element(grip())),
        contains(WidgetState.focused),
      );
      final ring = pill(tester, 4, 48).outerRect.inflate(2 + 1.5);
      expect(
        tester.renderObject(grip()),
        paints
          ..rrect(rrect: pill(tester, 4, 48), color: colors.outline)
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              ring,
              Radius.circular(ring.width / 2),
            ),
            color: colors.secondary,
            style: PaintingStyle.stroke,
            strokeWidth: 3,
          ),
      );
    });
  });

  group('Theme', () {
    test('carries the component styles through copyWith and equality', () {
      const theme = MaterialLayoutThemeData();
      final copy = theme.copyWith(
        paneSurfaceStyle: const PaneSurfaceStyle(color: red),
        sideSheetStyle: const SideSheetStyle(modalBarrierColor: blue),
      );
      expect(copy.paneSurfaceStyle.color, red);
      expect(copy.sideSheetStyle.modalBarrierColor, blue);
      expect(copy, isNot(theme));
      expect(
        copy,
        theme.copyWith(
          paneSurfaceStyle: const PaneSurfaceStyle(color: red),
          sideSheetStyle: const SideSheetStyle(modalBarrierColor: blue),
        ),
      );
    });

    test('interpolates the component styles', () {
      const from = MaterialLayoutThemeData(
        dragHandleStyle: DragHandleStyle(thickness: 4),
        sideSheetStyle: SideSheetStyle(backgroundColor: red),
      );
      const to = MaterialLayoutThemeData(
        dragHandleStyle: DragHandleStyle(thickness: 8, length: 60),
        paneSurfaceStyle: PaneSurfaceStyle(
          outline: BorderSide(color: green, width: 2),
        ),
        sideSheetStyle: SideSheetStyle(backgroundColor: blue),
      );
      final half = from.lerp(to, 0.5);
      expect(half.dragHandleStyle.thickness, 6);
      expect(half.sideSheetStyle.backgroundColor, Color.lerp(red, blue, 0.5));
      // A value left to the default has none to pass through, so it
      // switches halfway rather than growing from zero.
      expect(from.lerp(to, 0.4).dragHandleStyle.length, isNull);
      expect(from.lerp(to, 0.6).dragHandleStyle.length, 60);
      // An outline that is not there fades in, in the other's colour, and
      // one that goes fades out in its own.
      final outline = from.lerp(to, 0.5).paneSurfaceStyle.outline!;
      expect(outline.width, 1);
      expect(outline.color.a, closeTo(0.5, 0.01));
      expect(outline.color.g, closeTo(1, 0.01));
      final fading = to.lerp(from, 0.25).paneSurfaceStyle.outline!;
      expect(fading.width, 1.5);
      expect(fading.color.g, closeTo(1, 0.01));
      expect(fading.color.a, closeTo(0.75, 0.01));
    });

    test('switches what has no midpoint halfway, and keeps its own without '
        'another theme', () {
      const from = MaterialLayoutThemeData();
      final to = from.copyWith(
        breakpoints: const Breakpoints(mediumMinWidth: 500),
        paneBorderRadius: BorderRadius.circular(16),
        motionScheme: const MotionScheme.standard(),
      );
      expect(from.lerp(null, 0.7), same(from));
      final early = from.lerp(to, 0.4);
      expect(early.breakpoints, from.breakpoints);
      expect(early.motionScheme, from.motionScheme);
      expect(early.paneBorderRadius, BorderRadius.circular(16 * 0.4));
      final late = from.lerp(to, 0.6);
      expect(late.breakpoints, to.breakpoints);
      expect(late.motionScheme, to.motionScheme);
    });

    testWidgets('the nearest theme wins, then the extension, then the '
        'defaults; and a theme notifies only when it changes', (tester) async {
      MaterialLayoutThemeData? seen;
      var builds = 0;
      final probe = Builder(
        builder: (context) {
          builds++;
          seen = MaterialLayoutTheme.of(context);
          return const SizedBox();
        },
      );
      await tester.pumpWidget(MaterialApp(home: probe));
      expect(seen, const MaterialLayoutThemeData());

      const extension = MaterialLayoutThemeData(
        marginPlacement: MarginPlacement.inside,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [extension]),
          home: probe,
        ),
      );
      // The app animates to its new theme.
      await tester.pumpAndSettle();
      expect(seen, extension);

      final nearest = MaterialLayoutThemeData(
        paneBorderRadius: BorderRadius.circular(8),
      );
      Widget themed(MaterialLayoutThemeData data) => MaterialApp(
        theme: ThemeData(extensions: const [extension]),
        home: MaterialLayoutTheme(data: data, child: probe),
      );
      await tester.pumpWidget(themed(nearest));
      expect(seen, nearest);
      final before = builds;
      // An equal theme is no change.
      await tester.pumpWidget(
        themed(
          MaterialLayoutThemeData(paneBorderRadius: BorderRadius.circular(8)),
        ),
      );
      expect(builds, before);
      // Another is, whichever of its values differs; and an equal copy of
      // that is no change again.
      List<MaterialLayoutThemeData> changes() {
        const breakpoints = Breakpoints();
        const motion = MotionScheme.expressive();
        const spring = Motion.spring(dampingRatio: 0.5, stiffness: 500);
        const grip = DragHandleStyle();
        return [
          nearest.copyWith(paneBorderRadius: BorderRadius.circular(12)),
          nearest.copyWith(marginPlacement: MarginPlacement.inside),
          for (final changed in [
            breakpoints.copyWith(mediumMinWidth: 500),
            breakpoints.copyWith(expandedMinWidth: 800),
            breakpoints.copyWith(largeMinWidth: 1100),
            breakpoints.copyWith(extraLargeMinWidth: 1500),
            breakpoints.copyWith(mediumMinHeight: 400),
            breakpoints.copyWith(expandedMinHeight: 800),
          ])
            nearest.copyWith(breakpoints: changed),
          for (final changed in [
            motion.copyWith(fastSpatial: spring),
            motion.copyWith(defaultSpatial: spring),
            motion.copyWith(slowSpatial: spring),
            motion.copyWith(fastEffects: spring),
            motion.copyWith(defaultEffects: spring),
            motion.copyWith(slowEffects: spring),
          ])
            nearest.copyWith(motionScheme: changed),
          for (final changed in [
            grip.copyWith(thickness: 6),
            grip.copyWith(length: 40),
            grip.copyWith(pressedThickness: 10),
            grip.copyWith(pressedLength: 50),
            grip.copyWith(color: red),
            grip.copyWith(pressedColor: red),
          ])
            nearest.copyWith(dragHandleStyle: changed),
          nearest.copyWith(
            paneSurfaceStyle: const PaneSurfaceStyle(color: red),
          ),
          nearest.copyWith(
            paneSurfaceStyle: const PaneSurfaceStyle(outline: BorderSide()),
          ),
          nearest.copyWith(
            sideSheetStyle: const SideSheetStyle(backgroundColor: red),
          ),
          nearest.copyWith(
            sideSheetStyle: const SideSheetStyle(modalBackgroundColor: red),
          ),
          nearest.copyWith(
            sideSheetStyle: const SideSheetStyle(modalBarrierColor: red),
          ),
        ];
      }

      final others = changes();
      final copies = changes();
      for (var i = 0; i < others.length; i++) {
        await tester.pumpWidget(themed(nearest));
        final unchanged = builds;
        await tester.pumpWidget(themed(others[i]));
        expect(builds, unchanged + 1, reason: 'change $i is a change');
        await tester.pumpWidget(themed(copies[i]));
        expect(builds, unchanged + 1, reason: 'change $i again is none');
      }
      await tester.pumpWidget(themed(nearest));

      // A theme captured for another route carries the layout theme along.
      final context = tester.element(find.byWidget(probe));
      final wrapped = InheritedTheme.capture(from: context, to: null).wrap(
        Builder(
          builder: (context) {
            seen = MaterialLayoutTheme.of(context);
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(MaterialApp(home: wrapped));
      expect(seen, nearest);
    });
  });
}

class _Counted extends StatefulWidget {
  const new();

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
