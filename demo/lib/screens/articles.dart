// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import '../data/articles.dart';
import '../widgets/panes.dart';
import '../widgets/settings_panel.dart';

/// A reader: an article in the focus pane, related articles in a
/// supporting pane.
///
/// Beside the article, from expanded upwards, the related articles are a
/// standard side sheet, or, as the settings say, a pane on either side of
/// it; below expanded they move beneath the article. The reader can close
/// them, or, as the settings say, they always show. Opening a related
/// article replaces the focus pane's content without animating it.
class ArticlesScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  var _article = articles.first;
  var _related = true;

  void _open(Article article) => setState(() => _article = article);

  void _toggleRelated() => setState(() => _related = !_related);

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    final beside = AdaptiveRegion.breakpointOf(context) >= Breakpoint.expanded;
    final related = _RelatedArticles(current: _article, onOpen: _open);
    final sheet = settings.related == RelatedPlacement.sheet;
    // A temporary pane, which the reader can close, or a permanent one, which
    // always shows.
    final dismiss = settings.relatedDismissible ? _toggleRelated : null;
    final shown = _related || dismiss == null;
    return SupportingPaneLayout(
      supportingSide: settings.related == RelatedPlacement.leadingPane
          ? PaneSide.leading
          : PaneSide.trailing,
      resizable: settings.resizable && settings.articlesResizable,
      dragHandle: settings.dragHandle,
      resizeMemory: settings.articlesResizeMemory,
      motion: settings.paneMotion,
      onSupportingDismissed: dismiss,
      focus: PaneSurface(
        child: _ArticleView(
          article: _article,
          relatedShown: shown,
          onToggleRelated: dismiss,
        ),
      ),
      supporting: !shown
          ? null
          : beside && sheet
          ? SideSheet(
              width: settings.sideSheetWidth,
              headline: const Text('Related'),
              child: related,
            )
          : PaneSurface(
              child: _RelatedPane(onClose: dismiss, child: related),
            ),
    );
  }
}

// The related articles in a pane of their own, which has a close button
// where it is a temporary pane. The header stays at the top while the
// articles scroll below it; a pane shorter than the header, as one stacked
// below the article can be at a large text size, clips it.
class _RelatedPane extends StatelessWidget {
  const new({required this.onClose, required this.child});

  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = PaneSurface.paddingOf(context);
    final onClose = this.onClose;
    return CustomScrollView(
      slivers: [
        PinnedHeaderSliver(
          child: PaneHeader(
            title: 'Related',
            settings: false,
            actions: [
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: padding.start,
            end: padding.end,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

class _ArticleView extends StatelessWidget {
  const new({
    required this.article,
    required this.relatedShown,
    required this.onToggleRelated,
  });

  final Article article;
  final bool relatedShown;
  // Null where the related articles always show.
  final VoidCallback? onToggleRelated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = PaneSurface.paddingOf(context);
    return CustomScrollView(
      key: PageStorageKey<int>(article.id),
      slivers: [
        // A large app bar, as it comes: its title starts 16dp in, where the
        // article does, expanded and collapsed alike.
        SliverAppBar.large(
          automaticallyImplyLeading: false,
          title: Text(article.topic),
          actions: [
            if (onToggleRelated case final toggle?)
              IconButton(
                tooltip: relatedShown ? 'Close related' : 'Open related',
                isSelected: relatedShown,
                icon: const Icon(Icons.view_sidebar_outlined),
                selectedIcon: const Icon(Icons.view_sidebar),
                onPressed: toggle,
              ),
            const SettingsButton(),
          ],
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding.start,
            8,
            padding.end,
            24,
          ),
          // Lines of at most 60 characters, however wide the pane.
          sliver: SliverToBoxAdapter(
            child: LineLength(
              characters: Settings.of(context).lineLength,
              style: theme.textTheme.bodyLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(article.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${article.author} · ${article.minutes} min read',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Illustration(article: article, height: 180),
                  const SizedBox(height: 24),
                  for (final paragraph in article.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(paragraph, style: theme.textTheme.bodyLarge),
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

class _RelatedArticles extends StatelessWidget {
  const new({required this.current, required this.onOpen});

  final Article current;
  final ValueChanged<Article> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final article in articles)
          if (article.id != current.id)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card.filled(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(article),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _Illustration(article: article, height: 48, width: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                article.author,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const new({required this.article, required this.height, this.width});

  final Article article;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: article.color(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: height / 3,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

/// A card for an article, as shown in the feed.
class ArticleCard extends StatelessWidget {
  const new({super.key, required this.article, required this.imageHeight});

  final Article article;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Illustration(article: article, height: imageHeight),
              const SizedBox(height: 12),
              Text(
                article.topic.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(article.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                article.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
