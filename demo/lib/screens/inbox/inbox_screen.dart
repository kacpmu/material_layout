import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'package:demo/data/demo_data.dart';
import 'package:demo/screens/inbox/filters_sheet.dart';
import 'package:demo/screens/inbox/info_pane.dart';
import 'package:demo/shell/demo_shell.dart';

/// Inbox — the screen that exercises the most of the package.
///
/// Demonstrates: `ListDetailLayout`, `SupportingPaneLayout`, a custom
/// `SupportingPaneResolver`, `PaneContainer`, and `showAdaptiveSheet`.
///
/// A canonical list-detail, wrapped in a supporting pane so it becomes a
/// **three-pane** layout on the widest windows.
///
/// * narrow — one pane (tapping a message pushes a real detail page)
/// * wide — list + detail, resizable
/// * extra-large — filters + list + detail
///
/// Material 3 reserves three panes for the extra-large breakpoint ("the
/// extra-large breakpoint supports using a standard side sheet as a third
/// pane… Don't use more than three panes"), so the filters pane is placed by a
/// custom [SupportingPaneResolver] rather than the package default — below
/// 1600dp it resolves to `hidden` and the filter button opens it as an adaptive
/// sheet instead.
class InboxScreen extends StatefulWidget {
  const InboxScreen({
    super.key,
    required this.resizable,
    required this.behavior,
    required this.dismissible,
    this.selectedId,
    this.onSelectionChanged,
  });

  final bool resizable;
  final ListDetailBehavior behavior;

  /// Whether the filters pane is shown on demand rather than always present.
  /// Mirrors the demo's "Dismissible supporting pane" setting, the same one
  /// the Articles screen honours.
  final bool dismissible;

  /// When provided together with [onSelectionChanged], selection is *controlled*
  /// — e.g. driven by the URL in the GoRouter demo. Left null, the layout
  /// manages selection itself (the default demo).
  final Object? selectedId;
  final ValueChanged<Object?>? onSelectionChanged;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  /// The selection when nobody outside owns it. In the GoRouter entrypoint the
  /// URL owns it instead and this stays null.
  Object? _localId;

  bool get _externallyDriven => widget.onSelectionChanged != null;

  Object? get _selectedId => _externallyDriven ? widget.selectedId : _localId;

  /// The id whose content is actually on screen, including the `selected`
  /// behaviour's fall-back to [_initialId] — which is what the info pane needs
  /// to describe.
  Object? get _shownId => _selectedId ?? _initialId;

  Object? get _initialId => widget.behavior == ListDetailBehavior.selected
      ? demoItems.first.id
      : null;

  void _onSelectionChanged(Object? id) {
    if (_externallyDriven) {
      widget.onSelectionChanged!(id);
    } else {
      setState(() => _localId = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _shownId;
    return SupportingPaneLayout(
      resolver: _infoOnlyAtExtraLarge,
      dismissible: widget.dismissible,
      // M3 notes the tension here: fixed panes at this breakpoint want 412dp,
      // "but side sheets have a default maximum width of 400dp". The third pane
      // is a side sheet, so 400 wins.
      fixedPaneWidth: 400,
      supporting: InfoPane(item: id == null ? null : demoItemById(id)),
      content: _buildListDetail(context),
    );
  }

  /// Three panes only at extra-large; everywhere else the filters are a sheet.
  ///
  /// Note this deliberately reads `context.windowSizeClass` and **ignores** the
  /// `widthClass` argument. That argument classifies the *region* the layout
  /// occupies — here the body, already shortened by the navigation rail — so at
  /// a 1600dp window it reports `large` and the third pane would never appear.
  /// "Extra-large" is a breakpoint, and breakpoints describe the window.
  static SupportingPanePresentation _infoOnlyAtExtraLarge(
    BuildContext context,
    BoxConstraints region,
    WindowSizeClass widthClass,
    WindowHeightSizeClass heightClass,
  ) {
    return context.windowSizeClass.isAtLeast(WindowSizeClass.extraLarge)
        ? SupportingPanePresentation.trailing
        : SupportingPanePresentation.hidden;
  }

  Widget _buildListDetail(BuildContext context) {
    return ListDetailLayout(
      resizable: widget.resizable,
      behavior: widget.behavior,
      // Always controlled from here, so the supporting pane can follow the
      // selection — a sibling of the ListDetailLayout cannot reach
      // ListDetail.of(context).
      selectedId: _selectedId,
      onSelectionChanged: _onSelectionChanged,
      // Only `selected` needs a fall-back id; `placeholder` and `hidden`
      // should open on the list / placeholder.
      initialId: _initialId,
      listBuilder: (context) {
        final selectedId = ListDetail.of(context).selectedId;
        // The drawer hamburger stands in for a navigation rail, so it belongs
        // on screen exactly when there is no rail — which is not the same as
        // "narrow". Material 3 gives a single-pane *medium* layout a rail too,
        // and a short window a bar however wide it is. Asking the same resolver
        // the scaffold uses is the only way to stay in step with it.
        final showMenu = materialNavigationTypeResolver()(
              context.windowSize,
              demoPaneCount,
            ) ==
            NavigationType.bar;
        // On compact widths ListDetailLayout pushes this pane as a real page,
        // and the route's transition paints a background behind it. Give the
        // list its own (transparent) Material so the tiles' ink and selection
        // highlight land above that background rather than being hidden by it.
        return Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SearchBar(
                  elevation: const WidgetStatePropertyAll(0),
                  leading: showMenu
                      ? IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Open navigation',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        )
                      : const Padding(
                          padding: EdgeInsets.only(left: 12.0, right: 8),
                          child: Icon(Icons.search),
                        ),
                  hintText: 'Search...',
                  trailing: [
                    // Filters act on the *list*, not on one message, so they
                    // are not a supporting pane. A **standard** sheet keeps the
                    // list usable while they are open — a side sheet on wide
                    // windows, a bottom sheet on narrow ones.
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filters',
                      onPressed: () => showAdaptiveSheet<void>(
                        context,
                        mode: SheetMode.standard,
                        builder: (_) => const FiltersSheet(),
                      ),
                    ),
                    SizedBox(width: 4),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: demoItems.length,
                  itemBuilder: (context, i) {
                    final item = demoItems[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        isThreeLine: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.all(Radius.circular(16))
                        ),
                        selected: item.id == selectedId,
                        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                        leading: CircleAvatar(backgroundColor: Colors.blueGrey, child: Text(item.sender[0])),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.sender,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.fromDateTime(item.sentAt),
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            // Two lines of the message itself.
                            Text(
                              item.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        onTap: () => ListDetail.of(context).select(item.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      detailBuilder: (context, id) => PaneContainer(
        // Flush at compact, where the detail is a full-screen pushed page
        // rather than one pane among several.
        borderRadius: context.windowSizeClass.isExpandedOrWider
            ? kPaneBorderRadius
            : BorderRadius.zero,
        child: _MessageDetail(
          item: demoItemById(id),
          paneDismissible: widget.dismissible,
        ),
      ),
    );
  }
}

class _MessageDetail extends StatelessWidget {
  const _MessageDetail({required this.item, required this.paneDismissible});

  final DemoItem item;

  /// Whether the info pane can be toggled. A permanent pane cannot, so the
  /// action would be dead and is left out.
  final bool paneDismissible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final selection = ListDetail.of(context);
    // App-bar leading: an automatic Back button when this is a pushed page
    // (narrow); an explicit close that clears the selection when it's the inline
    // pane (wide) — except under `selected`, where there is no empty state to
    // clear to. `behavior` comes from the layout via the scope (no prop-drill).
    final canPop = Navigator.of(context).canPop();
    final Widget? leading = canPop
        ? null // pushed page → AppBar adds a Back button automatically
        : selection.behavior == ListDetailBehavior.selected
        ? null // wide + `selected` → nothing to close to
        : IconButton(
            icon: const Icon(Icons.close),
            padding: const EdgeInsets.all(16),
            tooltip: 'Close',
            onPressed: selection.clear,
          );
    return Scaffold(
      // The PaneContainer around this is what paints the pane; an opaque
      // Scaffold would cover it.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        leading: leading,
        title: Text(item.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // The supporting pane describes *this* message, so its affordance
          // belongs here rather than beside the list's search field.
          Builder(
            builder: (context) {
              final pane = SupportingPane.of(context);
              final beside = pane.presentation.isBeside;
              // Beside and permanent → always on screen, nothing to toggle.
              if (beside && !paneDismissible) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.info_outline),
                isSelected: beside && pane.visible,
                tooltip: 'Message details',
                onPressed: () => beside
                    ? pane.toggle()
                    : pane.presentAsSheet<void>(context),
              );
            },
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
          const SizedBox(width: 4),
        ],
      ),
      body: AdaptiveBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.blueGrey, child: Text(item.sender[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.sender, style: theme.textTheme.titleMedium),
                      Text(
                        '${localizations.formatFullDate(item.sentAt)} · '
                        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(item.sentAt))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(item.subject, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(item.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
