import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:demo/data/demo_data.dart';

/// The Inbox's supporting pane: details *about* the selected message.
///
/// This is what a supporting pane is for — content that is only meaningful in
/// relation to the primary content, which is why Material 3 distinguishes it
/// from a list-detail pairing. Filters are not that (they act on the list, not
/// on one message), so they live in a sheet instead.
class InfoPane extends StatelessWidget {
  const InfoPane({super.key, this.item});

  /// The selected message, or null when nothing is selected.
  final DemoItem? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A step up from the detail pane's level, so the two read as distinct
    // surfaces — Material 3 recommends exactly this for nested containers in
    // expanded layouts.
    return PaneContainer(
      level: PaneLevel.high,
      child: SafeArea(
        child: item == null
            ? _empty(theme)
            : _details(context, theme, item!),
      ),
    );
  }

  Widget _empty(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Select a message to see details about it.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  Widget _details(BuildContext context, ThemeData theme, DemoItem item) {
    final localizations = MaterialLocalizations.of(context);
    final words = item.body.split(RegExp(r'\s+')).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(radius: 24, child: Text(item.sender[0])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.sender, style: theme.textTheme.titleSmall),
                  Text(
                    'sender',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        _row(theme, 'Subject', item.subject),
        _row(theme, 'Received',
            localizations.formatFullDate(item.sentAt)),
        _row(theme, 'Time',
            localizations.formatTimeOfDay(TimeOfDay.fromDateTime(item.sentAt))),
        _row(theme, 'Length', '$words words'),
        const Divider(height: 28),
        Text('Labels', style: theme.textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('Primary')),
            Chip(label: Text('History')),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () {},
          icon: const Icon(Icons.push_pin_outlined),
          label: const Text('Pin conversation'),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}
