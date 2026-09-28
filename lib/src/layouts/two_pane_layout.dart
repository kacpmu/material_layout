// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// @docImport '../navigation/navigation_scaffold.dart';
/// @docImport '../panes/pane_surface.dart';
/// @docImport '../sheets/side_sheet.dart';
/// @docImport 'list_detail_layout.dart';
/// @docImport 'supporting_pane_layout.dart';
library;

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
import 'layout_support.dart';

/// One of the two panes of a [TwoPaneLayout].
enum PaneSlot {
  /// The first pane: leading where the panes sit side by side, and on top
  /// where they are stacked.
  first,

  /// The second pane: trailing where the panes sit side by side, and below
  /// where they are stacked.
  second,
}

/// How a [TwoPaneLayout] divides its space between two panes side by side:
/// one of Material's two arrangements of two panes.
@immutable
final class PaneArrangement {
  /// Two flexible panes that share the space evenly, with the spacer centred
  /// in the window: Material's split-pane arrangement, suited to content of
  /// equal weight.
  const new splitPane() : fixed = null, width = null;

  /// A pane of fixed width beside a flexible one, which takes the rest:
  /// Material's fixed-and-flexible arrangement, and the default from
  /// expanded upwards.
  ///
  /// The [fixed] pane is [width] wide, or Material's fixed pane width when
  /// that is null: 360dp at expanded, and 412dp at large and extra-large.
  const new fixedAndFlexible({this.fixed = PaneSlot.first, this.width})
    : assert(width == null || width > 0);

  /// The pane of fixed width, or null where both panes are flexible.
  final PaneSlot? fixed;

  /// The fixed pane's width, or null for Material's.
  final double? width;

  @override
  bool operator ==(Object other) =>
      other is PaneArrangement && other.fixed == fixed && other.width == width;

  @override
  int get hashCode => Object.hash(fixed, width);

  @override
  String toString() => fixed == null
      ? 'PaneArrangement.splitPane()'
      : 'PaneArrangement.fixedAndFlexible(fixed: $fixed, width: $width)';
}

/// What a [TwoPaneLayout] does with its panes where two do not fit side by
/// side.
enum PaneReflow {
  /// Stacks them, the first above the second: Material's reflow, as a
  /// supporting pane moves below the content it supports.
  stack,

  /// Shows only the first pane: Material's show and hide, as a list-detail
  /// layout shows only the list. Where there is no first pane, the second
  /// shows.
  first,

  /// Shows only the second pane. Where there is no second pane, the first
  /// shows.
  second,
}

/// Two panes, arranged for the space they have: side by side where two
/// fit, and otherwise stacked or one alone.
///
/// The engine the canonical layouts, [ListDetailLayout] and
/// [SupportingPaneLayout], are built on, for a layout of an app's own. It
/// resolves against the region it occupies, as they do: at and above
/// [twoPaneBreakpoint] the panes sit side by side in the [arrangement], and
/// below it they reflow as [reflow] says. Folds and hinges, the margins and
/// the spacer, the split centred in the window, the panes' motion, resizing
/// and nesting all work as they do in the canonical layouts.
///
/// ```dart
/// TwoPaneLayout(
///   // A leading outline of fixed width beside the document, and below
///   // expanded the document alone.
///   first: const Outline(),
///   second: const Document(),
///   reflow: PaneReflow.second,
///   resizable: true,
/// );
/// ```
///
/// Either pane may be null, and the other then takes the whole layout: a
/// pane that becomes null leaves on the exit motion, and one given again
/// enters on the enter motion. A change of breakpoint or posture rearranges
/// the panes at once.
///
/// With [resizable], a drag handle between the panes resizes them. By
/// default, as Material has it, it hides the fixed pane, either of two
/// flexible panes, and at medium, where the panes split evenly, either
/// pane; above medium it never hides the flexible pane beside a fixed one.
/// Where it would hide a pane that can be dismissed, with
/// [onFirstDismissed] or [onSecondDismissed], it dismisses the pane
/// instead. [firstCollapse] and [secondCollapse] say otherwise. A hidden
/// pane leaves the other the whole width, with the handle in the margin
/// beside it.
///
/// At medium, where Material has two panes split evenly, the panes split
/// evenly whatever the arrangement. A compact region always shows one pane
/// or stacks the two.
///
/// Each pane is a region, which the layouts nested in it adapt to. They may
/// use the panes this layout leaves: three in all, and a third side by side
/// only at extra-large, where it is a standard side sheet. The fixed pane,
/// or in a split-pane arrangement the first, keeps to one pane, and the
/// other pane has the rest. A two-pane layout given as a pane itself, not
/// wrapped in another widget, is not set in by this layout's margins: it
/// keeps the margins its pane meets, and sets its own panes in by them.
///
/// Wrap each pane's content in a [PaneSurface] to paint it as the margins
/// require, and place the layout in a [NavigationScaffold] to put
/// navigation beside it.
class TwoPaneLayout extends StatefulWidget {
  /// Creates a two-pane layout.
  const new({
    super.key,
    this.first,
    this.second,
    this.arrangement = const PaneArrangement.fixedAndFlexible(),
    this.twoPaneBreakpoint = Breakpoint.expanded,
    this.reflow = PaneReflow.stack,
    this.resizable = false,
    this.dragHandle = const PaneResizer(),
    this.splitController,
    this.resizeMemory = PaneResizeMemory.persistent,
    this.firstCollapse,
    this.secondCollapse,
    this.onFirstDismissed,
    this.onSecondDismissed,
    this.marginPlacement,
    this.motion,
  }) : assert(twoPaneBreakpoint != Breakpoint.compact),
       assert(
         firstCollapse != PaneCollapse.dismiss || onFirstDismissed != null,
         'The first pane is dismissed through onFirstDismissed.',
       ),
       assert(
         secondCollapse != PaneCollapse.dismiss || onSecondDismissed != null,
         'The second pane is dismissed through onSecondDismissed.',
       );

  /// The first pane's content: leading, or on top; null for none.
  final Widget? first;

  /// The second pane's content: trailing, or below; null for none.
  final Widget? second;

  /// How the panes divide the space while they sit side by side: a fixed
  /// first pane beside a flexible second one by default.
  final PaneArrangement arrangement;

  /// The narrowest breakpoint at which the panes sit side by side.
  ///
  /// Expanded by default. Material recommends one pane at medium, and allows
  /// two, splitting the space evenly, for content of low information
  /// density; pass [Breakpoint.medium] for that. Compact always has one
  /// pane beside another at most in a stack.
  final Breakpoint twoPaneBreakpoint;

  /// What the layout does below [twoPaneBreakpoint]: stack the panes, by
  /// default, or show one of them.
  final PaneReflow reflow;

  /// Whether a drag handle between the panes resizes them while they sit
  /// side by side.
  final bool resizable;

  /// The drag handle shown when [resizable] is true.
  ///
  /// A [PaneResizer] around a [PaneDragHandle] by default.
  final Widget dragHandle;

  /// Holds how the panes are divided, or null for a split the layout keeps.
  ///
  /// The split describes the fixed pane, or in a split-pane arrangement the
  /// first.
  final PaneSplitController? splitController;

  /// Whether a resize is remembered. Persistent by default.
  final PaneResizeMemory resizeMemory;

  /// What the drag handle may do to the first pane, or null for Material's:
  /// hide it, unless it is the flexible pane beside a fixed one above
  /// medium, and dismiss it rather than hide it where [onFirstDismissed] is
  /// given.
  final PaneCollapse? firstCollapse;

  /// What the drag handle may do to the second pane, or null for Material's:
  /// hide it, unless it is the flexible pane beside a fixed one above
  /// medium, and dismiss it rather than hide it where [onSecondDismissed] is
  /// given.
  final PaneCollapse? secondCollapse;

  /// Called when the user dismisses the first pane, or null when it is
  /// permanent.
  ///
  /// The layout does not hide the pane itself: set [first] to null in
  /// response. A [SideSheet]'s close button in the pane calls it.
  final VoidCallback? onFirstDismissed;

  /// Called when the user dismisses the second pane, or null when it is
  /// permanent.
  ///
  /// The layout does not hide the pane itself: set [second] to null in
  /// response. A [SideSheet]'s close button in the pane calls it.
  final VoidCallback? onSecondDismissed;

  /// Where the layout keeps its margins: around the panes, which are then
  /// set in from the edges as cards, or within them, for panes painted flat
  /// whose content keeps the margins that [AdaptiveRegion.marginsOf]
  /// reports.
  ///
  /// Null to keep them where the layout this one is nested in keeps its
  /// own, and in a layout that is not nested, where
  /// [MaterialLayoutThemeData.marginPlacement] says.
  final MarginPlacement? marginPlacement;

  /// How panes enter, leave and resize, or null for the default spatial
  /// motion of the scheme in effect.
  final PaneMotion? motion;

  @override
  State<TwoPaneLayout> createState() => _TwoPaneLayoutState();
}

class _TwoPaneLayoutState extends State<TwoPaneLayout>
    with PaneCountReporter<TwoPaneLayout>, LayoutRegionState {
  final _bucket = PageStorageBucket();
  // The panes' content, kept while a pane that is no longer given leaves.
  Widget? _lastFirst;
  Widget? _lastSecond;
  (Breakpoint, Axis?)? _arrangement;

  @override
  Widget build(BuildContext context) {
    final motion = PaneMotion.resolve(context, widget.motion);
    return buildRegion(
      marginPlacement: widget.marginPlacement,
      builder: (context, region) => _buildPanes(region, motion),
    );
  }

  VoidCallback? _dismissalOf(PaneSlot slot) => slot == PaneSlot.first
      ? widget.onFirstDismissed
      : widget.onSecondDismissed;

  Widget _buildPanes(LayoutRegion region, PaneMotion motion) {
    final breakpoint = region.breakpoint;
    final budget = region.budget;
    final band = region.band;
    final first = widget.first;
    final second = widget.second;
    if (first != null) _lastFirst = first;
    if (second != null) _lastSecond = second;

    // Neither pane may take a slot kept for a side sheet. A fold or hinge
    // down the region puts a pane on each side of it from medium; one across
    // the region stacks panes that would stack, on each side of it.
    final room =
        budget.sideBySide - budget.sheetSlots >= 2 && budget.panes >= 2;
    final hinge =
        band?.axis == Axis.horizontal && breakpoint >= Breakpoint.medium;
    final tabletop = band?.axis == Axis.vertical;
    final beside =
        room &&
        (hinge ||
            breakpoint >= widget.twoPaneBreakpoint &&
                !(tabletop && widget.reflow == PaneReflow.stack));
    final stacked =
        !beside && widget.reflow == PaneReflow.stack && budget.panes >= 2;
    // Alone, the pane the layout reflows to shows, or the other where there
    // is none.
    final alone = !beside && !stacked;
    final prefersSecond = widget.reflow == PaneReflow.second;
    final showsFirst =
        first != null && (!alone || !prefersSecond || second == null);
    final showsSecond =
        second != null && (!alone || prefersSecond || first == null);
    final both = showsFirst && showsSecond;
    reportPaneCount(context, beside && both ? 2 : 1);

    final axis = beside ? Axis.horizontal : Axis.vertical;
    // A change of breakpoint or posture rearranges the panes without
    // animating them; a pane that comes or goes by itself animates.
    final arrangement = (breakpoint, band?.axis);
    final resized = _arrangement != null && _arrangement != arrangement;
    _arrangement = arrangement;

    final fixed = widget.arrangement.fixed;
    // At medium, two panes split the space evenly.
    final even = breakpoint == Breakpoint.medium && !hinge;
    // The fixed pane, or the first of two flexible panes, keeps to one pane;
    // the other has the panes this layout leaves.
    final keeper = fixed ?? PaneSlot.first;
    PaneConfig pane(
      PaneSlot slot,
      Widget? content,
      Widget? last, {
      required bool shows,
    }) {
      final dismissal = _dismissalOf(slot);
      return PaneConfig(
        child: paneContent(
          bucket: _bucket,
          // Other content starts afresh rather than in the scroll position of
          // the content before it.
          storageKey: (slot, last.runtimeType, last?.key),
          budget: slot == keeper
              ? (both ? onePane : budget)
              : PaneScope.remaining(
                  budget,
                  shown: both,
                  beside: beside && both,
                ),
          marginPlacement: region.marginPlacement,
          onDismiss: dismissal,
          child: last ?? const SizedBox.shrink(),
        ),
        visible: shows,
        maintainState: content != null,
        holdsLayout: isPaneLayout(last),
      );
    }

    // The handle hides any pane but the flexible one beside a fixed pane
    // above medium, and dismisses rather than hides a pane that can be
    // dismissed.
    PaneCollapse collapseOf(PaneSlot slot) {
      final own = slot == PaneSlot.first
          ? widget.firstCollapse
          : widget.secondCollapse;
      if (own != null) return own;
      if (fixed != null && fixed != slot && !even) return PaneCollapse.never;
      return _dismissalOf(slot) != null
          ? PaneCollapse.dismiss
          : PaneCollapse.collapse;
    }

    // A fold or hinge holds the split along the panes' own axis.
    final held = band != null && band.axis == axis && !alone
        ? bandSpacer(band)
        : null;
    final other = keeper == PaneSlot.first ? PaneSlot.second : PaneSlot.first;
    final width = fixed == null
        ? null
        : widget.arrangement.width ?? breakpoint.fixedPaneWidth;
    final split = !beside && held == null
        ? null
        : SplitConfig(
            resizable: keeper == PaneSlot.first
                ? PaneLayoutSlot.first
                : PaneLayoutSlot.second,
            stops: even ? const [PaneSplit.centered] : PaneSplit.materialStops,
            defaultExtent: width,
            even: even,
            minExtent: math.min(_minPaneWidth, width ?? _minPaneWidth),
            otherMinExtent: _minPaneWidth,
            center: held?.center ?? region.windowCenter,
            locked: held != null,
            handle: widget.resizable ? widget.dragHandle : null,
            controller: widget.splitController,
            memory: widget.resizeMemory,
            resetToken: arrangement,
            collapse: collapseOf(keeper),
            otherCollapse: collapseOf(other),
            onDismissed: _dismissalOf(keeper),
            onOtherDismissed: _dismissalOf(other),
          );

    final margins = region.margins;
    return TwoPaneView(
      axis: axis,
      first: pane(PaneSlot.first, first, _lastFirst, shows: showsFirst),
      second: pane(PaneSlot.second, second, _lastSecond, shows: showsSecond),
      marginStart: margins.start,
      marginEnd: margins.end,
      marginPlacement: region.marginPlacement,
      spacer: held?.spacer ?? paneSpacer,
      split: split,
      motion: motion,
      animate: !resized,
    );
  }
}

// The narrowest a pane of a two-pane layout may be resized to, unless it is
// fixed at a width narrower still.
const double _minPaneWidth = 280;
