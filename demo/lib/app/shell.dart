// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import '../widgets/panes.dart';
import 'settings.dart';

/// The demo's top-level destinations: its own four, and those that the
/// navigation settings add, so that the rail and the bar can carry more
/// destinations than Material recommends.
enum Destination {
  inbox(Icons.inbox_outlined, Icons.inbox, 'Inbox', 'Inbox and messages'),
  articles(
    Icons.article_outlined,
    Icons.article,
    'Articles',
    'Articles and reading lists',
  ),
  feed(
    Icons.dashboard_outlined,
    Icons.dashboard,
    'Feed',
    'Feed of the latest articles',
  ),
  layout(
    Icons.straighten_outlined,
    Icons.straighten,
    'Layout',
    'Layout of this window',
  ),
  explore(
    Icons.explore_outlined,
    Icons.explore,
    'Explore',
    'Explore nearby places',
  ),
  saved(Icons.bookmark_border, Icons.bookmark, 'Saved', 'Saved for later'),
  favourites(
    Icons.favorite_border,
    Icons.favorite,
    'Favourites',
    'Favourite collections',
  ),
  alerts(
    Icons.notifications_outlined,
    Icons.notifications,
    'Alerts',
    'Notifications and alerts',
  ),
  profile(Icons.person_outline, Icons.person, 'Profile', 'Profile and account'),
  calendar(
    Icons.calendar_month_outlined,
    Icons.calendar_month,
    'Calendar',
    'Calendar and events',
  ),
  photos(Icons.photo_outlined, Icons.photo, 'Photos', 'Photos and albums'),
  music(
    Icons.music_note_outlined,
    Icons.music_note,
    'Music',
    'Music and podcasts',
  ),
  chats(
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
    'Chats',
    'Chats and groups',
  ),
  maps(Icons.map_outlined, Icons.map, 'Maps', 'Maps and directions'),
  help(Icons.help_outline, Icons.help, 'Help', 'Help and feedback'),
  about(Icons.info_outline, Icons.info, 'About', 'About this app');

  const new(this.icon, this.selectedIcon, this.label, this.longLabel);

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// A longer label, which the settings swap in to try labels that do not
  /// fit.
  final String longLabel;

  /// The destination's path under the router.
  String get path => '/$name';

  /// Whether the destination is one that the navigation settings add, a
  /// placeholder past the demo's own.
  bool get isExtra => index > layout.index;
}

/// Places navigation around the current destination.
///
/// The bar and the rail are `material_navigation`'s Material 3 Expressive
/// components, which `NavigationScaffold` places, as Material prescribes
/// unless the settings choose another placement: a navigation bar at
/// compact, and at medium when the inbox shows two panes, with its items
/// beside their labels at medium; a rail otherwise, expanded from large
/// upwards. The
/// rail's menu button expands and collapses it: in place from
/// large upwards, and below large as a modal over the content, so that the
/// panes do not reflow.
///
/// The settings change all of it: how many destinations each component
/// carries and how they are labelled, how the rail expands and what its
/// slots hold, the bar's width and layout, and every token of their styles.
class DemoShell extends StatefulWidget {
  const new({
    super.key,
    required this.destination,
    required this.onDestinationSelected,
    required this.body,
  });

  final Destination destination;
  final ValueChanged<Destination> onDestinationSelected;
  final Widget body;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  // What the settings ask of the rail: whether it is expanded, and why.
  ({RailExpansion expansion, bool expanded})? _asked;

  // Whether the rail is expanded in place, as the settings ask when they
  // change, and as its menu button leaves it in between. A change of what
  // the settings ask reseeds it, however the menu button left it
  // (NavigationRail.expanded).
  var _railExpanded = false;

  static Breakpoint _windowOf(BuildContext context) =>
      MaterialLayoutTheme.of(context).breakpoints
          .forWidth(MediaQuery.sizeOf(context).width);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expansion = Settings.of(context).railExpansion;
    final asked = (
      expansion: expansion,
      expanded: switch (expansion) {
        RailExpansion.byWindow => _windowOf(context) >= Breakpoint.large,
        RailExpansion.expanded => true,
        RailExpansion.collapsed => false,
      },
    );
    if (asked != _asked) {
      _asked = asked;
      _railExpanded = asked.expanded;
    }
  }

  // The menu button expands or collapses the rail in place.
  void _toggleRail() {
    final expanded = !_railExpanded;
    setState(() => _railExpanded = expanded);
    // A setting of expanded or collapsed follows the menu button, so that
    // choosing it again applies it.
    final settings = Settings.controllerOf(context);
    final expansion = settings.value.railExpansion;
    if (expansion == RailExpansion.byWindow) return;
    final now = expanded ? RailExpansion.expanded : RailExpansion.collapsed;
    if (now != expansion) {
      settings.value = settings.value.copyWith(railExpansion: now);
    }
  }

  void _showSecondary(String label) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label is a placeholder, among the destinations the expanded '
            'rail shows below its own (expandedBody).',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settings = Settings.of(context);
    final window = _windowOf(context);
    final destination = widget.destination;
    final inbox = destination == Destination.inbox;
    void select(int index) =>
        widget.onDestinationSelected(Destination.values[index]);
    List<NavigationDestination> destinations(int count) => [
      for (final destination in Destination.values.take(count))
        NavigationDestination(
          icon: Icon(destination.icon),
          selectedIcon: Icon(destination.selectedIcon),
          label: settings.navigationLongLabels
              ? destination.longLabel
              : destination.label,
          tooltip: settings.navigationTooltips
              ? 'Go to ${destination.label}'
              : null,
          enabled:
              !settings.navigationSecondDisabled ||
              destination != Destination.articles,
        ),
    ];
    final modalMenu = switch (settings.railMenu) {
      RailMenu.byWindow => window < Breakpoint.large,
      RailMenu.modal => true,
      RailMenu.inPlace => false,
    };

    // Panes are cards on this background from medium up; in a compact
    // window they are flat, and the background matches them.
    final flat = panesFlat(context);
    return NavigationScaffold(
      placementRule: settings.placementRule,
      paneCount: settings.paneCount,
      motion: settings.navigationMotion,
      backgroundColor: flat ? colors.surface : colors.surfaceContainer,
      // As narrow as the settings make it, centred.
      navigationBar: Align(
        heightFactor: 1,
        child: FractionallySizedBox(
          widthFactor: settings.barWidthFactor,
          child: NavigationBar(
            // Past its own destinations, a bar marks none, as a rail does.
            selectedIndex: destination.index,
            onDestinationSelected: select,
            itemLayout: switch (settings.barLayout) {
              BarLayout.byWindow =>
                window >= Breakpoint.medium
                    ? NavigationBarItemLayout.horizontal
                    : NavigationBarItemLayout.vertical,
              BarLayout.vertical => NavigationBarItemLayout.vertical,
              BarLayout.horizontal => NavigationBarItemLayout.horizontal,
            },
            labelBehavior: settings.barLabelBehavior,
            style: settings.barStyleIn(context),
            backgroundColor: colors.surfaceContainer,
            destinations: destinations(settings.barCount),
          ),
        ),
      ),
      navigationRail: NavigationRail(
        // Past its own destinations, a rail marks none.
        selectedIndex: destination.index < settings.railCount
            ? destination.index
            : null,
        onDestinationSelected: select,
        expanded: _railExpanded,
        labelType: settings.railLabelType,
        style: settings.railStyleIn(context),
        backgroundColor: colors.surfaceContainer,
        // The menu button collapses an expanded rail, and expands a
        // collapsed one in place, or opens it as a modal: what the button
        // does without an onPressed of its own.
        leading: NavigationMenuButton(
          onPressed: _railExpanded || !modalMenu ? _toggleRail : null,
        ),
        // The destinations stay put when the compose button comes and goes.
        floatingActionButton: !settings.railFab
            ? null
            : inbox
            ? const _RailComposeButton()
            : const SizedBox.square(dimension: 56),
        trailing: settings.railTrailing ? const _ThemeSwitch() : null,
        expandedBody: settings.railExpandedBody
            ? _RailSections(onSelected: _showSecondary)
            : null,
        destinations: destinations(settings.railCount),
      ),
      floatingActionButton: inbox ? const _BarComposeButton() : null,
      body: SafeArea(
        left: false,
        right: false,
        // Cards keep clear of the top and bottom edges as well.
        minimum: flat
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 12),
        child: widget.body,
      ),
    );
  }
}

class _RailComposeButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: null,
    elevation: 0,
    tooltip: 'Compose',
    onPressed: () => showCompose(context),
    child: const Icon(Icons.edit_outlined),
  );
}

// The compose button belongs to the rail when there is one, so the floating
// one shows only beside the navigation bar.
class _BarComposeButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    if (NavigationScaffold.placementOf(context) != NavigationPlacement.bar) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      tooltip: 'Compose',
      onPressed: () => showCompose(context),
      child: const Icon(Icons.edit_outlined),
    );
  }
}

// A destination below the rail's own, which switches between the light and
// dark themes. Outside the rail's destinations, it still takes their layout
// and style, and follows the rail as it expands.
class _ThemeSwitch extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final settings = Settings.controllerOf(context);
    final dark = settings.value.dark;
    return Padding(
      // Vertical only: padding at the sides would narrow the item below the
      // collapsed rail's width, and squeeze its icon aside.
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: NavigationDestination(
        icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        label: dark ? 'Light theme' : 'Dark theme',
        onTap: () => settings.value = settings.value.copyWith(dark: !dark),
      ),
    );
  }
}

// Secondary destinations, which the expanded rail shows below its own. They
// follow the rail as it expands, as its destinations do, and choosing one
// closes a modal rail, as choosing one of its destinations does.
class _RailSections extends StatelessWidget {
  const new({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _sections = [
    (
      'Mailboxes',
      [
        (Icons.star_outline, 'Starred'),
        (Icons.send_outlined, 'Sent'),
        (Icons.drafts_outlined, 'Drafts'),
      ],
    ),
    (
      'Labels',
      [
        (Icons.label_outline, 'Family'),
        (Icons.label_outline, 'Work'),
        (Icons.label_outline, 'Travel'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rail = NavigationRail.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (title, items) in _sections) ...[
          const Divider(indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(36, 8, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final (icon, label) in items)
            NavigationDestination(
              icon: Icon(icon),
              label: label,
              onTap: () {
                if (rail.isModalOpen) rail.closeModal();
                onSelected(label);
              },
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
