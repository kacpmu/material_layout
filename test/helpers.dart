// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/gestures.dart' show kDoubleTapMinTime;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Sets the test window to [size] logical pixels.
void setWindowSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Pumps two seconds of frames: long enough for any Material spring to
/// settle.
///
/// Springs come to rest asymptotically, so a fixed budget is used rather
/// than `pumpAndSettle`.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  // By then nothing moves: no animation runs on, and no placement swaps
  // back and forth.
  expect(
    tester.binding.transientCallbackCount,
    0,
    reason: 'Still animating after two seconds.',
  );
}

/// Wraps [child] in a `material_ui` app, in [textDirection].
Widget app(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  ThemeData? theme,
}) => MaterialApp(
  theme: theme,
  home: Directionality(textDirection: textDirection, child: child),
);

/// The global rectangle of the widget [finder] finds.
Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// Taps [finder] twice in quick succession, as a double tap.
Future<void> doubleTap(WidgetTester tester, Finder finder) =>
    doubleTapAt(tester, tester.getCenter(finder));

/// Taps at [position] twice in quick succession, as a double tap.
Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(kDoubleTapMinTime);
  await tester.tapAt(position);
}
