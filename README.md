# material_layout

Material 3 adaptive layouts for Flutter: the canonical list-detail, supporting-pane and feed layouts, adaptive navigation placement, resizable panes, adaptive sheets and foldable support.

## Scope

Supported:

* The three canonical layouts: list-detail, supporting pane, feed — each
  adapting to the space it is given.
* Navigation placement: a bottom bar or a navigation rail, selected by window
  size class and pane count, with an animated swap.
* Resizable panes: drag, magnet snapping, double-tap collapse, keyboard and
  screen-reader support. A resize is either remembered or released back to the
  default split.
* Show/hide and reflow: a pane that no longer fits leaves over the trailing
  edge or reflows below the content.
* Adaptive sheets: side or bottom by width, standard (persistent) or modal,
  dismissible by drag.
* Foldables: the split snaps onto a vertical hinge when one is reported.
* Configurable defaults: breakpoints, margins and gutters per subtree; pane
  widths, surfaces and motion per widget. RTL throughout.

Not supported:

* Floating and docked panes (Material's levitate strategy). Panes are
  co-planar; use a sheet or dialog for content above the plane.
* A dedicated three-pane API. A third pane is produced by nesting two layouts.
* Vertical resizing. Only side-by-side splits are resizable.
* The navigation bar and rail components. This package positions the widgets
  passed to it.
* Persistence. Pane widths serialise to JSON; storing them is the
  application's responsibility.

## Getting started

Requires Flutter 3.44 or later.

```sh
flutter pub add material_layout material_ui
```

[`material_ui`](https://pub.dev/packages/material_ui) is the Material library
decoupled from the Flutter framework. This package resolves `Theme` from it, so
the application must build its `MaterialApp` and `ThemeData` from `material_ui`
as well — a theme supplied through `package:flutter/material.dart` is not
visible to these widgets. To convert an existing application, follow
[`material_ui`'s migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package).

## Demo

[`demo/`](demo/) is a runnable application exercising every layout; resizing
the window shows the adaptation.

## Canonical layouts

Each layout adapts on the region it occupies, so it works nested as well as
full screen. The widths Material defines per breakpoint — the fixed pane's
360/412dp, the even split below expanded — are resolved against the window.

### List-detail

A collection beside the item selected from it.

```dart
ListDetailLayout(
  listBuilder: (context) => ListView(
    children: [
      for (final message in messages)
        ListTile(
          title: Text(message.subject),
          onTap: () => ListDetail.of(context).select(message.id),
        ),
    ],
  ),
  detailBuilder: (context, id) => MessageView(id: id as int),
);
```

* One pane below `twoPaneBreakpoint`, two at and above it. It defaults to the
  expanded breakpoint: Material 3 recommends a single pane at medium and allows
  two, and a lower `twoPaneBreakpoint` takes that option, where the panes split
  evenly.
* With one pane, selecting an item pushes the detail as a route, so the system
  Back button returns to the list.
* With two, the detail pane's width animates in, and selecting another item
  replaces its content without animating it.
* Narrowing past the breakpoint moves the detail off the trailing edge rather
  than removing it in a single frame.
* Selection is state, so it survives resizes, rotations and unfolding. It can
  be uncontrolled, controlled (`selectedId` with `onSelectionChanged`), or
  driven by a `ListDetailController`; leaf widgets call
  `ListDetail.of(context).select(id)` in all three cases.
* `behavior` selects what an empty detail pane shows.

### Supporting pane

Content that is meaningful only alongside the primary content.

```dart
SupportingPaneLayout(
  content: ArticleView(article: article),
  supporting: RelatedPeople(article: article),
);
```

* Expanded and wider: beside the content, at the Material fixed pane width.
* Compact and medium: the pane reflows below the content rather than being
  dropped.
* Short regions: hidden, since there is no room to stack.
* Placement is a pure function of the region, so a resize re-evaluates it; a
  custom `resolver` decides otherwise.
* `dismissible: true` makes the pane on-demand rather than always present.

### Feed

Equivalently weighted items in a grid that reflows by column count.

```dart
FeedLayout(
  itemCount: articles.length,
  itemBuilder: (context, i) => ArticleCard(article: articles[i]),
);
```

* Compact: a single full-width column.
* Wider: the column count is derived from the available width and
  `maxItemWidth` rather than fixed per breakpoint.

## Navigation placement

`AdaptiveNavigationScaffold` chooses between the widgets passed to it: a bottom
bar at compact, a rail at expanded and wider, and a bar on short windows
whatever their width. At medium it follows Material 3's pane-count rule — a
rail for a single-pane body, a bottom bar when the body itself holds two panes,
which `paneCount` declares.

```dart
AdaptiveNavigationScaffold(
  paneCount: 2, // the body is a two-pane layout
  navigationBar: NavigationBar(/* … */),
  navigationRail: NavigationRail(/* … */),
  body: ListDetailLayout(/* … */),
);
```

`material_ui`'s `NavigationBar` and `NavigationRail` fit the slots directly.
For the Material 3 Expressive components, the companion package
[`material_navigation`](https://pub.dev/packages/material_navigation) provides
a bottom bar whose items morph between vertical and horizontal, a rail that
collapses and expands (inline or modal) and re-aligns a FAB as it does, and
reusable destinations. The packages are independent; either can be adopted
alone.

## Common cases

### Retuning the defaults

Breakpoints, margins and the pane gutter are set for a subtree; pane widths,
surfaces and motion are arguments on the widget.

```dart
AdaptiveLayoutTheme(
  data: const AdaptiveLayoutThemeData(
    breakpoints: Breakpoints(mediumMinWidth: 700, expandedMinWidth: 1000),
    spacing: AdaptiveSpacing(paneGutter: 16),
  ),
  child: MyApp(),
);
```

### Persisting a pane width

`PaneController` holds the split as a fraction and serialises to JSON.

```dart
final split = PaneController.fromJson(jsonDecode(stored));
split.addListener(() => save(jsonEncode(split.toJson())));

ListDetailLayout(resizable: true, paneController: split, /* … */);
```

### Driving the selection from a router

`selectedId` with `onSelectionChanged` puts the layout in controlled mode, so
the route is the source of truth.

```dart
ListDetailLayout(
  selectedId: state.pathParameters['id'],
  onSelectionChanged: (id) =>
      id == null ? context.go('/inbox') : context.go('/inbox/$id'),
  // …
);
```

### Surfacing a pane that has no room

Where the resolver returns `hidden`, present the same content as a sheet: a
side sheet on wide windows, a bottom sheet on narrow ones. With
`dismissible: true`, the same control shows and hides the pane where there is
room for it.

```dart
final pane = SupportingPane.of(context);
pane.presentation.isVisible
    ? pane.toggle()
    : pane.presentAsSheet<void>(context);
```

Sheets are also usable on their own, standard (no scrim, content stays
interactive) or modal:

```dart
showAdaptiveSheet<void>(
  context,
  mode: SheetMode.standard,
  builder: (context) => const FiltersPanel(),
);
```

### Painting the panes

The layouts size panes but do not paint them. `PaneContainer` applies a
Material 3 surface container role, the corner radius, and an ink surface.

```dart
ListDetailLayout(
  listBuilder: (context) =>
      PaneContainer(level: PaneLevel.low, child: MessageList()),
  detailBuilder: (context, id) => PaneContainer(child: MessageView(id: id)),
);
```

### Adapting anything else

`AdaptiveBuilder` rebuilds on size-class changes — against the window, or the
enclosing box with `useLocalSize: true`. `adaptiveValue` selects a value for a
size class, falling back to the nearest smaller one given.

```dart
AdaptiveBuilder(
  useLocalSize: true,
  builder: (context, size) => GridView.count(
    crossAxisCount: adaptiveValue<int>(
      size.widthClass,
      compact: 1,
      expanded: 2,
      large: 3,
    ),
    children: cards,
  ),
);
```

## License

MIT — see [LICENSE](LICENSE).
