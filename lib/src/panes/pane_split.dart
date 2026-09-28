// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The two memories of a resize: whether a layout remembers how its panes
/// were resized.
enum PaneResizeMemory {
  /// Remembers the split.
  ///
  /// The split survives breakpoint changes: a layout collapsed to one pane
  /// stays collapsed at every size. To make it survive closing the app too,
  /// store [PaneSplit.toJson] and restore it with [PaneSplit.fromJson].
  persistent,

  /// Forgets the split.
  ///
  /// The layout returns to its default split when the resizable pane is
  /// closed and reopened, and when the breakpoint changes. Suited to layouts
  /// that are rarely resized, such as a supporting pane.
  temporary,
}

/// Whether the drag handle of a two-pane layout can hide a pane, and what
/// hiding it does.
///
/// Set per pane. Left unset, a layout follows Material: in a split-pane
/// layout, as where two panes split evenly at medium, the handle collapses
/// either pane; in a fixed-and-flexible layout, it collapses the fixed pane,
/// or dismisses it where the pane can be dismissed, and never hides the
/// flexible one.
///
/// Only the handle is bound by it: a split that the app sets through a
/// [PaneSplitController] applies whatever the panes allow.
enum PaneCollapse {
  /// The handle never hides the pane.
  never,

  /// The handle hides the pane, and the other pane takes the whole width.
  ///
  /// The space between the panes closes, and the handle rests in the middle
  /// of the margin beside the hidden pane, from where it shows the pane
  /// again. Where there is less margin than a spacer, as beside a navigation
  /// rail, which takes the margin's place, it rests half a spacer from the
  /// edge, over the pane that stays.
  collapse,

  /// Hiding the pane with the handle dismisses it, as closing a temporary
  /// pane does: the layout calls back, and the app removes the pane.
  dismiss,
}

enum _PaneSplitKind { automatic, width, centered, collapsed, expanded }

/// How the space of a two-pane layout is divided between its panes.
///
/// A split describes the layout's *resizable* pane: the list of a
/// list-detail layout, the supporting pane of a supporting-pane layout, and
/// the fixed pane, or the first of two flexible ones, of a two-pane layout.
/// The other pane takes the rest of the space.
///
/// A split is a value; [PaneSplitController] holds one and notifies its
/// listeners when it changes, so that a split is both observable and
/// settable. A split can be stored and restored through [toJson] and
/// [PaneSplit.fromJson].
@immutable
final class PaneSplit {
  /// A split that gives the resizable pane [width] logical pixels.
  ///
  /// The width is remembered across breakpoints. A medium layout
  /// still divides its panes evenly, because custom widths are not allowed
  /// there.
  const new width(double this.width)
    : assert(width >= 0),
      _kind = _PaneSplitKind.width;

  const new _(this._kind) : width = null;

  /// Creates a split from data produced by [toJson].
  ///
  /// Throws a [FormatException] if [json] is not such data.
  factory fromJson(Object? json) {
    if (json is num && json >= 0) return PaneSplit.width(json.toDouble());
    if (json is String) {
      for (final split in const [automatic, centered, collapsed, expanded]) {
        if (split._kind.name == json) return split;
      }
    }
    throw FormatException('Not a pane split', json);
  }

  /// The split the layout chooses for its breakpoint.
  ///
  /// The fixed pane at its default width from expanded upwards, and an even
  /// split at medium and where both panes are flexible.
  static const PaneSplit automatic = PaneSplit._(_PaneSplitKind.automatic);

  /// A split that keeps the spacer centred in the window.
  ///
  /// A navigation rail or drawer on the leading edge narrows only the
  /// leading pane, so the spacer stays in the middle of the window.
  static const PaneSplit centered = PaneSplit._(_PaneSplitKind.centered);

  /// A split that hides the resizable pane, leaving one pane.
  static const PaneSplit collapsed = PaneSplit._(_PaneSplitKind.collapsed);

  /// A split that widens the resizable pane to fill the space, hiding the
  /// other pane.
  static const PaneSplit expanded = PaneSplit._(_PaneSplitKind.expanded);

  /// The widths Material lets a resize of two panes settle on from expanded
  /// upwards: 360dp, 412dp and the centred split.
  static const List<PaneSplit> materialStops = [
    PaneSplit.width(360),
    PaneSplit.width(412),
    centered,
  ];

  /// The width of the resizable pane, in logical pixels, for a split created
  /// with [PaneSplit.width]; null otherwise.
  final double? width;

  final _PaneSplitKind _kind;

  /// Whether this split hides the resizable pane.
  bool get isCollapsed => _kind == _PaneSplitKind.collapsed;

  /// Whether this split hides the other pane.
  bool get isExpanded => _kind == _PaneSplitKind.expanded;

  /// Whether both panes are visible under this split.
  bool get showsBothPanes => !isCollapsed && !isExpanded;

  /// This split as data that `jsonEncode` accepts: a number for a width, a
  /// string otherwise.
  Object toJson() => width ?? _kind.name;

  @override
  bool operator ==(Object other) =>
      other is PaneSplit && other._kind == _kind && other.width == width;

  @override
  int get hashCode => Object.hash(_kind, width);

  @override
  String toString() => switch (_kind) {
    _PaneSplitKind.width => 'PaneSplit.width($width)',
    _ => 'PaneSplit.${_kind.name}',
  };
}

/// Holds a [PaneSplit] and notifies its listeners when it changes.
///
/// Pass one to a layout to observe or set how its panes are divided, and to
/// persist the split:
///
/// ```dart
/// final controller = PaneSplitController(
///   split: PaneSplit.fromJson(jsonDecode(stored)),
/// );
/// controller.addListener(() => store(jsonEncode(controller.value.toJson())));
/// ```
class PaneSplitController extends ValueNotifier<PaneSplit> {
  /// Creates a controller that starts at [split].
  new({PaneSplit split = PaneSplit.automatic})
    : _openSplit = split.showsBothPanes ? split : PaneSplit.automatic,
      super(split);

  PaneSplit _openSplit;

  @override
  set value(PaneSplit newValue) {
    if (newValue.showsBothPanes) _openSplit = newValue;
    super.value = newValue;
  }

  /// Hides the resizable pane, or shows both panes again when one is hidden.
  ///
  /// Showing both panes returns to the last split that did.
  void toggle() {
    value = value.showsBothPanes ? PaneSplit.collapsed : _openSplit;
  }
}
