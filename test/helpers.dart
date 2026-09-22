import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Sets the test window to [size] at a device pixel ratio of 1.
void setWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Pumps a fixed second of frames.
///
/// Pane motion is spring-driven and settles asymptotically, so `pumpAndSettle`
/// can spin; a fixed budget is plenty for any of the Material springs.
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Wraps [child] in a `material_ui` app.
Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));
