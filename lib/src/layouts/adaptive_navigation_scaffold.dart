import 'package:flutter/material.dart';

import '../foundation/adaptive_layout_theme.dart';
import '../foundation/breakpoints.dart';
import '../foundation/window_size.dart';
import '../foundation/window_size_class.dart';

/// Key on the bar's reveal transition — for tests that measure its collapse.
@visibleForTesting
const Key navigationBarRevealKey =
    Key('AdaptiveNavigationScaffold.navBarReveal');

/// Key on the rail's reveal transition — for tests that measure its collapse.
@visibleForTesting
const Key navigationRailRevealKey =
    Key('AdaptiveNavigationScaffold.navRailReveal');

/// The kind of navigation chrome an [AdaptiveNavigationScaffold] shows for a
/// given window size.
enum NavigationType {
  /// No navigation chrome.
  none,

  /// A bottom navigation bar — typically compact / medium widths.
  bar,

  /// A navigation rail — typically expanded and wider widths.
  rail,
}

/// Resolves the [NavigationType] to show for a given window size and pane
/// count.
///
/// [paneCount] matters because Material 3 makes the medium-breakpoint choice
/// depend on it: a single-pane medium layout takes a navigation **rail**, while
/// a two-pane one takes a navigation **bar** so the panes keep the full width.
typedef NavigationTypeResolver = NavigationType Function(
  WindowSize windowSize,
  int paneCount,
);

/// The default Material 3 navigation resolver.
///
/// * **Compact** — a bar. ("Use a navigation bar or modal expanded navigation
///   rail.")
/// * **Medium** — a rail for a single pane, a bar for two. ("Single-pane
///   layouts: Navigation rail. Two-pane layouts: Navigation bar… This allows
///   the panes to fully use the available window width.")
/// * **Expanded and wider** — a rail, collapsed or expanded.
/// * **Short windows** (compact height, e.g. a phone in landscape) — a bar
///   regardless of width; a tall rail does not fit.
///
/// Provide your own [NavigationTypeResolver] to move these breakpoints — e.g.
/// keep the bar up to a wider width, or switch to the rail earlier.
NavigationTypeResolver materialNavigationTypeResolver() => _materialResolver;

// Built once. `materialNavigationTypeResolver()` is called from build, and
// handing back a fresh closure each time makes every resolver comparison
// (including didUpdateWidget's) falsely unequal.
NavigationType _materialResolver(WindowSize windowSize, int paneCount) {
  final wc = windowSize.widthClass;
  if (windowSize.isCompactHeight || wc == WindowSizeClass.compact) {
    return NavigationType.bar;
  }
  if (wc == WindowSizeClass.medium) {
    // Two panes at medium want every pixel, so the navigation goes to the
    // bottom; a single pane has room for the rail on the leading edge.
    return paneCount >= 2 ? NavigationType.bar : NavigationType.rail;
  }
  return NavigationType.rail;
}

/// Overrides the reveal animation wrapped around a navigation component.
typedef NavigationTransitionBuilder = Widget Function(
  BuildContext context,
  NavigationType type,
  Animation<double> reveal,
  Widget child,
);

/// An adaptive Material 3 (Expressive) navigation scaffold — a layout shell that
/// places your navigation by window size, animating the swap as it resizes:
///
/// * compact / medium → [navigationBar] at the bottom;
/// * expanded and wider → [navigationRail] alongside the [body].
///
/// You supply the navigation as plain [navigationBar] / [navigationRail] widgets
/// (typically `NavigationBar` / `NavigationRail`); the scaffold
/// only reveals or hides each by window size — it doesn't change their contents.
///
/// Placement **adapts to which widgets you provide**: give only a
/// [navigationRail] and it shows at every width; only a [navigationBar] and it
/// shows everywhere; or override entirely with [navigationTypeResolver].
///
/// [drawer] / [endDrawer] are plain [Scaffold] drawers — always available
/// (opened from a menu button), *not* a breakpoint-driven nav surface; put
/// destinations in one with a [NavigationDrawer] if you want. A natural fit for
/// a router shell.
class AdaptiveNavigationScaffold extends StatefulWidget {
  /// Creates an adaptive navigation scaffold.
  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    this.navigationBar,
    this.navigationRail,
    this.drawer,
    this.endDrawer,
    this.navigationTypeResolver,
    this.navigationTransitionBuilder,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.breakpoints,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.paneCount = 1,
  }) : assert(paneCount >= 1);

  /// The screen content (e.g. a router nav-shell or a single screen).
  final Widget body;

  /// The bottom navigation bar (shown at compact / medium widths). Typically an
  /// `NavigationBar`.
  final Widget? navigationBar;

  /// The navigation rail (shown at expanded and wider widths). Typically an
  /// `NavigationRail`.
  final Widget? navigationRail;

  /// A plain [Scaffold] drawer — always available (opened from a menu button or
  /// an edge swipe), *not* a breakpoint-driven navigation surface. Pass a
  /// [NavigationDrawer] if you want navigation destinations in it.
  final Widget? drawer;

  /// A plain [Scaffold] end-drawer (trailing edge), always available.
  final Widget? endDrawer;

  /// Resolves which [NavigationType] to show. Defaults to
  /// [materialNavigationTypeResolver].
  final NavigationTypeResolver? navigationTypeResolver;

  /// Overrides the reveal animation around the bar/rail.
  final NavigationTransitionBuilder? navigationTransitionBuilder;

  /// An optional top app bar (shown across all size classes).
  final PreferredSizeWidget? appBar;

  /// An optional floating action button.
  final Widget? floatingActionButton;

  /// The FAB location. Defaults to [FloatingActionButtonLocation.endFloat].
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Overrides the breakpoints from the ambient [AdaptiveLayoutTheme].
  final Breakpoints? breakpoints;

  /// The scaffold background color.
  final Color? backgroundColor;

  /// Whether the body extends behind the app bar.
  final bool extendBodyBehindAppBar;

  /// How many panes [body] is showing right now. Defaults to 1.
  ///
  /// Only consulted at the medium breakpoint, where Material 3 picks the
  /// navigation surface by pane count rather than by width — see
  /// [materialNavigationTypeResolver]. Leave it at 1 unless the body actually
  /// puts two panes side by side at medium widths.
  final int paneCount;

  @override
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState extends State<AdaptiveNavigationScaffold>
    with TickerProviderStateMixin {
  late final AnimationController _barController;
  late final AnimationController _railController;
  late final _BarAnimation _barAnimation;
  late final _RailAnimation _railAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    const duration = Duration(milliseconds: 500);
    _barController =
        AnimationController(vsync: this, duration: duration, value: 0);
    _railController =
        AnimationController(vsync: this, duration: duration, value: 0);
    _barAnimation = _BarAnimation(parent: _barController);
    _railAnimation = _RailAnimation(parent: _railController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(animate: _initialized);
    _initialized = true;
  }

  @override
  void didUpdateWidget(AdaptiveNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Which chrome should be showing is a function of the *widget*, not only of
    // the MediaQuery: swapping in a different resolver, different breakpoints,
    // or adding/removing a bar or rail all change the answer without touching
    // any dependency. Without this the reveal stays parked on the old target
    // until something unrelated happens to nudge didChangeDependencies.
    final bool slotsChanged =
        (oldWidget.navigationBar == null) != (widget.navigationBar == null) ||
            (oldWidget.navigationRail == null) != (widget.navigationRail == null);
    if (slotsChanged ||
        oldWidget.navigationTypeResolver != widget.navigationTypeResolver ||
        oldWidget.paneCount != widget.paneCount ||
        oldWidget.breakpoints != widget.breakpoints) {
      _sync(animate: true);
    }
  }

  @override
  void dispose() {
    // CurvedAnimation holds a listener on its parent and must be disposed;
    // disposing only the controllers leaks one per mount.
    _barAnimation.dispose();
    _railAnimation.dispose();
    _barController.dispose();
    _railController.dispose();
    super.dispose();
  }

  WindowSize get _windowSize {
    final bp = widget.breakpoints ?? AdaptiveLayoutTheme.of(context).breakpoints;
    return WindowSize.fromSize(MediaQuery.sizeOf(context), bp);
  }

  NavigationType _typeFor(WindowSize windowSize) {
    final hasBar = widget.navigationBar != null;
    final hasRail = widget.navigationRail != null;
    if (!hasBar && !hasRail) return NavigationType.none;
    final resolver =
        widget.navigationTypeResolver ?? materialNavigationTypeResolver();
    final type = resolver(windowSize, widget.paneCount);
    // Fall back to whichever component the caller actually provided — so a
    // rail-only (or bar-only) scaffold shows it at every width.
    if (type == NavigationType.bar && !hasBar) return NavigationType.rail;
    if (type == NavigationType.rail && !hasRail) return NavigationType.bar;
    return type;
  }

  bool get _hasNavigation =>
      widget.navigationBar != null || widget.navigationRail != null;

  void _sync({required bool animate}) {
    if (!_hasNavigation) return;
    final type = _typeFor(_windowSize);
    final showBar = type == NavigationType.bar;
    final showRail = type == NavigationType.rail;
    // BarAnimation is reversed: controller 0 => bar shown, 1 => hidden.
    _drive(_barController, showBar ? 0.0 : 1.0, animate);
    _drive(_railController, showRail ? 1.0 : 0.0, animate);
  }

  void _drive(AnimationController controller, double target, bool animate) {
    if (animate) {
      controller.animateTo(target);
    } else {
      controller.value = target;
    }
  }

  Widget _wrapReveal(NavigationType type, Widget child, {required bool isBar}) {
    if (widget.navigationTransitionBuilder != null) {
      final reveal = isBar ? _barAnimation : _railAnimation;
      return widget.navigationTransitionBuilder!(context, type, reveal, child);
    }
    return isBar
        ? _NavBarTransition(
            key: navigationBarRevealKey,
            animation: _barAnimation,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          )
        : _NavRailTransition(
            key: navigationRailRevealKey,
            animation: _railAnimation,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: child,
          );
  }

  @override
  Widget build(BuildContext context) {
    final type = _hasNavigation ? _typeFor(_windowSize) : NavigationType.none;

    // The bar/rail stay mounted whenever provided, so the reveal can collapse
    // the inactive one to zero size as the window resizes.
    final Widget? leading = widget.navigationRail != null
        ? _wrapReveal(type, widget.navigationRail!, isBar: false)
        : null;

    final Widget? bottomBar = widget.navigationBar != null
        ? _wrapReveal(type, widget.navigationBar!, isBar: true)
        : null;

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.appBar,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The rail (when shown) handles its own safe-area insets internally,
          // so it isn't wrapped here — wrapping the whole Row would push a
          // system-inset gap *below* the rail. The body gets its own SafeArea.
          ?leading,
          Expanded(child: SafeArea(child: widget.body)),
        ],
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}

// --- Reveal animations + transitions ----------------------------------------
// Folded in from the former navigation/animations.dart + transitions.dart
// (private to the scaffold — the only consumer). These slice a single 0→1
// controller into staggered sub-curves so the slide and the size-collapse of a
// bar/rail play in sequence rather than all at once.

/// Drives the bottom navigation bar reveal. Reversed so the bar is fully shown
/// at controller value `0` (compact) and hidden at `1` (large).
class _BarAnimation extends ReverseAnimation {
  factory _BarAnimation({required AnimationController parent}) {
    return _BarAnimation._(CurvedAnimation(
      parent: parent,
      curve: const Interval(0, 1 / 5),
      reverseCurve: const Interval(1 / 5, 4 / 5),
    ));
  }

  _BarAnimation._(this._curved) : super(_curved);

  // Held so it can be disposed: the CurvedAnimation is what listens to the
  // controller, and ReverseAnimation gives no way back to it.
  final CurvedAnimation _curved;

  void dispose() => _curved.dispose();
}

/// The slide phase of a reveal (translated offset), played in the middle of the
/// timeline with emphasized easing.
class _OffsetAnimation extends CurvedAnimation {
  _OffsetAnimation({required super.parent})
      : super(
          curve: const Interval(
            2 / 5,
            3 / 5,
            curve: Curves.easeInOutCubicEmphasized,
          ),
          reverseCurve: Interval(
            4 / 5,
            1,
            curve: Curves.easeInOutCubicEmphasized.flipped,
          ),
        );
}

/// Drives the navigation rail reveal (shown at controller value `1`).
class _RailAnimation extends CurvedAnimation {
  _RailAnimation({required super.parent})
      : super(
          curve: const Interval(0 / 5, 4 / 5),
          reverseCurve: const Interval(3 / 5, 1),
        );
}

/// The size-collapse phase of a reveal (a width/height factor), played early so
/// the layout reflows smoothly as the panel slides away.
class _SizeAnimation extends CurvedAnimation {
  _SizeAnimation({required super.parent})
      : super(
          curve: const Interval(
            0 / 5,
            3 / 5,
            curve: Curves.easeInOutCubicEmphasized,
          ),
          reverseCurve: Interval(
            2 / 5,
            1,
            curve: Curves.easeInOutCubicEmphasized.flipped,
          ),
        );
}

/// Slides and size-collapses a bottom navigation bar in from the bottom edge in
/// compact windows (and out as the window grows past the rail breakpoint).
class _NavBarTransition extends StatefulWidget {
  const _NavBarTransition({
    super.key,
    required this.animation,
    required this.backgroundColor,
    required this.child,
  });

  final _BarAnimation animation;
  final Color backgroundColor;
  final Widget child;

  @override
  State<_NavBarTransition> createState() => _NavBarTransitionState();
}

class _NavBarTransitionState extends State<_NavBarTransition> {
  late final _OffsetAnimation _offset =
      _OffsetAnimation(parent: widget.animation);
  late final _SizeAnimation _size = _SizeAnimation(parent: widget.animation);

  late final Animation<Offset> offsetAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_offset);

  late final Animation<double> heightAnimation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(_size);

  @override
  void dispose() {
    _offset.dispose();
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: AnimatedBuilder(
          animation: heightAnimation,
          builder: (context, child) {
            return Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: heightAnimation.value,
              child: FractionalTranslation(
                translation: offsetAnimation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Slides and size-collapses a navigation rail in from the leading edge as the
/// window grows past the rail breakpoint (and back out below it). RTL-aware:
/// the rail slides in from the right when the text direction is right-to-left.
class _NavRailTransition extends StatefulWidget {
  const _NavRailTransition({
    super.key,
    required this.animation,
    required this.backgroundColor,
    required this.child,
  });

  final _RailAnimation animation;
  final Widget child;
  final Color backgroundColor;

  @override
  State<_NavRailTransition> createState() => _NavRailTransitionState();
}

class _NavRailTransitionState extends State<_NavRailTransition> {
  late final _OffsetAnimation _offset =
      _OffsetAnimation(parent: widget.animation);
  late final _SizeAnimation _size = _SizeAnimation(parent: widget.animation);

  late final Animation<double> widthAnimation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(_size);

  @override
  void dispose() {
    _offset.dispose();
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the direction on every build. Capturing it once (in a `late final`
    // or a Tween built in initState) freezes the rail sliding in from whichever
    // edge was leading at first paint, so a runtime locale/RTL switch leaves it
    // entering from the wrong side for the rest of its life.
    final bool ltr = Directionality.of(context) == TextDirection.ltr;
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: AnimatedBuilder(
          animation: widthAnimation,
          builder: (context, child) {
            // 0 → parked one full width off the leading edge; 1 → in place.
            final double dx = (ltr ? -1.0 : 1.0) * (1.0 - _offset.value);
            return Align(
              alignment: AlignmentDirectional.topStart,
              widthFactor: widthAnimation.value,
              child: FractionalTranslation(
                translation: Offset(dx, 0),
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
