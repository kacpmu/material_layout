// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import '../app/shell.dart';
import '../widgets/panes.dart';

/// One of the destinations that the navigation settings add past the
/// demo's own four, so that the rail and the bar can carry more
/// destinations than Material recommends: three to five in a bar, three to
/// seven in a rail.
///
/// A placeholder, in one pane that keeps the margins as the layouts' panes
/// do.
class ExtraScreen extends StatelessWidget {
  const new({super.key, required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) =>
      LonePane(child: _Placeholder(destination: destination));
}

class _Placeholder extends StatelessWidget {
  const new({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = PaneSurface.paddingOf(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaneHeader(title: destination.label),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                padding.start,
                24,
                padding.end,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Icon(
                    destination.selectedIcon,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  LineLength(
                    characters: Settings.of(context).lineLength,
                    style: style,
                    alignment: Alignment.topCenter,
                    child: Text(
                      'A placeholder, which the navigation settings add past '
                      "the demo's own destinations, so that the rail and the "
                      'bar can carry more than Material recommends: three to '
                      'five in a bar, and three to seven in a rail.',
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
