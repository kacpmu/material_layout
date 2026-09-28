// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:demo/app/demo_app.dart';
import 'package:demo/data/articles.dart';
import 'package:demo/main.dart';
import 'package:demo/screens/articles.dart';
import 'package:demo/screens/inbox.dart';
import 'package:demo/widgets/panes.dart';
import 'package:demo/widgets/settings_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

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

/// Chooses what two panes of the inbox show with nothing selected, in the
/// Inbox section of the demo settings.
Future<void> chooseNothingSelected(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Demo settings').first);
  await settle(tester);
  Finder inPanel(String text) => find.descendant(
    of: find.byType(SettingsPanel),
    matching: find.text(text),
  );
  // The sheet opens as it was left, so the section may be open already.
  if (inPanel('With no message selected').evaluate().isEmpty) {
    await tester.tap(inPanel('Inbox'));
    await settle(tester);
  }
  final chip = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(SideSheet),
      matching: find.byTooltip('Close'),
    ),
  );
  await settle(tester);
}

/// The back button in the message's app bar.
Finder messageBack() => find.descendant(
  of: find.byType(MessageDetail),
  matching: find.byType(BackButton),
);

void main() {
  testWidgets('every destination builds at every breakpoint', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
    for (final width in [400.0, 700.0, 1000.0, 1300.0, 1800.0]) {
      setWindowSize(tester, Size(width, 900));
      for (final label in ['Articles', 'Feed', 'Layout', 'Inbox']) {
        await tester.tap(find.text(label).first);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: '$label at $width');
      }
    }
  });

  group('Every screen lays out with large text', () {
    // Lays out each screen, and with [sheets] each sheet, at [scale] times
    // the text size, in each window of [sizes].
    void layOut(double scale, List<Size> sizes, {required bool sheets}) {
      for (final size in sizes) {
        testWidgets('${scale}x in a ${size.width.round()} by '
            '${size.height.round()}dp window', (tester) async {
          setWindowSize(tester, size);
          await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
          await settle(tester);
          Settings.controllerOf(tester.element(find.byType(NavigatorDemo)))
              .value = DemoSettings(
            textScale: scale,
            railCount: 5,
            barCount: 5,
          );
          await settle(tester);

          Future<void> tap(Finder finder) async {
            await tester.ensureVisible(finder.first);
            await tester.pump();
            await tester.tap(finder.first);
            await settle(tester);
            expect(tester.takeException(), isNull, reason: '$finder');
          }

          Future<void> back() async {
            await tester.binding.handlePopRoute();
            await settle(tester);
          }

          await tap(find.text('Ada Okafor'));
          if (sheets) {
            await tap(find.byTooltip('Open details'));
            await back();
            await tap(find.byTooltip('Compose'));
            await back();
          }
          for (final label in ['Articles', 'Feed', 'Layout', 'Explore']) {
            await tap(find.text(label));
          }
          if (sheets) {
            await tap(find.text('Layout'));
            for (final sheet in ['Modal side sheet', 'Adaptive sheet']) {
              await tester.dragUntilVisible(
                find.text(sheet),
                find.byKey(const ValueKey('window report')),
                const Offset(0, -200),
              );
              await tap(find.text(sheet));
              await back();
            }
            await tap(find.byTooltip('Demo settings'));
          }
        });
      }
    }

    // Twice the size, the most Android offers, in every form of each.
    layOut(2, const [
      Size(1300, 900),
      Size(1000, 800),
      Size(700, 900),
      Size(400, 800),
      Size(360, 640),
      Size(640, 360),
    ], sheets: true);
    // The most iOS offers, in the screens themselves.
    layOut(3.2, const [
      Size(1300, 900),
      Size(700, 900),
      Size(360, 640),
    ], sheets: false);
  });

  testWidgets('selecting a message shows it, and navigation follows the '
      'panes', (tester) async {
    setWindowSize(tester, const Size(1300, 900));
    await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
    await settle(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Chen Wei'));
    await settle(tester);
    expect(find.text('Draft of the accessibility notes'), findsOneWidget);

    setWindowSize(tester, const Size(400, 800));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  group('Panes keep the margins where their painting needs them', () {
    Finder surface() => find
        .descendant(
          of: find.byType(PaneSurface),
          matching: find.byType(Material),
        )
        .first;
    Finder header(String title) => find.descendant(
      of: find.byType(PaneHeader),
      matching: find.text(title),
    );

    testWidgets('a compact window shows flat panes that reach the edges, '
        'with content at the margin', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      expect(
        (tester.widget<Material>(surface()).shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.zero,
      );
      expect(tester.getRect(surface()).left, 0);
      expect(tester.getRect(surface()).right, 400);
      expect(tester.getTopLeft(header('Inbox')).dx, 16);
      expect(tester.getTopLeft(find.byType(CircleAvatar).first).dx, 16);

      // A message's page takes the list's place: its app bar spans the
      // page, with the back button's icon at the margin, as is the message.
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      final appBar = tester.getRect(find.byType(AppBar));
      expect(appBar.left, 0);
      expect(appBar.right, 400);
      expect(tester.getCenter(find.byType(BackButton)).dx, 16 + 12);
      expect(
        tester.getTopLeft(find.text('Draft of the accessibility notes')).dx,
        16,
      );
    });

    testWidgets('from medium up, panes are cards set in by the margins, with '
        "content at Material's card padding", (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      expect(
        (tester.widget<Material>(surface()).shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(16),
      );
      final card = tester.getRect(surface());
      final rail = tester.getRect(find.byType(NavigationRail));
      // The rail takes the place of the margin on its side.
      expect(card.left, rail.right);
      expect(tester.getTopLeft(header('Inbox')).dx, card.left + 16);
      expect(
        tester.getTopLeft(find.byType(CircleAvatar).first).dx,
        card.left + 16,
      );
    });

    testWidgets(
      "a message's app bar and content line up alike in a pane and on a "
      'page',
      (tester) async {
        // Where things are on the card the message sits on.
        final card = find.descendant(
          of: find.byType(MessageDetail),
          matching: find.byType(PaneSurface),
        );
        Rect onCard(Finder finder) =>
            tester.getRect(finder).shift(-tester.getTopLeft(card));
        final title = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Chen Wei'),
        );
        final subject = find.text('Draft of the accessibility notes');

        final back = find.descendant(
          of: find.byType(BackButton),
          matching: find.byType(Icon),
        );
        final details = find.byIcon(Icons.info_outline);

        setWindowSize(tester, const Size(1300, 900));
        await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
        await tester.tap(find.text('Chen Wei'));
        await settle(tester);
        // Beside the list, the back button closes the message. Its icon
        // starts 16dp in, and the last action's icon ends 16dp in, with
        // padded tap targets and without.
        final paneWidth = tester.getSize(card).width;
        expect(onCard(back).left, 16);
        expect(onCard(title).left, 16 + 56);
        expect(onCard(details).right, paneWidth - 16);
        final paneSubject = onCard(subject);
        expect(paneSubject.left, 16);

        // At medium the inbox shows one pane, and the message is a page.
        setWindowSize(tester, const Size(720, 900));
        await settle(tester);
        final pageWidth = tester.getSize(card).width;
        expect(onCard(back).left, 16);
        expect(onCard(title).left, 16 + 56);
        expect(onCard(details).right, pageWidth - 16);
        expect(onCard(subject).topLeft, paneSubject.topLeft);
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.linux,
      }),
    );

    testWidgets("an article's large app bar lines up with the article, "
        'expanded and collapsed', (tester) async {
      final topic = articles.first.topic;
      final headline = find.text(articles.first.title);
      final collapsedTitle = find.descendant(
        of: find.byType(NavigationToolbar),
        matching: find.text(topic),
      );
      // The expanded title is the other one, below the toolbar.
      Finder expandedTitle() => find.byElementPredicate(
        (element) =>
            element.widget is Text &&
            (element.widget as Text).data == topic &&
            collapsedTitle.evaluate().every((toolbar) => toolbar != element),
      );

      setWindowSize(tester, const Size(400, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Articles').first);
      await settle(tester);
      for (final width in [400.0, 1300.0]) {
        setWindowSize(tester, Size(width, 900));
        await settle(tester);
        final start = tester.getTopLeft(headline).dx;
        final card = find.ancestor(
          of: headline,
          matching: find.byType(PaneSurface),
        );
        expect(start - tester.getTopLeft(card).dx, 16, reason: 'at $width');
        expect(
          tester.getTopLeft(expandedTitle()).dx,
          start,
          reason: 'at $width',
        );
        expect(
          tester.getTopLeft(collapsedTitle).dx,
          start,
          reason: 'at $width',
        );

        // The article's own scroll view, beside the related articles' one.
        final article = find.byKey(PageStorageKey<int>(articles.first.id));
        await tester.drag(article, const Offset(0, -300));
        await settle(tester);
        expect(
          tester.getTopLeft(collapsedTitle).dx,
          start,
          reason: 'collapsed at $width',
        );
        await tester.drag(article, const Offset(0, 600));
        await settle(tester);
      }
    });

    testWidgets("the feed's header keeps the margins its cards keep", (
      tester,
    ) async {
      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Feed'),
      );
      final settings = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.tune),
      );
      setWindowSize(tester, const Size(400, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Feed').first);
      await settle(tester);
      for (final width in [400.0, 1300.0]) {
        setWindowSize(tester, Size(width, 900));
        await settle(tester);
        final feed = tester.getRect(find.byType(FeedLayout));
        // Beside the rail, from medium up, the rail takes the place of the
        // leading margin.
        final margin = width < 600 ? 16 : 24;
        final leading = width < 600 ? 16 : 0;
        expect(
          tester.getTopLeft(title).dx,
          tester.getTopLeft(find.byType(ArticleCard).first).dx,
          reason: 'at $width',
        );
        expect(tester.getTopLeft(title).dx, feed.left + leading);
        expect(tester.getTopRight(settings).dx, feed.right - margin);
      }
    });
  });

  group("A message's details", () {
    IconButton toggle(WidgetTester tester, String tooltip) =>
        tester.widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        );

    testWidgets('open and close beside the message from a toggle', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      expect(toggle(tester, 'Open details').isSelected, isFalse);

      await tester.tap(find.byTooltip('Open details'));
      await settle(tester);
      expect(find.byType(SideSheet), findsOneWidget);
      expect(toggle(tester, 'Close details').isSelected, isTrue);

      await tester.tap(find.byTooltip('Close details'));
      await settle(tester);
      expect(find.byType(SideSheet), findsNothing);
      expect(toggle(tester, 'Open details').isSelected, isFalse);
    });

    testWidgets('open in a bottom sheet in a narrower window', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      expect(toggle(tester, 'Open details').isSelected, isNull);
      await tester.tap(find.byTooltip('Open details'));
      await settle(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('close with the message, whose page then turns into the '
        'pane where it stands as the list slides back', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      await tester.tap(find.byTooltip('Open details'));
      await settle(tester);
      final page = tester.getRect(find.byType(MessageDetail));

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump();
      // The page is done at once, and the pane with nothing selected stands
      // in its place.
      expect(find.byType(MessageDetail), findsNothing);
      final pane = find
          .ancestor(
            of: find.text('Select a message to read it'),
            matching: find.byType(PaneSurface),
          )
          .first;
      expect(tester.getRect(pane), page);

      await settle(tester);
      expect(find.byType(SideSheet), findsNothing);
      expect(find.text('Chen Wei'), findsOneWidget);
      expect(tester.getRect(pane).left, greaterThan(page.left));
      expect(tester.takeException(), isNull);
    });

    // Where the message's title starts on the bar.
    double titleStart(WidgetTester tester) {
      final title = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Chen Wei'),
      );
      return tester.getTopLeft(title).dx -
          tester
              .getTopLeft(
                find.ancestor(of: title, matching: find.byType(AppBar)),
              )
              .dx;
    }

    testWidgets('move the message to a page, whose back button stays where '
        'it is', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      expect(messageBack(), findsOneWidget);
      expect(titleStart(tester), 72);

      // The sheet takes the list's room: the list leaves, and the message
      // becomes a page, with the back button it had beside the list.
      await tester.tap(find.byTooltip('Open details'));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(messageBack(), findsOneWidget);
        // The bar moves with the pane, at fractional offsets.
        expect(titleStart(tester), moreOrLessEquals(72));
      }
      await settle(tester);
      expect(find.byType(SideSheet), findsOneWidget);
      expect(
        tester.widget<MessageDetail>(find.byType(MessageDetail)).placement,
        DetailPlacement.page,
      );
      expect(titleStart(tester), 72);
    });

    testWidgets('move the message to a page, whose back button grows in '
        'where the first message always shows', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      await chooseNothingSelected(tester, 'First message');
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      // Beside the list, there is nothing to go back to.
      expect(messageBack(), findsNothing);
      expect(titleStart(tester), 16);

      await tester.tap(find.byTooltip('Open details'));
      final starts = <double>[];
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (messageBack().evaluate().isNotEmpty) {
          starts.add(titleStart(tester));
        }
      }
      await settle(tester);
      expect(starts.any((start) => start > 16 && start < 72), isTrue);
      expect(titleStart(tester), 72);
    });
  });

  group('Back from a message', () {
    testWidgets('beside the list closes it to the placeholder', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      await tester.tap(messageBack());
      await settle(tester);
      expect(find.text('Select a message to read it'), findsOneWidget);
      expect(find.byType(MessageDetail), findsNothing);
    });

    testWidgets('beside the list closes it to the list alone', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      await chooseNothingSelected(tester, 'List alone');
      expect(find.text('Select a message to read it'), findsNothing);
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      expect(find.byType(MessageDetail), findsOneWidget);
      await tester.tap(messageBack());
      await settle(tester);
      expect(find.byType(MessageDetail), findsNothing);
      expect(find.text('Chen Wei'), findsOneWidget);
    });

    testWidgets('is not offered beside the list where the first message '
        'always shows', (tester) async {
      setWindowSize(tester, const Size(1300, 900));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      await chooseNothingSelected(tester, 'First message');
      expect(find.byType(MessageDetail), findsOneWidget);
      expect(messageBack(), findsNothing);
    });

    testWidgets('on a page returns to the list', (tester) async {
      setWindowSize(tester, const Size(400, 800));
      await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
      await settle(tester);
      await tester.tap(find.text('Chen Wei'));
      await settle(tester);
      expect(
        tester.widget<MessageDetail>(find.byType(MessageDetail)).placement,
        DetailPlacement.page,
      );
      await tester.tap(messageBack());
      await settle(tester);
      expect(find.byType(MessageDetail), findsNothing);
      expect(find.text('Chen Wei'), findsOneWidget);
    });
  });

  testWidgets('the settings apply at once', (tester) async {
    setWindowSize(tester, const Size(1300, 900));
    await tester.pumpWidget(const DemoApp(home: NavigatorDemo()));
    await settle(tester);
    await tester.tap(find.byTooltip('Demo settings').first);
    await settle(tester);
    expect(find.byType(SideSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(SettingsPanel),
        matching: find.text('App'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Right to left'));
    await settle(tester);
    expect(
      Directionality.of(tester.element(find.byType(NavigationRail))),
      TextDirection.rtl,
    );
    expect(tester.getRect(find.byType(NavigationRail)).right, 1300);
  });
}
