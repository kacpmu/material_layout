import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../app/demo_app.dart';
import '../data/mail.dart';
import '../widgets/panes.dart';

/// The inbox: a list-detail layout, with a side sheet of message details
/// beside it where there is room.
///
/// The selection belongs to the caller, so that the router entrypoint can
/// keep it in the URL. The details sheet is the supporting pane of an outer
/// layout, which makes it a third pane at extra-large; on narrower
/// windows the details open in a bottom sheet instead. Both layouts
/// keep their margins as the app's layout theme says.
class InboxScreen extends StatefulWidget {
  const new({
    super.key,
    required this.selectedId,
    required this.onSelectionChanged,
  });

  final int? selectedId;
  final ValueChanged<int?> onSelectionChanged;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  var _details = false;

  void _showDetails(Message message) {
    if (AdaptiveRegion.breakpointOf(context) >= Breakpoint.expanded) {
      setState(() => _details = !_details);
      return;
    }
    final settings = Settings.of(context);
    showAdaptiveSheet<void>(
      context: context,
      headline: const Text('Details'),
      isDismissible: settings.scrimDismisses,
      motion: settings.paneMotion,
      builder: (context) => MessageDetails(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    final mail = Mail.of(context);
    final id = widget.selectedId;
    final message = id == null ? null : mail.byId(id);
    // Beside the message, the details are a side sheet the button opens and
    // closes; in narrower windows they open in a bottom sheet instead.
    final beside = AdaptiveRegion.breakpointOf(context) >= Breakpoint.expanded;

    return SupportingPaneLayout(
      motion: settings.paneMotion,
      supporting: _details && beside && message != null
          ? SideSheet(
              width: settings.sideSheetWidth,
              headline: const Text('Details'),
              child: MessageDetails(message: message),
            )
          : null,
      onSupportingDismissed: () => setState(() => _details = false),
      focus: ListDetailLayout<int>(
        selectedId: id,
        onSelectionChanged: widget.onSelectionChanged,
        twoPaneBreakpoint: settings.twoPanesFrom,
        resizable: settings.resizable,
        dragHandle: settings.dragHandle,
        splitController: InboxSplit.of(context),
        resizeMemory: settings.inboxResizeMemory,
        listCollapse: settings.listCollapse,
        detailCollapse: settings.messageCollapse,
        motion: settings.paneMotion,
        emptyBehavior: switch (settings.nothingSelected) {
          NothingSelected.placeholder =>
            const ListDetailEmptyBehavior.placeholder(
              child: PaneSurface(child: _NothingSelected()),
            ),
          NothingSelected.listOnly => const ListDetailEmptyBehavior.hidePane(),
          NothingSelected.firstMessage => ListDetailEmptyBehavior.select(
            mail.messages.first.id,
          ),
        },
        listBuilder: (context) => const PaneSurface(child: MessageList()),
        detailBuilder: (context, id, placement) => PaneSurface(
          child: MessageDetail(
            key: ValueKey(id),
            message: mail.byId(id),
            placement: placement,
            detailsOpen: beside ? _details : null,
            onDetails: () => _showDetails(mail.byId(id)),
          ),
        ),
      ),
    );
  }
}

/// The list of messages.
class MessageList extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = ListDetailLayout.of<int>(context);
    final mail = Mail.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final padding = PaneSurface.paddingOf(context);
    // In a card, the rows keep half the card's padding outside them, so that
    // a selected row's rounded shape stays clear of the card's edges. In a
    // flat pane, the rows reach the edges, and keep the margins inside.
    final outside = PaneSurface.inCard(context) ? 0.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PaneHeader(title: 'Inbox'),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsetsDirectional.fromSTEB(outside, 0, outside, 12),
            itemCount: mail.messages.length,
            itemBuilder: (context, index) {
              final message = mail.messages[index];
              final unread = !mail.isRead(message.id);
              final weight = unread ? FontWeight.w700 : FontWeight.w400;
              return ListTile(
                contentPadding: EdgeInsetsDirectional.only(
                  start: padding.start - outside,
                  end: padding.end - outside,
                ),
                // Marked only while the detail shows beside the list.
                selected: layout.isSelected(message.id),
                selectedTileColor: colors.secondaryContainer,
                selectedColor: colors.onSecondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(child: Text(message.initials)),
                // The time moves below the sender where the two do not fit
                // on one line, as with large text.
                title: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        message.sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: weight),
                      ),
                      Text(message.received, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                subtitle: Text(
                  '${message.subject}\n${message.preview}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () => layout.select(message.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A message, with the chrome of the placement it is shown in.
///
/// The app bar and the content are the same in a pane and on a page, and
/// line up with each other alike. The bar has a back button on a page of
/// its own, and beside the list where the message can be closed,
/// which the back button then does; where the first message always shows,
/// beside the list it has none. The message keeps its state as it moves
/// between the pane and the page, so the back button stays where it is, or
/// grows in and out where it comes and goes.
class MessageDetail extends StatefulWidget {
  const new({
    super.key,
    required this.message,
    required this.placement,
    required this.detailsOpen,
    required this.onDetails,
  });

  final Message message;
  final DetailPlacement placement;

  /// Whether the details sheet beside the message is open, or null where
  /// the details open in a bottom sheet rather than beside the message.
  final bool? detailsOpen;

  final VoidCallback onDetails;

  @override
  State<MessageDetail> createState() => _MessageDetailState();
}

class _MessageDetailState extends State<MessageDetail> {
  @override
  void initState() {
    super.initState();
    // Read state lives in the store, so it survives the detail moving
    // between a pane and a page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.getInheritedWidgetOfExactType<Mail>()?.notifier?.markRead(
        widget.message.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = ListDetailLayout.of<int>(context);
    final details = IconButton(
      tooltip: widget.detailsOpen ?? false ? 'Close details' : 'Open details',
      isSelected: widget.detailsOpen,
      icon: const Icon(Icons.info_outline),
      selectedIcon: const Icon(Icons.info),
      onPressed: widget.onDetails,
    );
    final page = widget.placement == DetailPlacement.page;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Durations.medium2;
    final content = _MessageContent(message: widget.message);
    // The same app bar in a pane and on a page, with a back button
    // wherever there is something to go back to: on the page, the list it
    // pops back to; beside the list, what the inbox shows without the
    // message, which closing the message shows, returning focus to
    // the list.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: page || layout.canClose ? 1 : 0),
          duration: duration,
          curve: Easing.standard,
          // The back button grows in its slot where it comes, and the
          // title moves over to make room for it.
          builder: (context, back, _) => AppBar(
            automaticallyImplyLeading: false,
            leading: back == 0
                ? null
                : _Growing(
                    value: back,
                    child: BackButton(onPressed: page ? null : layout.close),
                  ),
            leadingWidth: kToolbarHeight * back,
            title: Text(widget.message.sender),
            actions: [details],
          ),
        ),
      ),
      body: content,
    );
  }
}

// Shows [child] at its full size, scaled and faded by [value], clipped to
// the space it has while that space grows.
class _Growing extends StatelessWidget {
  const new({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      minWidth: kToolbarHeight,
      maxWidth: kToolbarHeight,
      child: Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.5 + 0.5 * value, child: child),
      ),
    ),
  );
}

class _MessageContent extends StatelessWidget {
  const new({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = PaneSurface.paddingOf(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        padding.start,
        8,
        padding.end,
        24,
      ),
      children: [
        Text(message.subject, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(child: Text(message.initials)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.sender, style: theme.textTheme.titleSmall),
                  Text(
                    'To me · ${message.received}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final paragraph in message.body)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LineLength(
              characters: Settings.of(context).lineLength,
              style: theme.textTheme.bodyLarge,
              child: Text(paragraph, style: theme.textTheme.bodyLarge),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.reply),
              label: const Text('Reply'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.forward),
              label: const Text('Forward'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The details of a message, for the side sheet or the bottom sheet.
class MessageDetails extends StatelessWidget {
  const new({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('From', '${message.sender} <${message.address}>'),
          row('To', 'me@example.com'),
          row('Received', message.received),
          row('Subject', message.subject),
          if (message.labels.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final label in message.labels) Chip(label: Text(label)),
              ],
            ),
        ],
      ),
    );
  }
}

class _NothingSelected extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('Select a message to read it', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
