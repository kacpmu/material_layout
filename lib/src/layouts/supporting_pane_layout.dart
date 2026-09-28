// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../foundation/adaptive_region.dart';
import '../foundation/breakpoints.dart';
import '../foundation/margins.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import '../panes/pane_layout.dart';
import '../panes/pane_resizer.dart';
import '../panes/pane_scope.dart';
import '../panes/pane_split.dart';
import '../panes/two_pane_view.dart';
import '../sheets/side_sheet.dart';
import 'layout_support.dart';

/// The side of the focus pane that a supporting pane takes.
enum PaneSide {
  /// Before the focus pane: left in a left-to-right layout.
  leading,

  /// After the focus pane: right in a left-to-right layout.
  trailing,
}

/// Primary content with secondary content that is meaningful only beside it.
///
/// The focus pane holds the primary content and takes most of the space.
/// Where the supporting pane goes depends on the breakpoint of the
/// region the layout occupies:
///
///  * compact and medium: below the focus pane, at the full width, taking a
///    third of the height;
///  * expanded and wider: beside it, on [supportingSide], at the fixed pane
///    width — 360dp at expanded and 412dp at large and extra-large.
///
/// A supporting widget that declares a preferred width — a
/// [PreferredSizeWidget] such as `SideSheet` — narrows the pane to that
/// width, so that a side sheet used as a pane keeps to its 400dp maximum.
///
/// A `SideSheet` given as [supporting] — itself, not wrapped in another
/// widget — is a standard side sheet, which has rules of its own:
/// it sits beside the focus pane from medium upwards, always on the
/// trailing edge, and it is never stacked below the content,
/// which would change its fixed width and full height. Where it
/// cannot sit beside the content — at compact, or inside a layout that
/// leaves no room — it is hidden; at compact, present its content in a
/// modal sheet instead, such as with `showAdaptiveSheet`. At
/// extra-large it may be the third pane beside a two-pane layout.
///
/// ```dart
/// SupportingPaneLayout(
///   focus: const ArticleView(),
///   supporting: showRelated ? const RelatedArticles() : null,
///   onSupportingDismissed: () => setState(() => showRelated = false),
/// );
/// ```
///
/// The supporting pane animates in and out as [supporting] changes between
/// null and a widget. With [onSupportingDismissed], the pane is one
/// the user can close: a side sheet's close button, and hiding the pane
/// with the drag handle, call it, and the caller removes the pane by passing
/// null. Without it, the pane is permanent: a side sheet shows no close
/// button, and the pane stays until the caller removes it. At compact, the
/// caller may instead present the supporting content in a bottom sheet.
///
/// With [resizable], a drag handle between the panes resizes them when they
/// are side by side, where the supporting pane can be dismissed: hiding the
/// pane with it dismisses the pane. A permanent pane has no handle, and
/// keeps its width. The focus pane is never hidden.
///
/// Where the layout cannot give the supporting pane room — inside another
/// layout that has used up the panes allowed — the pane is hidden. A
/// layout nested in the focus pane may use the panes this one leaves; the
/// supporting pane keeps to one. A two-pane layout given as [focus] itself,
/// not wrapped in another widget, is not set in by this layout's margins:
/// it keeps the margins its pane meets, and sets its own panes in by them.
class SupportingPaneLayout extends StatefulWidget {
  /// Creates a supporting-pane layout.
  const new({
    super.key,
    required this.focus,
    this.supporting,
    this.onSupportingDismissed,
    this.supportingSide = PaneSide.trailing,
    this.resizable = false,
    this.dragHandle = const PaneResizer(),
    this.splitController,
    this.resizeMemory = PaneResizeMemory.temporary,
    this.marginPlacement,
    this.motion,
  });

  /// The primary content.
  final Widget focus;

  /// The secondary content, or null for none.
  final Widget? supporting;

  /// Called when the user dismisses the supporting pane, or null when the
  /// pane is permanent.
  ///
  /// The layout does not hide the pane itself: set [supporting] to null in
  /// response.
  final VoidCallback? onSupportingDismissed;

  /// The side of the focus pane the supporting pane takes when beside it.
  ///
  /// A `SideSheet` takes the trailing side only.
  final PaneSide supportingSide;

  /// Whether a drag handle between the panes resizes them when they are
  /// side by side.
  ///
  /// The handle shows only where the supporting pane can be dismissed, with
  /// [onSupportingDismissed]: hiding the pane with the handle dismisses it.
  final bool resizable;

  /// The drag handle shown when [resizable] is true, where the supporting
  /// pane can be dismissed.
  final Widget dragHandle;

  /// Holds how the panes are divided, or null for a split the layout keeps.
  ///
  /// The split describes the supporting pane's width. It never hides a
  /// pane: a split that would, as [PaneSplit.collapsed], keeps the default
  /// split. The supporting pane leaves when [supporting] is null, and the
  /// focus pane always shows.
  final PaneSplitController? splitController;

  /// Whether a resize is remembered.
  ///
  /// Temporary by default: a supporting pane is resized rarely, and returns
  /// to its default width when it is closed and reopened.
  final PaneResizeMemory resizeMemory;

  /// Where the layout keeps its margins: around the panes, which are
  /// then set in from the edges as cards, or within them, for panes painted
  /// flat whose content keeps the margins that [AdaptiveRegion.marginsOf]
  /// reports.
  ///
  /// A side sheet keeps no margin: within the panes, it reaches the edge at
  /// its own width, and its own padding keeps its content clear of it.
  ///
  /// Null to keep them where the layout this one is nested in keeps its
  /// own, and in a layout that is not nested, where
  /// [MaterialLayoutThemeData.marginPlacement] says.
  final MarginPlacement? marginPlacement;

  /// How panes enter, leave and resize, or null for the default spatial
  /// motion of the scheme in effect.
  final PaneMotion? motion;

  @override
  State<SupportingPaneLayout> createState() => _SupportingPaneLayoutState();
}

class _SupportingPaneLayoutState extends State<SupportingPaneLayout>
    with PaneCountReporter<SupportingPaneLayout>, LayoutRegionState {
  final _bucket = PageStorageBucket();
  Widget? _lastSupporting;
  (Breakpoint, Axis?)? _arrangement;

  @override
  Widget build(BuildContext context) {
    final motion = PaneMotion.resolve(context, widget.motion);
    return buildRegion(
      marginPlacement: widget.marginPlacement,
      builder: (context, region) => _buildPanes(context, region, motion),
    );
  }

  Widget _buildPanes(
    BuildContext context,
    LayoutRegion region,
    PaneMotion motion,
  ) {
    final breakpoint = region.breakpoint;
    final budget = region.budget;
    final band = region.band;

    final supporting = widget.supporting;
    if (supporting != null) _lastSupporting = supporting;
    final lastSupporting = _lastSupporting;
    assert(
      supporting is! SideSheet || widget.supportingSide == PaneSide.trailing,
      'A side sheet sits on the trailing edge.',
    );
    final sheetWidth = lastSupporting is SideSheet
        ? lastSupporting.preferredSize.width
        : null;
    final sheet = sheetWidth != null;

    // A standard side sheet is for medium and wider, and may take the
    // slot kept for a third pane; other supporting content sits beside
    // the focus pane from expanded.
    final room =
        budget.sideBySide - budget.sheetSlots >= 2 ||
        (sheet && budget.sideBySide >= 2);
    final minimum = sheet ? Breakpoint.medium : Breakpoint.expanded;
    final beside = band != null
        ? band.axis == Axis.horizontal &&
              breakpoint >= Breakpoint.medium &&
              room
        : breakpoint >= minimum && room;
    // A side sheet keeps its width, its height and its edge,
    // so it is never stacked: where it cannot sit beside the content, it is
    // hidden.
    final shown = supporting != null && budget.panes >= 2 && (beside || !sheet);
    final besideShown = beside && shown;
    reportPaneCount(context, besideShown ? 2 : 1);

    final axis = beside ? Axis.horizontal : Axis.vertical;
    // A change of breakpoint or posture rearranges the panes without
    // animating them; a pane that comes or goes by itself animates.
    final arrangement = (breakpoint, band?.axis);
    final resized = _arrangement != null && _arrangement != arrangement;
    _arrangement = arrangement;

    // A nested layout may use the panes this one leaves: the focus
    // pane has them all, and the supporting pane keeps to one. A side sheet
    // beside the content takes the slot kept for one where there is such a
    // slot.
    Widget pane(
      Object storageKey,
      Widget child, {
      required bool focus,
      VoidCallback? onDismiss,
    }) {
      final content = paneContent(
        bucket: _bucket,
        storageKey: storageKey,
        budget: focus
            ? PaneScope.remaining(
                budget,
                shown: shown,
                beside: besideShown,
                takesSheetSlot: besideShown && sheet,
              )
            : onePane,
        marginPlacement: region.marginPlacement,
        onDismiss: onDismiss,
        child: child,
      );
      if (focus || sheetWidth == null) return content;
      // A side sheet keeps to its width on the trailing edge of a pane
      // that is wider, as on one side of a hinge, and
      // covers the safe-area inset it reaches there besides, which it
      // keeps its content clear of.
      return Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          final inset = Directionality.of(context) == TextDirection.rtl
              ? padding.left
              : padding.right;
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: sheetWidth + inset),
              child: content,
            ),
          );
        },
      );
    }

    // The panes are identified, so that their content keeps its state when a
    // leading supporting pane moves below the focus pane and back.
    final focus = PaneConfig(
      id: 'focus',
      child: pane('focus', widget.focus, focus: true),
      flex: 2,
      holdsLayout: isPaneLayout(widget.focus),
    );
    final supportingPane = PaneConfig(
      id: 'supporting',
      child: pane(
        // Other content starts afresh rather than in the scroll position of
        // the content before it.
        ('supporting', lastSupporting.runtimeType, lastSupporting?.key),
        lastSupporting ?? const SizedBox.shrink(),
        focus: false,
        onDismiss: widget.onSupportingDismissed,
      ),
      visible: shown,
      maintainState: supporting != null,
      keepsMargins: !sheet,
      holdsLayout: isPaneLayout(lastSupporting),
    );
    // A side sheet takes the trailing side whatever the layout asks.
    final supportingFirst =
        beside && widget.supportingSide == PaneSide.leading && !sheet;

    // A fold or hinge holds the split only across the panes' own axis: a
    // vertical hinge in a compact region leaves the panes stacked as usual.
    final held = band != null && band.axis == axis ? bandSpacer(band) : null;
    // The handle dismisses the supporting pane, and so shows only where the
    // pane can be dismissed.
    final dismiss = widget.onSupportingDismissed;
    final split = held == null && !beside
        ? null
        : SplitConfig(
            resizable: supportingFirst
                ? PaneLayoutSlot.first
                : PaneLayoutSlot.second,
            stops: PaneSplit.materialStops,
            defaultExtent: _supportingWidth(breakpoint),
            // The focus pane keeps the majority of the space, and a side
            // sheet its maximum width. Half the space is measured on the
            // panes' content, which has more room within the panes, where a
            // side sheet keeps no margin.
            minExtent: _minSupportingWidth,
            maxExtent: sheetWidth ?? double.infinity,
            otherMinShare: 0.5,
            center: held?.center ?? region.windowCenter,
            locked: held != null,
            handle: widget.resizable && dismiss != null
                ? widget.dragHandle
                : null,
            controller: widget.splitController,
            memory: widget.resizeMemory,
            resetToken: arrangement,
            collapse: dismiss != null
                ? PaneCollapse.dismiss
                : PaneCollapse.never,
            onDismissed: dismiss,
            hidesPanes: false,
          );

    final margins = region.margins;
    return TwoPaneView(
      axis: axis,
      first: supportingFirst ? supportingPane : focus,
      second: supportingFirst ? focus : supportingPane,
      marginStart: margins.start,
      marginEnd: margins.end,
      marginPlacement: region.marginPlacement,
      spacer: held?.spacer ?? paneSpacer,
      split: split,
      motion: motion,
      animate: !resized,
    );
  }

  // The supporting pane's width beside the focus pane: the fixed pane width,
  // narrowed to the preferred width of a supporting widget that
  // declares one, such as a side sheet. At medium, where there is no
  // fixed pane width, a side sheet asks for its own width, which the focus
  // pane's share of the space then limits.
  double? _supportingWidth(Breakpoint breakpoint) {
    final width = breakpoint.fixedPaneWidth;
    final supporting = _lastSupporting;
    final preferred = supporting is PreferredSizeWidget
        ? supporting.preferredSize.width
        : double.infinity;
    if (!preferred.isFinite) return width;
    return width == null ? preferred : math.min(width, preferred);
  }
}

// The minimum width of a supporting pane.
const double _minSupportingWidth = 280;
