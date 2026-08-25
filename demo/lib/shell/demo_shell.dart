/// The demo's navigation chrome, shared by both entrypoints.
///
/// Demonstrates: `AdaptiveNavigationScaffold`, `adaptiveValue`, and
/// `context.windowSizeClass`.
library;

import 'package:material_layout/material_layout.dart';
import 'package:flutter/material.dart'
    hide NavigationBar, NavigationRail, NavigationDestination;
import 'package:material_navigation/material_navigation.dart';

import 'package:demo/data/demo_settings.dart';
import 'package:demo/shell/animated_fab.dart';
import 'package:demo/shell/animated_menu_button.dart';
import 'package:demo/shell/settings_sheet.dart';

/// How many panes the demo's body shows side by side at the **medium**
/// breakpoint.
///
/// Material 3 picks the medium navigation surface by pane count — a rail for
/// one pane, a bar for two — so [AdaptiveNavigationScaffold] needs to be told.
/// The Inbox only splits into two panes above a 720dp *region*, which is past
/// medium, so one is correct here. Screens read it to work out whether a rail
/// is on screen.
const int demoPaneCount = 1;

/// The four demo destinations, shared by both entrypoints.
const List<NavigationDestination> demoDestinations = [
  NavigationDestination(
    icon: Icon(Icons.inbox_outlined),
    selectedIcon: Icon(Icons.inbox),
    label: 'Inbox',
  ),
  NavigationDestination(
    icon: Icon(Icons.article_outlined),
    selectedIcon: Icon(Icons.article),
    label: 'Articles',
  ),
  NavigationDestination(
    icon: Icon(Icons.grid_view_outlined),
    selectedIcon: Icon(Icons.grid_view),
    label: 'Feed',
  ),
  NavigationDestination(
    icon: Icon(Icons.layers_outlined),
    selectedIcon: Icon(Icons.layers),
    label: 'Sheets',
  ),
];

/// One secondary navigation entry — a mailbox or a folder.
typedef DemoSecondary = ({IconData icon, String label, int? count});

/// A titled group of [DemoSecondary] entries.
typedef DemoSection = ({String title, List<DemoSecondary> items});

/// The secondary navigation, defined once and rendered in **two** places: the
/// expanded rail's body and Flutter's drawer on compact. Sharing the data is
/// what keeps the two from drifting apart — the widgets differ because each
/// surface demands its own destination type, but the content cannot.
const List<DemoSection> demoSections = [
  (
    title: 'Mailboxes',
    items: [
      (icon: Icons.send_outlined, label: 'Sent', count: null),
      (icon: Icons.delete_outline, label: 'Trash', count: 12),
      (icon: Icons.report_gmailerrorred_outlined, label: 'Spam', count: 3),
    ],
  ),
  (
    title: 'Folders',
    items: [
      (icon: Icons.folder_outlined, label: 'Receipts', count: 8),
      (icon: Icons.folder_outlined, label: 'Travel', count: null),
    ],
  ),
];

/// How many secondary entries there are in total — the drawer needs it to know
/// where its own indices stop being primary destinations.
int get demoSecondaryCount =>
    demoSections.fold(0, (n, section) => n + section.items.length);

/// The entry's icon, carrying its unread count as a [Badge] when it has one —
/// neither destination type has a trailing slot, and a badge is the Material
/// idiom for a count on a navigation destination.
Widget demoSecondaryIcon(DemoSecondary item) => item.count == null
    ? Icon(item.icon)
    : Badge.count(count: item.count!, child: Icon(item.icon));

/// A section title, styled the same in both surfaces.
Widget demoSectionHeader(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );

/// Opens the demo settings in an adaptive sheet — a side sheet on wide windows,
/// a bottom sheet on narrow ones.
Future<void> openDemoSettings(BuildContext context) {
  final scope = DemoSettingsScope.of(context);
  return showAdaptiveSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) =>
        SettingsSheet(settings: scope.settings, onChanged: scope.onChanged),
  );
}

/// The demo's navigation chrome — bar, rail, and drawer — around whatever
/// [body] the entrypoint supplies.
///
/// Both `main_navigator.dart` and `main_router.dart` render **this**, so the
/// two apps look and behave identically. The only thing that differs between
/// them is how a destination change is carried out: `setState` over an
/// `IndexedStack` in one, `StatefulShellRoute.goBranch` (with the selection in
/// the URL) in the other. That difference lives entirely in [selectedIndex],
/// [onDestinationSelected] and [body] — nothing about the chrome knows which
/// strategy is in play.
class DemoShell extends StatelessWidget {
  const DemoShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final settings = DemoSettingsScope.of(context).settings;
    // Read the window size class through the package's own context extension,
    // so the shell adapts off exactly the breakpoints the scaffold uses.
    final sizeClass = context.windowSizeClass;

    return AdaptiveNavigationScaffold(
      paneCount: demoPaneCount,
      navigationBar: NavigationBar(
        // Stack icon over label on a phone; once there is room at medium, lay
        // each item out horizontally instead. `adaptiveValue` resolves down to
        // the nearest smaller class, so medium's value also covers expanded+.
        layoutDirection: adaptiveValue(
          sizeClass,
          compact: Axis.vertical,
          medium: Axis.horizontal,
        ),
        labelBehavior: NavigationLabelBehavior.all,
        destinations: demoDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
      navigationRail: NavigationRail(
        destinations: demoDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        expandedIndicatorSize: settings.railIndicatorSize,
        motion: NavigationMotion.expressive(),
        labelBehavior: NavigationLabelBehavior.all,
        leading: Builder(
          builder: (context) => AnimatedMenuButton(
            // The same hamburger opens the rail inline or as a modal overlay,
            // per the demo toggle — the rail decides nothing itself.
            onPressed: () => settings.modalRail
                ? NavigationRail.of(context).toggleModal()
                : NavigationRail.of(context).toggle(),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => AnimatedFab(
            animation: NavigationRail.of(context).expandAnimation,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Compose'),
            tooltip: 'Compose',
            onPressed: () {},
          ),
        ),
        // Revealed below the destinations only when the rail is expanded —
        // the secondary navigation an expanded rail has room for.
        expandedBody: const _RailSections(),
        trailing: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NavigationDestination(
              onTap: () => openDemoSettings(context),
              icon: const Icon(Icons.settings),
              label: 'Settings',
              expandAnimation: NavigationRail.of(context).expandAnimation,
            ),
          ),
        ),
      ),
      // Opened by the hamburger in the Inbox search bar, or an edge swipe.
      //
      // Carries the same secondary navigation as the expanded rail's body, from
      // the same `demoSections` data — the drawer is what stands in for that
      // rail on compact, so it would be odd for the two to disagree.
      drawer: Builder(
        builder: (context) {
          // NavigationDrawer indexes only its NavigationDrawerDestination
          // children, in order, skipping headers and dividers. Primary
          // destinations come first, then the sections, then Settings last.
          final settingsIndex = demoDestinations.length + demoSecondaryCount;
          return NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) {
              if (i < demoDestinations.length) {
                onDestinationSelected(i);
              } else if (i == settingsIndex) {
                openDemoSettings(context);
              }
              // The section entries are decorative in this demo; tapping one
              // just closes the drawer.
              Scaffold.of(context).closeDrawer();
            },
            children: [
              for (final d in demoDestinations)
                NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
              for (final section in demoSections) ...[
                const Divider(indent: 28, endIndent: 28),
                demoSectionHeader(context, section.title),
                for (final item in section.items)
                  NavigationDrawerDestination(
                    icon: demoSecondaryIcon(item),
                    label: Text(item.label),
                  ),
              ],
              const Divider(indent: 28, endIndent: 28),
              const NavigationDrawerDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          );
        },
      ),
      body: body,
    );
  }
}

/// The secondary navigation revealed inside an expanded navigation rail.
///
/// Real [NavigationDestination]s rather than list tiles, so they pick up the
/// same indicator, sizing and morph as the rail's primary destinations — and
/// they take the rail's expand animation, so labels arrive in step with it.
class _RailSections extends StatelessWidget {
  const _RailSections();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final expand = NavigationRail.of(context).expandAnimation;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, section) in demoSections.indexed) ...[
              if (index > 0)
                const Divider(height: 16, indent: 28, endIndent: 28),
              demoSectionHeader(context, section.title),
              for (final item in section.items)
                NavigationDestination(
                  icon: demoSecondaryIcon(item),
                  label: item.label,
                  expandAnimation: expand,
                  onTap: () {},
                ),
            ],
          ],
        );
      },
    );
  }
}
