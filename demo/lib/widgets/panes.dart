// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import 'settings_panel.dart';

/// Whether the demo's panes are flat: where the layouts keep their margins
/// within the panes, which the app sets in a compact window.
bool panesFlat(BuildContext context) =>
    MaterialLayoutTheme.of(context).marginPlacement == MarginPlacement.inside;

/// A screen of one pane outside any layout, which keeps the margins as the
/// layouts' panes do: a card is set in by them, and a flat pane reaches the
/// edges while its content keeps them.
class LonePane extends StatelessWidget {
  const new({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pane = PaneSurface(child: child);
    if (panesFlat(context)) return pane;
    return Padding(padding: AdaptiveRegion.marginsOf(context), child: pane);
  }
}

/// The app bar at the top of a pane, with the demo's settings button.
///
/// A plain [AppBar]: its title and icons start and end 16dp in, where the
/// pane's content does.
class PaneHeader extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.actions = const [],
    this.settings = true,
  });

  final String title;
  final List<Widget> actions;

  /// Whether the bar has the settings button.
  final bool settings;

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    title: Text(title),
    actions: [...actions, if (settings) const SettingsButton()],
  );
}

/// A form for a new message, shown in an adaptive sheet.
class ComposeForm extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const TextField(decoration: InputDecoration(labelText: 'To')),
        const TextField(decoration: InputDecoration(labelText: 'Subject')),
        const TextField(
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  );
}

/// Opens the compose form in an adaptive sheet.
void showCompose(BuildContext context) {
  final settings = Settings.of(context);
  showAdaptiveSheet<void>(
    context: context,
    headline: const Text('New message'),
    isDismissible: settings.scrimDismisses,
    motion: settings.paneMotion,
    builder: (context) => const ComposeForm(),
  );
}
