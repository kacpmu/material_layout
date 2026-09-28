// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../example/main.dart' as example;
import 'helpers.dart';

void main() {
  testWidgets('the example closes a message beside the list', (tester) async {
    setWindowSize(tester, const Size(1300, 800));
    example.main();
    await tester.pump();
    expect(find.text('Select a message'), findsOneWidget);
    await tester.tap(find.text('Message 3').first);
    await settle(tester);
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    expect(find.text('Select a message'), findsOneWidget);
  });

  testWidgets('the example goes back from a message on a page', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    example.main();
    await tester.pump();
    await tester.tap(find.text('Message 3').first);
    await settle(tester);
    expect(find.byTooltip('Close'), findsNothing);
    expect(find.text('The body of the message.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    // The page is gone, and the list shows again.
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('The body of the message.'), findsNothing);
    expect(find.text('Message 0'), findsOneWidget);
    expect(find.text('Message 3'), findsOneWidget);
  });
}
