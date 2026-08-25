import 'package:flutter/foundation.dart';

/// Which pane of a [TwoPane], if any, is fully collapsed.
enum PaneCollapse {
  /// Neither pane is collapsed — both share the splittable width.
  none,

  /// The leading/primary pane is collapsed (the secondary fills the region).
  primary,

  /// The trailing/secondary pane is collapsed (the primary fills the region).
  secondary,
}

/// Shared, persistable state for a resizable [TwoPane] split.
///
/// Holds the divider position as a **normalized fraction** (the primary pane's
/// share of the splittable width, `0..1`) plus which pane, if any, is
/// [collapse]d. A fraction (rather than an absolute width) keeps a user's
/// preference visually consistent across breakpoint changes, and makes
/// "collapsed-stays-collapsed" fall out for free.
///
/// It is a [ChangeNotifier], so the same object drives the layout *and* lets you
/// persist the preference: listen for changes and write [toJson], then restore
/// with [PaneController.fromJson] on the next launch. **The package stores
/// nothing itself** — persistence is entirely yours.
///
/// The two canonical layouts use it differently:
/// * `ListDetailLayout` treats it as **persistent** — pass your own controller
///   and persist it; the layout never resets it.
/// * `SupportingPaneLayout` treats resizing as **temporary** — it [reset]s the
///   controller whenever the supporting pane is closed or hidden, so the pane
///   always reopens at its default width.
class PaneController extends ChangeNotifier {
  /// Creates a pane controller.
  ///
  /// [fraction] is the primary pane's share of the splittable width (`0..1`),
  /// or `null` to use the layout's default split. [collapse] starts with a pane
  /// collapsed.
  PaneController({double? fraction, PaneCollapse collapse = PaneCollapse.none})
      : assert(
          fraction == null || (fraction >= 0 && fraction <= 1),
          'fraction must be within 0..1.',
        ),
        _fraction = fraction,
        // ignore: prefer_initializing_formals — private field, public parameter.
        _collapse = collapse;

  /// Restores a controller previously serialised with [toJson].
  factory PaneController.fromJson(Map<String, Object?> json) => PaneController(
        fraction: (json['fraction'] as num?)?.toDouble(),
        collapse: PaneCollapse.values.byName(
          (json['collapse'] as String?) ?? PaneCollapse.none.name,
        ),
      );

  double? _fraction;

  /// The primary pane's share of the splittable width (`0..1`), or `null` to use
  /// the layout's default split. Setting it clamps to `0..1` and notifies.
  double? get fraction => _fraction;

  set fraction(double? value) {
    final clamped = value?.clamp(0.0, 1.0);
    if (clamped == _fraction) return;
    _fraction = clamped;
    notifyListeners();
  }

  PaneCollapse _collapse;

  /// Which pane, if any, is fully collapsed. Setting it notifies.
  PaneCollapse get collapse => _collapse;

  set collapse(PaneCollapse value) {
    if (value == _collapse) return;
    _collapse = value;
    notifyListeners();
  }

  /// Whether either pane is currently collapsed.
  bool get isCollapsed => _collapse != PaneCollapse.none;

  /// Sets the split [fraction] and clears any collapse, in a single
  /// notification. Called as the user drags / snaps the divider.
  void resizeTo(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    if (clamped == _fraction && _collapse == PaneCollapse.none) return;
    _fraction = clamped;
    _collapse = PaneCollapse.none;
    notifyListeners();
  }

  /// Collapses [side] (or clears the collapse with [PaneCollapse.none]).
  void collapseTo(PaneCollapse side) => collapse = side;

  /// Restores the default split (no explicit fraction, no collapse).
  ///
  /// Temporary-resize layouts (e.g. `SupportingPaneLayout`) call this when the
  /// pane closes so it reopens at its default width.
  void reset() {
    if (_fraction == null && _collapse == PaneCollapse.none) return;
    _fraction = null;
    _collapse = PaneCollapse.none;
    notifyListeners();
  }

  /// Serialises the state for persistence. Pairs with [PaneController.fromJson].
  Map<String, Object?> toJson() => <String, Object?>{
        if (_fraction != null) 'fraction': _fraction,
        'collapse': _collapse.name,
      };
}
