# Changelog

## 0.2.0

Requires Flutter 3.47 (Dart 3.13) or later.

The package is rebuilt on Material 3's layout guidance: its breakpoints,
margins, panes and canonical layouts. Most of the API is new; the table below
maps the API of 0.1.0 onto it.

### Migration

| 0.1.0 | 0.2.0 |
| --- | --- |
| `AdaptiveNavigationScaffold` | `NavigationScaffold`, which learns the pane count from the layouts in its body; `paneCount` overrides it. |
| `NavigationType`, `NavigationTypeResolver`, `materialNavigationTypeResolver`, `NavigationTransitionBuilder` | `NavigationPlacement`; a `NavigationPlacementRule` for `NavigationScaffold.placementRule`, `NavigationPlacementRule.material` by default; `NavigationScaffold.placementOf`; a `PaneMotion` for `NavigationScaffold.motion` |
| `WindowSizeClass`, `WindowHeightSizeClass` | `Breakpoint`, `HeightBreakpoint` |
| `WindowSize`, `AdaptiveBuilder`, `WindowSizeClassBuilder`, `adaptiveValue`, `AdaptiveLayoutContext`, `AdaptiveWidgetBuilder`, `WindowSizeClassWidgetBuilder` | `AdaptiveRegion.sizeOf`, `AdaptiveRegion.breakpointOf` and `AdaptiveRegion.heightBreakpointOf`, read in a `Builder` |
| `Breakpoints` | `Breakpoints(mediumMinWidth: …)`, with `forWidth` and `forHeight` |
| `AdaptiveLayoutTheme`, `AdaptiveLayoutThemeData` | `MaterialLayoutTheme`, and `MaterialLayoutThemeData`, which is also a `ThemeExtension` |
| `AdaptiveSpacing` | `Breakpoint.margin`, `Breakpoint.fixedPaneWidth` |
| `TwoPane`, `TwoPaneStrategy`, `kFixedPaneWidthFor` | `TwoPaneLayout`, with a `PaneArrangement` for the strategy; `Breakpoint.fixedPaneWidth` |
| `PaneController`, and `PaneCollapse`, which told which pane was collapsed | `PaneSplitController`, holding a `PaneSplit`; `PaneSplit.collapsed` and `PaneSplit.expanded`. `PaneCollapse` now says what the drag handle may do to a pane. |
| `PaneResizeBehavior` | `PaneResizeMemory` |
| `PaneTransition`, `MaterialSprings` | `PaneMotion`, `MotionScheme`, `Motion` |
| `PaneDragHandle`, which was the whole handle | `PaneResizer`, the behaviour, around `PaneDragHandle`, the grip |
| `handleBuilder`, `snap`, `snapStops` | `dragHandle`, `PaneResizer.snapStops` |
| `ratio`, `fixedPaneWidth`, `minPaneWidth`, `gutter` | `PaneSplit.width`; pane widths, margins and the spacer follow the breakpoint |
| `PaneSide.primary`, `PaneSide.secondary` | `PaneSide.leading`, `PaneSide.trailing`, for `SupportingPaneLayout.supportingSide` |
| `ListDetailLayout.twoPaneBreakpoint`, a width | `ListDetailLayout.twoPaneBreakpoint`, a `Breakpoint` |
| `ListDetailBehavior`, `behavior` | `ListDetailEmptyBehavior`, `emptyBehavior` |
| `ListDetailController`, `ListDetail.of`, `ListDetailSelection` | `selectedId` with `onSelectionChanged`; `ListDetailLayout.of`, which returns a `ListDetailScope` |
| `detailBuilder: (context, id)` | `detailBuilder: (context, id, placement)` |
| `SupportingPaneLayout.content` | `SupportingPaneLayout.focus` |
| `dismissible`, `SupportingPaneController`, `SupportingPane.of`, `SupportingPaneHandle` | `supporting: null` to hide the pane, and `onSupportingDismissed` to let the user close it |
| `SupportingPanePresentation`, `SupportingPaneResolver`, `defaultSupportingPaneResolver` | Removed: the placement follows the breakpoint of the layout's region. |
| `FeedLayout.maxItemWidth` | `FeedLayout.minItemWidth` |
| `showAppBottomSheet` | `showModalBottomSheet` from `material_ui` |
| `SheetMode`, `SideSheetHandle`, `SheetDragHandle` | A standard side sheet is a pane: `SupportingPaneLayout(supporting: SideSheet(…))`. `showSideSheet` shows a modal one. |
| `PaneContainer`, `PaneLevel` | `PaneSurface`, which paints a pane as its layout keeps the margins, in the colour of `PaneSurfaceStyle` |
| `AdaptiveGrid`, `AdaptiveBody` | Removed. `FeedLayout` lays out a grid of items, and `LineLength` keeps text to a readable width. |
| `VerticalFold`, `verticalFoldFor`, `verticalFoldOf` | Removed: the layouts avoid folds and hinges themselves. |
| `kPaneBorderRadius`, `kPaneCornerRadius` | `MaterialLayoutThemeData.paneBorderRadius` |
| `kPaneExitCurve`, `kPaneExitDuration`, `kSheetCurve`, `kSheetEnterDuration`, `kSheetExitDuration` | `PaneMotion`, from the `MotionScheme` in the layout theme |
| `kRecommendedSnapWidths` | `PaneResizer.snapStops`, Material's stops by default |
| `kSideSheetShape` | Removed. A modal `SideSheet` has 16dp leading corners; a standard one takes `paneBorderRadius`. |
| `navigationBarRevealKey`, `navigationRailRevealKey` | Removed: `NavigationScaffold` swaps the bar and the rail itself. |

Parameters that changed:

* Renamed: `resizeBehavior` to `resizeMemory`, `paneController` to
  `splitController`, and `transition` and `spring` to `motion`.
* `ListDetailLayout`: `initialId`, `controller` and `placeholderBuilder` give
  way to `selectedId`, `onSelectionChanged` and
  `ListDetailEmptyBehavior.placeholder(child:)`. `minPaneWidth` is gone, as
  panes are at least 360dp wide, and so is `respectDisplayFeatures`, as folds
  and hinges are always avoided.
* `SupportingPaneLayout`: `controller`, `belowRatio`, `onPresentationChanged`
  and `minPaneWidth` are gone. Stacked below the focus pane, the supporting
  pane takes a third of the height.
* `FeedLayout`: `spacing` and `runSpacing` are `gap`. `compactColumns` is
  gone, as a compact feed is one column, and so are `childAspectRatio`, as
  items take the height they need, `header` and `physics`. `padding` is none
  by default: the feed keeps the margins itself.
* `NavigationScaffold`: `breakpoints` comes from the layout theme, and
  `extendBodyBehindAppBar` is gone.
* `SideSheet`: `elevation` and `shape` are gone, as the variant sets them.
  `width` is 400dp by default, and at most `SideSheet.maxWidth`.
* `showSideSheet` and `showAdaptiveSheet` take `context` as a named
  argument. `mode`, `width`, `maxWidth`, `sideWidth`, `sideMaxWidth`,
  `sideBreakpoint`, `isScrollControlled`, `backgroundColor`, `enableDrag`,
  `showDragHandle`, `dragHandle` and the durations are gone: a side sheet in a
  layout is a pane, the form follows the window's breakpoint, and motion comes
  from `motion`. `useRootNavigator` is `true` by default, as a sheet is a
  window-level surface.

### Breakpoints and regions

* `Breakpoint` has Material's five width ranges, compact below 600dp, medium,
  expanded from 840dp, large from 1200dp and extra-large from 1600dp, and
  `HeightBreakpoint` its three heights, at 480dp and 900dp. `Breakpoints`
  retunes the thresholds.
* A layout resolves against the region it occupies, not the window, and each
  pane is a region for the widgets inside it: a layout beside a navigation
  rail adapts to the body, and one nested in a pane to the pane.
  `AdaptiveRegion.sizeOf`, `breakpointOf`, `heightBreakpointOf` and
  `marginsOf` read the region; a widget that reads only a breakpoint rebuilds
  only when it changes.
* While a pane beside it enters or leaves, a region is arranged for the width
  its pane will rest at, so that its content rearranges once, as the motion
  begins.

### Margins and panes

* Margins are 16dp at compact and 24dp above, beyond any horizontal
  safe-area inset, and the spacer between panes is 24dp. A navigation rail
  takes the margin's place on its side.
* `MarginPlacement.outside`, the default, keeps the margins around the panes,
  which are set in as cards; `MarginPlacement.inside` keeps them within the
  panes, for panes painted flat that reach the edges, whose content pads
  itself by `AdaptiveRegion.marginsOf`. `MaterialLayoutThemeData` sets the
  placement for the app, a layout's `marginPlacement` for itself, and a
  nested layout keeps the placement of the layout around it. Split widths are
  the widths of the panes' content either way.
* `PaneSurface` paints a pane to match: a card, whose content keeps
  Material's 16dp padding, or a flat pane, whose content keeps the margins.
  `PaneSurface.paddingOf` gives the padding, and `PaneSurface.inCard` which
  it is. It takes its colour and outline from itself, then from the theme's
  `paneSurfaceStyle`.
* `MaterialLayoutThemeData.paneBorderRadius` gives the layouts the corners of
  the app's panes, which a pane keeps while it enters or leaves, down to a
  sliver.
* Each pane keeps the parts of the safe-area insets it reaches: a pane set in
  by the margins keeps none of the horizontal insets, and of stacked panes,
  only the top one keeps the top inset.
* Nested layouts share Material's pane budget: three panes at most, and three
  side by side only at extra-large, where the third is a standard side sheet.
  A layout nested in the detail or focus pane has the panes left; one in the
  list or the supporting pane keeps to one.
* A two-pane layout given directly as another layout's pane keeps the margins
  its pane meets, sets its own panes in by them, and resolves against the
  width it would have if it were not nested.
* Panes keep out of a hinge or a half-open fold: they sit side by side across
  a vertical one and stack across a horizontal one. A compact region keeps
  to one pane.
* `LineLength` keeps lines of text to 60 characters, or `characters`,
  measured in the text style, so that the limit follows the type scale and
  text scaling.

### List-detail

* `ListDetailLayout` shows one pane below `twoPaneBreakpoint`, expanded by
  default, and two at and above it; at medium, two panes split evenly around
  the window's centre. Going from two panes to one with an item selected
  shows its detail, and the list marks the selected item only beside it.
* At one pane, selecting an item pushes its detail as a page on a navigator
  the layout owns, whose back button and the system back gesture return to
  the list. `ListDetailLayout.custom` places a detail it is given, such as a
  shell route's navigator, and mounts no navigator.
* `detailBuilder` is told the detail's `DetailPlacement`, a pane or a page.
  A detail built at the same place in the tree in both keeps its state,
  focus and scroll position as it moves between them, and each item keeps
  its own scroll position.
* A resize never changes the selection or navigates. The selection belongs
  to the layout, or to the caller with `onSelectionChanged`, and
  `restorationId` restores it with the split.
* `emptyBehavior` chooses what two panes show with nothing selected: a
  placeholder, the list alone, or an item of the caller's choosing.
* `ListDetailScope.canClose` and `close` give the detail beside the list a
  close button where two panes have something to show without it; closing
  clears the selection and returns focus to the item that opened the detail.
* When another pane takes the room, as a side sheet opening beside the
  layout, the list slides out before the detail becomes a page; when the
  room comes back, the page turns back into the pane where it stands and the
  list slides in. Going back from the page when that brings the room back
  turns the page into the pane the same way. A change of the window
  rearranges the panes at once.

### Supporting pane

* `SupportingPaneLayout` stacks the supporting pane below the focus pane at
  compact and medium, taking a third of the height, and puts it beside the
  focus pane from expanded, 360dp or 412dp wide, on the side
  `supportingSide` says. A supporting widget with a preferred width narrows
  the pane to it.
* A `SideSheet` given as the supporting pane is a standard side sheet: it
  sits beside the content from medium, on the trailing edge, at its own
  width, and is hidden rather than stacked at compact. It keeps no margin, so
  within the panes it reaches the trailing edge.
* With `onSupportingDismissed`, the supporting pane is temporary: its side
  sheet's close button, and the drag handle, close it. Without it, the pane
  is permanent: a side sheet in it shows no close button, and it has no drag
  handle. The focus pane is never hidden.

### Feed

* `FeedLayout` is one column at compact, and above it as many columns as fit
  at `minItemWidth`, `gap` apart. Items keep their order, row by row, and
  may span columns (`spanBuilder`) and differ in height. The feed keeps the
  margins of its region, and its first and last items start clear of the
  top and bottom insets.

### Two panes of your own

* `TwoPaneLayout` is the engine of the list-detail and supporting-pane
  layouts, for layouts of an app's own: a fixed pane beside a flexible one,
  of Material's width or its own (`PaneArrangement.fixedAndFlexible`), or two
  flexible panes with the spacer centred in the window
  (`PaneArrangement.splitPane`). The panes sit side by side from
  `twoPaneBreakpoint`, and below it stack or show one alone (`PaneReflow`).
  Either pane may be null, and `onFirstDismissed` and `onSecondDismissed`
  make a pane one the user can close. Regions, margins, folds, nesting, pane
  counts, motion and resizing work as in the canonical layouts.

### Resizing

* `resizable` puts a drag handle between two panes: a `PaneResizer` around a
  `PaneDragHandle` by default, or `dragHandle`. The handle has a 48dp
  target, and takes input only there and on the spacer, so the panes beside
  it keep theirs.
* A drag settles on Material's stops: 360dp, 412dp and the centred split, the
  even split at medium, and the end on either side where the handle may hide
  a pane. `PaneResizer.snapStops` replaces them; an empty list lets a drag
  rest anywhere between the panes' minimum widths.
* A tap returns to the default split (`PaneResizer.restore`), a double tap
  hides a pane or shows both again (`PaneResizer.toggle`), and a long press
  splits the panes evenly (`PaneResizer.splitEvenly`). `onTap`,
  `onDoubleTap` and `onLongPress` choose otherwise, with the `PaneHandle`
  the gesture is made on: its split and stops, `toggle` and `moveTo`. A long
  press acts when the handle is let go, and a handle held and then moved is
  dragged. Enter and Space always toggle.
* The arrow keys move between the stops, and Home and End to either end.
  Screen readers see a slider with the split as a percentage and an action
  per stop, and hear where a gesture, a key or an action leaves the panes.
* A hidden pane leaves the other the whole width: the spacer closes, and the
  handle rests in the middle of the margin beside the hidden pane, or half a
  spacer inside the other beside a navigation rail. A drag stops at the
  minimum width of a pane the handle may not hide. The handle comes in with
  a pane that enters, fading in, and takes input once the pane has arrived;
  as a pane goes, the handle fades out where it is.
* `PaneCollapse` says what the handle may do to a pane: never hide it,
  collapse it, or dismiss it, as a temporary pane. `listCollapse` and
  `detailCollapse`, and `firstCollapse` and `secondCollapse`, set it. By
  default the handle collapses the fixed pane, either of two flexible
  panes, and at medium, where two panes split evenly, either pane; above
  medium it never hides the flexible pane beside a fixed one. Where it
  would collapse a pane that can be dismissed, it dismisses the pane
  instead. A list-detail layout's detail is dismissed with the
  handle only when `detailCollapse` says so, which needs
  `ListDetailEmptyBehavior.hidePane`, where the list then shows alone;
  selecting an item while the detail is hidden shows it again. A supporting
  pane's handle only resizes the pane and dismisses it.
* `PaneSplit` describes a split, and a `PaneSplitController` observes and
  sets it; `PaneSplit.toJson` and `PaneSplit.fromJson` store it.
  `PaneResizeMemory.persistent` keeps a split across breakpoints, and
  `temporary` forgets it when the pane closes and reopens, or the breakpoint
  changes. A split that settles on the breakpoint's default width stays the
  default, and follows the next breakpoint.
* `PaneDragHandle` is a 4 × 48dp pill that grows to 12 × 52dp while pressed,
  or as its `style`, and then the theme's `dragHandleStyle`, says.

### Navigation

* `NavigationScaffold` shows a navigation bar at compact, a rail beside one
  pane and a bar below two at medium, and a rail from expanded upwards, by
  the panes its body's layouts report. It never shows both: the leaving
  component goes before the arriving one comes. Where the component the
  placement calls for is not given, it shows none.
* `placementRule` chooses another placement: `NavigationPlacementRule.only`
  shows one placement at every breakpoint, and `NavigationPlacementRule.from`
  decides by the breakpoint and the pane count. `NavigationScaffold.placementOf`
  tells the widgets below which placement shows.

### Sheets

* `SideSheet` is one surface for both variants: a standard sheet in a pane,
  on the surface colour with the panes' corners, and a modal sheet from
  `showSideSheet`, on surface container low with 16dp leading corners.
  `backgroundColor`, and then the theme's `sideSheetStyle`, colour either.
  It takes a headline, a back button and bottom actions, which stack where
  the sheet is too narrow for them; it is a dialog to screen readers, and
  scrolls vertically only.
* A side sheet shows a close button wherever it can be closed: always as a
  modal sheet, and in a pane that can be dismissed or with `onClose`. A
  permanent sheet shows none.
* `showSideSheet` is a modal route: its scrim, `barrierColor` or the theme's,
  blocks the content, focus moves to the sheet and back, and back closes it.
  It follows Android's predictive back gesture, detaching from the edges as
  the gesture progresses; it cannot be dragged away.
* `showAdaptiveSheet` shows a side sheet from expanded upwards and a bottom
  sheet below, by the window's width. Either form scrolls the content, so the
  same content, a column rather than a list view, works in both.

### Motion

* Panes, sheets and navigation move on Material's spring tokens, from
  `MotionScheme.expressive()`, the default, or `MotionScheme.standard()`,
  set through the theme or per widget as a `PaneMotion`, whose motions may
  also be timed curves. Nothing moves where the platform asks for reduced
  motion.

### Theming

* `MaterialLayoutThemeData`, a theme extension or a `MaterialLayoutTheme`,
  holds how the widgets look: breakpoints, where the margins are kept, the
  panes' corners, motion, and the styles of the drag handle, pane surfaces
  and side sheets. A value resolves as Flutter's own do: the widget's
  argument, then the theme, then Material's default. What the widgets do is
  set only on the widgets.

### Localisation

* The package's strings come from `MaterialLayoutLocalizations`, with an
  English fallback, `DefaultMaterialLayoutLocalizations`.
  `MaterialLayoutLocalizations.delegate` supplies it for every locale, after
  any translation of the app's own.

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
