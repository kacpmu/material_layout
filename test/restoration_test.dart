// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  testWidgets('a layout with a restoration id restores its selection and '
      'split', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          body: ListDetailLayout<int>(
            restorationId: 'inbox',
            resizable: true,
            listBuilder: (context) => Column(
              children: [
                for (final id in [1, 2, 3])
                  TextButton(
                    onPressed: () =>
                        ListDetailLayout.of<int>(context).select(id),
                    child: Text('Item $id'),
                  ),
              ],
            ),
            detailBuilder: (context, id, placement) => Text('Detail $id'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Item 2'));
    await tester.pump();
    await doubleTap(tester, find.byType(PaneResizer));
    await settle(tester);
    expect(find.text('Detail 2'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);

    await tester.restartAndRestore();
    await settle(tester);
    expect(find.text('Detail 2'), findsOneWidget);
    // The list stays collapsed.
    expect(find.text('Item 1'), findsNothing);
  });

  Widget inbox({int? selectedId}) => ListDetailLayout<int>(
    restorationId: 'inbox',
    selectedId: selectedId,
    resizable: true,
    listBuilder: (context) => Column(
      children: [
        for (final id in [1, 2, 3])
          TextButton(
            onPressed: () => ListDetailLayout.of<int>(context).select(id),
            child: Text('Item $id'),
          ),
      ],
    ),
    detailBuilder: (context, id, placement) => Text('Detail $id'),
  );

  testWidgets('restoring an earlier state moves the split the layout '
      'keeps', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(body: inbox(selectedId: 1)),
      ),
    );
    await doubleTap(tester, find.byType(PaneResizer));
    await settle(tester);
    expect(find.text('Item 1'), findsNothing);
    final collapsed = await tester.getRestorationData();

    await doubleTap(tester, find.byType(PaneResizer));
    await settle(tester);
    expect(find.text('Item 1'), findsOneWidget);

    await tester.restoreFrom(collapsed);
    await settle(tester);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Detail 1'), findsOneWidget);
  });

  testWidgets('a stored split the layout cannot read restores the default, '
      'and the selection still restores', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    final bucket = RestorationBucket.root(
      manager: tester.binding.restorationManager,
      rawData: <Object?, Object?>{
        'c': <Object?, Object?>{
          'inbox': <Object?, Object?>{
            'v': <Object?, Object?>{'selection': 2, 'split': 'sideways'},
          },
        },
      },
    );
    addTearDown(bucket.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnmanagedRestorationScope(bucket: bucket, child: inbox()),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Detail 2'), findsOneWidget);
    expect(
      tester.getRect(find.byType(Column)).width,
      412,
      reason: 'the default split at large',
    );
  });

  testWidgets('restoration data that changes under a layout moves its '
      'split', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    // No route restores, so the layout keeps its state as the data changes.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RootRestorationScope(
            restorationId: 'root',
            child: inbox(selectedId: 1),
          ),
        ),
      ),
    );
    final state = tester.state(find.byType(ListDetailLayout<int>));
    await doubleTap(tester, find.byType(PaneResizer));
    await settle(tester);
    expect(find.text('Item 1'), findsNothing);
    final collapsed = await tester.getRestorationData();

    await doubleTap(tester, find.byType(PaneResizer));
    await settle(tester);
    expect(find.text('Item 1'), findsOneWidget);

    await tester.restoreFrom(collapsed);
    await settle(tester);
    expect(tester.state(find.byType(ListDetailLayout<int>)), same(state));
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Detail 1'), findsOneWidget);
  });

  testWidgets('restores neither a selection the caller owns nor a split the '
      "caller's controller holds", (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    final split = PaneSplitController();
    addTearDown(split.dispose);
    final bucket = RestorationBucket.root(
      manager: tester.binding.restorationManager,
      rawData: <Object?, Object?>{
        'c': <Object?, Object?>{
          'inbox': <Object?, Object?>{
            'v': <Object?, Object?>{'selection': 2, 'split': 'collapsed'},
          },
        },
      },
    );
    addTearDown(bucket.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UnmanagedRestorationScope(
            bucket: bucket,
            child: ListDetailLayout<int>(
              restorationId: 'inbox',
              selectedId: 1,
              onSelectionChanged: (_) {},
              resizable: true,
              splitController: split,
              listBuilder: (context) => const SizedBox.expand(key: listKey),
              detailBuilder: (context, id, placement) => Text('Detail $id'),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Detail 1'), findsOneWidget);
    expect(tester.getRect(find.byKey(listKey)).width, 412);
    expect(split.value, PaneSplit.automatic);
  });

  testWidgets('an id that is not a number, a string or a boolean is not '
      'restored', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          body: ListDetailLayout<(int, String)>(
            restorationId: 'inbox',
            listBuilder: (context) => TextButton(
              onPressed: () =>
                  ListDetailLayout.of<(int, String)>(context).select((1, 'a')),
              child: const Text('Select'),
            ),
            detailBuilder: (context, id, placement) => Text('Detail $id'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select'));
    await settle(tester);
    expect(find.text('Detail (1, a)'), findsOneWidget);
    await tester.getRestorationData();
    await tester.restartAndRestore();
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Detail (1, a)'), findsNothing);
  });
}

const listKey = ValueKey('list');
