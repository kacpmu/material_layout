// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/scheduler.dart';
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

/// Where a list-detail layout shows the detail.
///
/// A pane and a page need different chrome — a back affordance belongs on
/// the page only — so the layout states the placement rather than
/// leaving it to be inferred.
enum DetailPlacement {
  /// In a pane beside the list: the layout shows two panes.
  pane,

  /// On a page of its own, in place of the list: the layout shows one pane.
  page,
}

/// Builds the detail of the item [id], for [placement].
///
/// Build the same content for both placements and vary only the chrome:
/// on a page, an app bar with a back button. Keep the
/// content at the same place in the tree in both, as the body of a
/// [Scaffold] whose app bar comes and goes, so that it keeps its state and
/// focus as it moves between the pane and the page: content that
/// moves to another place in the tree is built afresh.
///
/// A detail stays on screen while it leaves — on a page that is popped, or
/// in a pane that hides — and widgets inside it may rebuild meanwhile. When
/// an item can be removed, let its detail build without it.
typedef DetailBuilder<T extends Object> = Widget Function(
  BuildContext context,
  T id,
  DetailPlacement placement,
);

enum _EmptyBehaviorKind { placeholder, hidePane, select }

/// What a two-pane list-detail layout shows when nothing is selected.
///
/// A layout with one pane shows the list whatever this is.
@immutable
final class ListDetailEmptyBehavior<T extends Object> {
  /// Shows [child] in the detail pane, or an empty pane when [child] is
  /// null.
  ///
  /// The placeholder is shown only in the pane, never as a page.
  const new placeholder({this.child})
    : id = null,
      _kind = _EmptyBehaviorKind.placeholder;

  /// Shows no detail pane: the list takes the whole layout until an item is
  /// selected, and the detail pane then appears.
  ///
  /// The detail pane is then a temporary pane, which the detail lets
  /// the user close ([ListDetailScope.canClose]).
  const new hidePane()
    : child = null,
      id = null,
      _kind = _EmptyBehaviorKind.hidePane;

  /// Shows the detail of [id] and marks it selected in the list; usually
  /// the first item.
  ///
  /// The selection itself stays empty, so that a resize never changes state
  /// the caller owns, and returning to one pane shows the list again.
  /// Pass the id on every build, so that it follows the list as items
  /// arrive or are removed. Only a layout that builds its own detail, from
  /// [ListDetailLayout.new], can show one this way.
  const new select(T this.id) : child = null, _kind = _EmptyBehaviorKind.select;

  /// The placeholder, for [ListDetailEmptyBehavior.placeholder].
  final Widget? child;

  /// The item shown, for [ListDetailEmptyBehavior.select].
  final T? id;

  final _EmptyBehaviorKind _kind;

  @override
  bool operator ==(Object other) =>
      other is ListDetailEmptyBehavior<T> &&
      other._kind == _kind &&
      other.child == child &&
      other.id == id;

  @override
  int get hashCode => Object.hash(_kind, child, id);
}

/// A list-detail layout as seen from a widget inside it.
///
/// Obtained with [ListDetailLayout.of]. The list uses it to select items and
/// to mark the selected one; the detail uses it to learn its placement.
@immutable
final class ListDetailScope<T extends Object> {
  const new _({
    required this.placement,
    required this.selectedId,
    required this.canClose,
    required this._marked,
    required this._onSelect,
    required this._onClose,
  });

  /// Where the detail is shown.
  ///
  /// Inside the detail, the placement it was built for. Elsewhere, such as
  /// in the list, where the detail of a selected item appears: in a pane
  /// when the layout shows two, on a page when it shows one.
  final DetailPlacement placement;

  /// The selected item, or null when nothing is selected.
  final T? selectedId;

  /// Whether the detail beside the list can be closed, with [close].
  ///
  /// True while two panes show the selected item's detail and the layout has
  /// something to show without it: a placeholder, or the list alone
  /// ([ListDetailEmptyBehavior.placeholder] and
  /// [ListDetailEmptyBehavior.hidePane]). A detail that can be closed should
  /// offer a close button: beside the list it has no back affordance,
  /// and nothing else takes it away. A close button is not a back
  /// button: it dismisses the detail, while the list stays where it is.
  ///
  /// False on a page, where the back affordance leads to the list, and with
  /// [ListDetailEmptyBehavior.select], where closing would only show another
  /// item.
  final bool canClose;

  // The item the list marks as selected, or null.
  final T? _marked;
  final ValueChanged<T?> _onSelect;
  final VoidCallback _onClose;

  /// Whether the list should show [id] as selected.
  ///
  /// True when two panes show and [id]'s detail is the one beside the list.
  /// A list at one pane marks nothing: selecting an item there opens it.
  bool isSelected(T id) => _marked == id;

  /// Selects [id], or clears the selection when [id] is null.
  void select(T? id) => _onSelect(id);

  /// Closes the detail beside the list, where [canClose] is true, clearing
  /// the selection.
  ///
  /// Focus in the detail moves to the list, to the item that opened the
  /// detail when that item had focus, so that it is not lost with the detail.
  void close() => _onClose();

  bool _differs(ListDetailScope<Object> other) =>
      placement != other.placement ||
      selectedId != other.selectedId ||
      canClose != other.canClose ||
      _marked != other._marked;
}

class _ListDetailInherited extends InheritedWidget {
  const new({super.key, required this.scope, required super.child});

  final ListDetailScope<Object> scope;

  @override
  bool updateShouldNotify(_ListDetailInherited oldWidget) =>
      scope._differs(oldWidget.scope);
}

/// A collection beside the detail of the item selected from it.
///
/// Inbox and message, file browser and file, settings and category. The
/// layout shows one pane below [twoPaneBreakpoint] and two at and above it,
/// resolved against the region it occupies:
///
///  * With one pane, only the list or the detail shows. Selecting an
///    item pushes its detail as a page on a navigator the layout owns,
///    so the page's app bar supplies the back affordance and the
///    system back button returns to the list.
///  * With two panes, the detail sits beside the list, which marks the
///    selected item. Selecting another item replaces the detail
///    without animating it. The detail has no back affordance there;
///    where the layout has something to show without it, it offers
///    a close button instead, which [ListDetailScope.canClose] and
///    [ListDetailScope.close] support.
///  * Widening with an item selected shows both panes with its detail;
///    narrowing shows the detail on its page; and returning to one pane
///    restores the view shown before. A resize never navigates outside the
///    layout, and a change of the window alone pushes or removes the
///    detail page without a transition. Room that another pane takes or
///    gives back, as a side sheet that opens or closes beside the layout, is
///    given up and taken back with motion: the list leaves or enters on the
///    pane motion, and the detail moves between the page and the
///    pane where it stands. Going back from the page when that brings the
///    room back, as when the side sheet shows the selected item and closes
///    with the selection, turns the page into the detail pane the same way,
///    showing what two panes show with nothing selected; a page that the
///    back gesture takes away, which showed the list at one pane as it went,
///    leaves first.
///  * Each item's detail keeps its state and its scroll position, in the
///    pane and on the page alike, and as it moves between them.
///
/// At one pane, the detail's page takes the list pane's place: with the
/// margins around the panes it is set in by them, and it keeps the corners
/// of [MaterialLayoutThemeData.paneBorderRadius] while it comes and goes.
///
/// With [resizable], a drag handle between the panes resizes them. It
/// collapses the list, and where the panes split evenly, at medium, the
/// detail too; [listCollapse] and [detailCollapse] change which pane it may
/// hide, and whether hiding the detail closes it. A hidden pane leaves the
/// other the whole width, with the handle in the margin beside it.
/// Selecting an item while the detail is hidden shows it again.
///
/// ```dart
/// ListDetailLayout<int>(
///   listBuilder: (context) {
///     final layout = ListDetailLayout.of<int>(context);
///     return ListView(
///       children: [
///         for (final message in messages)
///           ListTile(
///             title: Text(message.subject),
///             selected: layout.isSelected(message.id),
///             onTap: () => layout.select(message.id),
///           ),
///       ],
///     );
///   },
///   // The same place in the tree in both placements, which keeps the
///   // message's state as it moves; only the page has an app bar.
///   detailBuilder: (context, id, placement) => Scaffold(
///     appBar: placement == DetailPlacement.page ? AppBar() : null,
///     body: MessageView(id: id),
///   ),
/// );
/// ```
///
/// The selection belongs to the layout unless [onSelectionChanged] is given;
/// the caller then owns it and passes it back as [selectedId], which is how
/// a selection is bound to a URL. The layout never reads or writes a
/// URL, and never touches the caller's navigator.
///
/// Because the layout owns a navigator, a route pushed from inside it with
/// `Navigator.of` opens within the layout's region, and at one pane within
/// the pane's place. Push with `Navigator.of(context, rootNavigator: true)`
/// to cover the whole screen.
/// [ListDetailLayout.custom] mounts no navigator.
///
/// A layout nested in the detail pane may use the panes this one leaves:
/// at extra-large, a standard side sheet beside the detail makes the
/// third pane. The list keeps to one pane.
class ListDetailLayout<T extends Object> extends StatefulWidget {
  /// Creates a list-detail layout that builds the detail of the selected
  /// item with [detailBuilder].
  const new({
    super.key,
    this.selectedId,
    this.onSelectionChanged,
    required this.listBuilder,
    required DetailBuilder<T> this.detailBuilder,
    this.emptyBehavior = const ListDetailEmptyBehavior.placeholder(),
    this.twoPaneBreakpoint = Breakpoint.expanded,
    this.resizable = false,
    this.dragHandle = const PaneResizer(),
    this.splitController,
    this.resizeMemory = PaneResizeMemory.persistent,
    this.listCollapse,
    this.detailCollapse,
    this.marginPlacement,
    this.motion,
    this.restorationId,
  }) : detail = null,
       assert(twoPaneBreakpoint != Breakpoint.compact),
       assert(
         listCollapse != PaneCollapse.dismiss,
         'The list can be collapsed, but never dismissed.',
       );

  /// Creates a list-detail layout that places the [detail] it is given.
  ///
  /// The layout mounts no navigator and handles no back navigation. With
  /// two panes, [detail] shows beside the list while [selectedId] is not
  /// null; with one, it replaces the list, and the caller navigates back by
  /// clearing the selection. [detail] may itself be a [Navigator] or a
  /// [Router], such as a shell route's child, and stays mounted as the
  /// layout changes between one and two panes.
  ///
  /// [ListDetailEmptyBehavior.select] is not available: the layout cannot
  /// build the detail of an item it was not given.
  const new custom({
    super.key,
    this.selectedId,
    this.onSelectionChanged,
    required this.listBuilder,
    required Widget this.detail,
    this.emptyBehavior = const ListDetailEmptyBehavior.placeholder(),
    this.twoPaneBreakpoint = Breakpoint.expanded,
    this.resizable = false,
    this.dragHandle = const PaneResizer(),
    this.splitController,
    this.resizeMemory = PaneResizeMemory.persistent,
    this.listCollapse,
    this.detailCollapse,
    this.marginPlacement,
    this.motion,
    this.restorationId,
  }) : detailBuilder = null,
       assert(twoPaneBreakpoint != Breakpoint.compact),
       assert(
         listCollapse != PaneCollapse.dismiss,
         'The list can be collapsed, but never dismissed.',
       );

  /// The selected item, or null when nothing is selected.
  ///
  /// When the layout owns the selection — [onSelectionChanged] is null and
  /// the layout builds the detail — this is only its initial value.
  final T? selectedId;

  /// Called when the user selects an item or navigates back from its detail.
  ///
  /// When given, the caller owns the selection: the layout shows
  /// [selectedId] and asks for changes through this callback. A resize
  /// never calls it.
  final ValueChanged<T?>? onSelectionChanged;

  /// Builds the list.
  ///
  /// Items select themselves through [ListDetailLayout.of], which also tells
  /// them whether to show as selected.
  final WidgetBuilder listBuilder;

  /// Builds the detail of an item, for [ListDetailLayout.new].
  final DetailBuilder<T>? detailBuilder;

  /// The detail, for [ListDetailLayout.custom].
  final Widget? detail;

  /// What two panes show when nothing is selected.
  final ListDetailEmptyBehavior<T> emptyBehavior;

  /// The narrowest breakpoint at which the layout shows two panes.
  ///
  /// Expanded by default. Material recommends one pane at medium and allows
  /// two for content of low information density, where they
  /// split evenly; pass [Breakpoint.medium] for that. Compact always
  /// shows one pane.
  final Breakpoint twoPaneBreakpoint;

  /// Whether a drag handle between the panes resizes them.
  final bool resizable;

  /// The drag handle shown when [resizable] is true.
  ///
  /// A [PaneResizer] around a [PaneDragHandle] by default.
  final Widget dragHandle;

  /// Holds how the panes are divided, or null for a split the layout keeps.
  ///
  /// The split describes the list pane.
  final PaneSplitController? splitController;

  /// Whether a resize is remembered. Persistent by default.
  final PaneResizeMemory resizeMemory;

  /// What the drag handle may do to the list, or null for Material's:
  /// collapse it.
  ///
  /// The list is never dismissed.
  final PaneCollapse? listCollapse;

  /// What the drag handle may do to the detail pane, or null for Material's:
  /// collapse it where the panes split evenly, at medium, and never hide it
  /// beside a list of fixed width, from expanded upwards.
  ///
  /// [PaneCollapse.dismiss] closes the detail as [ListDetailScope.close]
  /// does, clearing the selection. It needs
  /// [ListDetailEmptyBehavior.hidePane], where the list then shows alone:
  /// with a placeholder the detail pane would stay to show it, and with an
  /// item selected in its place it could not be closed at all.
  final PaneCollapse? detailCollapse;

  /// Where the layout keeps its margins: around the panes, which are
  /// then set in from the edges as cards, or within them, for panes painted
  /// flat whose content keeps the margins that [AdaptiveRegion.marginsOf]
  /// reports.
  ///
  /// The detail's page, at one pane, takes the pane's place: it is set in
  /// as the pane is, or reaches the edges while its content keeps the
  /// margins.
  ///
  /// Null to keep them where the layout this one is nested in keeps its
  /// own, and in a layout that is not nested, where
  /// [MaterialLayoutThemeData.marginPlacement] says.
  final MarginPlacement? marginPlacement;

  /// How panes enter, leave and resize, or null for the default spatial
  /// motion of the scheme in effect.
  final PaneMotion? motion;

  /// Restores the selection, when the layout owns it, and the split, when
  /// the layout keeps it.
  ///
  /// The selection is restored when its id is a number, a string or a
  /// boolean.
  final String? restorationId;

  /// The list-detail layout enclosing [context].
  static ListDetailScope<T> of<T extends Object>(BuildContext context) {
    final scope = maybeOf<T>(context);
    assert(scope != null, 'No ListDetailLayout encloses this context.');
    return scope!;
  }

  /// The list-detail layout enclosing [context], or null.
  static ListDetailScope<T>? maybeOf<T extends Object>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ListDetailInherited>()?.scope
          as ListDetailScope<T>?;

  @override
  State<ListDetailLayout<T>> createState() => _ListDetailLayoutState<T>();
}

class _ListDetailLayoutState<T extends Object>
    extends State<ListDetailLayout<T>>
    with
        PaneCountReporter<ListDetailLayout<T>>,
        RestorationMixin,
        LayoutRegionState {
  final _bucket = PageStorageBucket();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _transitions = _ListDetailTransitionDelegate();
  late final _ownSelection = _RestorableId<T>(widget.selectedId);
  final _restorableSplit = _RestorableSplit();
  HeroController? _heroController;
  PaneSplitController? _ownSplit;
  bool? _twoPanes;
  // The window, and whether a fold or hinge divides the layout, as of the
  // last build.
  Size? _window;
  bool? _hinged;
  bool _listLeaving = false;
  bool _listLeft = false;
  bool _listReturning = false;
  // Whether the list pane was shown, or on its way, as of the last build.
  bool _listShown = false;
  // Whether the detail was on a page, as of the last build.
  bool _hadPage = false;
  // The detail page on its way out, and whether a back gesture took it
  // away. It leaves in the pane's place.
  _DetailRoute? _leavingPage;
  bool _leftByGesture = false;
  late final _navigatorObservers = <NavigatorObserver>[
    _PagePops(_handlePagePopped),
  ];
  _LeavingDetail? _lastDetail;
  // A detail keeps its element, and so its state, as it moves between the
  // pane and the page.
  final _detailKeys = <T, GlobalKey>{};
  // The selected item that one pane shows the list for rather than its
  // page: one whose page was closed while the caller kept it selected.
  T? _listShownFor;
  bool _canClose = false;
  // Whether two panes show, as of the last build.
  bool _showsTwo = false;
  // The list and the detail beside it, for moving focus from one to the
  // other when the detail closes.
  final _listFocus = FocusNode(
    debugLabel: 'ListDetailLayout list',
    skipTraversal: true,
    canRequestFocus: false,
  );
  final _detailFocus = FocusNode(
    debugLabel: 'ListDetailLayout detail',
    skipTraversal: true,
    canRequestFocus: false,
  );
  // The item in the list that had focus when it was selected.
  FocusNode? _opener;

  bool _inList(FocusNode node) => node.ancestors.contains(_listFocus);

  void _close() {
    if (!_canClose) return;
    if (_detailFocus.hasFocus) {
      final opener = _opener;
      if (opener != null &&
          opener.context != null &&
          opener.canRequestFocus &&
          _inList(opener)) {
        opener.requestFocus();
      } else {
        _listFocus.traversalDescendants.firstOrNull?.requestFocus();
      }
    }
    _select(null);
  }

  bool get _builds => widget.detailBuilder != null;

  // A layout given its detail follows the caller's selection, which the
  // caller's own navigation may change without a callback.
  bool get _callerOwned => widget.onSelectionChanged != null || !_builds;

  T? get _selection => _callerOwned ? widget.selectedId : _ownSelection.value;

  PaneSplitController get _splitController =>
      widget.splitController ?? (_ownSplit ??= _createSplit());

  PaneSplitController _createSplit() =>
      PaneSplitController(split: _restorableSplit.value)
        ..addListener(_storeSplit);

  void _storeSplit() => _restorableSplit.value = _ownSplit!.value;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_ownSelection, 'selection');
    registerForRestoration(_restorableSplit, 'split');
    final split = _ownSplit;
    if (split != null && split.value != _restorableSplit.value) {
      split.value = _restorableSplit.value;
    }
  }

  @override
  void didUpdateWidget(ListDetailLayout<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) _listShownFor = null;
  }

  @override
  void dispose() {
    _listFocus.dispose();
    _detailFocus.dispose();
    _ownSelection.dispose();
    _restorableSplit.dispose();
    _ownSplit?.dispose();
    _heroController?.dispose();
    super.dispose();
  }

  void _select(T? id) {
    if (id != null) {
      // Selecting the item whose page was closed, which the caller kept
      // selected, opens it again.
      if (id == _listShownFor) setState(() => _listShownFor = null);
      final focus = FocusManager.instance.primaryFocus;
      _opener = focus != null && _inList(focus) ? focus : null;
      // A detail the handle has hidden shows the item selected beside the
      // list.
      final split = _splitController;
      if (_showsTwo && split.value.isExpanded) {
        if (widget.resizeMemory == PaneResizeMemory.temporary) {
          split.value = PaneSplit.automatic;
        } else {
          split.toggle();
        }
      }
    }
    if (_callerOwned) {
      widget.onSelectionChanged?.call(id);
    } else if (_ownSelection.value != id) {
      setState(() => _ownSelection.value = id);
    }
  }

  // A navigator reports whether it can pop only when its history changes, so
  // one that starts with the detail page, as after a deep link, would leave
  // the system back button to the navigator above it. The layout reports it
  // instead.
  void _announcePage({required bool hasPage}) {
    if (hasPage == _hadPage) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (!mounted || navigator == null) return;
      NavigationNotification(canHandlePop: navigator.canPop())
          .dispatch(navigator.context);
    });
  }

  // The list has left for want of room: the detail becomes a page.
  void _handleListSettled(PaneLayoutSlot slot, {required bool visible}) {
    if (slot != PaneLayoutSlot.first || visible || !_listLeaving) return;
    setState(() {
      _listLeaving = false;
      _listLeft = true;
    });
  }

  void _handlePagePopped(Route<Object?> route) {
    if (route is! _DetailRoute) return;
    final animation = route.animation;
    if (animation == null || animation.isDismissed) return;
    // Popped while the layout builds, the page is noted for the builds to
    // come.
    _leavingPage = route;
    _leftByGesture = route.navigator?.userGestureInProgress ?? false;
    route.completed.whenComplete(() {
      if (!mounted || _leavingPage != route) return;
      setState(() => _leavingPage = null);
    });
  }

  void _handlePageRemoved(Page<Object?> page) {
    if (page.key != _detailPageKey) return;
    final selection = _selection;
    if (_callerOwned) _listShownFor = selection;
    // The page leaves with its detail on it, which a pane that shows the
    // item again while the page is still leaving must not take from it.
    _detailKeys.remove(selection);
    _select(null);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      _builds || widget.emptyBehavior._kind != _EmptyBehaviorKind.select,
      'ListDetailEmptyBehavior.select needs a layout that builds its own '
      'detail: use ListDetailLayout.new.',
    );
    assert(
      widget.detailCollapse != PaneCollapse.dismiss ||
          widget.emptyBehavior._kind == _EmptyBehaviorKind.hidePane,
      'The drag handle dismisses the detail only where the list then shows '
      'alone, with ListDetailEmptyBehavior.hidePane. With a placeholder, '
      'the detail pane would stay to show it; with an item selected in its '
      'place, the detail cannot be closed.',
    );
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
    final marginPlacement = region.marginPlacement;
    final band = region.band;
    // A hinge puts a pane on each side of it, but a compact layout keeps to
    // one pane.
    final hinge =
        band?.axis == Axis.horizontal && breakpoint >= Breakpoint.medium
        ? band
        : null;
    final held = hinge == null ? null : bandSpacer(hinge);

    // Neither the list nor the detail may take a slot kept for a side sheet.
    final room =
        budget.sideBySide - budget.sheetSlots >= 2 && budget.panes >= 2;
    final fits = breakpoint >= widget.twoPaneBreakpoint || hinge != null;
    final selection = _selection;
    final placeholder =
        widget.emptyBehavior._kind == _EmptyBehaviorKind.placeholder;
    // A detail page that leaves as the room for two panes comes back, as
    // when back also closes a side sheet beside the layout, turns into the
    // detail pane where it stands: it is gone at once, the pane shows what
    // two panes show with nothing selected, and the list enters beside it.
    // One that a back gesture took away showed the list at one pane as it
    // went, so the panes wait for it to leave in its pane's place, and then
    // rearrange; as they do for a page leaving with nothing to show in the
    // pane.
    final leavingPage = _leavingPage;
    final pageTurnsIntoPane =
        leavingPage != null &&
        !_leftByGesture &&
        room &&
        fits &&
        ((selection ?? widget.emptyBehavior.id) != null || placeholder);
    final twoPanes = room && fits && (leavingPage == null || pageTurnsIntoPane);

    // A change of the window, as when it is resized or folded, changes the
    // number of panes at once. Room that another pane takes, as a side sheet
    // that opens beside the layout, is given up with motion: the list leaves
    // on the pane motion, and only then does the selected item's
    // detail become a page.
    final window = MediaQuery.sizeOf(context);
    final hinged = hinge != null;
    final rearranged = _twoPanes != null && _twoPanes != twoPanes;
    final windowChanged =
        (_window != null && _window != window) ||
        (_hinged != null && _hinged != hinged);
    // A change of the window while the list leaves ends its leaving too.
    final resized = (rearranged || _listLeaving) && windowChanged;
    _window = window;
    _hinged = hinged;
    // At one pane, the selection whose detail shows in place of the list:
    // none where the caller kept one whose page was closed.
    final pageSelection = selection == _listShownFor ? null : selection;
    // Only a list that shows has anywhere to leave from: one yet to enter,
    // as the frame after the page turned back into the pane, is gone
    // already. A list that one pane shows stays.
    if (rearranged &&
        !resized &&
        !twoPanes &&
        _builds &&
        pageSelection != null &&
        _listShown &&
        !motion.exit.isNone &&
        !_splitController.value.isCollapsed) {
      _listLeaving = true;
    }
    if (twoPanes || resized || pageSelection == null) _listLeaving = false;
    // Room regained, as when the side sheet beside the layout closes, is
    // taken back with motion too: the page turns back into the detail pane
    // where it stands, and the list then enters on the pane motion.
    final pageReturns =
        rearranged &&
        !resized &&
        twoPanes &&
        _builds &&
        (_hadPage && selection != null || pageTurnsIntoPane);
    if (pageReturns && !motion.enter.isNone) {
      _listReturning = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_listReturning) return;
        setState(() => _listReturning = false);
      });
    }
    if (!twoPanes || selection == null && !pageTurnsIntoPane) {
      _listReturning = false;
    }
    // The page is done after the frame, which it covers the pane in.
    if (pageTurnsIntoPane && rearranged) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => leavingPage.finishLeaving(),
      );
    }
    final finishing = _listLeft;
    _listLeft = false;
    _twoPanes = twoPanes;
    final showsTwo = _showsTwo = twoPanes || _listLeaving;

    final shownId = selection ?? (showsTwo ? widget.emptyBehavior.id : null);
    final hasDetail = _builds ? shownId != null : selection != null;
    // The detail pane as it shows, and as it will once the list has left.
    final detailPane = showsTwo && (hasDetail || placeholder);
    final detailBeside = twoPanes && (hasDetail || placeholder);
    reportPaneCount(context, detailBeside ? 2 : 1);
    // A detail beside the list can be closed where the layout has something
    // to show without it.
    _canClose =
        showsTwo &&
        selection != null &&
        widget.emptyBehavior._kind != _EmptyBehaviorKind.select;
    // The item the list marks: the one beside it. At one pane, the list
    // marks none.
    final marked = showsTwo ? shownId : null;

    final even = breakpoint == Breakpoint.medium && hinge == null;

    // A nested layout may use the panes this one leaves. Beside the
    // list, the detail pane has them all, and the list keeps to one pane.
    Widget content({
      required Object storageKey,
      required DetailPlacement placement,
      required WidgetBuilder builder,
      bool list = false,
      Key? key,
    }) => _ListDetailInherited(
      key: key,
      scope: ListDetailScope<T>._(
        placement: placement,
        selectedId: selection,
        canClose: _canClose,
        marked: marked,
        onSelect: _select,
        onClose: _close,
      ),
      child: paneContent(
        bucket: _bucket,
        storageKey: storageKey,
        budget: list && detailBeside
            ? onePane
            : PaneScope.remaining(
                budget,
                shown: detailBeside,
                beside: detailBeside,
              ),
        marginPlacement: marginPlacement,
        child: Builder(builder: builder),
      ),
    );

    final listPlacement = showsTwo
        ? DetailPlacement.pane
        : DetailPlacement.page;
    final list = content(
      storageKey: 'list',
      placement: listPlacement,
      builder: widget.listBuilder,
      list: true,
    );

    // A detail pane that leaves because nothing is selected, with no
    // placeholder to show, leaves with the detail it showed, as it was: the
    // detail builder is not asked again for an item that may be gone.
    // It keeps it while it leaves whatever the arrangement, as when room is
    // given up to another pane meanwhile.
    final lastDetail = _lastDetail;
    final detailLeaving =
        !detailPane && (_builds ? lastDetail != null : showsTwo);
    Widget detail;
    if (!hasDetail && !detailLeaving) {
      detail = content(
        storageKey: 'placeholder',
        placement: DetailPlacement.pane,
        builder: (_) => widget.emptyBehavior.child ?? const SizedBox.expand(),
      );
    } else if (_builds && !hasDetail) {
      lastDetail!.leaving = true;
      detail = lastDetail.widget;
    } else if (_builds) {
      final id = shownId!;
      final shown = _LeavingDetail(id);
      shown.widget = content(
        key: _detailKeyOf(id),
        storageKey: ('detail', id),
        placement: DetailPlacement.pane,
        builder: (context) => shown.leaving
            ? shown.built ?? const SizedBox.shrink()
            : shown.built = widget.detailBuilder!(
                context,
                id,
                DetailPlacement.pane,
              ),
      );
      _lastDetail = shown;
      detail = shown.widget;
    } else {
      detail = content(
        storageKey: 'detail',
        placement: listPlacement,
        builder: (_) => widget.detail!,
      );
    }

    final margins = region.margins;
    // The detail can be dismissed by the handle only where it can be closed.
    var detailCollapse =
        widget.detailCollapse ??
        (even ? PaneCollapse.collapse : PaneCollapse.never);
    if (detailCollapse == PaneCollapse.dismiss && !_canClose) {
      detailCollapse = PaneCollapse.never;
    }
    final split = showsTwo
        ? SplitConfig(
            resizable: PaneLayoutSlot.first,
            stops: even ? const [PaneSplit.centered] : PaneSplit.materialStops,
            defaultExtent: breakpoint.fixedPaneWidth,
            even: even,
            minExtent: _minPaneWidth,
            otherMinExtent: _minPaneWidth,
            center: held?.center ?? region.windowCenter,
            locked: hinge != null,
            handle: widget.resizable ? widget.dragHandle : null,
            controller: _splitController,
            memory: widget.resizeMemory,
            resetToken: (breakpoint, hinge != null),
            collapse: widget.listCollapse ?? PaneCollapse.collapse,
            otherCollapse: detailCollapse,
            onOtherDismissed: _close,
          )
        : null;

    final pageId = _builds && !showsTwo ? pageSelection : null;
    // The detail moves between the pane and the page where it stands, and is
    // never on both: the pane gives way to a page that appears at once, and
    // the page turns back into the pane at once, the list entering
    // afterwards when the room was regained. A list still on its way out
    // when the room comes back, before there was a page, turns back on the
    // pane motion instead.
    final paneBecomesPage = pageId != null && !_hadPage;
    // At one pane, and while a page leaves, the pages take the pane's place.
    // With the margins around the panes, that place is set in by them and
    // has the panes' corners.
    final pagesSetIn =
        _builds &&
        (!showsTwo || leavingPage != null) &&
        marginPlacement == MarginPlacement.outside;
    final listVisible = showsTwo
        ? !_listLeaving && !_listReturning
        : _builds || pageSelection == null;
    _listShown = listVisible;
    final base = TwoPaneView(
      first: PaneConfig(
        child: Focus(
          focusNode: _listFocus,
          includeSemantics: false,
          child: list,
        ),
        visible: listVisible,
      ),
      second: PaneConfig(
        child: Focus(
          focusNode: _detailFocus,
          includeSemantics: false,
          child: detail,
        ),
        visible: showsTwo ? detailPane : !_builds && pageSelection != null,
        maintainState: !_builds,
      ),
      marginStart: pagesSetIn ? 0 : margins.start,
      marginEnd: pagesSetIn ? 0 : margins.end,
      marginPlacement: marginPlacement,
      spacer: held?.spacer ?? paneSpacer,
      split: split,
      motion: motion,
      animate:
          !resized &&
          !finishing &&
          !paneBecomesPage &&
          !pageReturns &&
          (showsTwo || _builds || rearranged),
      onPaneSettled: _listLeaving ? _handleListSettled : null,
    );
    if (!_builds) return base;

    _announcePage(hasPage: pageId != null);
    _hadPage = pageId != null;
    // Only a selection pushes or pops the detail page with a transition.
    _transitions.animate = !rearranged && !resized && !finishing;
    // Keys are kept for the details on screen, and for the one leaving.
    final leaving = _lastDetail;
    _detailKeys.removeWhere(
      (id, _) =>
          id != pageId &&
          id != shownId &&
          !(leaving != null && leaving.leaving && id == leaving.id),
    );
    return _PageArea(
      margins: pagesSetIn ? margins : null,
      borderRadius: pagesSetIn
          ? MaterialLayoutTheme.of(context).paneBorderRadius
          : BorderRadius.zero,
      child: NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
        child: HeroControllerScope(
          controller: _heroController ??=
              MaterialApp.createMaterialHeroController(),
          child: Navigator(
            key: _navigatorKey,
            transitionDelegate: _transitions,
            onDidRemovePage: _handlePageRemoved,
            observers: _navigatorObservers,
            pages: [
              MaterialPage<void>(key: _listPageKey, child: base),
              if (pageId != null)
                _DetailPage(
                  key: _detailPageKey,
                  // The page takes the place of the pane it replaces, and
                  // keeps the margins as that pane does: in a place already
                  // set in by them, its content keeps none, and reaching the
                  // edges, its content keeps them.
                  child: PaneMargins(
                    margins: marginPlacement == MarginPlacement.inside
                        ? margins
                        : EdgeInsetsDirectional.zero,
                    child: Material(
                      type: MaterialType.transparency,
                      child: content(
                        key: _detailKeyOf(pageId),
                        storageKey: ('detail', pageId),
                        placement: DetailPlacement.page,
                        builder: (context) => widget.detailBuilder!(
                          context,
                          pageId,
                          DetailPlacement.page,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GlobalKey _detailKeyOf(T id) =>
      _detailKeys[id] ??= GlobalKey(debugLabel: 'ListDetailLayout detail $id');
}

// The place the layout's pages take: at one pane with the margins around the
// panes, the pane's place, set in by the margins and clipped to the panes'
// corners, so that a page, and the transition it comes and goes with, stays
// within the pane. It keeps no horizontal safe-area insets there, which the
// margins keep it clear of. The media query is read here, so that the layout
// does not rebuild with every change to it.
class _PageArea extends StatelessWidget {
  const new({
    required this.margins,
    required this.borderRadius,
    required this.child,
  });

  // The margins the place is set in by, or null for the whole region.
  final EdgeInsetsDirectional? margins;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final margins = this.margins;
    final setIn = margins != null;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: margins?.start ?? 0,
        end: margins?.end ?? 0,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: borderRadius != BorderRadius.zero
            ? Clip.antiAlias
            : Clip.none,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .removePadding(removeLeft: setIn, removeRight: setIn),
          child: child,
        ),
      ),
    );
  }
}

// The detail's page, which can be done leaving at once, when it turns into
// the detail pane where it stands.
class _DetailPage extends MaterialPage<void> {
  const new({required super.key, required super.child});

  @override
  Route<void> createRoute(BuildContext context) =>
      _DetailRoute(page: this, allowSnapshotting: allowSnapshotting);
}

class _DetailRoute extends PageRoute<void>
    with MaterialRouteTransitionMixin<void> {
  new({required _DetailPage page, super.allowSnapshotting})
    : super(settings: page);

  _DetailPage get _page => settings as _DetailPage;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get includeRouteSemantics => _page.includeRouteSemantics;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  // Ends the transition the popped page leaves on, which removes it.
  void finishLeaving() {
    final controller = this.controller;
    if (controller == null || controller.isDismissed || isActive) return;
    controller.value = controller.lowerBound;
  }
}

// Reports the routes popped from the layout's navigator.
class _PagePops extends NavigatorObserver {
  new(this._onPop);

  final void Function(Route<Object?> route) _onPop;

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      _onPop(route);
}

// The minimum width of a list-detail pane.
const double _minPaneWidth = 360;

// The detail last shown in the detail pane. Once it leaves, rebuilding it
// reuses what the detail builder built last rather than building the detail
// of an item that may have gone.
class _LeavingDetail {
  new(this.id);

  final Object id;
  late Widget widget;
  Widget? built;
  bool leaving = false;
}

const _listPageKey = ValueKey<String>('list');
const _detailPageKey = ValueKey<String>('detail');

// Pushes and pops the detail page with a transition when the selection
// changes, and without one when a resize alone changes the placement.
class _ListDetailTransitionDelegate extends TransitionDelegate<void> {
  bool animate = true;

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    if (animate) {
      return const DefaultTransitionDelegate<void>().resolve(
        newPageRouteHistory: newPageRouteHistory,
        locationToExitingPageRoute: locationToExitingPageRoute,
        pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
      );
    }
    final results = <RouteTransitionRecord>[];
    void exit(RouteTransitionRecord? location) {
      final exiting = locationToExitingPageRoute[location];
      if (exiting == null) return;
      if (exiting.isWaitingForExitingDecision) {
        exiting.markForComplete(exiting.route.currentResult);
        for (final pageless
            in pageRouteToPagelessRoutes[exiting] ??
                const <RouteTransitionRecord>[]) {
          if (pageless.isWaitingForExitingDecision) {
            pageless.markForComplete(pageless.route.currentResult);
          }
        }
      }
      results.add(exiting);
      exit(exiting);
    }

    exit(null);
    for (final route in newPageRouteHistory) {
      if (route.isWaitingForEnteringDecision) route.markForAdd();
      results.add(route);
      exit(route);
    }
    return results;
  }
}

class _RestorableId<T extends Object> extends RestorableValue<T?> {
  new(this._initial);

  final T? _initial;

  @override
  T? createDefaultValue() => _initial;

  @override
  void didUpdateValue(T? oldValue) => notifyListeners();

  @override
  T? fromPrimitives(Object? data) => data is T ? data : null;

  @override
  Object? toPrimitives() {
    final id = value;
    return id is num || id is String || id is bool ? id : null;
  }
}

class _RestorableSplit extends RestorableValue<PaneSplit> {
  @override
  PaneSplit createDefaultValue() => PaneSplit.automatic;

  @override
  void didUpdateValue(PaneSplit? oldValue) => notifyListeners();

  @override
  PaneSplit fromPrimitives(Object? data) {
    try {
      return PaneSplit.fromJson(data);
    } on FormatException {
      return PaneSplit.automatic;
    }
  }

  @override
  Object? toPrimitives() => value.toJson();
}
