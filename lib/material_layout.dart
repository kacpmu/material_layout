// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// Material 3 adaptive layout: breakpoints, panes, the canonical layouts,
/// navigation placement and side sheets.
///
/// The vocabulary is Material's. A **breakpoint** is one of five
/// ranges of width, from compact to extra-large. A **pane** holds content
/// and is either **fixed** or **flexible**; a layout shows one to three of
/// them, separated by a **spacer** and kept from the window's edges by
/// **margins**, which the layout keeps around its panes or within them
/// ([MarginPlacement]). Every layout resolves against the **region** it
/// occupies, so a layout nested in a pane adapts to that pane.
///
/// The canonical layouts are [ListDetailLayout], [SupportingPaneLayout] and
/// [FeedLayout], and [TwoPaneLayout] is the engine of the first two, for
/// layouts of an app's own. [PaneSurface] paints a pane as its layout keeps
/// the margins. [NavigationScaffold] places a navigation bar or rail beside
/// them. [SideSheet] is a sheet on the trailing edge, used as a pane or shown
/// modally with [showSideSheet]; [showAdaptiveSheet] picks a side or bottom
/// sheet for the window.
///
/// ```dart
/// NavigationScaffold(
///   navigationBar: NavigationBar(/* … */),
///   navigationRail: NavigationRail(/* … */),
///   body: ListDetailLayout<int>(
///     listBuilder: (context) => const MessageList(),
///     detailBuilder: (context, id, placement) => MessageView(id: id),
///   ),
/// );
/// ```
///
/// The widgets are built on `material_ui`: the app's `MaterialApp` and
/// `ThemeData` must come from that package for its theme to reach them.
/// How the widgets look — breakpoints, motion, and the styles of the drag
/// handle, pane surfaces and side sheets — is set with
/// [MaterialLayoutThemeData], and the package's strings come from
/// [MaterialLayoutLocalizations].
///
/// @docImport 'src/foundation/localizations.dart';
/// @docImport 'src/foundation/margins.dart';
/// @docImport 'src/foundation/theme.dart';
/// @docImport 'src/layouts/feed_layout.dart';
/// @docImport 'src/layouts/list_detail_layout.dart';
/// @docImport 'src/layouts/supporting_pane_layout.dart';
/// @docImport 'src/layouts/two_pane_layout.dart';
/// @docImport 'src/navigation/navigation_scaffold.dart';
/// @docImport 'src/panes/pane_surface.dart';
/// @docImport 'src/sheets/side_sheet.dart';
library;

export 'src/foundation/adaptive_region.dart' show AdaptiveRegion;
export 'src/foundation/breakpoints.dart'
    show Breakpoint, Breakpoints, HeightBreakpoint;
export 'src/foundation/line_length.dart' show LineLength;
export 'src/foundation/localizations.dart'
    show DefaultMaterialLayoutLocalizations, MaterialLayoutLocalizations;
export 'src/foundation/margins.dart' show MarginPlacement;
export 'src/foundation/motion.dart' show Motion, MotionScheme, PaneMotion;
export 'src/foundation/theme.dart'
    show
        DragHandleStyle,
        MaterialLayoutTheme,
        MaterialLayoutThemeData,
        PaneSurfaceStyle,
        SideSheetStyle;
export 'src/layouts/feed_layout.dart' show FeedLayout, FeedSpanBuilder;
export 'src/layouts/list_detail_layout.dart'
    show
        DetailBuilder,
        DetailPlacement,
        ListDetailEmptyBehavior,
        ListDetailLayout,
        ListDetailScope;
export 'src/layouts/supporting_pane_layout.dart'
    show PaneSide, SupportingPaneLayout;
export 'src/layouts/two_pane_layout.dart'
    show PaneArrangement, PaneReflow, PaneSlot, TwoPaneLayout;
export 'src/navigation/navigation_scaffold.dart'
    show NavigationPlacement, NavigationPlacementRule, NavigationScaffold;
export 'src/panes/pane_resizer.dart'
    show PaneDragHandle, PaneHandle, PaneHandleCallback, PaneResizer;
export 'src/panes/pane_split.dart'
    show PaneCollapse, PaneResizeMemory, PaneSplit, PaneSplitController;
export 'src/panes/pane_surface.dart' show PaneSurface;
export 'src/sheets/side_sheet.dart'
    show SideSheet, showAdaptiveSheet, showSideSheet;
