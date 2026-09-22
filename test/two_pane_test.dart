import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const _primaryKey = Key('primary');
const _secondaryKey = Key('secondary');

Widget _twoPane({
  bool showSecondary = true,
  PaneTransition transition = const PaneTransition.spring(),
  double? ratio = 0.25,
  PaneSide fixedSide = PaneSide.primary,
}) {
  return app(
    TwoPane(
      primary: const SizedBox.expand(key: _primaryKey),
      secondary: showSecondary
          ? const SizedBox.expand(key: _secondaryKey)
          : null,
      strategy: TwoPaneStrategy.fixedFlexible,
      fixedSide: fixedSide,
      ratio: ratio,
      gutter: 24,
      minPaneWidth: 0,
      transition: transition,
    ),
  );
}

/// Whether the secondary is being faded, i.e. sits under a partial Opacity.
bool _secondaryFades(WidgetTester tester) {
  final opacity = find.ancestor(
    of: find.byKey(_secondaryKey),
    matching: find.byType(Opacity),
  );
  if (opacity.evaluate().isEmpty) return false;
  return tester.widget<Opacity>(opacity.first).opacity < 1;
}

void main() {
  group('ratio is the fixed pane\'s share', () {
    testWidgets('fixed primary', (tester) async {
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(_twoPane());
      await pumpFrames(tester);

      expect(tester.getSize(find.byKey(_primaryKey)).width, 300);
      expect(tester.getSize(find.byKey(_secondaryKey)).width, 900);
    });

    testWidgets('fixed secondary', (tester) async {
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(_twoPane(fixedSide: PaneSide.secondary));
      await pumpFrames(tester);

      expect(tester.getSize(find.byKey(_primaryKey)).width, 900);
      expect(tester.getSize(find.byKey(_secondaryKey)).width, 300);
    });
  });

  group('transition', () {
    testWidgets('the default spring enters over several frames', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(_twoPane(showSecondary: false));
      await tester.pumpWidget(_twoPane());
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.getSize(find.byKey(_primaryKey)).width,
        greaterThan(300),
        reason: 'mid-entrance the secondary has not reached its width',
      );

      await pumpFrames(tester);
      expect(tester.getSize(find.byKey(_primaryKey)).width, 300);
    });

    testWidgets('the default spring leaves without fading', (tester) async {
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(_twoPane());
      await pumpFrames(tester);

      await tester.pumpWidget(_twoPane(showSecondary: false));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(_secondaryKey),
        findsOneWidget,
        reason: 'the secondary is still on its way out',
      );
      expect(_secondaryFades(tester), isFalse);

      await pumpFrames(tester);
      expect(find.byKey(_secondaryKey), findsNothing);
      expect(tester.getSize(find.byKey(_primaryKey)).width, 1224);
    });

    testWidgets('curvedExit fades on the way out', (tester) async {
      const transition = PaneTransition.curvedExit();
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(_twoPane(transition: transition));
      await pumpFrames(tester);

      await tester.pumpWidget(
        _twoPane(showSecondary: false, transition: transition),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(_secondaryFades(tester), isTrue);

      await pumpFrames(tester);
      expect(find.byKey(_secondaryKey), findsNothing);
    });

    testWidgets('none shows and hides at once', (tester) async {
      const transition = PaneTransition.none();
      setWindowSize(tester, const Size(1224, 800));
      await tester.pumpWidget(
        _twoPane(showSecondary: false, transition: transition),
      );

      await tester.pumpWidget(_twoPane(transition: transition));
      await tester.pump();
      expect(tester.getSize(find.byKey(_secondaryKey)).width, 900);

      await tester.pumpWidget(
        _twoPane(showSecondary: false, transition: transition),
      );
      await tester.pump();
      expect(find.byKey(_secondaryKey), findsNothing);
    });
  });

  testWidgets('temporary resizing springs back to the default on release', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1224, 800));
    final controller = PaneController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        TwoPane(
          primary: const SizedBox.expand(key: _primaryKey),
          secondary: const SizedBox.expand(key: _secondaryKey),
          strategy: TwoPaneStrategy.fixedFlexible,
          ratio: 0.25,
          gutter: 24,
          minPaneWidth: 0,
          resizable: true,
          resizeBehavior: PaneResizeBehavior.temporary,
          paneController: controller,
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.drag(find.byType(PaneDragHandle), const Offset(200, 0));
    await pumpFrames(tester);

    expect(controller.fraction, isNull);
    expect(tester.getSize(find.byKey(_primaryKey)).width, 300);
  });

  group('the default fixed pane width follows the breakpoint', () {
    // Material 3: a fixed pane is 360dp through expanded and 412dp at large
    // and extra-large.
    Widget fixedPane() => app(
      TwoPane(
        primary: const SizedBox.expand(key: _primaryKey),
        secondary: const SizedBox.expand(key: _secondaryKey),
        strategy: TwoPaneStrategy.fixedFlexible,
        gutter: 24,
      ),
    );

    testWidgets('360dp at expanded', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(fixedPane());
      await pumpFrames(tester);

      expect(
        tester.getSize(find.byKey(_primaryKey)).width,
        closeTo(360, 0.001),
      );
    });

    testWidgets('412dp at large', (tester) async {
      setWindowSize(tester, const Size(1300, 800));
      await tester.pumpWidget(fixedPane());
      await pumpFrames(tester);

      expect(
        tester.getSize(find.byKey(_primaryKey)).width,
        closeTo(412, 0.001),
      );
    });
  });

  group('the drag handle offers each snap stop as a semantic action', () {
    Widget resizable(PaneController controller) => app(
      TwoPane(
        primary: const SizedBox.expand(key: _primaryKey),
        secondary: const SizedBox.expand(key: _secondaryKey),
        strategy: TwoPaneStrategy.fixedFlexible,
        ratio: 0.3,
        gutter: 24,
        resizable: true,
        paneController: controller,
      ),
    );

    testWidgets('the stops are announced', (tester) async {
      setWindowSize(tester, const Size(1224, 800));
      final controller = PaneController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(resizable(controller));
      await pumpFrames(tester);

      final node = tester.getSemantics(find.byType(PaneDragHandle));
      final labels = node
          .getSemanticsData()
          .customSemanticsActionIds!
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toList();

      expect(labels, contains('Collapse the leading pane'));
      expect(labels, contains('Set pane split to 50%'));
      expect(labels, contains('Set pane split to 30%'));
    });

    testWidgets('invoking one moves the divider', (tester) async {
      setWindowSize(tester, const Size(1224, 800));
      final controller = PaneController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(resizable(controller));
      await pumpFrames(tester);

      final node = tester.getSemantics(find.byType(PaneDragHandle));
      final id = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
        (id) =>
            CustomSemanticsAction.getAction(id)!.label ==
            'Set pane split to 50%',
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Resize panes'),
        SemanticsAction.customAction,
        args: id,
      );
      await pumpFrames(tester);

      expect(controller.fraction, closeTo(0.5, 0.001));
      expect(tester.getSize(find.byKey(_primaryKey)).width, closeTo(600, 0.5));
    });
  });
}
