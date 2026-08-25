import 'package:material_layout/material_layout.dart';
import 'package:flutter/material.dart';
import 'package:material_navigation/material_navigation.dart';

import 'package:demo/data/demo_settings.dart';

/// The demo's settings, shown in an adaptive sheet (a side sheet on wide
/// windows, a bottom sheet on narrow ones) — itself a package feature.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final DemoSettings settings;
  final ValueChanged<DemoSettings> onChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late DemoSettings _s = widget.settings;

  void _set(DemoSettings next) {
    setState(() => _s = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Read the brightness actually on screen rather than `themeMode == dark`.
    // The demo starts on ThemeMode.system, so on a dark-themed device the app
    // is already dark while `themeMode` is still `system` — the switch has to
    // report what the user can see, not which enum value is stored.
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Demo settings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Resize the window to watch the layout adapt.',
                style: theme.textTheme.bodySmall),

            _section(theme, 'General'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark theme'),
              subtitle: Text(
                _s.themeMode == ThemeMode.system
                    ? 'Following the system (currently '
                        '${isDark ? 'dark' : 'light'})'
                    : 'Set by you',
              ),
              value: isDark,
              onChanged: (v) => _set(
                  _s.copyWith(themeMode: v ? ThemeMode.dark : ThemeMode.light)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Right-to-left'),
              subtitle: const Text('Mirrors panes, rails, and sheets'),
              value: _s.rtl,
              onChanged: (v) => _set(_s.copyWith(rtl: v)),
            ),

            _section(theme, 'Navigation'),
            _note(
              theme,
              'The bar and rail come from the separate material_navigation '
              'package. material_layout only places them by window size — '
              'these options configure the components themselves.',
            ),
            _label(theme, 'Rail indicator size (resize to \u22651200)'),
            SegmentedButton<NavigationIndicatorSize>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: NavigationIndicatorSize.fill, label: Text('Fill')),
                ButtonSegment(
                    value: NavigationIndicatorSize.label, label: Text('Label')),
              ],
              selected: {_s.railIndicatorSize},
              onSelectionChanged: (s) =>
                  _set(_s.copyWith(railIndicatorSize: s.first)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modal rail'),
              subtitle: const Text(
                  'Expanded rail overlays the content instead of pushing it'),
              value: _s.modalRail,
              onChanged: (v) => _set(_s.copyWith(modalRail: v)),
            ),

            _section(theme, 'Panes'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Resizable panes'),
              subtitle: const Text('Drag the divider; double-tap to collapse'),
              value: _s.resizablePanes,
              onChanged: (v) => _set(_s.copyWith(resizablePanes: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dismissible supporting pane'),
              subtitle: const Text(
                  'Inbox info and the Articles pane open on demand'),
              value: _s.supportingDismissible,
              onChanged: (v) => _set(_s.copyWith(supportingDismissible: v)),
            ),
            const SizedBox(height: 8),
            _label(theme, 'List-detail empty state'),
            SegmentedButton<ListDetailBehavior>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: ListDetailBehavior.placeholder,
                    label: Text('Placeholder')),
                ButtonSegment(
                    value: ListDetailBehavior.hidden, label: Text('Hidden')),
                ButtonSegment(
                    value: ListDetailBehavior.selected,
                    label: Text('Selected')),
              ],
              selected: {_s.listDetailBehavior},
              onSelectionChanged: (s) =>
                  _set(_s.copyWith(listDetailBehavior: s.first)),
            ),
          ],
        ),
      ),
    );
  }

  /// A section break: a rule and a title, so the sheet reads as three groups
  /// rather than one long list of switches.
  Widget _section(ThemeData theme, String title) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );

  /// Explanatory prose under a section title.
  Widget _note(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );

  Widget _label(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: theme.textTheme.labelLarge),
      );
}
