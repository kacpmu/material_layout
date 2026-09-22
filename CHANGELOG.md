# Changelog

## 0.1.0+1

* Add a preview gif to the package page. No code changes.

## 0.1.0

Requires Flutter 3.44 or later.

### Dependencies

* The package is built on
  [`material_ui`](https://pub.dev/packages/material_ui) instead of
  `package:flutter/material.dart`. Its widgets resolve `Theme`, `ColorScheme`
  and `MaterialLocalizations` from `material_ui`; these are distinct types from
  the framework's, so an application supplying its theme through
  `package:flutter/material.dart` is not themed through to them. See
  [`material_ui`'s migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package).

### Pane arguments

`TwoPane`, `ListDetailLayout` and `SupportingPaneLayout` accept the same
arguments for the split, with identical meaning: `transition`, `spring`,
`gutter`, `paneController`, `resizable`, `resizeBehavior`, `fixedPaneWidth`,
`ratio`, `minPaneWidth`, `snap`, `snapStops` and `handleBuilder`.
`ListDetailLayout` also accepts `respectDisplayFeatures`, which applies to its
medium-width split.

| Removed | Replacement |
| --- | --- |
| `TwoPane.controller` | `TwoPane.paneController` |
| `TwoPane.temporaryResize` | `resizeBehavior: PaneResizeBehavior.temporary` |
| `TwoPane.exitDuration`, `TwoPane.exitCurve` | `transition: PaneTransition.curvedExit(exitDuration:, exitCurve:)` |
| `ListDetailLayout.revealSpring` | `transition` for the pane, `spring` for the divider |
| `ListDetailLayout.listPaneWidth` | `ListDetailLayout.fixedPaneWidth` |
| `SupportingPaneLayout.supportingWidth` | `SupportingPaneLayout.fixedPaneWidth` |
| `kExpressiveSpring` | `MaterialSprings.expressiveDefaultSpatial` |
| `PaneTransition.standard`, `.bounce`, `.custom` | `PaneTransition.spring`, `.curvedExit`, `.none` |
| `StandardPaneTransition`, `BouncePaneTransition`, `NonePaneTransition`, `CustomPaneTransition` | `PaneTransition`, no longer a sealed hierarchy |
| `PaneTransition.duration`, `.switchInCurve`, `.switchOutCurve`, `.buildTransition` | `PaneTransition.enterSpring`, `.exitSpring`, `.exitCurve`, `.exitDuration`, `.fadesOnExit` |

* `ratio` is the fixed pane's share of the splittable width in all three
  widgets: the list in `ListDetailLayout`, the supporting pane in
  `SupportingPaneLayout`, the `fixedSide` pane in `TwoPane`. It was the
  primary pane's share in `TwoPane` and the content's share in
  `SupportingPaneLayout`, so existing code keeps compiling and resolves to the
  complementary split; pass `1 - ratio` to keep the previous layout.
* `PaneResizeBehavior` replaces the boolean resize modes. `ListDetailLayout`
  defaults to `persistent`, `SupportingPaneLayout` to `temporary`.
* `ListDetailLayout` additionally accepts `ratio`, `resizeBehavior`, `snap`,
  `snapStops`, `handleBuilder` and `respectDisplayFeatures`;
  `SupportingPaneLayout` additionally accepts `transition`, `paneController`,
  `resizeBehavior`, `snap`, `snapStops` and `handleBuilder`.

### Layout

* `ListDetailLayout.twoPaneBreakpoint` defaults to 840, the expanded
  breakpoint, so a medium window shows a single pane as Material 3 recommends.
  Set it to 720 for the two-pane option, where the panes split evenly.

### Pane motion

* `PaneTransition` describes how a pane enters and leaves. Its constructors are
  `PaneTransition.spring()`, `.curvedExit()` and `.none()`. `.none()` keeps its
  name and changes meaning: it now suppresses the pane's enter and exit, where
  it previously suppressed a content animation only. Code passing it keeps
  compiling.
* Pane motion runs on the Material 3 Expressive default spatial spring (damping
  ratio 0.8, stiffness 380) by default. A pane leaves on the spring it enters
  on and does not fade; `PaneTransition.curvedExit()` leaves on 300ms
  emphasized easing with a fade.
* Selecting another item in a two-pane `ListDetailLayout` replaces the detail
  content without animating it.
* `MaterialSprings` provides the six Material 3 spatial spring tokens
  (expressive and standard; fast, default and slow).

### Accessibility

* The pane drag handle exposes each snap stop as a custom semantic action
  ("Set pane split to 50%", "Collapse the leading pane"), so assistive
  technology can reach a split directly instead of nudging to it. `TwoPane`
  derives them from its snap stops. As with `PaneDragHandle.semanticLabel`, the
  labels are English and are set on `PaneDragHandle` itself.

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
