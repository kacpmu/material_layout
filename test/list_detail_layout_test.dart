import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Widget _layout({
  ListDetailController? controller,
  ListDetailBehavior behavior = ListDetailBehavior.placeholder,
  PaneTransition transition = const PaneTransition.spring(),
}) {
  return app(
    ListDetailLayout(
      controller: controller,
      behavior: behavior,
      transition: transition,
      // ListTile paints on the nearest Material, which a real list pane gets
      // from its Scaffold or PaneContainer.
      listBuilder: (context) => Material(
        child: ListView(
          children: [
            for (final id in const ['A', 'B'])
              ListTile(
                title: Text('Item $id'),
                onTap: () => ListDetail.of(context).select(id),
              ),
          ],
        ),
      ),
      detailBuilder: (_, id) =>
          SizedBox.expand(key: const Key('detail'), child: Text('Detail $id')),
    ),
  );
}

void main() {
  testWidgets('compact shows only the list until an item is selected', (
    tester,
  ) async {
    setWindowSize(tester, const Size(400, 800));
    await tester.pumpWidget(_layout());
    await pumpFrames(tester);

    expect(find.text('Item A'), findsOneWidget);
    expect(find.text('Detail A'), findsNothing);

    await tester.tap(find.text('Item A'));
    await pumpFrames(tester);

    expect(
      find.text('Detail A'),
      findsOneWidget,
      reason: 'the detail is pushed as a page over the list',
    );
  });

  testWidgets('wide shows list and detail side by side after selection', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    await tester.pumpWidget(_layout());
    await pumpFrames(tester);

    await tester.tap(find.text('Item A'));
    await pumpFrames(tester);

    expect(find.text('Item A'), findsOneWidget);
    expect(find.text('Detail A'), findsOneWidget);
  });

  testWidgets('selecting another item swaps the detail content in place', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final controller = ListDetailController(initialId: 'A');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_layout(controller: controller));
    await pumpFrames(tester);

    controller.select('B');
    await tester.pump();

    // The pane stays in place and only its content changes: no frame shows
    // both details.
    expect(find.text('Detail A'), findsNothing);
    expect(find.text('Detail B'), findsOneWidget);
  });

  testWidgets('the detail pane enters on the transition', (tester) async {
    setWindowSize(tester, const Size(1400, 900));
    final controller = ListDetailController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _layout(controller: controller, behavior: ListDetailBehavior.hidden),
    );
    await pumpFrames(tester);
    expect(find.byKey(const Key('detail')), findsNothing);

    controller.select('A');
    await pumpFrames(tester);
    final rest = tester.getSize(find.byKey(const Key('detail'))).width;

    controller.clear();
    await pumpFrames(tester);
    expect(find.byKey(const Key('detail')), findsNothing);

    controller.select('A');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final list = tester.getSize(find.byType(ListView)).width;
    expect(
      list,
      greaterThan(1400 - 24 - rest),
      reason: 'mid-entrance the list is still wider than at rest',
    );
  });

  testWidgets('PaneTransition.none shows the detail pane at once', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final controller = ListDetailController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _layout(
        controller: controller,
        behavior: ListDetailBehavior.hidden,
        transition: const PaneTransition.none(),
      ),
    );
    await pumpFrames(tester);

    controller.select('A');
    await tester.pump();
    final list = tester.getSize(find.byType(ListView)).width;
    final detail = tester.getSize(find.byKey(const Key('detail'))).width;
    expect(list + 24 + detail, 1400);
  });

  group('the default two-pane breakpoint is expanded', () {
    // Material 3 recommends a single pane at medium and allows two; the
    // default takes the recommendation.
    testWidgets('one pane at medium', (tester) async {
      setWindowSize(tester, const Size(800, 900));
      final controller = ListDetailController(initialId: 'A');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_layout(controller: controller));
      await pumpFrames(tester);

      // One pane: the detail is a page over the list, not beside it.
      expect(find.byKey(const Key('detail')), findsOneWidget);
      expect(find.text('Item A'), findsNothing);
    });

    testWidgets('two panes at expanded', (tester) async {
      setWindowSize(tester, const Size(900, 900));
      final controller = ListDetailController(initialId: 'A');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_layout(controller: controller));
      await pumpFrames(tester);

      expect(find.byKey(const Key('detail')), findsOneWidget);
      expect(find.text('Item A'), findsOneWidget);
    });
  });
}
