# Changelog

## 0.0.1

Initial release.

### Layouts

* `ListDetailLayout`, `SupportingPaneLayout` and `FeedLayout` — the three
  Material 3 canonical layouts, each adapting from one pane to three.
* `TwoPane` — the engine underneath: fixed-and-flexible or split-pane, with
  drag-to-resize, magnet snapping, double-tap collapse, and persistent or
  temporary width semantics.
* `AdaptiveNavigationScaffold` — places a bottom bar or a navigation rail by
  breakpoint (and by pane count at medium), animating the swap.
* `PaneContainer` — the pane surface: a Material 3 surface container role and
  corner radius, plus an ink surface for its content.
* `AdaptiveGrid` and `AdaptiveBody` helpers.

### Foundation

* `WindowSizeClass` / `WindowHeightSizeClass`, `WindowSize`, and `Breakpoints`
  as a single overridable source of truth.
* `AdaptiveLayoutTheme` for breakpoints, spacing and the body width cap.
* `AdaptiveBuilder`, `adaptiveValue`, and `BuildContext` extensions.

### Sheets

* `showAdaptiveSheet`, `showSideSheet`, `showAppBottomSheet`, and the inline
  `SideSheet` surface.
* Standard sheets are genuinely persistent — no barrier, so the app stays
  interactive underneath — while modal ones block, as Material describes.
* Both forms drag away to dismiss, share Flutter's bottom-sheet motion, and
  accept a custom `dragHandle`.

### Adaptation

* Panes **enter** on an expressive spring and **leave** on a curve; an exit that
  overshoots would read as a bounce back into view.
* A pane that no longer fits slides off the trailing edge — drag handle included
  — or reflows below the content, rather than disappearing between frames.
* Foldables: the split snaps onto a vertical hinge when one is present.
* RTL throughout.
