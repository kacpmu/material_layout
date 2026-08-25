# material_layout

Material 3 adaptive layouts for Flutter.

**Supported**

* The three canonical layouts — **list-detail**, **supporting pane**, **feed** —
  each adapting on its own from one pane to three.
* **Navigation placement** — a bottom bar or a rail, chosen by breakpoint and
  animated across the swap.
* **Resizable panes** — drag, magnet-snap, double-tap to collapse, with widths
  either carried across breakpoints or reset at each one.
* **Show-and-hide and reflow** — a pane that no longer fits slides off the edge
  or stacks below the content rather than disappearing between frames.
* **Adaptive sheets** — side or bottom by width, standard (persistent) or modal,
  draggable away.
* **Foldables** — the split snaps onto a vertical hinge when one is present.
* **Retunable Material defaults** — breakpoints, margins, pane widths, surfaces
  and motion, per subtree or per widget. RTL throughout.

**Not supported**

* **Floating and docked panes** — Material's *levitate* strategy. Panes here are
  co-planar; a sheet or a dialog covers content that hovers.
* **A first-class three-pane API** — a third pane is composed by nesting two
  layouts. Material caps the count at three.
* **Vertical resizing** — a supporting pane that has reflowed below the content
  has no drag handle; only side-by-side splits are resizable.
* **The navigation bar and rail themselves** — this package places the widgets
  passed to it. See [Navigation components](#navigation-components).
* **Persistence** — pane widths serialise to JSON; storing and restoring them is
  the application's responsibility.

## Getting started

```sh
flutter pub add material_layout
```

```dart
import 'package:material_layout/material_layout.dart';
```

Nothing needs initialising. The layouts read the window size from `MediaQuery`
and their own region from the enclosing constraints, so they work anywhere —
full screen, inside a pane, or inside another layout.

The defaults are Material's breakpoints (600 / 840 / 1200 / 1600dp), margins,
pane widths and spacers. Retuning them for a whole subtree takes a wrapper:

```dart
AdaptiveLayoutTheme(
  data: const AdaptiveLayoutThemeData(
    breakpoints: Breakpoints(mediumMinWidth: 700, expandedMinWidth: 1000),
    spacing: AdaptiveSpacing(paneGutter: 16),
  ),
  child: MyApp(),
);
```

Every theme value can also be set on a single widget, and every animation the
package runs can be re-timed or replaced.

A runnable app exercising all of this lives in [`demo/`](demo/); resizing the
window shows the adaptation. The entry point is `demo/lib/main_navigator.dart`.

## Navigation components

This package decides *where* navigation goes and animates the swap; it does not
draw the bar or the rail. Placement is a layout concern, and the components are
a component concern.

Flutter's own `NavigationBar` and `NavigationRail` drop straight into the slots.
For the Material 3 **Expressive** versions, the companion package
[**`material_navigation`**](https://pub.dev/packages/material_navigation) is the
recommended pairing:

```sh
flutter pub add material_navigation
```

It provides a bottom bar whose items morph between vertical and horizontal, a
rail that collapses and expands (inline or modal) with an extended FAB, and
reusable destinations for building custom navigation. The two packages are
independent — `material_navigation` does not depend on this one — so either can
be adopted alone. Together they cover the whole scaffold.

The [demo](demo/) is built on both.

## Canonical layouts

Material 3 names three canonical layouts. This package implements all three, and
each adapts on its own: the description is of the content, not of the
breakpoints.

### List-detail

A collection beside the item selected from it — an inbox and a message, a file
browser and a file, settings and a settings page.

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

* **Narrow** — one pane. Selecting pushes the detail as a real route, so the
  system Back button returns to the list.
* **Wide** — two panes. The detail reveals its width on a spring, and selecting
  a different item cross-fades the content in place.
* Narrowing past the breakpoint **slides the detail off the trailing edge**
  rather than dropping it mid-frame, and takes the drag handle with it.
* Selection is plain state, so it survives resizes, rotations and unfolding. It
  can be driven uncontrolled, from a router (`selectedId` +
  `onSelectionChanged`), or with a controller — leaf widgets call
  `ListDetail.of(context).select(id)` in every case and never learn which.
* `behavior:` decides what an empty detail shows. `resizable: true` adds a
  draggable divider whose width is remembered across breakpoints.

### Supporting pane

Content that only means something next to the primary content — comments on a
document, related items, a filter or tool panel.

```dart
SupportingPaneLayout(
  content: ArticleView(article: article),
  supporting: RelatedPeople(article: article),
);
```

* **Expanded and wider** — beside the content, at Material's fixed pane width.
* **Compact and medium** — the pane *reflows below* the content instead of
  disappearing, as the spec requires.
* **Short windows** — hidden, since there is no room to stack.
  `SupportingPane.of(context).presentAsSheet(context)` surfaces it on demand,
  picking a side sheet on wide windows and a bottom sheet on narrow ones.
* Placement is a pure function of the region, so a resize simply re-evaluates
  it. A custom `resolver:` decides differently — for instance holding a third
  pane back until extra-large.
* `dismissible: true` makes the pane on-demand rather than always present.

### Feed

Equivalently weighted items in a grid that reflows by column count.

```dart
FeedLayout(
  itemCount: articles.length,
  itemBuilder: (context, i) => ArticleCard(article: articles[i]),
);
```

* **Compact** — a single full-width column, as the spec requires.
* **Wider** — the column count grows with the available width, derived from
  `maxItemWidth` rather than hardcoded per breakpoint.
* The region is measured rather than the window, so a feed inside a narrow pane
  of a wide window still stacks.

### Composing them

The layouts nest. A list-detail inside a supporting pane is a three-pane layout,
which is where Material caps the count.

```dart
SupportingPaneLayout(
  content: ListDetailLayout(/* … */),
  supporting: MessageInfo(/* … */),
);
```

## License

MIT — see [LICENSE](LICENSE).
