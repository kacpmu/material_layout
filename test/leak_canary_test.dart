// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:material_ui/material_ui.dart';

/// Leaks a notifier on purpose, and fails unless the leak is reported.
///
/// Without this test, a leak-tracking configuration that had stopped working
/// would pass every other test.
void main() {
  LeakTesting.collectedLeaksReporter = (leaks) {
    final canaries = leaks.notDisposed.where(
      (leak) => leak.type == '$ChangeNotifier',
    );
    expect(
      canaries,
      isNotEmpty,
      reason:
          'The canary leaked a ChangeNotifier and the leak tracker did not '
          'report it: leak tracking is not armed.',
    );
  };

  testWidgets('leaks a ChangeNotifier', (tester) async {
    // Without leak testing enabled, the reporter above is never called.
    expect(LeakTesting.enabled, isTrue, reason: 'Leak tracking is not armed.');
    await tester.pumpWidget(const _Leaking());
    await tester.pumpWidget(const SizedBox());
  });
}

class _Leaking extends StatefulWidget {
  const new();

  @override
  State<_Leaking> createState() => _LeakingState();
}

class _LeakingState extends State<_Leaking> {
  // Never disposed. A notifier reports its creation to the leak tracker when
  // it gets its first listener.
  final notifier = ChangeNotifier()..addListener(() {});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
