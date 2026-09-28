// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../foundation/adaptive_region.dart';
import '../foundation/breakpoints.dart';
import '../foundation/margins.dart';
import '../foundation/motion.dart';
import '../foundation/resting_width.dart';
import '../foundation/theme.dart';
import '../panes/pane_scope.dart';

/// Where a [NavigationScaffold] shows navigation.
enum NavigationPlacement {
  /// No navigation shows.
  none,

  /// A navigation bar at the bottom.
  bar,

  /// A navigation rail on the leading edge.
  rail,
}

/// Decides where a [NavigationScaffold] shows navigation, for the breakpoint
/// of its region and the number of panes its body shows side by side.
///
/// [material], the default, is the placement Material's guidance requires.
/// Any other rule departs from it: a rail beside two panes at medium takes
/// width the panes need, and a bar from expanded upwards leaves unused the
/// width a rail puts to use.
/// [NavigationPlacementRule.only] shows one placement at every breakpoint,
/// and [NavigationPlacementRule.from] decides by a function:
///
/// ```dart
/// // The bar alone.
/// const NavigationPlacementRule.only(NavigationPlacement.bar)
///
/// // A rail up to expanded, and the bar from expanded upwards.
/// NavigationPlacementRule.from(
///   (breakpoint, paneCount) => breakpoint < Breakpoint.expanded
///       ? NavigationPlacement.rail
///       : NavigationPlacement.bar,
/// )
/// ```
///
/// A rule chooses a component; the scaffold shows it where it is given, and
/// no navigation where it is not, rather than the other component.
///
/// A rule that goes by the pane count sees the panes the body shows in the
/// room the navigation leaves it: a rail narrows the body, and a narrower
/// body may show fewer panes. Material's rule gives two panes the bar, which
/// takes no width from them, so a placement it chooses stays; where two
/// panes fit only without the rail's width, it keeps the navigation the body
/// had, the rail for a window growing into that width and the bar for one
/// shrinking into it. A rule that gives two panes the rail and one pane the
/// bar can swap them back and forth where the rail's width decides whether
/// two panes fit.
@immutable
abstract class NavigationPlacementRule {
  /// Const constructor for subclasses.
  const new();

  /// A rule that shows [placement] at every breakpoint, whatever the panes.
  const factory only(NavigationPlacement placement) = _OnlyRule;

  /// A rule that decides with [placementFor], called with the breakpoint of
  /// the scaffold's region and the number of panes its body shows.
  const factory from(
    NavigationPlacement Function(Breakpoint breakpoint, int paneCount)
    placementFor,
  ) = _FunctionRule;

  /// The placement Material prescribes, and the default: a bar at compact;
  /// at medium, a rail beside one pane and a bar below two, so that two
  /// panes keep the full width; a rail from expanded upwards.
  static const NavigationPlacementRule material = _MaterialRule();

  /// Where navigation shows at [breakpoint], for a body showing [paneCount]
  /// panes side by side.
  NavigationPlacement placementFor(Breakpoint breakpoint, int paneCount);
}

final class _MaterialRule extends NavigationPlacementRule {
  const new();

  @override
  NavigationPlacement placementFor(Breakpoint breakpoint, int paneCount) =>
      switch (breakpoint) {
        Breakpoint.compact => NavigationPlacement.bar,
        Breakpoint.medium =>
          paneCount > 1 ? NavigationPlacement.bar : NavigationPlacement.rail,
        _ => NavigationPlacement.rail,
      };

  @override
  String toString() => 'NavigationPlacementRule.material';
}

final class _OnlyRule extends NavigationPlacementRule {
  const new(this.placement);

  final NavigationPlacement placement;

  @override
  NavigationPlacement placementFor(Breakpoint breakpoint, int paneCount) =>
      placement;

  @override
  bool operator ==(Object other) =>
      other is _OnlyRule && other.placement == placement;

  @override
  int get hashCode => placement.hashCode;

  @override
  String toString() => 'NavigationPlacementRule.only($placement)';
}

final class _FunctionRule extends NavigationPlacementRule {
  const new(this.function);

  final NavigationPlacement Function(Breakpoint breakpoint, int paneCount)
  function;

  @override
  NavigationPlacement placementFor(Breakpoint breakpoint, int paneCount) =>
      function(breakpoint, paneCount);

  @override
  bool operator ==(Object other) =>
      other is _FunctionRule && other.function == function;

  @override
  int get hashCode => function.hashCode;

  @override
  String toString() => 'NavigationPlacementRule.from($function)';
}

/// The navigation placement [rule] chooses for [breakpoint] and a body
/// showing [paneCount] panes side by side, Material's unless another rule
/// is given.
///
/// When the chosen component is not given, no navigation shows rather than
/// the other one, which would break the rule.
NavigationPlacement navigationPlacementFor({
  required Breakpoint breakpoint,
  required int paneCount,
  required bool hasBar,
  required bool hasRail,
  required NavigationPlacementRule rule,
}) => switch (rule.placementFor(breakpoint, paneCount)) {
  NavigationPlacement.bar when hasBar => NavigationPlacement.bar,
  NavigationPlacement.rail when hasRail => NavigationPlacement.rail,
  _ => NavigationPlacement.none,
};

/// A [Scaffold] that places navigation for the space it has.
///
/// Its one job is navigation placement: it shows [navigationBar] or
/// [navigationRail] by the breakpoint of its region and the number of panes
/// its [body] shows, as Material prescribes unless [placementRule] decides
/// otherwise, and animates the swap: the leaving component goes before the
/// arriving one comes, so the two never show together. It draws neither
/// component: any bar and any rail can be given, as long as they lead to the
/// same destinations. Give both; where the chosen one is missing no
/// navigation shows, as when a compact app keeps a modal rail in its
/// [drawer] instead of a bar.
///
/// ```dart
/// NavigationScaffold(
///   navigationBar: NavigationBar(/* … */),
///   navigationRail: NavigationRail(/* … */),
///   body: ListDetailLayout<int>(/* … */),
/// );
/// ```
///
/// At medium, the placement depends on the body: a rail beside one pane, a
/// bar below two. The layouts of this package report how many panes
/// they show, so the scaffold follows them without being told; [paneCount]
/// states the count for a body that does not report it. Widgets below
/// the scaffold read the placement it chose with
/// [NavigationScaffold.placementOf].
///
/// [placementRule] chooses another placement, as the bar alone, or a rail
/// up to expanded and the bar from there (see [NavigationPlacementRule]).
///
/// When the placement changes, the layouts in the body arrange themselves at
/// once for the room they will have when the swap is done, while the body's
/// width follows the rail as it comes or goes: a layout that has room for
/// one pane beside the arriving rail keeps one pane throughout, rather than
/// showing two until the rail takes their room.
///
/// Whether the rail is collapsed or expanded is the rail's own property;
/// pass an expanded rail from large upwards where it suits the app.
/// The body is a region that layouts inside it adapt to. Beside the
/// rail, they keep no margin on its side: the rail is the edge there,
/// and the first pane starts where it ends. The remaining arguments
/// are forwarded to [Scaffold].
class NavigationScaffold extends StatefulWidget {
  /// Creates a navigation scaffold.
  const new({
    super.key,
    this.navigationBar,
    this.navigationRail,
    required this.body,
    this.paneCount,
    this.placementRule = NavigationPlacementRule.material,
    this.motion,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.restorationId,
  }) : assert(paneCount == null || paneCount > 0);

  /// The navigation bar, with three to five destinations.
  final Widget? navigationBar;

  /// The navigation rail, leading to the same destinations as the bar.
  final Widget? navigationRail;

  /// The content: typically a layout of this package.
  final Widget body;

  /// The number of panes [body] shows side by side, or null to follow the
  /// layouts inside it.
  final int? paneCount;

  /// Where the bar and the rail show: [NavigationPlacementRule.material], the
  /// placement Material prescribes, unless another rule is given.
  final NavigationPlacementRule placementRule;

  /// How the bar and the rail swap: the leaving one on its exit motion, the
  /// arriving one on its enter motion; null for the default spatial motion of
  /// the scheme in effect.
  final PaneMotion? motion;

  /// Forwarded to [Scaffold.appBar].
  final PreferredSizeWidget? appBar;

  /// Forwarded to [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// Forwarded to [Scaffold.floatingActionButtonLocation].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Forwarded to [Scaffold.drawer].
  final Widget? drawer;

  /// Forwarded to [Scaffold.endDrawer].
  final Widget? endDrawer;

  /// Forwarded to [Scaffold.bottomSheet].
  final Widget? bottomSheet;

  /// Forwarded to [Scaffold.backgroundColor].
  final Color? backgroundColor;

  /// Whether the body resizes to make room for the keyboard; forwarded to
  /// [Scaffold.resizeToAvoidBottomInset].
  final bool? resizeToAvoidBottomInset;

  /// Whether the body extends behind the navigation bar; forwarded to
  /// [Scaffold.extendBody].
  final bool extendBody;

  /// Forwarded to [Scaffold.restorationId].
  final String? restorationId;

  /// The placement chosen by the navigation scaffold enclosing [context], or
  /// [NavigationPlacement.none] outside one.
  static NavigationPlacement placementOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_NavigationPlacementScope>()
          ?.placement ??
      NavigationPlacement.none;

  @override
  State<NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends State<NavigationScaffold>
    with TickerProviderStateMixin {
  final _registry = PaneCountRegistry();
  late final AnimationController _bar = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _rail = AnimationController.unbounded(
    vsync: this,
  );
  NavigationPlacement? _placement;

  // The width the rail was last laid out at: the room the body keeps for it.
  double _railWidth = 0;

  // Whether the layouts in the body have had a frame to count their panes,
  // which a first placement that depends on them waits for.
  bool _panesCounted = false;
  bool _countingPanes = false;

  void _waitForPanes() {
    if (_countingPanes) return;
    _countingPanes = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _panesCounted = true);
    });
  }

  @override
  void initState() {
    super.initState();
    _registry.addListener(_handlePaneCountChanged);
  }

  @override
  void dispose() {
    _cancelArrival();
    _registry.dispose();
    _bar.dispose();
    _rail.dispose();
    super.dispose();
  }

  void _handlePaneCountChanged() {
    if (widget.paneCount == null) setState(() {});
  }

  void _place(NavigationPlacement placement, PaneMotion motion) {
    if (placement == _placement) return;
    final initial = _placement == null;
    _placement = placement;
    _cancelArrival();
    final arriving = switch (placement) {
      NavigationPlacement.bar => _bar,
      NavigationPlacement.rail => _rail,
      NavigationPlacement.none => null,
    };
    final leaving = [
      for (final controller in [_bar, _rail])
        if (controller != arriving) controller,
    ];
    if (initial) {
      for (final controller in leaving) {
        controller.value = 0;
      }
      arriving?.value = 1;
      return;
    }
    for (final controller in leaving) {
      _show(controller, motion, visible: false);
    }
    if (arriving == null) return;
    bool gone() => leaving.every((controller) => controller.value <= 0);
    if (gone()) {
      _show(arriving, motion, visible: true);
      return;
    }
    // The arriving component waits for the leaving one to go, so that the
    // two are never shown together.
    final departures = Listenable.merge(leaving);
    void arrive() {
      if (!gone()) return;
      _cancelArrival();
      _show(arriving, motion, visible: true);
    }

    departures.addListener(arrive);
    _cancelArrival = () {
      departures.removeListener(arrive);
      _cancelArrival = _nothing;
    };
  }

  VoidCallback _cancelArrival = _nothing;

  static void _nothing() {}

  // The listeners that stop leaving components at their edge.
  final _landings = <AnimationController, VoidCallback>{};

  void _show(
    AnimationController controller,
    PaneMotion motion, {
    required bool visible,
  }) {
    final landing = _landings.remove(controller);
    if (landing != null) controller.removeListener(landing);
    final target = visible ? 1.0 : 0.0;
    final token = visible ? motion.enter : motion.exit;
    if (token.isNone) {
      controller.value = target;
      return;
    }
    if (!visible) {
      // A leaving component has gone once it reaches its edge; a spring
      // would carry it past and back into view.
      void land() {
        if (controller.value > 0) return;
        controller.removeListener(land);
        _landings.remove(controller);
        controller.value = 0;
        if (mounted) setState(() {});
      }

      _landings[controller] = land;
      controller.addListener(land);
    }
    controller.animateOn(token, target).then((_) {
      // Drops a component that has left, so it is no longer laid out.
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      final bar = widget.navigationBar;
      if (bar is NavigationBar) {
        final count = bar.destinations.length;
        if (count < 3 || count > 5) {
          throw FlutterError(
            'A navigation bar carries three to five destinations; '
            'this one has $count.',
          );
        }
      }
      return true;
    }());
    final motion = PaneMotion.resolve(context, widget.motion);
    final breakpoints = MaterialLayoutTheme.of(context).breakpoints;
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = breakpoints.forWidth(constraints.maxWidth);
        NavigationPlacement placementFor(int paneCount) =>
            navigationPlacementFor(
              breakpoint: breakpoint,
              paneCount: paneCount,
              hasBar: widget.navigationBar != null,
              hasRail: widget.navigationRail != null,
              rule: widget.placementRule,
            );
        final stated = widget.paneCount;
        // A first placement that depends on the pane count waits until the
        // layouts in the body have counted their panes, rather than place a
        // component on a guess and swap it a frame later.
        final waiting =
            _placement == null &&
            !_panesCounted &&
            stated == null &&
            placementFor(1) != placementFor(2);
        final NavigationPlacement? placement;
        if (waiting) {
          placement = null;
          _waitForPanes();
        } else {
          placement = placementFor(stated ?? _registry.paneCount);
          _place(placement, motion);
        }
        final rail = placement == NavigationPlacement.rail;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final barShown =
            placement == NavigationPlacement.bar ||
            _bar.value > 0 ||
            _bar.isAnimating;

        return _NavigationPlacementScope(
          placement: placement ?? NavigationPlacement.none,
          child: Scaffold(
            appBar: widget.appBar,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonLocation: widget.floatingActionButtonLocation,
            drawer: widget.drawer,
            endDrawer: widget.endDrawer,
            bottomSheet: widget.bottomSheet,
            backgroundColor: widget.backgroundColor,
            resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
            extendBody: widget.extendBody,
            restorationId: widget.restorationId,
            bottomNavigationBar: barShown
                ? _NavigationSlot(
                    animation: _bar,
                    axis: Axis.vertical,
                    active: placement == NavigationPlacement.bar,
                    child: widget.navigationBar,
                  )
                : null,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavigationSlot(
                  animation: _rail,
                  axis: Axis.horizontal,
                  active: rail,
                  onLaidOut: (size) => _railWidth = size.width,
                  child: widget.navigationRail,
                ),
                Expanded(
                  // The body's insets are those the Scaffold gives its body,
                  // as under an app bar, above the keyboard or behind a bar.
                  child: AnimatedBuilder(
                    animation: _rail,
                    builder: (context, child) {
                      final presence = widget.navigationRail == null
                          ? 0.0
                          : clampDouble(_rail.value, 0, 1);
                      // The rail keeps its own side clear of the safe area,
                      // and takes the place of the body's leading margin: it
                      // takes both over as it comes, and gives them back as
                      // it goes.
                      EdgeInsets beside(EdgeInsets insets) => rtl
                          ? insets.copyWith(
                              right: insets.right * (1 - presence),
                            )
                          : insets.copyWith(left: insets.left * (1 - presence));
                      final media = MediaQuery.of(context);
                      return MediaQuery(
                        data: media.copyWith(
                          padding: beside(media.padding),
                          viewPadding: beside(media.viewPadding),
                        ),
                        child: RailPresence(value: presence, child: child!),
                      );
                    },
                    // The layouts in the body arrange themselves for the room
                    // the body will have once the rail has come or gone, and
                    // its width follows the rail on the way. The rail is laid
                    // out before the body, so its width is this frame's.
                    child: LayoutBuilder(
                      builder: (context, body) => PaneRestingWidth(
                        width: body.maxWidth,
                        restingWidth: clampDouble(
                          constraints.maxWidth - (rail ? _railWidth : 0),
                          0,
                          constraints.maxWidth,
                        ),
                        child: PaneCountScope(
                          registry: _registry,
                          child: AdaptiveRegion(child: widget.body),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// A navigation component that grows in from its edge and shrinks out to it.
// While it leaves it takes no input, focus or semantics, so only one
// component is ever usable.
class _NavigationSlot extends StatelessWidget {
  const new({
    required this.animation,
    required this.axis,
    required this.active,
    this.onLaidOut,
    required this.child,
  });

  final Animation<double> animation;
  final Axis axis;
  final bool active;

  // Called with the size the component is laid out at, whatever part of it
  // shows.
  final ValueSetter<Size>? onLaidOut;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final component = child;
    if (component == null) return const SizedBox.shrink();
    Widget inert = ExcludeFocus(
      excluding: !active,
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(excluding: !active, child: component),
      ),
    );
    final onLaidOut = this.onLaidOut;
    if (onLaidOut != null) {
      inert = _SizeReporter(onLaidOut: onLaidOut, child: inert);
    }
    return AnimatedBuilder(
      animation: animation,
      child: inert,
      builder: (context, child) {
        final factor = clampDouble(animation.value, 0, 1);
        if (factor == 0 && !active) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: axis == Axis.horizontal
                ? AlignmentDirectional.centerEnd
                : Alignment.topCenter,
            widthFactor: axis == Axis.horizontal ? factor : null,
            heightFactor: axis == Axis.vertical ? factor : null,
            child: child,
          ),
        );
      },
    );
  }
}

// Reports the size its child is laid out at.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const new({required this.onLaidOut, super.child});

  final ValueSetter<Size> onLaidOut;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onLaidOut);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onLaidOut = onLaidOut;
}

class _RenderSizeReporter extends RenderProxyBox {
  new(this.onLaidOut);

  ValueSetter<Size> onLaidOut;

  @override
  void performLayout() {
    super.performLayout();
    onLaidOut(size);
  }
}

class _NavigationPlacementScope extends InheritedWidget {
  const new({required this.placement, required super.child});

  final NavigationPlacement placement;

  @override
  bool updateShouldNotify(_NavigationPlacementScope oldWidget) =>
      placement != oldWidget.placement;
}
