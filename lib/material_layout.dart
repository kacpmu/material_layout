/// Material 3 adaptive layouts for Flutter.
///
/// The package provides:
/// * **Foundation** — [WindowSizeClass]/[WindowHeightSizeClass], overridable
///   [Breakpoints], [WindowSize], [AdaptiveLayoutTheme], the [AdaptiveBuilder],
///   and the [adaptiveValue] selector.
/// * **Spacing** — [AdaptiveSpacing] tokens and [AdaptiveBody] content cap.
/// * **Navigation** — the [AdaptiveNavigationScaffold] that swaps a bottom bar,
///   navigation rail, and expanded rail/drawer by window size class.
/// * **Layouts** — the raw [TwoPane], plus the canonical [ListDetailLayout],
///   [SupportingPaneLayout], and [FeedLayout].
/// * **Sheets** — [showAdaptiveSheet], [showSideSheet], [showAppBottomSheet].
library;

// Foundation
export 'src/foundation/adaptive_builder.dart';
export 'src/foundation/adaptive_layout_theme.dart';
export 'src/foundation/adaptive_value.dart';
export 'src/foundation/breakpoints.dart';
export 'src/foundation/context_extensions.dart';
export 'src/foundation/pane_transition.dart';
export 'src/foundation/window_size.dart';
export 'src/foundation/window_size_class.dart';

// Spacing
export 'src/spacing/adaptive_body.dart';
export 'src/spacing/spacing.dart';

// Grid (optional)
export 'src/grid/adaptive_grid.dart';

// Layouts
export 'src/layouts/adaptive_navigation_scaffold.dart';
export 'src/layouts/feed_layout.dart';
export 'src/layouts/foldable.dart';
export 'src/layouts/list_detail_layout.dart';
export 'src/layouts/pane_container.dart';
export 'src/layouts/pane_controller.dart';
export 'src/layouts/pane_drag_handle.dart';
export 'src/layouts/supporting_pane_layout.dart';
export 'src/layouts/two_pane.dart';

// Sheets
export 'src/sheets/adaptive_sheet.dart';
export 'src/sheets/bottom_sheet.dart';
export 'src/sheets/sheet_drag_handle.dart';
export 'src/sheets/sheet_mode.dart';
export 'src/sheets/side_sheet.dart';
