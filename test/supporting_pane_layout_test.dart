import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

const _supportingKey = Key('supporting');

Widget _layout({
  required SupportingPaneController controller,
  required PaneController paneController,
  PaneResizeBehavior? resizeBehavior,
  double? ratio,
}) {
  return app(
    SupportingPaneLayout(
      dismissible: true,
      controller: controller,
      paneController: paneController,
      resizable: true,
      resizeBehavior: resizeBehavior ?? PaneResizeBehavior.temporary,
      ratio: ratio,
      content: const SizedBox.expand(),
      supporting: const SizedBox.expand(key: _supportingKey),
    ),
  );
}

void main() {
  testWidgets('the supporting pane rests at the Material fixed width', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1000, 800)); // expanded
    final controller = SupportingPaneController(visible: true);
    final split = PaneController();
    addTearDown(controller.dispose);
    addTearDown(split.dispose);
    await tester.pumpWidget(
      _layout(controller: controller, paneController: split),
    );
    await pumpFrames(tester);

    expect(
      tester.getSize(find.byKey(_supportingKey)).width,
      closeTo(360, 0.001),
    );
  });

  testWidgets('ratio is the supporting pane\'s share', (tester) async {
    setWindowSize(tester, const Size(1024, 800));
    final controller = SupportingPaneController(visible: true);
    final split = PaneController();
    addTearDown(controller.dispose);
    addTearDown(split.dispose);
    await tester.pumpWidget(
      _layout(controller: controller, paneController: split, ratio: 0.4),
    );
    await pumpFrames(tester);

    expect(
      tester.getSize(find.byKey(_supportingKey)).width,
      closeTo(400, 0.001),
    );
  });

  testWidgets('temporary resizing forgets the width when the pane closes', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final controller = SupportingPaneController(visible: true);
    final split = PaneController(fraction: 0.5);
    addTearDown(controller.dispose);
    addTearDown(split.dispose);
    await tester.pumpWidget(
      _layout(controller: controller, paneController: split),
    );
    await pumpFrames(tester);

    controller.hide();
    await pumpFrames(tester);

    expect(split.fraction, isNull);
  });

  testWidgets('persistent resizing keeps the width when the pane closes', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1400, 900));
    final controller = SupportingPaneController(visible: true);
    final split = PaneController(fraction: 0.5);
    addTearDown(controller.dispose);
    addTearDown(split.dispose);
    await tester.pumpWidget(
      _layout(
        controller: controller,
        paneController: split,
        resizeBehavior: PaneResizeBehavior.persistent,
      ),
    );
    await pumpFrames(tester);

    controller.hide();
    await pumpFrames(tester);

    expect(split.fraction, 0.5);
  });
}
