import 'package:material_layout/material_layout.dart';
import 'package:flutter/material.dart';

/// Sheets — every sheet the package can open, side by side.
///
/// Demonstrates: `showAppBottomSheet`, `showSideSheet`, `showAdaptiveSheet`,
/// and the standard/modal distinction.
class SheetsScreen extends StatelessWidget {
  const SheetsScreen({super.key});

  Widget _sheetBody(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Supplementary content lives here.'),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => showAppBottomSheet(context,
                  builder: (_) => _sheetBody(context, 'Modal bottom sheet')),
              icon: const Icon(Icons.vertical_align_bottom),
              label: const Text('Modal bottom sheet'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => showAppBottomSheet(context,
                  mode: SheetMode.standard,
                  builder: (_) => _sheetBody(context, 'Standard bottom sheet')),
              icon: const Icon(Icons.vertical_align_bottom),
              label: const Text('Standard bottom sheet'),
            ),
            FilledButton.icon(
              onPressed: () => showSideSheet(context,
                  builder: (_) => _sheetBody(context, 'Modal side sheet')),
              icon: const Icon(Icons.view_sidebar_outlined),
              label: const Text('Modal side sheet'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => showSideSheet(context,
                  mode: SheetMode.standard,
                  builder: (_) => _sheetBody(context, 'Standard side sheet')),
              icon: const Icon(Icons.view_sidebar_outlined),
              label: const Text('Standard side sheet'),
            ),
            OutlinedButton.icon(
              onPressed: () => showAdaptiveSheet(context,
                  builder: (_) => _sheetBody(context, 'Adaptive sheet')),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Adaptive sheet'),
            ),
          ],
        ),
      ),
    );
  }
}
