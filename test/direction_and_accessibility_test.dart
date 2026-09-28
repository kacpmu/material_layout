// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Widget listDetail({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  bool focusable = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(padding: padding),
    child: Directionality(textDirection: textDirection, child: child!),
  ),
  home: Scaffold(
    body: ListDetailLayout<int>(
      selectedId: 1,
      resizable: focusable,
      listBuilder: (context) => focusable
          ? Center(
              child: TextButton(onPressed: () {}, child: const Text('In list')),
            )
          : const SizedBox.expand(key: ValueKey('list')),
      detailBuilder: (context, id, placement) => focusable
          ? Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('In detail'),
              ),
            )
          : const SizedBox.expand(key: ValueKey('detail')),
    ),
  ),
);

Rect rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void main() {
  group('Right-to-left', () {
    testWidgets('the list-detail layout mirrors', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(listDetail(textDirection: TextDirection.rtl));
      expect(rect(tester, 'list').right, 1000 - 24);
      expect(rect(tester, 'list').width, 360);
      expect(rect(tester, 'detail').left, 24);
    });

    testWidgets('the supporting pane takes the trailing side, on the left', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: SupportingPaneLayout(
              focus: SizedBox.expand(key: ValueKey('focus')),
              supporting: SizedBox.expand(key: ValueKey('supporting')),
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      expect(rect(tester, 'supporting').left, 24);
      expect(rect(tester, 'focus').right, 1000 - 24);
    });

    testWidgets('leading and trailing margins swap; left and right insets '
        'do not', (tester) async {
      setWindowSize(tester, const Size(1000, 800));
      const notch = EdgeInsets.only(left: 40);
      await tester.pumpWidget(listDetail(padding: notch));
      expect(rect(tester, 'list').left, 24 + 40);
      expect(rect(tester, 'detail').right, 1000 - 24);

      await tester.pumpWidget(
        listDetail(padding: notch, textDirection: TextDirection.rtl),
      );
      await tester.pump();
      expect(rect(tester, 'list').right, 1000 - 24);
      expect(rect(tester, 'detail').left, 24 + 40);
    });
  });

  group('Accessibility', () {
    Future<List<String>> traversal(WidgetTester tester) async {
      final order = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus!.context!;
        if (find
            .ancestor(
              of: find.byWidget(context.widget),
              matching: find.byType(PaneResizer),
            )
            .evaluate()
            .isNotEmpty) {
          order.add('handle');
        } else {
          final text = find.descendant(
            of: find.byWidget(context.widget),
            matching: find.byType(Text),
          );
          order.add(tester.widget<Text>(text.first).data!);
        }
      }
      return order;
    }

    testWidgets('focus follows the panes from leading to trailing', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(listDetail(focusable: true));
      expect(await traversal(tester), ['In list', 'handle', 'In detail']);
    });

    testWidgets('focus follows the mirrored panes in right-to-left', (
      tester,
    ) async {
      setWindowSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        listDetail(focusable: true, textDirection: TextDirection.rtl),
      );
      expect(await traversal(tester), ['In list', 'handle', 'In detail']);
    });

    testWidgets('interactive targets are at least 48 by 48dp', (tester) async {
      final semantics = tester.ensureSemantics();
      setWindowSize(tester, const Size(1700, 800));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SupportingPaneLayout(
              resizable: true,
              onSupportingDismissed: () {},
              focus: listDetail(focusable: true),
              supporting: const SideSheet(
                headline: Text('Filters'),
                child: Text('Content'),
              ),
            ),
          ),
        ),
      );
      // Both handles show: the supporting pane's, and that of the list
      // and the detail beside the sheet.
      expect(find.byType(PaneResizer), findsNWidgets(2));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });
  });
}
