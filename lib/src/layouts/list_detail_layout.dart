import 'package:material_ui/material_ui.dart';

import '../foundation/adaptive_layout_theme.dart';
import '../foundation/pane_transition.dart';
import 'pane_controller.dart';
import 'pane_drag_handle.dart';
import 'two_pane.dart';

/// What a [ListDetailLayout] shows when nothing is selected.
enum ListDetailBehavior {
  /// No selection → the detail pane is **hidden** and the list fills the whole
  /// region. Selecting an item reveals the pane (its width animates in).
  hidden,

  /// No selection → a **placeholder** occupies the detail pane (which is always
  /// present in two-pane mode).
  placeholder,

  /// [ListDetailLayout.initialId] is treated as **selected** by default, so the
  /// detail pane always has content.
  /// On wide layouts it fills the detail pane (so the two-pane is never empty);
  /// on narrow layouts the list is shown and the default is *not* auto-pushed —
  /// tap an item to open its detail. A detail being viewed on wide is kept
  /// (pushed) when shrinking to narrow.
  selected,
}

/// A read/write handle on a [ListDetailLayout]'s selection, obtained via
/// [ListDetail.of]. Leaf list items use it to open a detail without knowing
/// whether selection is controlled, uncontrolled, or controller-driven.
abstract class ListDetailSelection {
  /// The currently selected id, or `null` when nothing is selected.
  Object? get selectedId;

  /// Whether something is selected.
  bool get hasSelection;

  /// The enclosing layout's empty-state [ListDetailBehavior]. Exposed on the
  /// handle so the list and the detail can adapt (e.g. choose their own close
  /// affordance) without the behavior being passed down the widget tree.
  ListDetailBehavior get behavior;

  /// Selects [id] (shows its detail).
  void select(Object id);

  /// Clears the selection (returns to the list on compact widths).
  void clear();
}

/// An external, imperative selection driver for a [ListDetailLayout]. Hold one
/// and pass it to [ListDetailLayout.controller] to drive and observe the
/// selection from outside the tree (it is a [ChangeNotifier]).
///
/// It is *not* the in-tree handle: descendants read the live selection (and
/// [ListDetailSelection.behavior]) via [ListDetail.of], which always resolves
/// to the enclosing layout regardless of how selection is driven.
class ListDetailController extends ChangeNotifier {
  /// Creates a controller, optionally starting with [initialId] selected.
  ListDetailController({Object? initialId}) : _selectedId = initialId;

  Object? _selectedId;

  /// The currently selected id, or `null` when nothing is selected.
  Object? get selectedId => _selectedId;

  /// Whether something is selected.
  bool get hasSelection => _selectedId != null;

  /// Selects [id].
  void select(Object id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Clears the selection.
  void clear() {
    if (_selectedId == null) return;
    _selectedId = null;
    notifyListeners();
  }
}

/// Look up the enclosing [ListDetailLayout]'s selection handle.
class ListDetail {
  const ListDetail._();

  /// Returns the nearest [ListDetailSelection]. Asserts if there is no
  /// enclosing [ListDetailLayout].
  static ListDetailSelection of(BuildContext context) {
    final selection = maybeOf(context);
    assert(
      selection != null,
      'ListDetail.of() was called outside a ListDetailLayout.',
    );
    return selection!;
  }

  /// Returns the nearest [ListDetailSelection], or `null` if there is none.
  static ListDetailSelection? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ListDetailScope>()
        ?.selection;
  }
}

class _ListDetailScope extends InheritedWidget {
  const _ListDetailScope({
    required this.selection,
    required this.selectedId,
    required this.behavior,
    required super.child,
  });

  final ListDetailSelection selection;
  final Object? selectedId;
  final ListDetailBehavior behavior;

  @override
  bool updateShouldNotify(_ListDetailScope old) =>
      selectedId != old.selectedId || behavior != old.behavior;
}

/// The Material 3 list-detail canonical layout.
///
/// * **Compact / narrow** (region width `< twoPaneBreakpoint`): one pane.
///   Selecting an item pushes its detail as a real (nested) [Navigator] route;
///   system Back returns to the list.
/// * **Expanded / wide**: a fixed-width list and a flexible detail, built on
///   [TwoPane]. The detail pane enters and leaves on [transition]; the content
///   inside it is not animated, so selecting another item replaces it in
///   place. When [resizable], the split is a
///   user-draggable [PaneController], [PaneResizeBehavior.persistent] by
///   default.
///
/// The layout arguments — [transition], [spring], [gutter], [paneController],
/// [resizable], [resizeBehavior], [fixedPaneWidth], [ratio], [minPaneWidth],
/// [snap], [snapStops] and [handleBuilder] — mean the same as on [TwoPane] and
/// [SupportingPaneLayout]. The list is the fixed pane.
///
/// The empty state is configurable via [behavior]:
/// * [ListDetailBehavior.hidden] — the list fills the region until an item is
///   selected, then the detail reveals (and drag-away dismisses it).
/// * [ListDetailBehavior.placeholder] — an empty detail pane shows
///   [placeholderBuilder] (default).
/// * [ListDetailBehavior.selected] — [initialId] is the default detail.
///
/// Selection is plain state, so it **persists across resizes**. Drive it three
/// ways (all equivalent at the leaf, which calls
/// `ListDetail.of(context).select(id)`): uncontrolled (default),
/// *controlled* ([selectedId] + [onSelectionChanged]), or via a
/// [ListDetailController].
class ListDetailLayout extends StatefulWidget {
  /// Creates a list-detail layout.
  const ListDetailLayout({
    super.key,
    this.controller,
    required this.listBuilder,
    required this.detailBuilder,
    this.selectedId,
    this.onSelectionChanged,
    this.initialId,
    this.placeholderBuilder,
    this.behavior = ListDetailBehavior.placeholder,
    this.twoPaneBreakpoint = 840,
    this.transition = const PaneTransition.spring(),
    this.spring = MaterialSprings.expressiveDefaultSpatial,
    this.gutter,
    this.paneController,
    this.resizable = false,
    this.resizeBehavior = PaneResizeBehavior.persistent,
    this.fixedPaneWidth,
    this.ratio,
    this.minPaneWidth = 360,
    this.snap = true,
    this.snapStops,
    this.handleBuilder,
    this.respectDisplayFeatures = true,
  }) : assert(ratio == null || (ratio > 0 && ratio < 1)),
       assert(
         ratio == null || fixedPaneWidth == null,
         'Give either a proportional ratio or a fixedPaneWidth, not both — '
         'they describe the same dimension.',
       ),
       assert(
         controller == null ||
             (selectedId == null && onSelectionChanged == null),
         'Use either a controller or selectedId/onSelectionChanged, not both.',
       ),
       assert(
         selectedId == null || onSelectionChanged != null,
         'selectedId puts ListDetailLayout in controlled mode, where the '
         'parent owns the selection — so it must be paired with '
         'onSelectionChanged, or nothing can ever change the selection and '
         'the list will silently do nothing when tapped. For an uncontrolled '
         'starting selection, use initialId instead.',
       );

  /// An optional imperative controller.
  final ListDetailController? controller;

  /// Builds the list pane.
  final WidgetBuilder listBuilder;

  /// Builds the detail pane for a selected [id].
  final Widget Function(BuildContext context, Object id) detailBuilder;

  /// The selected id in *controlled* mode.
  final Object? selectedId;

  /// Called whenever the selection changes (with `null` on clear). Providing
  /// this puts the layout in *controlled* mode.
  final ValueChanged<Object?>? onSelectionChanged;

  /// The id selected initially (and the fall-back for
  /// [ListDetailBehavior.selected]). Typically the first item's id.
  final Object? initialId;

  /// Builds the empty-selection placeholder (for
  /// [ListDetailBehavior.placeholder]).
  ///
  /// Defaults to Flutter's [Placeholder] — the outlined, crossed box — which
  /// reads unmistakably as "nothing selected yet" and needs no localization.
  /// Supply this to put your own empty state in the detail pane.
  final WidgetBuilder? placeholderBuilder;

  /// What to show when nothing is selected. Defaults to
  /// [ListDetailBehavior.placeholder].
  final ListDetailBehavior behavior;

  /// The region width at/above which two panes are shown. Defaults to 840,
  /// the expanded breakpoint.
  ///
  /// Material 3 recommends a single pane at medium (600–839dp) and allows two;
  /// set this to 720 (or to `Breakpoints.mediumMinWidth`) to take the two-pane
  /// option. Below expanded the panes split evenly, as the spec requires of a
  /// two-pane medium layout.
  ///
  /// This is measured against the **region** the layout occupies, not the
  /// window, so a layout nested inside a pane adapts to the space it actually
  /// has. [fixedPaneWidth]'s 360/412dp default is resolved against the
  /// **window** instead, because that step is a breakpoint rule. The two
  /// therefore read different widths when the layout does not fill the window.
  final double twoPaneBreakpoint;

  /// How the detail pane enters and leaves in two-pane mode. Defaults to
  /// [PaneTransition.spring], on the Material 3 Expressive default spatial
  /// spring.
  ///
  /// Below [twoPaneBreakpoint] the detail is a pushed page, so the route's own
  /// transition applies there instead.
  final PaneTransition transition;

  /// The spring the divider moves on when it snaps, toggles or springs back.
  /// Defaults to [MaterialSprings.expressiveDefaultSpatial].
  final SpringDescription spring;

  /// The gap between the panes.
  ///
  /// Defaults to the ambient [AdaptiveLayoutThemeData.spacing]'s
  /// `paneGutter` (24 out of the box).
  final double? gutter;

  /// The split state. Pass your own to read or restore the user's pane-width
  /// preference (the package stores nothing itself). When null an internal one
  /// is used.
  final PaneController? paneController;

  /// Whether the split is user-resizable via a drag handle in the gutter.
  final bool resizable;

  /// Whether a resize is remembered. Defaults to
  /// [PaneResizeBehavior.persistent], as Material 3 specifies for list-detail:
  /// the width is kept across resizes and breakpoint changes.
  final PaneResizeBehavior resizeBehavior;

  /// The fixed list pane's width in two-pane mode.
  ///
  /// Defaults to the Material 3 fixed-pane width for the current breakpoint:
  /// 360dp at expanded, 412dp at large and extra-large. Resolved against the
  /// window, not the region — see [twoPaneBreakpoint]. Only applies from
  /// expanded up; at medium the panes split evenly, as the spec requires.
  final double? fixedPaneWidth;

  /// If set, the list pane takes this share of the splittable width instead of
  /// [fixedPaneWidth]. Like [fixedPaneWidth], only applies from expanded up.
  final double? ratio;

  /// The minimum width each pane keeps in two-pane mode. Defaults to 360.
  final double minPaneWidth;

  /// Whether a resize magnet-snaps to nearby stops on release. Defaults to
  /// `true`. See [TwoPane.snap].
  final bool snap;

  /// Custom snap stops, as the list pane's share of the splittable width. See
  /// [TwoPane.snapStops].
  final List<double>? snapStops;

  /// Builds custom gutter content when [resizable], in place of the default
  /// [PaneDragHandle].
  final WidgetBuilder? handleBuilder;

  /// Whether the medium-width even split snaps onto a vertical foldable hinge.
  /// Defaults to `true`. See [TwoPane.respectDisplayFeatures].
  final bool respectDisplayFeatures;

  @override
  State<ListDetailLayout> createState() => _ListDetailLayoutState();
}

class _ListDetailLayoutState extends State<ListDetailLayout>
    implements ListDetailSelection {
  Object? _internalId;
  bool _wide = false;

  // Keyed by selection, so each detail's scroll offset is restored when you
  // come back to it. Material 3: "Detail views should retain their scroll
  // position when navigating to other items." The detail subtree is replaced
  // on every selection change, so without this the offset would be lost.
  final PageStorageBucket _detailStorage = PageStorageBucket();

  static const LocalKey _basePageKey = ValueKey(
    'material_layout.listDetail.base',
  );
  static const LocalKey _detailPageKey = ValueKey(
    'material_layout.listDetail.detail',
  );

  /// Controlled mode is defined by the presence of the *callback*, not of a
  /// value. Treating a non-null `selectedId` as sufficient means a caller who
  /// passes only `selectedId` gets a layout that reports nothing and updates
  /// nothing — a list that silently ignores every tap. The constructor asserts
  /// against that pairing; this keeps the behaviour sane in release too.
  bool get _isControlled =>
      widget.controller == null && widget.onSelectionChanged != null;

  @override
  void initState() {
    super.initState();
    // initialId is an initial *selection* for placeholder/hidden, but under
    // `selected` it is only the *fall-back* (the default detail shown inline on
    // wide) — not a real selection — so entering `selected` on the narrow list
    // never conjures a detail page out of nowhere.
    _internalId = widget.behavior == ListDetailBehavior.selected
        ? null
        : widget.initialId;
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ListDetailLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    // The controller is owned by the caller; only detach our listener.
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Object? get _rawSelectedId {
    if (widget.controller != null) return widget.controller!.selectedId;
    if (_isControlled) return widget.selectedId;
    return _internalId;
  }

  /// The id actually shown. Applies the [ListDetailBehavior.selected]
  /// fall-back to [ListDetailLayout.initialId] only where a detail is actually
  /// displayed — i.e. inline on wide. On narrow there is no fall-back: after the
  /// detail page is popped, nothing is selected (so the list highlights nothing)
  /// until an item is tapped or the layout re-enters narrow from wide.
  @override
  Object? get selectedId {
    final raw = _rawSelectedId;
    if (raw != null) return raw;
    if (widget.behavior == ListDetailBehavior.selected && _wide) {
      return widget.initialId;
    }
    return null;
  }

  @override
  bool get hasSelection => selectedId != null;

  @override
  ListDetailBehavior get behavior => widget.behavior;

  @override
  void select(Object id) {
    if (widget.controller != null) {
      widget.controller!.select(id);
    } else if (!_isControlled) {
      setState(() => _internalId = id);
    }
    widget.onSelectionChanged?.call(id);
  }

  @override
  void clear() {
    if (widget.controller != null) {
      widget.controller!.clear();
    } else if (!_isControlled) {
      setState(() => _internalId = null);
    }
    widget.onSelectionChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    // The scope lives *inside* the LayoutBuilder on purpose. `selectedId`
    // consults `_wide` to apply the `selected` fall-back, so reading it above
    // the LayoutBuilder would publish the previous frame's answer — and since
    // _ListDetailScope.updateShouldNotify compares exactly that value, a
    // narrow→wide change could fail to notify dependents on the frame it
    // actually happened.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wasWide = _wide;
        _wide = constraints.maxWidth >= widget.twoPaneBreakpoint;

        // `selected` continuity: a detail being viewed on wide (the inline
        // default, with nothing *explicitly* picked) is kept when shrinking to
        // narrow — adopt the initial item as the selection so it pushes as a
        // page. Only on the wide→narrow *transition*, so simply entering
        // `selected` on the narrow list (fresh or by toggling behavior) does
        // NOT conjure a detail, and Back still returns to the list.
        if (widget.behavior == ListDetailBehavior.selected &&
            !_wide &&
            wasWide &&
            widget.controller == null &&
            !_isControlled &&
            _internalId == null) {
          _internalId = widget.initialId;
        }

        // On narrow widths the detail is a real (nested) Navigator page —
        // platform push/pop + system Back — driven declaratively from the
        // selection. Because the list and the page-stack live below this
        // always-on-screen LayoutBuilder, the narrow↔wide decision and the
        // grow-wide hand-back are exact and reliable. Only an *explicit*
        // selection shows a page (`selected`'s fall-back stays on the list).
        final rawId = _rawSelectedId;
        final showDetailPage = !_wide && rawId != null;

        // selectedId (re-read here) reflects the just-computed _wide, so the
        // wide pane gets `selected`'s fall-back even on a narrow→wide frame.
        //
        // The TwoPane stays mounted at *every* width — narrow simply means it
        // has no secondary. That is what lets a window shrinking past
        // twoPaneBreakpoint drive the detail off the trailing edge instead of
        // dropping it between frames; a TwoPane with a null secondary renders
        // as nothing but the primary, so the narrow layout is unchanged once
        // the exit finishes.
        return _ListDetailScope(
          selection: this,
          selectedId: selectedId,
          behavior: widget.behavior,
          // The Builder matters: listBuilder/detailBuilder call
          // ListDetail.of(context), so they have to run against a context
          // *below* the scope. Building them with the LayoutBuilder's own
          // context would put them above it and the lookup would assert.
          child: Builder(
            builder: (context) {
              final Widget base = _buildWidePane(
                context,
                selectedId,
                twoPane: _wide,
              );

              final Widget navigator = Navigator(
                onDidRemovePage: (page) {
                  // The detail page was removed. If we still *want* it (still
                  // narrow with an explicit selection), it was a user /
                  // app-bar Back — so clear the selection. Otherwise the
                  // removal was state-driven (selection cleared, or grown
                  // wide) and is already reconciled.
                  if (page.key == _detailPageKey &&
                      !_wide &&
                      _rawSelectedId != null) {
                    clear();
                  }
                },
                pages: <Page<Object?>>[
                  MaterialPage<Object?>(key: _basePageKey, child: base),
                  if (showDetailPage)
                    MaterialPage<Object?>(
                      key: _detailPageKey,
                      child: widget.detailBuilder(context, rawId),
                    ),
                ],
              );

              // The nested Navigator doesn't receive the root/system Back, so
              // route it here: while a detail page is up, intercept and pop.
              return PopScope<Object?>(
                canPop: !showDetailPage,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) clear();
                },
                child: navigator,
              );
            },
          ),
        );
      },
    );
  }

  /// The [TwoPane] half of the layout: a fixed list and a flexible detail (or
  /// placeholder), with the expressive width-reveal and optional persistent
  /// resize.
  ///
  /// [twoPane] is false below [ListDetailLayout.twoPaneBreakpoint]. That yields
  /// a null secondary, which the [TwoPane] reveals *out* — so narrowing the
  /// window slides the detail off the edge rather than dropping it.
  Widget _buildWidePane(
    BuildContext context,
    Object? id, {
    required bool twoPane,
  }) {
    Widget? detail;
    if (!twoPane) {
      detail = null; // reveals out, then the primary fills the region
    } else if (id != null) {
      // Keyed by the selection: a new id is a new subtree, and the
      // PageStorageKey namespaces the scroll offsets this detail writes into
      // _detailStorage.
      detail = KeyedSubtree(
        key: PageStorageKey<Object>(id),
        child: widget.detailBuilder(context, id),
      );
    } else if (widget.behavior == ListDetailBehavior.placeholder) {
      detail = KeyedSubtree(
        key: const ValueKey<String>('material_layout.listDetail.placeholder'),
        child: widget.placeholderBuilder?.call(context) ?? const Placeholder(),
      );
    }

    if (detail != null) {
      detail = PageStorage(bucket: _detailStorage, child: detail);
    }
    // Material 3 splits two-pane layouts differently by breakpoint: at medium
    // "each pane should take up 50% of the window width. Avoid setting custom
    // widths", and only from expanded does the fixed-and-flexible shape (a
    // 360/412dp list beside a flexible detail) apply.
    final sizeClass = AdaptiveLayoutTheme.of(context).breakpoints
        .resolve(MediaQuery.sizeOf(context).width);
    final bool evenSplit = !sizeClass.isExpandedOrWider;

    return TwoPane(
      primary: widget.listBuilder(context),
      secondary: detail,
      strategy: evenSplit
          ? TwoPaneStrategy.splitPane
          : TwoPaneStrategy.fixedFlexible,
      fixedPaneWidth: widget.fixedPaneWidth,
      ratio: widget.ratio,
      gutter: widget.gutter,
      minPaneWidth: widget.minPaneWidth,
      // Left on even while the pane is leaving, so the handle travels off the
      // edge with it. TwoPane stops the handle responding to drags the moment
      // the exit starts, and drops it entirely once there is no secondary.
      resizable: widget.resizable,
      resizeBehavior: widget.resizeBehavior,
      snap: widget.snap,
      snapStops: widget.snapStops,
      handleBuilder: widget.handleBuilder,
      respectDisplayFeatures: widget.respectDisplayFeatures,
      transition: widget.transition,
      spring: widget.spring,
      paneController: widget.paneController,
      // Only `hidden` dismisses by dragging the detail away (to the list).
      // `placeholder` reverts via the close button; `selected` cannot be
      // dismissed — there is always a detail.
      onSecondaryDismissed:
          twoPane && widget.behavior == ListDetailBehavior.hidden
          ? clear
          : null,
    );
  }
}
