import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationRail, NavigationDestination;
import 'package:flutter_test/flutter_test.dart';

import 'package:demo/data/demo_data.dart';
import 'package:demo/data/demo_settings.dart';
import 'package:demo/main_navigator.dart';
import 'package:demo/main_router.dart';
import 'package:demo/screens/feed_screen.dart';
import 'package:demo/screens/inbox/filters_sheet.dart';
import 'package:demo/screens/inbox/inbox_screen.dart';
import 'package:demo/screens/inbox/info_pane.dart';
import 'package:demo/shell/animated_fab.dart';
import 'package:demo/shell/animated_menu_button.dart';
import 'package:demo/shell/demo_shell.dart';
import 'package:demo/shell/settings_sheet.dart';

void main() {
  _threePaneTests();
  _settingsSheetTests();
  _hamburgerTests();
  _drawerParityTests();
  _railSectionsTests();
  _parityTests();
  _dismissibleFiltersTests();

  /// Pumps the demo at a given logical window size.
  ///
  /// The pane reveal is spring-driven and settles asymptotically, so
  /// `pumpAndSettle` can spin. Pump a fixed budget instead.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('AdaptiveNavigationScaffold', () {
    testWidgets('shows the bottom bar and hides the rail at compact width',
        (tester) async {
      await pumpAt(tester, const Size(400, 800));

      expect(tester.getSize(find.byKey(navigationBarRevealKey)).height,
          greaterThan(0),
          reason: 'the bottom bar carries navigation on a phone-width window');
      expect(tester.getSize(find.byKey(navigationRailRevealKey)).width, 0,
          reason: 'the rail collapses to zero width below the breakpoint');
    });

    testWidgets('shows the rail and collapses the bar at expanded width',
        (tester) async {
      await pumpAt(tester, const Size(1400, 900));

      expect(
          tester.getSize(find.byKey(navigationRailRevealKey)).width,
          greaterThan(0),
          reason: 'expanded and wider windows carry navigation in the rail');
      expect(tester.getSize(find.byKey(navigationBarRevealKey)).height, 0,
          reason: 'the bottom bar collapses to zero height above the breakpoint');
    });
  });

  group('ListDetailLayout', () {
    testWidgets('compact shows only the list until an item is selected',
        (tester) async {
      await pumpAt(tester, const Size(400, 800));

      final first = demoItems.first;
      expect(find.text(first.sender), findsOneWidget);
      // Nothing selected yet, so the message body is not on screen.
      expect(find.text(first.body), findsNothing);

      await tester.tap(find.text(first.sender));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The detail was pushed as a page over the list.
      expect(find.text(first.body), findsOneWidget);
    });

    testWidgets('wide shows list and detail side by side after selection',
        (tester) async {
      await pumpAt(tester, const Size(1400, 900));

      final first = demoItems.first;
      await tester.tap(find.text(first.sender));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Both panes are on screen at once: the list still lists the sender,
      // and the detail shows the body.
      expect(find.text(first.sender), findsWidgets);
      expect(find.text(first.body), findsOneWidget);
    });
  });
}

void _threePaneTests() {
  group('Mail is a three-pane layout at extra-large', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    testWidgets('filters sit beside list and detail at 1700dp',
        (tester) async {
      await pumpAt(tester, const Size(1700, 1000));

      // Select a message so all three panes have content.
      await tester.tap(find.text(demoItems.first.sender).first);
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(find.byType(InfoPane), findsOneWidget,
          reason: 'the third pane is inline at extra-large');

      final filters = tester.getRect(find.byType(InfoPane));
      final detail = tester.getRect(find.text(demoItems.first.body));
      expect(filters.left, greaterThan(detail.left),
          reason: 'filters are the trailing pane, after the detail');
      expect(filters.width, closeTo(400, 1),
          reason: 'a side sheet as third pane caps at 400dp, not 412dp');
    });

    testWidgets('below extra-large the filters are not a pane',
        (tester) async {
      await pumpAt(tester, const Size(1300, 900));

      expect(find.byType(InfoPane), findsNothing,
          reason: 'M3 reserves three panes for extra-large');
      expect(find.byTooltip('Filters'), findsOneWidget,
          reason: 'filters still live in the search bar');
    });

    testWidgets('the filters button opens a standard sheet', (tester) async {
      await pumpAt(tester, const Size(1300, 900));

      await tester.tap(find.byTooltip('Filters'));
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(find.byType(FiltersSheet), findsOneWidget);
    });
  });
}

/// A fingerprint of the rendered chrome, so the two entrypoints can be
/// compared rather than eyeballed.
Future<Map<String, Object>> _chrome(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  return <String, Object>{
    'shell': find.byType(DemoShell).evaluate().length,
    'destinations': [
      for (final d in demoDestinations)
        if (find.text(d.label).evaluate().isNotEmpty) d.label,
    ].join(','),
    'fab': find.byType(AnimatedFab).evaluate().length,
    'menuButton': find.byType(AnimatedMenuButton).evaluate().length,
    'railWidth':
        tester.getSize(find.byKey(navigationRailRevealKey)).width.round(),
    'barHeight':
        tester.getSize(find.byKey(navigationBarRevealKey)).height.round(),
  };
}

void _parityTests() {
  group('both entrypoints render the same app', () {
    for (final size in const [
      Size(420, 900), // compact
      Size(700, 900), // medium
      Size(1300, 900), // large
    ]) {
      testWidgets('identical chrome at ${size.width.toInt()}dp',
          (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);

        final navigator =
            await _chrome(tester, const AdaptiveLayoutsDemoApp());
        final router =
            await _chrome(tester, const AdaptiveLayoutsRouterDemoApp());

        expect(router, navigator,
            reason: 'the two entrypoints must differ only in push/pop '
                'strategy — the chrome they render should be identical');
        expect(navigator['shell'], 1,
            reason: 'both go through the shared DemoShell');
      });
    }
  });
}

void _dismissibleFiltersTests() {
  group('Inbox info pane honours the dismissible setting', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    Future<void> pump(WidgetTester tester, Size size,
        {required bool dismissible}) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: DemoSettingsScope(
          settings: DemoSettings(supportingDismissible: dismissible),
          onChanged: (_) {},
          child: Scaffold(
            body: InboxScreen(
              resizable: false,
              behavior: ListDetailBehavior.placeholder,
              dismissible: dismissible,
            ),
          ),
        ),
      ));
      await settle(tester);
    }

    // The info action lives in the detail's app bar, so a message has to be
    // open before it exists.
    Future<void> openFirstMessage(WidgetTester tester) async {
      await tester.tap(find.text(demoItems.first.sender).first);
      await settle(tester);
    }

    testWidgets('permanent: the pane is up and the action is left out',
        (tester) async {
      await pump(tester, const Size(1700, 1000), dismissible: false);
      expect(find.byType(InfoPane), findsOneWidget);

      await openFirstMessage(tester);
      expect(find.byTooltip('Message details'), findsNothing,
          reason: 'a permanent pane cannot be toggled, so the action would '
              'be dead');
    });

    testWidgets('dismissible: starts hidden and the action brings it back',
        (tester) async {
      await pump(tester, const Size(1700, 1000), dismissible: true);
      expect(find.byType(InfoPane), findsNothing,
          reason: 'a dismissible pane starts hidden');

      await openFirstMessage(tester);
      expect(find.byTooltip('Message details'), findsOneWidget);

      await tester.tap(find.byTooltip('Message details'));
      await settle(tester);
      expect(find.byType(InfoPane), findsOneWidget);
    });

    testWidgets('below extra-large the action opens it as a sheet',
        (tester) async {
      await pump(tester, const Size(1300, 900), dismissible: false);
      expect(find.byType(InfoPane), findsNothing,
          reason: 'M3 reserves three panes for extra-large');

      await openFirstMessage(tester);
      await tester.tap(find.byTooltip('Message details'));
      await settle(tester);
      expect(find.byType(InfoPane), findsOneWidget);
    });

    testWidgets('filters are always reachable, independent of that setting',
        (tester) async {
      for (final d in [false, true]) {
        await pump(tester, const Size(1300, 900), dismissible: d);
        expect(find.byTooltip('Filters'), findsOneWidget,
            reason: 'filters are a sheet now, not the supporting pane');
      }
    });
  });
}

void _railSectionsTests() {
  group('expanded rail reveals secondary navigation', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    testWidgets('sections and destinations render once expanded',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      await settle(tester);

      // Collapsed: the secondary navigation is not on screen yet.
      expect(find.text('Mailboxes'), findsNothing);

      final menu = find.descendant(
        of: find.byKey(navigationRailRevealKey),
        matching: find.byIcon(Icons.menu),
      );
      expect(menu, findsOneWidget);
      await tester.tap(menu, warnIfMissed: false);
      await settle(tester);

      expect(tester.takeException(), isNull,
          reason: 'expandedBody is built inside the rail, so anything reading '
              'NavigationRail.of(context) there must resolve');
      // findsWidgets, not findsOneWidget: a morphing destination keeps both
      // its layouts in the tree — label beside the icon and label below it —
      // and cross-fades between them, so each label is present twice.
      for (final label in [
        'Sent',
        'Trash',
        'Spam',
        'Receipts',
        'Travel',
      ]) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      for (final header in ['Mailboxes', 'Folders']) {
        expect(find.text(header), findsOneWidget,
            reason: 'section headers are plain text, rendered once');
      }
    });

    testWidgets('unread counts ride on the icons as badges', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(navigationRailRevealKey),
          matching: find.byIcon(Icons.menu),
        ),
        warnIfMissed: false,
      );
      await settle(tester);

      // The icon is one widget shared by both layouts (only the label is
      // built twice), so three counted destinations means three badges.
      expect(find.byType(Badge), findsNWidgets(3),
          reason: 'Trash 12, Spam 3, Receipts 8 — Sent and Travel have no '
              'count and get a plain icon');
      for (final n in ['12', '3', '8']) {
        expect(find.text(n), findsWidgets, reason: 'missing count $n');
      }
    });
  });
}

void _drawerParityTests() {
  group('drawer carries the same secondary navigation as the rail', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    Future<void> openDrawer(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
    }

    Future<void> pumpCompact(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      await settle(tester);
    }

    Finder inDrawer(Finder matching) => find.descendant(
          of: find.byType(NavigationDrawer),
          matching: matching,
        );

    testWidgets('shows every section and entry from the shared data',
        (tester) async {
      await pumpCompact(tester);
      await openDrawer(tester);

      for (final section in demoSections) {
        expect(inDrawer(find.text(section.title)), findsOneWidget,
            reason: 'missing section ${section.title}');
        for (final item in section.items) {
          expect(inDrawer(find.text(item.label)), findsOneWidget,
              reason: 'missing entry ${item.label}');
        }
      }
      // Same counts, same badges as the rail body.
      expect(inDrawer(find.byType(Badge)), findsNWidgets(3));
    });

    testWidgets('primary destinations still switch', (tester) async {
      await pumpCompact(tester);
      await openDrawer(tester);

      await tester.tap(inDrawer(find.text('Feed')));
      await settle(tester);

      expect(find.byType(FeedScreen), findsOneWidget,
          reason: 'index 0..3 must still reach onDestinationSelected');
    });

    testWidgets('Settings is still reached despite the shifted index',
        (tester) async {
      await pumpCompact(tester);
      await openDrawer(tester);

      await tester.tap(inDrawer(find.text('Settings')));
      await settle(tester);

      expect(find.byType(SettingsSheet), findsOneWidget,
          reason: 'adding 5 section entries moved Settings from index 4 to 9; '
              'the handler must follow');
    });

    testWidgets('section entries switch nothing', (tester) async {
      await pumpCompact(tester);
      await openDrawer(tester);

      await tester.tap(inDrawer(find.text('Trash')));
      await settle(tester);

      expect(find.byType(SettingsSheet), findsNothing);
      expect(find.byType(InboxScreen), findsOneWidget,
          reason: 'still on the Inbox destination');
    });
  });
}

void _hamburgerTests() {
  group('the drawer hamburger tracks the navigation surface', () {
    Future<({double rail, int menus})> probe(
        WidgetTester tester, Size size) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      return (
        rail: tester.getSize(find.byKey(navigationRailRevealKey)).width,
        menus: find.byTooltip('Open navigation').evaluate().length,
      );
    }

    testWidgets('shown at compact, where navigation is a bar', (tester) async {
      final r = await probe(tester, const Size(420, 900));
      expect(r.rail, 0);
      expect(r.menus, 1, reason: 'no rail, so the drawer is the way in');
    });

    testWidgets('hidden at medium, where a single pane already gets a rail',
        (tester) async {
      final r = await probe(tester, const Size(700, 900));
      expect(r.rail, greaterThan(0),
          reason: 'M3 gives a single-pane medium layout a rail');
      expect(r.menus, 0,
          reason: 'a hamburger beside a visible rail is redundant — this is '
              'what keying off isExpandedOrWider got wrong');
    });

    testWidgets('hidden at expanded', (tester) async {
      final r = await probe(tester, const Size(900, 900));
      expect(r.rail, greaterThan(0));
      expect(r.menus, 0);
    });

    testWidgets('shown on a short window, however wide', (tester) async {
      // Compact height falls back to a bar at any width, so the rail is gone
      // and the hamburger has to come back.
      final r = await probe(tester, const Size(1100, 420));
      expect(r.rail, 0);
      expect(r.menus, 1,
          reason: 'width alone cannot answer this — the resolver can');
    });
  });
}

void _settingsSheetTests() {
  group('settings sheet', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    Future<void> openSettings(WidgetTester tester, Brightness system) async {
      tester.platformDispatcher.platformBrightnessTestValue = system;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(420, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AdaptiveLayoutsDemoApp());
      await settle(tester);
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
      await tester.tap(find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Settings'),
      ));
      await settle(tester);
      expect(find.byType(SettingsSheet), findsOneWidget);
    }

    bool switchValue(WidgetTester tester, String title) =>
        tester.widget<SwitchListTile>(find.ancestor(
          of: find.text(title),
          matching: find.byType(SwitchListTile),
        )).value;

    testWidgets('dark switch follows a dark system theme', (tester) async {
      await openSettings(tester, Brightness.dark);

      expect(switchValue(tester, 'Dark theme'), isTrue,
          reason: 'the app is dark because the system is; the switch must say '
              'so even though themeMode is still ThemeMode.system');
      expect(find.textContaining('Following the system'), findsOneWidget);
    });

    testWidgets('dark switch is off on a light system theme', (tester) async {
      await openSettings(tester, Brightness.light);
      expect(switchValue(tester, 'Dark theme'), isFalse);
    });

    testWidgets('is grouped into General, Navigation and Panes',
        (tester) async {
      await openSettings(tester, Brightness.light);

      for (final section in ['General', 'Navigation', 'Panes']) {
        expect(find.text(section), findsOneWidget, reason: 'missing $section');
      }
      expect(find.textContaining('material_navigation'), findsOneWidget,
          reason: 'the Navigation group says where those components come from');
    });

    testWidgets('the modal rail is off by default', (tester) async {
      await openSettings(tester, Brightness.light);
      expect(switchValue(tester, 'Modal rail'), isFalse);
    });
  });
}
