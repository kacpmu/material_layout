// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import '../data/articles.dart';
import '../widgets/settings_panel.dart';
import 'articles.dart';

/// A feed of article cards.
///
/// One column at compact; above it, as many columns as fit at the settings'
/// minimum card width, 280dp to begin with, with the first article spanning
/// two. The cards' pictures differ in height, and the cards reflow in order
/// as the window changes.
class FeedScreen extends StatelessWidget {
  const new({super.key});

  static const _pictureHeights = [220.0, 120.0, 160.0, 100.0, 140.0, 180.0];

  @override
  Widget build(BuildContext context) {
    // The feed's cards keep the window's margins, which from medium up are
    // wider than an app bar's own 16dp inset. The header's bar moves in by
    // the difference, less the safe-area padding it keeps clear of itself.
    final settings = Settings.of(context);
    final margins = AdaptiveRegion.marginsOf(context);
    final insets = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = margins.start - (rtl ? insets.right : insets.left);
    final end = margins.end - (rtl ? insets.left : insets.right);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          // The bar sits on the background, as the cards do.
          backgroundColor: Colors.transparent,
          titleSpacing: start,
          actionsPadding: EdgeInsetsDirectional.only(
            end: end - iconButtonInset(Theme.of(context)),
          ),
          title: const Text('Feed'),
          actions: const [SettingsButton()],
        ),
        Expanded(
          child: FeedLayout(
            minItemWidth: settings.feedMinItemWidth,
            gap: settings.feedGap,
            itemCount: articles.length * 3,
            padding: const EdgeInsets.only(bottom: 16),
            spanBuilder: settings.feedSpans,
            itemBuilder: (context, index) => ArticleCard(
              article: articles[index % articles.length],
              imageHeight: _pictureHeights[index % _pictureHeights.length],
            ),
          ),
        ),
      ],
    );
  }
}
