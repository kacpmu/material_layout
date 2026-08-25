import 'package:material_layout/material_layout.dart';
import 'package:flutter/material.dart';

import 'package:demo/data/demo_data.dart';

/// Articles — the supporting-pane layout on its own.
///
/// Demonstrates: `SupportingPaneLayout` with the **default** resolver, which
/// puts the pane beside the content at expanded and wider, reflows it **below**
/// at compact and medium, and only hides it on a short window where there is no
/// room to stack.
///
/// An article with a "Related people" pane. When [dismissible] the pane is
/// shown on demand —
/// a header button toggles it, and where there's no inline room it opens as an
/// adaptive sheet; otherwise the pane is always present and the button is
/// hidden. The beside split is temporary: drag it and it springs back.
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({
    super.key,
    required this.resizable,
    required this.dismissible,
  });

  final bool resizable;
  final bool dismissible;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final SupportingPaneController _related = SupportingPaneController();
  SupportingPanePresentation _presentation = SupportingPanePresentation.hidden;

  @override
  void dispose() {
    _related.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_presentation == SupportingPanePresentation.hidden) {
      // No inline room → present the pane as an adaptive sheet instead.
      showAdaptiveSheet(context, builder: (_) => _relatedPane(context));
    } else {
      _related.toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportingPaneLayout(
      dismissible: widget.dismissible,
      controller: _related,
      resizable: widget.resizable,
      onPresentationChanged: (p) => setState(() => _presentation = p),
      supporting: _relatedPane(context),
      content: _article(context),
    );
  }

  Widget _article(BuildContext context) {
    final theme = Theme.of(context);
    return AdaptiveBody(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(demoArticleKicker,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
              // A toggle only makes sense for a dismissible pane; a permanent
              // one is always present, so there is nothing to toggle.
              if (widget.dismissible)
                IconButton.filledTonal(
                  onPressed: _toggle,
                  icon: const Icon(Icons.people_alt_outlined),
                  tooltip: 'Related people',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(demoArticleTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Text(demoArticleBody, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _relatedPane(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Related people', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in demoItems)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.blueGrey, child: Text(item.sender[0])),
              title: Text(item.sender),
              subtitle: Text(item.subject,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
