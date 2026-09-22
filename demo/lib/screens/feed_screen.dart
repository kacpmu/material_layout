import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:demo/data/demo_data.dart';

/// Feed — a responsive grid of cards that reflows by column count.
///
/// Demonstrates: `FeedLayout`.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FeedLayout(
      maxItemWidth: 280,
      padding: const EdgeInsets.all(16),
      itemCount: demoItems.length,
      itemBuilder: (context, i) {
        final item = demoItems[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: Colors.blueGrey, child: Text(item.sender[0])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.sender,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item.subject, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(item.body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
