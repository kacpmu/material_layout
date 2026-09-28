// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../foundation/margins.dart';

/// The space between two panes: 24dp at medium and above, and between
/// vertically stacked panes.
const double paneSpacer = 24;

/// The most panes a layout may show.
const int maxPanes = 3;

/// The panes a layout may show: in all, side by side, and how many of those
/// side by side only a standard side sheet may take.
typedef PaneBudget = ({int panes, int sideBySide, int sheetSlots});

/// The budget of a pane that keeps to one pane, as the list of a list-detail
/// layout and a supporting pane do.
const PaneBudget onePane = (panes: 1, sideBySide: 1, sheetSlots: 0);

/// The pane a widget is in, as seen by the layouts nested inside it.
///
/// A layout publishes one around each of its panes. A nested layout reads
/// it to leave the window margins to the outer layout, and to stay within
/// the panes the outer layout leaves it: never more than three in all,
/// and a third side by side only at extra-large, where it is a
/// standard side sheet.
class PaneScope extends InheritedWidget {
  /// Publishes a pane's budget and dismissal to [child].
  const new({
    super.key,
    required this.budget,
    required this.marginPlacement,
    this.onDismiss,
    required super.child,
  });

  /// The panes a layout inside this pane may show.
  final PaneBudget budget;

  /// Where the layout keeps its margins, which a layout nested in this pane
  /// keeps its own in unless told otherwise.
  final MarginPlacement marginPlacement;

  /// Dismisses this pane, or null when the pane is permanent.
  final VoidCallback? onDismiss;

  /// The pane enclosing [context], or null outside every layout.
  static PaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneScope>();

  /// The panes a layout in [scope] may show, or, where no other layout
  /// encloses it, those of the outermost layout: three, two of them side by
  /// side, and a third beside those that is a side sheet when its region is
  /// [extraLarge].
  static PaneBudget budgetOf(PaneScope? scope, {required bool extraLarge}) =>
      scope?.budget ??
      (extraLarge
          ? (panes: maxPanes, sideBySide: maxPanes, sheetSlots: 1)
          : (panes: maxPanes, sideBySide: 2, sheetSlots: 0));

  /// What [budget] leaves a pane beside which another pane shows: one pane
  /// fewer where the other [shown] with it, one fewer side by side where the
  /// other is [beside] it, and one sheet slot fewer where the other is a side
  /// sheet that [takesSheetSlot].
  static PaneBudget remaining(
    PaneBudget budget, {
    required bool shown,
    required bool beside,
    bool takesSheetSlot = false,
  }) {
    final sideBySide = beside ? budget.sideBySide - 1 : budget.sideBySide;
    final sheetSlots = takesSheetSlot && budget.sheetSlots > 0
        ? budget.sheetSlots - 1
        : budget.sheetSlots;
    return (
      panes: shown ? budget.panes - 1 : budget.panes,
      sideBySide: sideBySide,
      sheetSlots: math.min(sheetSlots, sideBySide),
    );
  }

  @override
  bool updateShouldNotify(PaneScope oldWidget) =>
      budget != oldWidget.budget ||
      marginPlacement != oldWidget.marginPlacement ||
      onDismiss != oldWidget.onDismiss;
}

/// A record of how many panes the layouts below a navigation scaffold show
/// side by side.
///
/// Layouts report as they resolve and withdraw when they are disposed, so the
/// count follows the body as it changes. Only one pane or more than one
/// matters to navigation placement, so the count saturates at two.
class PaneCountRegistry extends ChangeNotifier {
  final _counts = <Object, int>{};
  bool _notifyScheduled = false;

  /// The number of panes shown side by side: 1 or 2.
  int get paneCount {
    for (final count in _counts.values) {
      if (count > 1) return 2;
    }
    return 1;
  }

  /// Records that [layout] shows [count] panes side by side.
  void report(Object layout, int count) {
    if (_counts[layout] == count) return;
    final before = paneCount;
    _counts[layout] = count;
    if (paneCount != before) _scheduleNotify();
  }

  /// Forgets [layout].
  void withdraw(Object layout) {
    final before = paneCount;
    if (_counts.remove(layout) == null) return;
    if (paneCount != before) _scheduleNotify();
  }

  // Layouts report while they build and lay out, when the scaffold above
  // them cannot rebuild, so the change is delivered after the frame.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _notifyScheduled = false;
        if (hasListeners) notifyListeners();
      })
      ..ensureVisualUpdate();
  }
}

/// The [PaneCountRegistry] published to the layouts below a navigation
/// scaffold.
class PaneCountScope extends InheritedWidget {
  /// Publishes [registry] to [child].
  const new({super.key, required this.registry, required super.child});

  /// The registry layouts report to.
  final PaneCountRegistry registry;

  /// The registry enclosing [context], or null.
  static PaneCountRegistry? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PaneCountScope>()?.registry;

  @override
  bool updateShouldNotify(PaneCountScope oldWidget) =>
      registry != oldWidget.registry;
}

/// Reports a layout's side-by-side pane count to the enclosing registry, and
/// withdraws it when the layout is disposed or its subtree stops ticking.
mixin PaneCountReporter<T extends StatefulWidget> on State<T> {
  PaneCountRegistry? _registry;

  /// Reports [count] panes side by side, looking the registry up from
  /// [context].
  ///
  /// A layout that is not showing — in an inactive tab of an [IndexedStack],
  /// or in a subtree whose tickers are off — does not count.
  void reportPaneCount(BuildContext context, int count) {
    final registry = PaneCountScope.maybeOf(context);
    if (registry != _registry) {
      _registry?.withdraw(this);
      _registry = registry;
    }
    if (TickerMode.valuesOf(context).enabled && Visibility.of(context)) {
      registry?.report(this, count);
    } else {
      registry?.withdraw(this);
    }
  }

  @override
  void dispose() {
    _registry?.withdraw(this);
    super.dispose();
  }
}

/// Storage for the scroll offsets and other page storage of a pane's
/// content, which survives the content moving between a pane and a page.
class PaneStorage extends StatelessWidget {
  /// Stores the state of [child] under [storageKey] in [bucket].
  const new({
    super.key,
    required this.bucket,
    required this.storageKey,
    required this.child,
  });

  /// The bucket the layout owns.
  final PageStorageBucket bucket;

  /// Identifies the content; content with a new key starts afresh.
  final Object storageKey;

  /// The pane's content.
  final Widget child;

  @override
  Widget build(BuildContext context) => PageStorage(
    bucket: bucket,
    child: KeyedSubtree(key: PageStorageKey<Object>(storageKey), child: child),
  );
}

/// A widget that reports where its child sits in the window.
///
/// A layout needs its position in the window for the two rules stated in
/// window terms: a split centred in the window and a hinge that
/// separates the display.
///
/// The position is where the child rests: paint transforms, such as the
/// slide of a page transition, are left out, so a layout that moves in with
/// a transition is placed for where it will stay. A move that relays the
/// child out, as when the window resizes, is reported after that frame; a
/// move by an ancestor alone, as when a page view scrolls, once it ends.
class RegionOffsetReporter extends SingleChildRenderObjectWidget {
  /// Reports the window offset of [child] to [onChanged].
  const new({super.key, required this.onChanged, super.child});

  /// Called after a frame with the child's new offset in the window.
  final ValueChanged<Offset> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRegionOffsetReporter(onChanged);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRegionOffsetReporter).onChanged = onChanged;
  }
}

class _RenderRegionOffsetReporter extends RenderProxyBox {
  new(this.onChanged);

  ValueChanged<Offset> onChanged;
  Offset? _reported;
  Offset? _moving;
  bool _laidOut = false;
  bool _watching = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _watch();
  }

  @override
  void performLayout() {
    super.performLayout();
    _laidOut = true;
  }

  // Measures after every frame while attached: the child can move without
  // being laid out or painted again, as when an ancestor scrolls it behind a
  // repaint boundary.
  void _watch() {
    if (_watching) return;
    _watching = true;
    SchedulerBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration timeStamp) {
    _watching = false;
    if (!attached) return;
    _watch();
    if (!hasSize) return;
    final offset = _restingOffset();
    final laidOut = _laidOut;
    _laidOut = false;
    if (offset == _reported) {
      _moving = null;
      return;
    }
    // A move by an ancestor alone is reported once the child has rested for
    // a frame, rather than on every frame of it.
    if (!laidOut && _reported != null && offset != _moving) {
      _moving = offset;
      SchedulerBinding.instance.scheduleFrame();
      return;
    }
    _moving = null;
    _reported = offset;
    onChanged(offset);
  }

  // The child's offset in the window by layout alone.
  Offset _restingOffset() {
    var offset = Offset.zero;
    RenderObject child = this;
    var parent = child.parent;
    // The root view's own transform maps to physical pixels; it is left out.
    while (parent != null && parent.parent != null) {
      final data = child.parentData;
      if (data is BoxParentData) {
        offset += data.offset;
      } else if (parent is! RenderProxyBox) {
        // Slivers and viewports place what they hold by its paint offset,
        // which scrolling changes.
        final transform = Matrix4.identity();
        parent.applyPaintTransform(child, transform);
        offset += MatrixUtils.getAsTranslation(transform) ?? Offset.zero;
      }
      // A proxy holds its child at its own origin, and whatever transform it
      // paints with is left out.
      child = parent;
      parent = child.parent;
    }
    return offset;
  }
}
