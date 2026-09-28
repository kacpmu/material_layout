// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, SemanticsRole;

import 'package:flutter/rendering.dart'
    show RenderAnimatedOpacity, RenderObject, RenderOpacity;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const triggerKey = ValueKey('trigger');

// An app with a button that opens a modal side sheet.
Widget modalHost({
  TextDirection textDirection = TextDirection.ltr,
  bool withBack = false,
  List<Widget> actions = const [],
  bool disableAnimations = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: Directionality(textDirection: textDirection, child: child!),
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          key: triggerKey,
          onPressed: () => showSideSheet<void>(
            context: context,
            builder: (context) => SideSheet(
              headline: const Text('Filters'),
              onBack: withBack ? () {} : null,
              actions: actions,
              child: const Text('Content'),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

// A standard side sheet, as the supporting pane of a layout.
Widget paneHost({List<Widget> actions = const []}) => app(
  Scaffold(
    body: SupportingPaneLayout(
      focus: const SizedBox.expand(),
      onSupportingDismissed: () {},
      supporting: SideSheet(
        headline: const Text('Filters'),
        actions: actions,
        child: const Text('Content'),
      ),
    ),
  ),
);

Finder get sheet => find.byType(SideSheet);

Material sheetMaterial(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: sheet, matching: find.byType(Material)).first,
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.byKey(triggerKey));
  await settle(tester);
}

void main() {
  group('Modal side sheet', () {
    testWidgets('has a fixed width, spans the height, and sits on the '
        'trailing edge', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await open(tester);
      final rect = tester.getRect(sheet);
      expect(rect.width, 400);
      expect(rect.height, 800);
      expect(rect.right, 1300);
    });

    testWidgets('sits on the leading edge in a right-to-left layout', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost(textDirection: TextDirection.rtl));
      await open(tester);
      expect(tester.getRect(sheet).left, 0);
    });

    testWidgets('is narrower than the window when the window is narrow', (
      tester,
    ) async {
      setWindowSize(tester, const Size(360, 700));
      await tester.pumpWidget(modalHost());
      await open(tester);
      expect(tester.getRect(sheet).width, 360);
    });

    testWidgets('uses surface container low and 16dp leading corners', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await open(tester);
      final material = sheetMaterial(tester);
      final colors = Theme.of(tester.element(sheet)).colorScheme;
      expect(material.color, colors.surfaceContainerLow);
      expect(
        material.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(
            start: Radius.circular(16),
          ),
        ),
      );
    });

    testWidgets('is a dialog that names its route', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await open(tester);
      final data = tester.getSemantics(sheet).getSemanticsData();
      expect(data.role, SemanticsRole.dialog);
      expect(data.label, 'Side sheet');
      expect(data.flagsCollection.namesRoute, isTrue);
      semantics.dispose();
    });

    testWidgets('closes from its close button', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await open(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);
      expect(sheet, findsNothing);
    });

    testWidgets('closes from the scrim and from the back button', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await open(tester);
      await tester.tapAt(const Offset(100, 400));
      await settle(tester);
      expect(sheet, findsNothing);

      await open(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(sheet, findsNothing);
    });

    testWidgets('blocks the content behind it', (tester) async {
      var taps = 0;
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: TextButton(
                      onPressed: () => taps++,
                      child: const Text('Behind'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      key: triggerKey,
                      onPressed: () => showSideSheet<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const SideSheet(child: Text('Content')),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await open(tester);
      await tester.tap(find.text('Behind'), warnIfMissed: false);
      expect(taps, 0);
      expect(sheet, findsOneWidget);
    });

    testWidgets('moves focus to its first element when it opens, and back '
        'to the trigger when it closes', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      final trigger = Focus.of(tester.element(find.text('Open')))
        ..requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(sheet, findsOneWidget);
      expect(trigger.hasFocus, isFalse);
      final close = Focus.of(
        tester.element(
          find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
        ),
      );
      expect(close.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(sheet, findsNothing);
      expect(trigger.hasFocus, isTrue);
    });

    testWidgets('focuses its back button first, when it has one', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost(withBack: true));
      await open(tester);
      final back = Focus.of(
        tester.element(
          find.descendant(of: sheet, matching: find.byType(BackButtonIcon)),
        ),
      );
      expect(back.hasFocus, isTrue);
    });

    group('with the system back gesture', () {
      Future<void> send(
        WidgetTester tester,
        String method, [
        Map<String, Object?>? arguments,
      ]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );

      // A gesture from the left edge: the far edge from the sheet.
      Map<String, Object?> event(double progress) => {
        'touchOffset': [progress * 1300, 400.0],
        'progress': progress,
        'swipeEdge': SwipeEdge.left.index,
      };

      Rect container(WidgetTester tester) => tester.getRect(
        find.descendant(of: sheet, matching: find.byType(Material)).first,
      );

      testWidgets('detaches from the edges and narrows as it goes, and '
          'closes when it completes', (tester) async {
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(modalHost());
        await open(tester);
        final rest = container(tester);

        await send(tester, 'startBackGesture', event(0));
        await send(tester, 'updateBackGestureProgress', event(0.5));
        await tester.pump();
        final during = container(tester);
        expect(during.top, greaterThan(rest.top));
        expect(during.bottom, lessThan(rest.bottom));
        expect(during.width, lessThan(rest.width));
        expect(during.right, rest.right);
        // The content keeps its proportions.
        final icon = tester.getSize(
          find.descendant(of: sheet, matching: find.byIcon(Icons.close)),
        );
        expect(icon.width, closeTo(icon.height, 0.01));

        await send(tester, 'commitBackGesture');
        await settle(tester);
        expect(sheet, findsNothing);
      });

      testWidgets('returns to its place when the gesture is cancelled', (
        tester,
      ) async {
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(modalHost());
        await open(tester);
        final rest = container(tester);

        await send(tester, 'startBackGesture', event(0));
        await send(tester, 'updateBackGestureProgress', event(0.6));
        await tester.pump();
        expect(container(tester), isNot(rest));
        await send(tester, 'cancelBackGesture');
        await settle(tester);
        expect(sheet, findsOneWidget);
        expect(container(tester), rest);
      });

      testWidgets('returns at once where the platform reduces motion', (
        tester,
      ) async {
        setWindowSize(tester, const Size(1300, 800));
        await tester.pumpWidget(modalHost(disableAnimations: true));
        await open(tester);
        final rest = container(tester);

        await send(tester, 'startBackGesture', event(0));
        await send(tester, 'updateBackGestureProgress', event(0.6));
        await tester.pump();
        expect(container(tester), isNot(rest));
        await send(tester, 'cancelBackGesture');
        await tester.pump();
        expect(container(tester), rest);
      });
    });

    testWidgets('fades its scrim on the default effects token', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost());
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final scrim = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is ColoredBox && widget.color == Colors.black54,
              ),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      final effects = const MotionScheme.expressive().defaultEffects;
      expect(
        scrim.opacity.value,
        closeTo(effects.simulation(0, 1).x(0.04), 0.02),
      );
      await settle(tester);
    });

    testWidgets('does not animate when the platform reduces motion', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost(disableAnimations: true));
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(sheet).right, 1300);
      final route = ModalRoute.of(tester.element(sheet))!;
      expect(route.animation!.status, AnimationStatus.completed);
    });
  });

  group('Standard side sheet', () {
    testWidgets("uses the surface colour, with the panes' corners, square "
        'by default', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(paneHost());
      final material = sheetMaterial(tester);
      final colors = Theme.of(tester.element(sheet)).colorScheme;
      expect(material.color, colors.surface);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.zero,
      );
    });

    testWidgets('is a dialog too, but does not take the route', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(paneHost());
      final data = tester.getSemantics(sheet).getSemanticsData();
      expect(data.role, SemanticsRole.dialog);
      expect(data.flagsCollection.namesRoute, isFalse);
      semantics.dispose();
    });

    testWidgets('shows a close button only where it can be closed, and '
        'keeps its header either way', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      Widget permanent({VoidCallback? onClose}) => app(
        Scaffold(
          body: SupportingPaneLayout(
            focus: const SizedBox.expand(),
            supporting: SideSheet(
              headline: const Text('Filters'),
              onClose: onClose,
              child: const Text('Content'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(paneHost());
      final closable = (
        tester.getTopLeft(find.text('Filters')),
        tester.getTopLeft(find.text('Content')),
      );
      expect(find.byTooltip('Close'), findsOneWidget);
      // The header is 72dp: 12dp above and below a 48dp row.
      expect(
        tester.getTopLeft(find.text('Content')).dy - tester.getRect(sheet).top,
        72,
      );

      // A permanent pane cannot be closed, and its sheet shows no button.
      await tester.pumpWidget(permanent());
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Close'), findsNothing);
      expect(tester.getTopLeft(find.text('Filters')), closable.$1);
      expect(tester.getTopLeft(find.text('Content')), closable.$2);

      // A sheet may still close itself.
      var closed = 0;
      await tester.pumpWidget(permanent(onClose: () => closed++));
      await tester.tap(find.byTooltip('Close'));
      expect(closed, 1);

      // Its own action comes before the pane's dismissal.
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              focus: const SizedBox.expand(),
              onSupportingDismissed: () => dismissed++,
              supporting: SideSheet(
                onClose: () => closed++,
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Close'));
      expect((closed, dismissed), (2, 0));
    });
  });

  group('Anatomy', () {
    testWidgets('pads the header and content by 24dp', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(paneHost());
      final rect = tester.getRect(sheet);
      final headline = tester.getRect(find.text('Filters'));
      final close = tester.getRect(find.byType(IconButton));
      final content = tester.getRect(find.text('Content'));
      expect(headline.left - rect.left, 24);
      expect(rect.right - close.right, 24);
      expect(content.left - rect.left, 24);
      // The close button keeps its 48dp target.
      expect(close.width, greaterThanOrEqualTo(48));
      expect(close.height, greaterThanOrEqualTo(48));
    });

    testWidgets('starts 16dp in, with 12dp between top elements, beside a '
        'back button in a modal sheet', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(modalHost(withBack: true));
      await open(tester);
      final rect = tester.getRect(sheet);
      final buttons = find.byType(IconButton);
      final back = tester.getRect(buttons.first);
      final headline = tester.getRect(find.text('Filters'));
      final close = tester.getRect(buttons.last);
      expect(back.left - rect.left, 16);
      expect(headline.left - back.right, 12);
      expect(close.left - headline.right, greaterThanOrEqualTo(12));
    });

    testWidgets('sets the bottom actions below a divider, from the start, '
        'with 16dp above and 24dp below', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        paneHost(
          actions: [
            FilledButton(onPressed: () {}, child: const Text('Apply')),
            OutlinedButton(onPressed: () {}, child: const Text('Reset')),
          ],
        ),
      );
      final rect = tester.getRect(sheet);
      final line = tester.getRect(find.byType(Divider));
      final apply = tester.getRect(find.byType(FilledButton));
      final reset = tester.getRect(find.byType(OutlinedButton));
      expect(apply.left - rect.left, 24);
      expect(reset.left, greaterThan(apply.right));
      expect(apply.top - line.bottom, 16);
      expect(rect.bottom - apply.bottom, 24);
      expect(rect.bottom - line.bottom, greaterThanOrEqualTo(72));
      final colors = Theme.of(tester.element(sheet)).colorScheme;
      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.color, colors.outlineVariant);
    });

    testWidgets('stacks the bottom actions where a row of them would be '
        'wider than the sheet', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(
        paneHost(
          actions: [
            FilledButton(
              onPressed: () {},
              child: const Text('Apply every filter'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Reset every filter'),
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(sheet);
      final apply = tester.getRect(find.byType(FilledButton));
      final reset = tester.getRect(find.byType(OutlinedButton));
      expect(reset.top, greaterThan(apply.bottom));
      expect(apply.left - rect.left, 24);
      expect(reset.left - rect.left, 24);
      expect(rect.bottom - reset.bottom, 24);
    });

    testWidgets('scrolls vertically only', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(paneHost());
      final scrollables = tester.widgetList<Scrollable>(
        find.descendant(of: sheet, matching: find.byType(Scrollable)),
      );
      expect(scrollables, isNotEmpty);
      for (final scrollable in scrollables) {
        expect(scrollable.axisDirection, AxisDirection.down);
      }
      final content = tester.getRect(find.text('Content'));
      expect(content.right, lessThanOrEqualTo(tester.getRect(sheet).right));
    });
  });

  group('Adaptive sheet', () {
    Widget host({required double regionWidth}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: regionWidth,
            child: Builder(
              builder: (context) => TextButton(
                key: triggerKey,
                onPressed: () => showAdaptiveSheet<void>(
                  context: context,
                  headline: const Text('Filters'),
                  builder: (context) => const Text('Content'),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('is a side sheet at expanded and wider', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(host(regionWidth: 1000));
      await open(tester);
      expect(sheet, findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('is a bottom sheet below expanded', (tester) async {
      setWindowSize(tester, const Size(700, 800));
      await tester.pumpWidget(host(regionWidth: 700));
      await open(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(sheet, findsNothing);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      // The content keeps the side sheet's 24dp inset, as the headline does.
      expect(
        tester.getRect(find.text('Content')).left,
        tester.getRect(find.text('Filters')).left,
      );
    });

    testWidgets('chooses by the window, not the region', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(host(regionWidth: 300));
      await open(tester);
      expect(sheet, findsOneWidget);
    });

    for (final width in [700.0, 1000.0]) {
      testWidgets('scrolls content taller than it in either form '
          '(${width.round()}dp)', (tester) async {
        setWindowSize(tester, Size(width, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: triggerKey,
                  onPressed: () => showAdaptiveSheet<void>(
                    context: context,
                    headline: const Text('Filters'),
                    builder: (context) => Column(
                      children: [
                        for (var i = 0; i < 40; i++)
                          SizedBox(height: 48, child: Text('Item $i')),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await open(tester);
        expect(tester.takeException(), isNull);
        final top = tester.getTopLeft(find.text('Item 0')).dy;
        await tester.drag(find.text('Item 2'), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Item 0')).dy, lessThan(top - 100));
      });
    }
  });

  group('Opening and closing', () {
    // An app with a button that calls [onOpen].
    Widget host(void Function(BuildContext context) onOpen) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: triggerKey,
              onPressed: () => onOpen(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    void openSideSheet(BuildContext context, {PaneMotion? motion}) =>
        showSideSheet<void>(
          context: context,
          motion: motion,
          builder: (context) => const SideSheet(child: Text('Content')),
        );

    testWidgets('slides the sheet in without fading it', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(host(openSideSheet));
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      // On its way in from beyond the trailing edge.
      final right = tester.getRect(sheet).right;
      expect(right, greaterThan(1300));
      expect(right, lessThan(1300 + 400));
      // Nothing above it fades it.
      RenderObject? node = tester.renderObject(sheet);
      while (node != null) {
        if (node is RenderOpacity) expect(node.opacity, 1);
        if (node is RenderAnimatedOpacity) expect(node.opacity.value, 1);
        node = node.parent;
      }
      await settle(tester);
      expect(tester.getRect(sheet).right, 1300);
    });

    testWidgets('leaves on the exit motion, however it entered', (
      tester,
    ) async {
      const spring = MotionScheme.expressive();
      Future<void> openAndClose(PaneMotion motion) async {
        await tester.pumpWidget(
          host((context) => openSideSheet(context, motion: motion)),
        );
        await tester.tap(find.byKey(triggerKey));
        await settle(tester);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
      }

      setWindowSize(tester, const Size(1300, 800));
      await openAndClose(
        PaneMotion(enter: spring.defaultSpatial, exit: const Motion.none()),
      );
      expect(sheet, findsNothing);
      await settle(tester);

      await openAndClose(
        PaneMotion(enter: const Motion.none(), exit: spring.defaultSpatial),
      );
      expect(sheet, findsOneWidget);
      expect(tester.getRect(sheet).right, greaterThan(1300));
      await settle(tester);
      expect(sheet, findsNothing);
    });

    testWidgets('sits on the trailing screen of a window a hinge divides', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 800));
      tester.view.displayFeatures = [
        const DisplayFeature(
          bounds: Rect.fromLTRB(640, 0, 660, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.unknown,
        ),
      ];
      addTearDown(tester.view.resetDisplayFeatures);
      await tester.pumpWidget(host(openSideSheet));
      await tester.tap(find.byKey(triggerKey));
      await settle(tester);
      expect(tester.getRect(sheet).right, 1300);
    });

    Widget tallAdaptive() => host(
      (context) => showAdaptiveSheet<void>(
        context: context,
        headline: const Text('Filters'),
        builder: (context) => Column(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 48, child: Text('Item $i')),
          ],
        ),
      ),
    );

    testWidgets('as a bottom sheet, keeps its content clear of the bottom '
        'inset', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(tallAdaptive());
      await tester.tap(find.byKey(triggerKey));
      await settle(tester);
      final scrollable = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(
        tester.getRect(find.text('Item 39')).bottom,
        lessThanOrEqualTo(752),
      );
    });

    testWidgets('as a bottom sheet, opens at once where motion is reduced', (
      tester,
    ) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: tallAdaptive(),
        ),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.pump();
      final opened = tester.getRect(find.byType(BottomSheet));
      await settle(tester);
      expect(tester.getRect(find.byType(BottomSheet)), opened);
    });
  });
}
