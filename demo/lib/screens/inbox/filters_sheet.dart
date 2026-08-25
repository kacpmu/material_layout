import 'package:flutter/material.dart';

/// Inbox filters, shown in a **standard** adaptive sheet.
///
/// Filters act on the list rather than on one message, so they are not a
/// supporting pane — Material 3 reserves that for content "only meaningful in
/// relation to the primary content". A standard sheet is the right home: no
/// scrim, no barrier, so the list stays usable while you filter.
///
/// The controls are deliberately **decorative** — they toggle so the sheet
/// feels alive, but nothing actually filters.
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  bool _unreadOnly = true;
  bool _hasAttachment = false;
  bool _flagged = false;
  final Set<String> _categories = {'Primary'};
  String _range = 'Any time';

  static const _allCategories = ['Primary', 'Social', 'Promotions', 'Updates'];
  static const _ranges = ['Any time', 'Today', 'This week'];

  void _clear() => setState(() {
        _unreadOnly = false;
        _hasAttachment = false;
        _flagged = false;
        _categories.clear();
        _range = 'Any time';
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No PaneContainer here: the sheet already paints its own surface.
    return SafeArea(
      child: ListView(
        // The sheet sizes itself to this content and scrolls it if the window
        // is short, so the filters never fight the sheet for height.
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filters', style: theme.textTheme.titleMedium),
                ),
                TextButton(onPressed: _clear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Decorative — nothing here actually filters the list.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 28),
            _label(theme, 'Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _allCategories)
                  FilterChip(
                    label: Text(c),
                    selected: _categories.contains(c),
                    onSelected: (on) => setState(() {
                      on ? _categories.add(c) : _categories.remove(c);
                    }),
                  ),
              ],
            ),
            const Divider(height: 28),
            _label(theme, 'Received'),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final r in _ranges)
                  ButtonSegment(value: r, label: Text(r)),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            const Divider(height: 28),
            _label(theme, 'Show only'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Unread'),
              value: _unreadOnly,
              onChanged: (v) => setState(() => _unreadOnly = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('With attachments'),
              value: _hasAttachment,
              onChanged: (v) => setState(() => _hasAttachment = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Flagged'),
              value: _flagged,
              onChanged: (v) => setState(() => _flagged = v),
            ),
          ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: theme.textTheme.labelLarge),
      );
}
