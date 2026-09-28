// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:ui' show Tristate;

import 'package:demo/app/demo_app.dart';
import 'package:demo/app/shell.dart';
import 'package:demo/main.dart';
import 'package:demo/screens/articles.dart';
import 'package:demo/screens/extra.dart';
import 'package:demo/screens/inbox.dart';
import 'package:demo/widgets/panes.dart';
import 'package:demo/widgets/settings_panel.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

// Every setting in the demo's settings reaches the parameter of the package
// it names, and changes what the package does.

void setWindowSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the demo in a window of [size], and returns its settings.
Future<ValueNotifier<DemoSettings>> pumpDemo(
  WidgetTester tester,
  Size size,
) async {
  setWindowSize(tester, size);
  await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
  await settle(tester);
  return Settings.controllerOf(tester.element(find.byType(NavigatorDemo)));
}

Future<void> apply(
  WidgetTester tester,
  ValueNotifier<DemoSettings> settings,
  DemoSettings Function(DemoSettings settings) change,
) async {
  settings.value = change(settings.value);
  await settle(tester);
}

/// Goes to the destination labelled [label].
Future<void> visit(WidgetTester tester, String label) async {
  final navigation = find.byWidgetPredicate(
    (widget) => widget is NavigationRail || widget is NavigationBar,
  );
  await tester.tap(
    find.descendant(of: navigation, matching: find.text(label)).first,
  );
  await settle(tester);
}

Finder inPanel(String text) =>
    find.descendant(of: find.byType(SettingsPanel), matching: find.text(text));

/// Scrolls the settings to [finder], and taps it.
Future<void> tapSetting(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Demo settings').first);
  await settle(tester);
}

/// The setting titled [title], with its value and its controls.
Finder setting(String title) =>
    find.ancestor(of: inPanel(title), matching: find.byType(Column)).first;

/// The slider of the setting titled [title].
Slider sliderOf(WidgetTester tester, String title) => tester.widget(
  find.descendant(of: setting(title), matching: find.byType(Slider)),
);

ListDetailLayout<int> inbox(WidgetTester tester) =>
    tester.widget(find.byType(ListDetailLayout<int>));

BuildContext inboxContext(WidgetTester tester) =>
    tester.element(find.byType(ListDetailLayout<int>));

void main() {
  group('The settings sheet', () {
    const sizes = [Size(1300, 900), Size(400, 800)];

    // Closes the sheet, in whichever form it is.
    Future<void> closeSettings(WidgetTester tester) async {
      Navigator.of(tester.element(find.byType(SettingsPanel))).pop();
      await settle(tester);
      expect(find.byType(SettingsPanel), findsNothing);
    }

    for (final size in sizes) {
      final width = size.width.round();

      testWidgets('opens with its sections closed, each of which opens '
          '(${width}dp)', (tester) async {
        await pumpDemo(tester, size);
        await openSettings(tester);
        for (final section in SettingsSection.values) {
          expect(inPanel(section.title), findsOneWidget);
        }
        expect(inPanel('Right to left'), findsNothing);
        expect(inPanel('Two panes from'), findsNothing);

        for (final section in SettingsSection.values) {
          await tapSetting(tester, inPanel(section.title));
        }
        expect(tester.takeException(), isNull);
        expect(inPanel('Right to left'), findsOneWidget);
        expect(inPanel('Line length'), findsOneWidget);
      });

      testWidgets('opens as it was left: the same sections open, scrolled '
          'as far (${width}dp)', (tester) async {
        await pumpDemo(tester, size);
        await openSettings(tester);
        await tapSetting(tester, inPanel('Motion'));
        await tapSetting(tester, inPanel('Inbox'));
        await tester.ensureVisible(inPanel('Split'));
        await settle(tester);
        final split = tester.getTopLeft(inPanel('Split')).dy;
        await closeSettings(tester);

        // From another screen.
        await visit(tester, 'Feed');
        await openSettings(tester);
        expect(inPanel('Motion scheme'), findsOneWidget);
        expect(inPanel('Two panes from'), findsOneWidget);
        expect(inPanel('Right to left'), findsNothing);
        expect(tester.getTopLeft(inPanel('Split')).dy, moreOrLessEquals(split));
      });

      testWidgets('keeps the reset button in view below the settings '
          '(${width}dp)', (tester) async {
        final settings = await pumpDemo(tester, size);
        await apply(tester, settings, (s) => s.copyWith(feedGap: 0));
        await openSettings(tester);
        for (final section in SettingsSection.values) {
          await tapSetting(tester, inPanel(section.title));
        }
        final reset = find.widgetWithText(OutlinedButton, 'Reset all settings');
        final at = tester.getRect(reset);
        expect(at.bottom, lessThanOrEqualTo(size.height));
        await tester.ensureVisible(inPanel('Line length'));
        await settle(tester);
        expect(tester.getRect(reset), at);

        await tester.tap(reset);
        await settle(tester);
        expect(settings.value.feedGap, 16);
      });
    }

    testWidgets('scrolls when dragged beside the content', (tester) async {
      await pumpDemo(tester, const Size(1300, 900));
      await openSettings(tester);
      for (final section in [
        SettingsSection.app,
        SettingsSection.motion,
        SettingsSection.inbox,
      ]) {
        await tapSetting(tester, inPanel(section.title));
      }
      Scrollable.of(tester.element(inPanel('App'))).position.jumpTo(0);
      await tester.pump();
      final top = tester.getTopLeft(inPanel('App')).dy;
      // A drag on the settings, in the middle of the sheet.
      final sheet = tester.getRect(find.byType(SideSheet));
      await tester.dragFrom(sheet.center, const Offset(0, -300));
      await settle(tester);
      expect(tester.getTopLeft(inPanel('App')).dy, lessThan(top - 100));
    });

    testWidgets('below expanded, is a bottom sheet dragged taller, which '
        'opens as tall as it was left', (tester) async {
      await pumpDemo(tester, const Size(400, 800));
      await openSettings(tester);
      expect(find.byType(SideSheet), findsNothing);
      final half = tester.getTopLeft(inPanel('App')).dy;

      // Dragging the headline takes the sheet to the whole window.
      await tester.drag(find.text('Demo settings'), const Offset(0, -500));
      await settle(tester);
      final whole = tester.getTopLeft(inPanel('App')).dy;
      expect(whole, lessThan(half - 200));
      await closeSettings(tester);

      await openSettings(tester);
      expect(tester.getTopLeft(inPanel('App')).dy, moreOrLessEquals(whole));
    });

    testWidgets('changes the navigation settings, and puts a token back to '
        'its default', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Navigation rail'));
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Modal'));
      expect(settings.value.railMenu, RailMenu.modal);
      await tapSetting(
        tester,
        find.widgetWithText(SwitchListTile, 'Theme switch'),
      );
      expect(settings.value.railTrailing, isTrue);
      final count = find.descendant(
        of: setting('Destinations'),
        matching: find.byType(Slider),
      );
      await tester.ensureVisible(count);
      await tester.drag(count, const Offset(400, 0));
      await settle(tester);
      expect(settings.value.railCount, Destination.values.length);

      await tapSetting(tester, inPanel('Rail style'));
      final minWidth = find.descendant(
        of: setting('minWidth'),
        matching: find.byType(Slider),
      );
      Finder shown(String value) =>
          find.descendant(of: setting('minWidth'), matching: find.text(value));
      expect(shown('96dp (default)'), findsOneWidget);
      await tester.ensureVisible(minWidth);
      await tester.drag(minWidth, const Offset(400, 0));
      await settle(tester);
      expect(settings.value.railTokens, {RailToken.minWidth: 200});
      expect(shown('200dp'), findsOneWidget);

      await tapSetting(
        tester,
        find.descendant(
          of: setting('minWidth'),
          matching: find.byTooltip('Back to default'),
        ),
      );
      expect(settings.value.railTokens, isEmpty);
      expect(shown('96dp (default)'), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railTokens: {RailToken.iconSize: 32, RailToken.itemSpace: 12},
        ),
      );
      await tapSetting(tester, inPanel('Use the default tokens'));
      expect(settings.value.railTokens, isEmpty);

      // The labels' lines and overflow, before the label tokens.
      expect(
        find.descendant(
          of: setting('labelMaxLines'),
          matching: find.text('no limit'),
        ),
        findsOneWidget,
      );
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Ellipsis'));
      expect(settings.value.railLabelOverflow, TextOverflow.ellipsis);
      await tapSetting(
        tester,
        find.widgetWithText(SwitchListTile, 'Bottom inset'),
      );
      expect(settings.value.railBottomInset, isFalse);

      // The bar's labels scale without a cap by default.
      await tapSetting(tester, inPanel('Bar style'));
      expect(
        find.descendant(
          of: setting('maxLabelScale'),
          matching: find.text('no cap'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('chooses the placement, and the breakpoint of a rule that '
        'swaps there', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      ChoiceChip chip(String label) =>
          tester.widget(find.widgetWithText(ChoiceChip, label));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Navigation'));
      expect(inPanel('From'), findsNothing);
      expect(chip('Two panes').onSelected, isNotNull);

      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Bar from'));
      expect(settings.value.navigationRule, NavigationRule.barFrom);
      // Only Material's placement goes by the panes.
      expect(chip('Two panes').onSelected, isNull);
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Large'));
      expect(settings.value.navigationRuleFrom, Breakpoint.large);
      expect(
        NavigationScaffold.placementOf(inboxContext(tester)),
        NavigationPlacement.bar,
      );
    });

    testWidgets('changes the settings from its chips, switches and '
        'sliders', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      final split = InboxSplit.of(tester.element(find.byType(NavigatorDemo)));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Inbox'));

      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'List alone'));
      expect(settings.value.nothingSelected, NothingSelected.listOnly);

      await tapSetting(tester, find.widgetWithText(ChoiceChip, '412dp'));
      expect(split.value, const PaneSplit.width(412));

      await tapSetting(
        tester,
        find.widgetWithText(SwitchListTile, 'Remember resizes').first,
      );
      expect(settings.value.inboxRemembersResize, isFalse);

      await tapSetting(tester, inPanel('Feed'));
      final gap = find.descendant(
        of: find
            .ancestor(of: inPanel('Gap'), matching: find.byType(Column))
            .first,
        matching: find.byType(Slider),
      );
      await tester.ensureVisible(gap);
      await tester.drag(gap, const Offset(-400, 0));
      await settle(tester);
      expect(settings.value.feedGap, 0);

      await tester.tap(find.text('Reset all settings'));
      await settle(tester);
      expect(settings.value.nothingSelected, NothingSelected.placeholder);
      expect(settings.value.inboxRemembersResize, isTrue);
      expect(settings.value.feedGap, 16);
      expect(split.value, PaneSplit.automatic);
    });
  });

  group('Every setting reaches the package:', () {
    testWidgets('reduce motion asks for no motion', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      expect(MediaQuery.disableAnimationsOf(inboxContext(tester)), isFalse);
      await apply(tester, settings, (s) => s.copyWith(reduceMotion: true));
      final context = inboxContext(tester);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      expect(PaneMotion.resolve(context, null), const PaneMotion.none());
    });

    testWidgets('the breakpoints are the thresholds the layouts resolve '
        'against', (tester) async {
      // Beside the rail, a 900dp window leaves a medium body, which the
      // inbox shows as one pane.
      final settings = await pumpDemo(tester, const Size(900, 900));
      expect(find.text('Select a message to read it'), findsNothing);

      const custom = Breakpoints(mediumMinWidth: 500, expandedMinWidth: 760);
      await apply(tester, settings, (s) => s.copyWith(breakpoints: custom));
      expect(MaterialLayoutTheme.of(inboxContext(tester)).breakpoints, custom);
      expect(find.text('Select a message to read it'), findsOneWidget);
    });

    testWidgets('the pane style sets where the layouts keep the margins, '
        'with the corners of the cards', (tester) async {
      Finder surface() => find
          .descendant(
            of: find.byType(PaneSurface),
            matching: find.byType(Material),
          )
          .first;
      final settings = await pumpDemo(tester, const Size(400, 800));
      expect(tester.getRect(surface()).left, 0);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(paneStyle: PaneStyle.cards, cardRadius: 24),
      );
      expect(
        MaterialLayoutTheme.of(inboxContext(tester)).marginPlacement,
        MarginPlacement.outside,
      );
      expect(tester.getRect(surface()).left, 16);
      expect(
        (tester.widget<Material>(surface()).shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(24),
      );

      setWindowSize(tester, const Size(1300, 900));
      await apply(
        tester,
        settings,
        (s) => s.copyWith(paneStyle: PaneStyle.flat),
      );
      expect(
        MaterialLayoutTheme.of(inboxContext(tester)).marginPlacement,
        MarginPlacement.inside,
      );
      expect(
        (tester.widget<Material>(surface()).shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.zero,
      );
      expect(
        tester.getRect(surface()).left,
        tester.getRect(find.byType(NavigationRail)).right,
      );
    });

    testWidgets("the panes' colour and outline", (tester) async {
      Finder surface() => find
          .descendant(
            of: find.byType(PaneSurface),
            matching: find.byType(Material),
          )
          .first;
      final settings = await pumpDemo(tester, const Size(1300, 900));
      final colors = Theme.of(inboxContext(tester)).colorScheme;
      expect(tester.widget<Material>(surface()).color, colors.surface);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(paneColor: PaneColor.lowest, paneOutline: true),
      );
      final style = MaterialLayoutTheme.of(inboxContext(tester))
          .paneSurfaceStyle;
      expect(style.color, colors.surfaceContainerLowest);
      expect(style.outline, BorderSide(color: colors.outlineVariant));
      final material = tester.widget<Material>(surface());
      expect(material.color, colors.surfaceContainerLowest);
      expect(
        (material.shape! as RoundedRectangleBorder).side,
        BorderSide(color: colors.outlineVariant),
      );
    });

    testWidgets('the motion scheme, and the motion of panes and '
        'navigation', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      MotionScheme scheme() => MotionScheme.of(inboxContext(tester));

      await apply(
        tester,
        settings,
        (s) => s.copyWith(motion: MotionChoice.standard),
      );
      expect(scheme(), const MotionScheme.standard());

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          motion: MotionChoice.spring,
          springDamping: 0.5,
          springStiffness: 600,
        ),
      );
      expect(
        scheme().defaultSpatial,
        const Motion.spring(dampingRatio: 0.5, stiffness: 600),
      );

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          motion: MotionChoice.curve,
          curveDuration: const Duration(milliseconds: 300),
        ),
      );
      expect(
        scheme().defaultSpatial,
        const Motion.curved(
          duration: Duration(milliseconds: 300),
          curve: Easing.standard,
        ),
      );

      await apply(
        tester,
        settings,
        (s) => s.copyWith(animatePanes: false, animateNavigation: false),
      );
      expect(inbox(tester).motion, const PaneMotion.none());
      expect(
        tester
            .widget<SupportingPaneLayout>(
              find.byType(SupportingPaneLayout).first,
            )
            .motion,
        const PaneMotion.none(),
      );
      expect(
        tester
            .widget<NavigationScaffold>(find.byType(NavigationScaffold))
            .motion,
        const PaneMotion.none(),
      );
    });

    testWidgets('slow animations slow every animation until they are turned '
        'off or reset, or the app goes', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Motion'));

      await tapSetting(tester, find.widgetWithText(ChoiceChip, '5×'));
      expect(settings.value.slowAnimations, 5);
      expect(timeDilation, 5);
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Off'));
      expect(timeDilation, 1);

      await tapSetting(tester, find.widgetWithText(ChoiceChip, '10×'));
      expect(timeDilation, 10);
      await tester.tap(find.text('Reset all settings'));
      await settle(tester);
      expect(timeDilation, 1);

      await apply(tester, settings, (s) => s.copyWith(slowAnimations: 2));
      expect(timeDilation, 2);
      await tester.pumpWidget(const SizedBox());
      expect(timeDilation, 1);
    });

    testWidgets('resizing, the stops and the drag handle', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      expect(find.byType(PaneDragHandle), findsOneWidget);
      expect((inbox(tester).dragHandle as PaneResizer).snapStops, isNull);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          snapToStops: false,
          handle: const DragHandleStyle(
            thickness: 6,
            length: 40,
            pressedThickness: 10,
            pressedLength: 44,
          ),
          handleColor: HandleColor.primary,
        ),
      );
      expect((inbox(tester).dragHandle as PaneResizer).snapStops, isEmpty);
      final context = inboxContext(tester);
      final style = MaterialLayoutTheme.of(context).dragHandleStyle;
      expect(style.thickness, 6);
      expect(style.length, 40);
      expect(style.pressedThickness, 10);
      expect(style.pressedLength, 44);
      expect(style.color, Theme.of(context).colorScheme.primary);

      await apply(tester, settings, (s) => s.copyWith(resizable: false));
      expect(inbox(tester).resizable, isFalse);
      expect(find.byType(PaneDragHandle), findsNothing);
    });

    testWidgets("the drag handle's gestures", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      PaneResizer resizer() => inbox(tester).dragHandle as PaneResizer;
      expect(resizer().onTap, PaneResizer.restore);
      expect(resizer().onDoubleTap, PaneResizer.toggle);
      expect(resizer().onLongPress, PaneResizer.splitEvenly);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          handleTap: HandleAction.toggle,
          handleDoubleTap: HandleAction.nothing,
          handleLongPress: HandleAction.splitEvenly,
        ),
      );
      expect(resizer().onTap, PaneResizer.toggle);
      expect(resizer().onDoubleTap, isNull);
      final split = InboxSplit.of(tester.element(find.byType(NavigatorDemo)));
      // A tap toggles at once, with no double tap to wait for.
      await tester.tap(find.byType(PaneResizer));
      await tester.pump();
      expect(split.value, PaneSplit.collapsed);
      split.value = PaneSplit.automatic;
      await settle(tester);
      await tester.longPress(find.byType(PaneResizer));
      await settle(tester);
      expect(split.value, PaneSplit.centered);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(handleLongPress: HandleAction.restore),
      );
      await tester.longPress(find.byType(PaneResizer));
      await settle(tester);
      expect(split.value, PaneSplit.automatic);
    });

    testWidgets('what the handle hides in the inbox', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      expect(inbox(tester).listCollapse, isNull);
      expect(inbox(tester).detailCollapse, isNull);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          listCollapse: PaneCollapse.never,
          messageCollapse: PaneCollapse.dismiss,
          nothingSelected: NothingSelected.listOnly,
        ),
      );
      expect(inbox(tester).listCollapse, PaneCollapse.never);
      expect(inbox(tester).detailCollapse, PaneCollapse.dismiss);

      // A message dismissed with the handle leaves the list alone: with a
      // placeholder or the first message in its place, the handle does what
      // it does by default.
      for (final nothingSelected in [
        NothingSelected.placeholder,
        NothingSelected.firstMessage,
      ]) {
        await apply(
          tester,
          settings,
          (s) => s.copyWith(
            nothingSelected: NothingSelected.listOnly,
            messageCollapse: PaneCollapse.dismiss,
          ),
        );
        await apply(
          tester,
          settings,
          (s) => s.copyWith(nothingSelected: nothingSelected),
        );
        expect(inbox(tester).detailCollapse, isNull);
        await apply(
          tester,
          settings,
          (s) => s.copyWith(messageCollapse: PaneCollapse.dismiss),
        );
        expect(inbox(tester).detailCollapse, isNull);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets("the inbox's panes, empty behaviour, split and memory", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      final split = InboxSplit.of(tester.element(find.byType(NavigatorDemo)));
      expect(inbox(tester).splitController, same(split));

      await apply(
        tester,
        settings,
        (s) => s.copyWith(twoPanesFrom: Breakpoint.extraLarge),
      );
      expect(inbox(tester).twoPaneBreakpoint, Breakpoint.extraLarge);
      expect(find.text('Select a message to read it'), findsNothing);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          twoPanesFrom: Breakpoint.expanded,
          nothingSelected: NothingSelected.listOnly,
          inboxRemembersResize: false,
        ),
      );
      expect(
        inbox(tester).emptyBehavior,
        const ListDetailEmptyBehavior<int>.hidePane(),
      );
      expect(inbox(tester).resizeMemory, PaneResizeMemory.temporary);

      // The split the settings set is the one the list keeps.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(nothingSelected: NothingSelected.placeholder),
      );
      split.value = const PaneSplit.width(412);
      await settle(tester);
      final list = find.ancestor(
        of: find.text('Inbox'),
        matching: find.byType(PaneSurface),
      );
      expect(tester.getSize(list).width, 412);
    });

    testWidgets("the related articles' form, side, dismissal and memory", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await visit(tester, 'Articles');
      final layoutFinder = find.descendant(
        of: find.byType(ArticlesScreen),
        matching: find.byType(SupportingPaneLayout),
      );
      SupportingPaneLayout layout() => tester.widget(layoutFinder);
      Rect related() => tester.getRect(
        find.ancestor(
          of: find.text('Related'),
          matching: find.byType(PaneSurface),
        ),
      );
      expect(layout().supporting, isA<SideSheet>());

      await apply(
        tester,
        settings,
        (s) => s.copyWith(related: RelatedPlacement.trailingPane),
      );
      expect(layout().supporting, isA<PaneSurface>());
      expect(layout().supportingSide, PaneSide.trailing);
      final middle = tester.getCenter(layoutFinder).dx;
      expect(related().center.dx, greaterThan(middle));
      Finder close() =>
          find.descendant(of: layoutFinder, matching: find.byTooltip('Close'));
      expect(close(), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          related: RelatedPlacement.leadingPane,
          relatedDismissible: false,
          articlesRememberResize: true,
        ),
      );
      expect(layout().supportingSide, PaneSide.leading);
      expect(related().center.dx, lessThan(middle));
      expect(layout().onSupportingDismissed, isNull);
      expect(close(), findsNothing);
      expect(layout().resizeMemory, PaneResizeMemory.persistent);
    });

    testWidgets('related articles that cannot be closed always show, with '
        'no close button and no handle, as a side sheet too', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await visit(tester, 'Articles');
      final articles = find.byType(ArticlesScreen);
      SupportingPaneLayout layout() => tester.widget(
        find.descendant(
          of: articles,
          matching: find.byType(SupportingPaneLayout),
        ),
      );
      Finder inArticles(Finder finder) =>
          find.descendant(of: articles, matching: finder);
      expect(layout().supporting, isA<SideSheet>());
      expect(layout().onSupportingDismissed, isNotNull);
      expect(inArticles(find.byTooltip('Close')), findsOneWidget);
      expect(inArticles(find.byType(PaneResizer)), findsOneWidget);

      // Closed first, the related articles come back once they are
      // permanent.
      await tester.tap(inArticles(find.byTooltip('Close related')));
      await settle(tester);
      expect(layout().supporting, isNull);
      await apply(
        tester,
        settings,
        (s) => s.copyWith(relatedDismissible: false),
      );
      expect(layout().supporting, isA<SideSheet>());
      expect(layout().onSupportingDismissed, isNull);
      expect(layout().resizable, isTrue);
      expect(inArticles(find.byTooltip('Close')), findsNothing);
      expect(inArticles(find.byTooltip('Open related')), findsNothing);
      expect(inArticles(find.byTooltip('Close related')), findsNothing);
      expect(inArticles(find.byType(PaneResizer)), findsNothing);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(related: RelatedPlacement.trailingPane),
      );
      expect(layout().supporting, isA<PaneSurface>());
      expect(inArticles(find.byTooltip('Close')), findsNothing);
      expect(inArticles(find.byType(PaneResizer)), findsNothing);
    });

    testWidgets('the related articles resize with a handle unless the '
        'articles say otherwise, as long as panes resize at all', (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await visit(tester, 'Articles');
      final articles = find.byType(ArticlesScreen);
      SupportingPaneLayout layout() => tester.widget(
        find.descendant(
          of: articles,
          matching: find.byType(SupportingPaneLayout),
        ),
      );
      Finder handle() =>
          find.descendant(of: articles, matching: find.byType(PaneResizer));
      expect(layout().resizable, isTrue);
      expect(handle(), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(articlesResizable: false),
      );
      expect(layout().resizable, isFalse);
      expect(handle(), findsNothing);
      // The related articles can still be closed, from their close button.
      expect(layout().onSupportingDismissed, isNotNull);
      expect(
        find.descendant(of: articles, matching: find.byTooltip('Close')),
        findsOneWidget,
      );

      // The switch for all panes wins.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(articlesResizable: true, resizable: false),
      );
      expect(layout().resizable, isFalse);
      expect(handle(), findsNothing);

      // In the settings, the switch follows the one for all panes.
      await apply(tester, settings, (s) => s.copyWith(resizable: true));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Articles'));
      final resizable = find.widgetWithText(SwitchListTile, 'Resizable');
      await tapSetting(tester, resizable);
      expect(settings.value.articlesResizable, isFalse);
      await apply(tester, settings, (s) => s.copyWith(resizable: false));
      expect(tester.widget<SwitchListTile>(resizable).onChanged, isNull);
    });

    testWidgets('the settings offer to dismiss the message with the handle '
        'only where the list then shows alone, and let a side sheet be '
        'permanent', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await openSettings(tester);
      await tapSetting(tester, inPanel('Inbox'));
      Finder chip(String label) => find.descendant(
        of: setting('The handle hides the message'),
        matching: find.widgetWithText(ChoiceChip, label),
      );
      expect(chip('Collapse'), findsOneWidget);
      expect(chip('Dismiss'), findsNothing);
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'List alone'));
      await tapSetting(tester, chip('Dismiss'));
      expect(settings.value.messageCollapse, PaneCollapse.dismiss);
      await tapSetting(tester, find.widgetWithText(ChoiceChip, 'Placeholder'));
      expect(settings.value.messageCollapse, isNull);
      expect(chip('Dismiss'), findsNothing);

      await tapSetting(tester, inPanel('Articles'));
      final closable = find.widgetWithText(
        SwitchListTile,
        'Related articles can be closed',
      );
      expect(settings.value.related, RelatedPlacement.sheet);
      expect(tester.widget<SwitchListTile>(closable).onChanged, isNotNull);
      await tapSetting(tester, closable);
      expect(settings.value.relatedDismissible, isFalse);
    });

    testWidgets("the layout screen's two panes", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await visit(tester, 'Layout');
      TwoPaneLayout layout() => tester.widget(find.byType(TwoPaneLayout));
      Rect pane(String title) => tester.getRect(
        find.ancestor(
          of: find.descendant(
            of: find.byType(PaneHeader),
            matching: find.text(title),
          ),
          matching: find.byType(PaneSurface),
        ),
      );
      expect(layout().arrangement, const PaneArrangement.fixedAndFlexible());
      // Beside the expanded rail, the body is expanded, not large.
      expect(pane('Layout').width, 360);
      expect(find.text('Second pane'), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          layoutArrangement: LayoutArrangement.fixedSecond,
          layoutPaneWidth: 300,
          layoutTwoPanesFrom: Breakpoint.extraLarge,
          layoutReflow: PaneReflow.second,
          layoutFirstCollapse: PaneCollapse.never,
          layoutSecondCollapse: PaneCollapse.collapse,
        ),
      );
      expect(
        layout().arrangement,
        const PaneArrangement.fixedAndFlexible(
          fixed: PaneSlot.second,
          width: 300,
        ),
      );
      expect(layout().twoPaneBreakpoint, Breakpoint.extraLarge);
      expect(layout().reflow, PaneReflow.second);
      expect(layout().firstCollapse, PaneCollapse.never);
      expect(layout().secondCollapse, PaneCollapse.collapse);
      // Below extra-large, only the second pane shows.
      expect(find.text('Second pane'), findsOneWidget);
      expect(find.text('Window'), findsNothing);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          layoutTwoPanesFrom: Breakpoint.expanded,
          layoutSecondClosable: true,
        ),
      );
      expect(pane('Second pane').width, 300);
      await tester.tap(
        find.descendant(
          of: find.byType(TwoPaneLayout),
          matching: find.byTooltip('Close'),
        ),
      );
      await settle(tester);
      expect(find.text('Second pane'), findsNothing);
      expect(layout().second, isNull);
      await tester.tap(find.byTooltip('Open pane'));
      await settle(tester);
      expect(find.text('Second pane'), findsOneWidget);
    });

    testWidgets("the feed's card width, gap and spans", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await visit(tester, 'Feed');
      FeedLayout feed() => tester.widget(find.byType(FeedLayout));
      expect(feed().spanBuilder, isNotNull);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          feedMinItemWidth: 400,
          feedGap: 0,
          feedLeadSpansTwo: false,
        ),
      );
      expect(feed().minItemWidth, 400);
      expect(feed().gap, 0);
      expect(feed().spanBuilder, isNull);
    });

    testWidgets('the panes navigation is placed for', (tester) async {
      // At medium, the inbox shows one pane, which a rail goes beside.
      final settings = await pumpDemo(tester, const Size(700, 900));
      expect(find.byType(NavigationRail), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(navigationPanes: NavigationPanes.two),
      );
      expect(
        tester
            .widget<NavigationScaffold>(find.byType(NavigationScaffold))
            .paneCount,
        2,
      );
      expect(find.byType(NavigationBar), findsOneWidget);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(navigationPanes: NavigationPanes.one),
      );
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets("where navigation shows: Material's placement, one component "
        'alone, or either side of a breakpoint', (tester) async {
      final settings = await pumpDemo(tester, const Size(400, 900));
      NavigationScaffold scaffold() =>
          tester.widget(find.byType(NavigationScaffold));
      // The placement at each breakpoint in turn.
      Future<List<NavigationPlacement>> across() async {
        final placements = <NavigationPlacement>[];
        for (final width in [400.0, 700.0, 1000.0, 1300.0, 1700.0]) {
          setWindowSize(tester, Size(width, 900));
          await settle(tester);
          placements.add(NavigationScaffold.placementOf(inboxContext(tester)));
        }
        return placements;
      }

      const bar = NavigationPlacement.bar;
      const rail = NavigationPlacement.rail;

      expect(scaffold().placementRule, NavigationPlacementRule.material);
      expect(await across(), [bar, rail, rail, rail, rail]);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(navigationRule: NavigationRule.barOnly),
      );
      expect(
        scaffold().placementRule,
        const NavigationPlacementRule.only(NavigationPlacement.bar),
      );
      expect(await across(), [bar, bar, bar, bar, bar]);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(navigationRule: NavigationRule.railOnly),
      );
      expect(await across(), [rail, rail, rail, rail, rail]);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          navigationRule: NavigationRule.railFrom,
          navigationRuleFrom: Breakpoint.large,
        ),
      );
      expect(await across(), [bar, bar, bar, rail, rail]);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          navigationRule: NavigationRule.barFrom,
          navigationRuleFrom: Breakpoint.expanded,
        ),
      );
      expect(await across(), [rail, rail, bar, bar, bar]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the inbox at the panes that fit beside an arriving '
        'rail', (tester) async {
      final settings = await pumpDemo(tester, const Size(830, 900));
      // The rail from expanded, where the inbox shows two panes too.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(navigationRule: NavigationRule.railFrom),
      );
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      DetailPlacement placement() =>
          tester.widget<MessageDetail>(find.byType(MessageDetail)).placement;
      expect(placement(), DetailPlacement.page);

      // Wide enough for two panes in the inbox's card until the rail is in,
      // and too narrow once it is.
      setWindowSize(tester, const Size(920, 900));
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(placement(), DetailPlacement.page, reason: 'frame $frame');
      }
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets("the side sheets' width, and the scrim of modal sheets", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(tester, settings, (s) => s.copyWith(sideSheetWidth: 320));
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      await tester.tap(find.byTooltip('Open details'));
      await settle(tester);
      expect(tester.getSize(find.byType(SideSheet)).width, 320);
      // The message is a page beside the details; closing them brings the
      // list, and its settings button, back.
      await tester.tap(find.byTooltip('Close details'));
      await settle(tester);

      // A tap on the scrim closes a modal sheet, unless told otherwise.
      await openSettings(tester);
      await tester.tapAt(const Offset(200, 450));
      await settle(tester);
      expect(find.byType(SettingsPanel), findsNothing);
      await apply(tester, settings, (s) => s.copyWith(scrimDismisses: false));
      await openSettings(tester);
      await tester.tapAt(const Offset(200, 450));
      await settle(tester);
      expect(find.byType(SettingsPanel), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await settle(tester);
      expect(find.byType(SettingsPanel), findsNothing);

      await apply(tester, settings, (s) => s.copyWith(scrimOpacity: 0.3));
      await visit(tester, 'Layout');
      await tester.tap(find.text('Modal side sheet'));
      await settle(tester);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox &&
              widget.color == Colors.black.withValues(alpha: 0.3),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(SideSheet).last).width, 320);
    });

    testWidgets('tinted side sheets', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      final colors = Theme.of(inboxContext(tester)).colorScheme;
      await apply(tester, settings, (s) => s.copyWith(tintedSheets: true));
      final style = MaterialLayoutTheme.of(inboxContext(tester)).sideSheetStyle;
      expect(style.backgroundColor, colors.surfaceContainerHigh);
      expect(style.modalBackgroundColor, colors.surfaceContainerHighest);
      await openSettings(tester);
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(SideSheet),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color,
        colors.surfaceContainerHighest,
      );
    });

    testWidgets('the line length of the text', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(tester, settings, (s) => s.copyWith(lineLength: 45));
      await visit(tester, 'Articles');
      final lengths = tester
          .widgetList<LineLength>(
            find.descendant(
              of: find.byType(ArticlesScreen),
              matching: find.byType(LineLength),
            ),
          )
          .map((lineLength) => lineLength.characters);
      expect(lengths, isNotEmpty);
      expect(lengths, everyElement(45));
    });
  });

  group('Every navigation setting reaches the rail and the bar:', () {
    NavigationRail rail(WidgetTester tester) =>
        tester.widget(find.byType(NavigationRail));
    NavigationBar bar(WidgetTester tester) =>
        tester.widget(find.byType(NavigationBar));
    // Whether the rail is expanded in place, and whether it is open as a
    // modal, which its controller knows.
    bool expanded(WidgetTester tester) => rail(tester).expanded;
    bool modalOpen(WidgetTester tester) => NavigationRail.of(
      tester.element(find.byType(NavigationMenuButton).first),
    ).isModalOpen;
    Future<void> menu(WidgetTester tester) async {
      await tester.tap(find.byType(NavigationMenuButton).hitTestable().first);
      await settle(tester);
    }

    Destination shownDestination(WidgetTester tester) =>
        tester.widget<ExtraScreen>(find.byType(ExtraScreen)).destination;
    // A value half way along a token's slider.
    double halfway(StyleToken token) =>
        token.min +
        ((token.max - token.min) / token.step / 2).round() * token.step;

    for (final size in const [Size(1300, 900), Size(400, 800)]) {
      testWidgets('the text scale, which the settings keep clear of '
          '(${size.width.round()}dp)', (tester) async {
        final settings = await pumpDemo(tester, size);
        double scaleOf(Finder finder) =>
            MediaQuery.textScalerOf(tester.element(finder.first)).scale(1);
        final navigation = find.byWidgetPredicate(
          (widget) => widget is NavigationRail || widget is NavigationBar,
        );
        await apply(tester, settings, (s) => s.copyWith(textScale: 2));
        expect(scaleOf(find.byType(ListDetailLayout<int>)), 2);
        expect(scaleOf(navigation), 2);

        await openSettings(tester);
        expect(scaleOf(find.byType(SettingsPanel)), 1);
        expect(scaleOf(find.text('Demo settings')), 1);
        expect(scaleOf(find.text('Reset all settings')), 1);

        // By default, the platform's, which the slider's button puts back.
        await tapSetting(tester, inPanel('App'));
        expect(
          find.descendant(
            of: setting('Text scale'),
            matching: find.text('2.00'),
          ),
          findsOneWidget,
        );
        await tapSetting(
          tester,
          find.descendant(
            of: setting('Text scale'),
            matching: find.byTooltip('Back to default'),
          ),
        );
        expect(settings.value.textScale, isNull);
        expect(
          find.descendant(
            of: setting('Text scale'),
            matching: find.text('1.00 (system)'),
          ),
          findsOneWidget,
        );
        expect(scaleOf(navigation), 1);
      });
    }

    testWidgets("the destinations' labels, tooltips and the disabled one", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      Iterable<NavigationDestination> destinations() =>
          rail(tester).destinations;
      expect(destinations().map((destination) => destination.label), [
        'Inbox',
        'Articles',
        'Feed',
        'Layout',
      ]);
      expect(
        destinations().map((destination) => destination.tooltip),
        everyElement(isNull),
      );

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          navigationLongLabels: true,
          navigationTooltips: true,
          navigationSecondDisabled: true,
        ),
      );
      const long = [
        'Inbox and messages',
        'Articles and reading lists',
        'Feed of the latest articles',
        'Layout of this window',
      ];
      expect(destinations().map((destination) => destination.label), long);
      expect(destinations().map((destination) => destination.tooltip), [
        'Go to Inbox',
        'Go to Articles',
        'Go to Feed',
        'Go to Layout',
      ]);
      expect(destinations().map((destination) => destination.enabled), [
        true,
        false,
        true,
        true,
      ]);

      // A disabled destination cannot be chosen.
      await visit(tester, 'Articles and reading lists');
      expect(rail(tester).selectedIndex, 0);

      // The tooltips show where the labels do not. A destination builds its
      // tooltip whatever its label does, and leaves the tooltip out of the
      // semantics, where the destination names itself.
      bool tooltipShows(String message) => tester
          .widget<TooltipVisibility>(
            find
                .ancestor(
                  of: find.byWidgetPredicate(
                    (widget) => widget is Tooltip && widget.message == message,
                    skipOffstage: false,
                  ),
                  matching: find.byType(TooltipVisibility, skipOffstage: false),
                )
                .first,
          )
          .visible;
      expect(tooltipShows('Go to Feed'), isFalse);
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railExpansion: RailExpansion.collapsed,
          railLabelType: NavigationRailLabelType.none,
        ),
      );
      expect(tooltipShows('Go to Feed'), isTrue);

      // The bar carries the same destinations.
      setWindowSize(tester, const Size(400, 800));
      await settle(tester);
      expect(
        bar(tester).destinations.map((destination) => destination.label),
        long,
      );
      expect(bar(tester).destinations[1].enabled, isFalse);
    });

    testWidgets('how many destinations each carries, placeholders past the '
        "demo's own", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(tester, settings, (s) => s.copyWith(railCount: 7));
      expect(
        rail(tester).destinations.map((destination) => destination.label),
        [
          for (final destination in Destination.values.take(7))
            destination.label,
        ],
      );
      await visit(tester, 'Saved');
      expect(shownDestination(tester), Destination.saved);
      expect(rail(tester).selectedIndex, Destination.saved.index);

      // Past its destinations, a rail marks none.
      await apply(tester, settings, (s) => s.copyWith(railCount: 3));
      expect(rail(tester).selectedIndex, isNull);
      await apply(tester, settings, (s) => s.copyWith(railCount: 0));
      expect(rail(tester).destinations, isEmpty);

      // Past its destinations, a bar marks none too, as screen readers hear.
      final semantics = tester.ensureSemantics();
      Iterable<String> markedInBar() {
        final destinations = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(NavigationDestination),
        );
        return [
          for (var i = 0; i < destinations.evaluate().length; i++)
            if (tester
                    .getSemantics(destinations.at(i))
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue)
              tester.widget<NavigationDestination>(destinations.at(i)).label,
        ];
      }

      setWindowSize(tester, const Size(400, 800));
      await apply(tester, settings, (s) => s.copyWith(barCount: 6));
      expect(markedInBar(), ['Saved']);
      await apply(tester, settings, (s) => s.copyWith(barCount: 3));
      expect(bar(tester).selectedIndex, Destination.saved.index);
      expect(markedInBar(), isEmpty);
      await apply(tester, settings, (s) => s.copyWith(barCount: 0));
      expect(bar(tester).destinations, isEmpty);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(barCount: Destination.values.length),
      );
      await visit(tester, 'About');
      expect(shownDestination(tester), Destination.about);
      expect(bar(tester).selectedIndex, Destination.about.index);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('how the rail expands: by window, as set, and as its menu '
        'button leaves it', (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      // By window, expanded from large up.
      expect(expanded(tester), isTrue);
      await menu(tester);
      expect(expanded(tester), isFalse);
      expect(settings.value.railExpansion, RailExpansion.byWindow);

      // Setting it expanded expands it, however the menu button left it.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(railExpansion: RailExpansion.expanded),
      );
      expect(expanded(tester), isTrue);

      // Set, it follows the menu button, so that setting it again applies.
      await menu(tester);
      expect(expanded(tester), isFalse);
      expect(settings.value.railExpansion, RailExpansion.collapsed);
      await apply(
        tester,
        settings,
        (s) => s.copyWith(railExpansion: RailExpansion.expanded),
      );
      expect(expanded(tester), isTrue);

      // By window, collapsed below large.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(railExpansion: RailExpansion.byWindow),
      );
      expect(expanded(tester), isTrue);
      setWindowSize(tester, const Size(1000, 900));
      await settle(tester);
      expect(expanded(tester), isFalse);
    });

    testWidgets('expanded, however the rail was last opened, expands it in '
        'place', (tester) async {
      final settings = await pumpDemo(tester, const Size(1000, 900));
      double railWidth() => tester.getSize(find.byType(NavigationRail)).width;
      // Below large, the menu button opens a modal, which choosing a
      // destination closes.
      await menu(tester);
      expect(modalOpen(tester), isTrue);
      await tester.tap(find.text('Feed').hitTestable().first);
      await settle(tester);
      expect(modalOpen(tester), isFalse);
      expect(expanded(tester), isFalse);

      // By window, a large window expands the rail in place.
      setWindowSize(tester, const Size(1300, 900));
      await settle(tester);
      expect(expanded(tester), isTrue);
      expect(modalOpen(tester), isFalse);
      expect(railWidth(), greaterThan(96));

      // Set expanded, likewise.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railMenu: RailMenu.modal,
          railExpansion: RailExpansion.collapsed,
        ),
      );
      await menu(tester);
      expect(modalOpen(tester), isTrue);
      await tester.tap(find.text('Articles').hitTestable().first);
      await settle(tester);
      expect(settings.value.railExpansion, RailExpansion.collapsed);
      await apply(
        tester,
        settings,
        (s) => s.copyWith(railExpansion: RailExpansion.expanded),
      );
      expect(expanded(tester), isTrue);
      expect(modalOpen(tester), isFalse);
      expect(railWidth(), greaterThan(96));
    });

    testWidgets("the rail's menu button expands it in place or as a modal", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railMenu: RailMenu.modal,
          railExpansion: RailExpansion.collapsed,
        ),
      );
      await menu(tester);
      expect(modalOpen(tester), isTrue);
      expect(expanded(tester), isFalse);

      // Choosing a destination closes the modal.
      await tester.tap(find.text('Feed').hitTestable().first);
      await settle(tester);
      expect(modalOpen(tester), isFalse);
      expect(rail(tester).selectedIndex, Destination.feed.index);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(railMenu: RailMenu.inPlace),
      );
      await menu(tester);
      expect(expanded(tester), isTrue);
      expect(modalOpen(tester), isFalse);
      await menu(tester);
      expect(expanded(tester), isFalse);

      // By window: in place from large up, and a modal below large.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(railMenu: RailMenu.byWindow),
      );
      await menu(tester);
      expect(expanded(tester), isTrue);
      expect(modalOpen(tester), isFalse);
      await menu(tester);
      setWindowSize(tester, const Size(1000, 900));
      await settle(tester);
      await menu(tester);
      expect(modalOpen(tester), isTrue);
      expect(expanded(tester), isFalse);
    });

    testWidgets("the rail's labels, indicator and slots", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railLabelType: NavigationRailLabelType.selected,
          railIndicatorSize: NavigationIndicatorSize.fill,
          railScrollable: false,
        ),
      );
      expect(rail(tester).labelType, NavigationRailLabelType.selected);
      expect(
        rail(tester).style!.expandedIndicatorSize,
        NavigationIndicatorSize.fill,
      );
      expect(rail(tester).style!.scrollable, isFalse);

      expect(rail(tester).floatingActionButton, isNotNull);
      await apply(tester, settings, (s) => s.copyWith(railFab: false));
      expect(rail(tester).floatingActionButton, isNull);

      // A theme switch below the destinations.
      Finder inRail(String text) => find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(text),
      );
      Finder iconInRail(IconData icon) => find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byIcon(icon),
      );
      await apply(tester, settings, (s) => s.copyWith(railTrailing: true));
      await tester.tap(iconInRail(Icons.dark_mode_outlined));
      await settle(tester);
      expect(settings.value.dark, isTrue);
      expect(iconInRail(Icons.light_mode_outlined), findsOneWidget);

      // Mailboxes and labels, while the rail is expanded, and scrolls.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railExpandedBody: true,
          railExpansion: RailExpansion.expanded,
          railScrollable: true,
        ),
      );
      await tester.tap(inRail('Starred'));
      await settle(tester);
      expect(find.textContaining('Starred is a placeholder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("every token of the rail's style", (tester) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      for (final token in RailToken.values) {
        final value = halfway(token);
        await apply(
          tester,
          settings,
          (s) => s.copyWith(railTokens: {token: value}),
        );
        expect(
          token.read(rail(tester).style!),
          moreOrLessEquals(value),
          reason: token.name,
        );
      }
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          railExpansion: RailExpansion.collapsed,
          railTokens: {RailToken.minWidth: 120},
        ),
      );
      expect(tester.getSize(find.byType(NavigationRail)).width, 120);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the rail's extreme sizes, down to no collapsed rail at all", (
      tester,
    ) async {
      final settings = await pumpDemo(tester, const Size(1300, 900));
      Future<void> tokens(Map<RailToken, double> tokens) => apply(
        tester,
        settings,
        (s) => s.copyWith(
          railExpansion: RailExpansion.collapsed,
          railTokens: tokens,
        ),
      );
      double railWidth() => tester.getSize(find.byType(NavigationRail)).width;
      await tokens({
        RailToken.minWidth: 40,
        RailToken.verticalIndicatorWidth: 160,
      });
      expect(railWidth(), 40);
      expect(tester.takeException(), isNull);
      // At 0, the collapsed rail takes no room.
      await tokens({RailToken.minWidth: 0});
      expect(railWidth(), 0);
      expect(tester.takeException(), isNull);

      // Their sliders cover their whole ranges.
      await openSettings(tester);
      await tapSetting(tester, inPanel('Rail style'));
      expect(sliderOf(tester, 'verticalIndicatorWidth').max, 160);
      expect(sliderOf(tester, 'minWidth').min, 0);
    });

    testWidgets("the labels' lines and overflow, and the bar's cap on their "
        'scale', (tester) async {
      final settings = await pumpDemo(tester, const Size(400, 800));
      double barHeight() => tester.getSize(find.byType(NavigationBar)).height;
      await apply(
        tester,
        settings,
        (s) =>
            s.copyWith(navigationLongLabels: true, barCount: 5, textScale: 2),
      );
      final wrapped = barHeight();
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          barLabelMaxLines: 1,
          barLabelOverflow: TextOverflow.ellipsis,
        ),
      );
      expect(bar(tester).style!.labelMaxLines, 1);
      expect(bar(tester).style!.labelOverflow, TextOverflow.ellipsis);
      expect(barHeight(), lessThan(wrapped));

      // Capped, the labels scale less, and the bar grows less with them.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          barLabelMaxLines: null,
          barLabelOverflow: null,
          textScale: 3.2,
        ),
      );
      final uncapped = barHeight();
      await apply(
        tester,
        settings,
        (s) => s.copyWith(barTokens: {BarToken.maxLabelScale: 1.3}),
      );
      expect(bar(tester).style!.maxLabelScale, 1.3);
      expect(barHeight(), lessThan(uncapped));

      setWindowSize(tester, const Size(1300, 900));
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          textScale: null,
          railLabelMaxLines: 3,
          railLabelOverflow: TextOverflow.fade,
        ),
      );
      expect(rail(tester).style!.labelMaxLines, 3);
      expect(rail(tester).style!.labelOverflow, TextOverflow.fade);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the rail's bottom inset, which keeps its content clear of a "
        'gesture bar', (tester) async {
      tester.view
        ..padding = const FakeViewPadding(bottom: 40)
        ..viewPadding = const FakeViewPadding(bottom: 40);
      final settings = await pumpDemo(tester, const Size(1300, 900));
      await apply(tester, settings, (s) => s.copyWith(railTrailing: true));
      double switchBottom() => tester
          .getRect(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.byIcon(Icons.dark_mode_outlined),
            ),
          )
          .bottom;
      final inset = switchBottom();
      expect(inset, lessThanOrEqualTo(900 - 40));
      await apply(tester, settings, (s) => s.copyWith(railBottomInset: false));
      expect(rail(tester).style!.applyBottomInset, isFalse);
      expect(switchBottom(), greaterThan(inset));
    });

    testWidgets("the bar's width, layout and labels", (tester) async {
      final settings = await pumpDemo(tester, const Size(400, 800));
      // By window, labels below the icons in a compact window.
      expect(bar(tester).itemLayout, NavigationBarItemLayout.vertical);

      await apply(tester, settings, (s) => s.copyWith(barWidthFactor: 0.5));
      expect(tester.getSize(find.byType(NavigationBar)).width, 200);
      expect(tester.getCenter(find.byType(NavigationBar)).dx, 200);

      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          barLayout: BarLayout.horizontal,
          barLabelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
      );
      expect(bar(tester).itemLayout, NavigationBarItemLayout.horizontal);
      expect(
        bar(tester).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );

      // By window, labels beside the icons from medium up.
      await apply(
        tester,
        settings,
        (s) => s.copyWith(
          barLayout: BarLayout.byWindow,
          navigationPanes: NavigationPanes.two,
        ),
      );
      setWindowSize(tester, const Size(700, 900));
      await settle(tester);
      expect(bar(tester).itemLayout, NavigationBarItemLayout.horizontal);
    });

    testWidgets("every token of the bar's style", (tester) async {
      final settings = await pumpDemo(tester, const Size(400, 800));
      for (final token in BarToken.values) {
        final value = halfway(token);
        await apply(
          tester,
          settings,
          (s) => s.copyWith(barTokens: {token: value}),
        );
        expect(
          token.read(bar(tester).style!),
          moreOrLessEquals(value),
          reason: token.name,
        );
      }
      await apply(
        tester,
        settings,
        (s) => s.copyWith(barTokens: {BarToken.height: 100}),
      );
      expect(tester.getSize(find.byType(NavigationBar)).height, 100);
      expect(tester.takeException(), isNull);
    });
  });
}
