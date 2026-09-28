// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import '../widgets/panes.dart';

/// What the layout resolves to right now, and the sheets, in the two panes
/// of a [TwoPaneLayout].
///
/// The first pane reports the window, and each pane reports the region it
/// is: resize the window, or drag the handle, to watch the values change.
/// The settings arrange the panes, choose where they go below the two-pane
/// breakpoint and what the handle may hide, and let the second pane be
/// closed.
class LayoutScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  var _secondOpen = true;

  void _toggleSecond() => setState(() => _secondOpen = !_secondOpen);

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    // Only a pane that can be closed can be dismissed.
    final closable = settings.layoutSecondClosable;
    PaneCollapse? collapse(PaneCollapse? collapse, {required bool closable}) =>
        !closable && collapse == PaneCollapse.dismiss
        ? PaneCollapse.collapse
        : collapse;
    return TwoPaneLayout(
      arrangement: settings.twoPaneArrangement,
      twoPaneBreakpoint: settings.layoutTwoPanesFrom,
      reflow: settings.layoutReflow,
      resizable: settings.resizable,
      dragHandle: settings.dragHandle,
      firstCollapse: collapse(settings.layoutFirstCollapse, closable: false),
      secondCollapse: collapse(
        settings.layoutSecondCollapse,
        closable: closable,
      ),
      onSecondDismissed: closable ? _toggleSecond : null,
      motion: settings.paneMotion,
      first: PaneSurface(
        child: _Report(
          title: 'Layout',
          listKey: const ValueKey('window report'),
          actions: [
            if (closable)
              IconButton(
                tooltip: _secondOpen ? 'Close pane' : 'Open pane',
                isSelected: _secondOpen,
                icon: const Icon(Icons.view_sidebar_outlined),
                selectedIcon: const Icon(Icons.view_sidebar),
                onPressed: _toggleSecond,
              ),
          ],
          window: true,
        ),
      ),
      second: closable && !_secondOpen
          ? null
          : PaneSurface(
              child: _Report(
                title: 'Second pane',
                listKey: const ValueKey('pane report'),
                settingsButton: false,
                actions: [
                  if (closable)
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSecond,
                    ),
                ],
              ),
            ),
    );
  }
}

// What a pane resolves to, and with [window], the window and the sheets.
class _Report extends StatelessWidget {
  const new({
    required this.title,
    required this.listKey,
    this.actions = const [],
    this.settingsButton = true,
    this.window = false,
  });

  final String title;
  final Key listKey;
  final List<Widget> actions;
  final bool settingsButton;
  final bool window;

  static String _name(Enum value) => switch (value) {
    Breakpoint.extraLarge => 'extra-large',
    _ => value.name,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakpoints = MaterialLayoutTheme.of(context).breakpoints;
    final window = MediaQuery.sizeOf(context);
    final windowBreakpoint = breakpoints.forWidth(window.width);
    final region = AdaptiveRegion.sizeOf(context);
    final regionBreakpoint = AdaptiveRegion.breakpointOf(context);
    final placement = NavigationScaffold.placementOf(context);
    final fixed = regionBreakpoint.fixedPaneWidth;
    final padding = PaneSurface.paddingOf(context);
    final margins = AdaptiveRegion.marginsOf(context);
    final settings = Settings.of(context);

    Widget section(String title, List<(String, String)> rows) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              // The value moves below its label where the two do not fit on
              // one line, as with large text.
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(value, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(title: title, actions: actions, settings: settingsButton),
        Expanded(
          child: ListView(
            key: listKey,
            padding: EdgeInsetsDirectional.fromSTEB(
              padding.start,
              8,
              padding.end,
              24,
            ),
            children: [
              if (this.window)
                section('Window', [
                  (
                    'Size',
                    '${window.width.round()} × ${window.height.round()}dp',
                  ),
                  ('Width breakpoint', _name(windowBreakpoint)),
                  (
                    'Height breakpoint',
                    _name(breakpoints.forHeight(window.height)),
                  ),
                  ('Navigation', placement.name),
                ]),
              section('This pane', [
                (
                  'Size',
                  '${region.width.round()} × ${region.height.round()}dp',
                ),
                ('Width breakpoint', _name(regionBreakpoint)),
                ('Margins', '${regionBreakpoint.margin.round()}dp'),
                (
                  'Margins kept',
                  PaneSurface.inCard(context)
                      ? 'around the panes'
                      : 'within the panes',
                ),
                (
                  'Content keeps',
                  '${margins.start.round()}dp and ${margins.end.round()}dp',
                ),
                ('Fixed pane', fixed == null ? 'none' : '${fixed.round()}dp'),
              ]),
              LineLength(
                characters: settings.lineLength,
                style: theme.textTheme.bodyMedium,
                child: Text(
                  this.window
                      ? 'Layouts resolve against the region they occupy: '
                            'beside a navigation rail, the body is narrower '
                            'than the window, and its breakpoint can be one '
                            'step smaller. Each pane is a region too.'
                      : 'This pane is a region of its own, as every pane '
                            'is: a layout inside it adapts to the pane, not '
                            'the window. Drag the handle to watch its '
                            'breakpoint change.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (this.window) ...[
                const SizedBox(height: 24),
                Text('Sheets', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _showSideSheet(context, settings),
                      child: const Text('Modal side sheet'),
                    ),
                    OutlinedButton(
                      onPressed: () => showAdaptiveSheet<void>(
                        context: context,
                        isDismissible: settings.scrimDismisses,
                        motion: settings.paneMotion,
                        headline: const Text('Adaptive sheet'),
                        builder: (context) => const _SheetText(
                          'A side sheet from expanded upwards, a bottom sheet '
                          'below. The form follows the window, not the '
                          'region.',
                        ),
                      ),
                      child: const Text('Adaptive sheet'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSideSheet(
    BuildContext context,
    DemoSettings settings,
  ) => showSideSheet<void>(
    context: context,
    barrierDismissible: settings.scrimDismisses,
    motion: settings.paneMotion,
    builder: (context) => SideSheet(
      width: settings.sideSheetWidth,
      headline: const Text('Filters'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Apply'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetText(
            'A modal side sheet covers the content and blocks it until it is '
            'closed: with the close button, the scrim, or the back gesture.',
          ),
          SizedBox(height: 16),
          _FilterChips(),
        ],
      ),
    ),
  );
}

class _SheetText extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class _FilterChips extends StatefulWidget {
  const new();

  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  final _selected = <String>{'Unread'};

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final label in ['Unread', 'Starred', 'Attachments', 'This week'])
        FilterChip(
          label: Text(label),
          selected: _selected.contains(label),
          onSelected: (selected) => setState(
            () => selected ? _selected.add(label) : _selected.remove(label),
          ),
        ),
    ],
  );
}
