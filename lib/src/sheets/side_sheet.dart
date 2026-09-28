// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../foundation/breakpoints.dart';
import '../foundation/localizations.dart';
import '../foundation/motion.dart';
import '../foundation/theme.dart';
import '../panes/pane_scope.dart';

/// A sheet on the trailing edge of the screen, holding content supplementary
/// to the screen's main content.
///
/// The same surface serves both variants, chosen by how it is used:
///
///  * **standard**: placed as a pane, typically the supporting pane of a
///    `SupportingPaneLayout`. It sits beside the content, which shrinks to
///    make room, and stays interactive with it. Its container is the
///    surface colour, with the corners the app gives its panes,
///    [MaterialLayoutThemeData.paneBorderRadius]: rounded where the panes are
///    cards set in by the margins, square where they are flat at the edge.
///  * **modal**: presented by [showSideSheet] in front of the content, which
///    it blocks until dismissed. Its container is the surface container low
///    colour, with 16dp corners on its leading edge.
///
/// [backgroundColor] colours either variant; left null, the colour is
/// [MaterialLayoutThemeData.sideSheetStyle]'s for the variant, and then
/// Material's.
///
/// The container is the only element the component requires; this
/// widget adds, when given, a [headline], a back button ([onBack]) and
/// bottom [actions] below a divider, spaced to the component's measurements.
/// It shows a close button, which keyboards and assistive technology can
/// reach, wherever it can be closed: the button calls [onClose], or closes
/// whatever presents the sheet — the modal route, or the supporting pane when
/// the layout lets it be dismissed. A standard sheet that nothing closes,
/// as a permanent supporting pane, shows none. Its role is a dialog in both
/// variants.
///
/// The [child] scrolls vertically, independently of the rest of the screen,
/// and never horizontally. The sheet scrolls it, so build content
/// that does not scroll itself, such as a [Column]: a list view inside would
/// take the drags without anything to scroll.
///
/// A side sheet is at most [maxWidth] wide and declares its [width]
/// as its preferred size, which a supporting pane honours.
class SideSheet extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a side sheet.
  const new({
    super.key,
    this.headline,
    this.onBack,
    this.onClose,
    this.actions = const <Widget>[],
    this.width = maxWidth,
    this.backgroundColor,
    required this.child,
  }) : assert(width > 0 && width <= maxWidth);

  /// The widest a side sheet may be.
  static const double maxWidth = 400;

  /// The sheet's title, typically a [Text].
  final Widget? headline;

  /// Called by the back button, which shows only when this is not null.
  final VoidCallback? onBack;

  /// Called by the close button, or null to close whatever presents the
  /// sheet.
  ///
  /// A modal sheet, and one in a pane that can be dismissed, as a supporting
  /// pane with `onSupportingDismissed`, close by themselves. Elsewhere, a
  /// sheet without [onClose] shows no close button, and stays until the app
  /// removes it.
  final VoidCallback? onClose;

  /// Buttons at the bottom of the sheet, aligned to its start.
  ///
  /// They sit in a row, or stack where the row would be wider than the
  /// sheet.
  final List<Widget> actions;

  /// The sheet's width: [maxWidth] unless narrowed to suit the layout.
  ///
  /// It is the width of the pane the sheet takes, which a layout arranges its
  /// panes by before the sheet is built, so it is the sheet's own, never the
  /// theme's.
  final double width;

  /// The sheet's colour, or null for the theme's: the surface colour for a
  /// standard sheet and the surface container low colour for a modal one,
  /// unless [SideSheetStyle] says otherwise.
  final Color? backgroundColor;

  /// The sheet's content, which the sheet scrolls.
  final Widget child;

  @override
  Size get preferredSize => Size.fromWidth(width);

  @override
  Widget build(BuildContext context) {
    final presentation = context
        .dependOnInheritedWidgetOfExactType<_ModalPresentation>();
    final modal = presentation != null;
    final close =
        onClose ?? presentation?.close ?? PaneScope.maybeOf(context)?.onDismiss;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = MaterialLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = onBack;

    final header = Padding(
      padding: EdgeInsetsDirectional.only(
        start: modal && back != null ? 16 : 24,
        end: 24,
        top: _gap,
        bottom: _gap,
      ),
      // The header keeps its height without the buttons.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Row(
          spacing: _gap,
          children: [
            // A modal sheet moves focus to its first element when it opens.
            if (back != null)
              IconButton(
                autofocus: modal,
                icon: const BackButtonIcon(),
                color: colors.onSurfaceVariant,
                tooltip: strings.backButtonTooltip,
                onPressed: back,
              ),
            Expanded(
              child: DefaultTextStyle(
                style: _headlineStyle(theme),
                child: headline ?? const SizedBox.shrink(),
              ),
            ),
            if (close != null)
              IconButton(
                autofocus: modal && back == null,
                icon: const Icon(Icons.close),
                color: colors.onSurfaceVariant,
                tooltip: strings.closeButtonTooltip,
                onPressed: close,
              ),
          ],
        ),
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('side-sheet'),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            child: child,
          ),
        ),
        if (actions.isNotEmpty) ...[
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
              // In a row where they fit, and stacked where the sheet is
              // too narrow for them, or the text too large.
              child: OverflowBar(
                spacing: 8,
                overflowSpacing: 8,
                children: actions,
              ),
            ),
          ),
        ],
      ],
    );

    // The sheet keeps its content clear of the safe-area inset on the
    // trailing edge, which a modal sheet always meets, and a sheet in a pane
    // meets where its layout keeps the margins within the panes. It never
    // meets the leading edge.
    final content = SafeArea(left: rtl, right: !rtl, child: body);
    // A standard sheet is shaped as the app's other panes are.
    final layoutTheme = MaterialLayoutTheme.of(context);
    final paneCorners = layoutTheme.paneBorderRadius;
    final style = layoutTheme.sideSheetStyle;
    final color =
        backgroundColor ??
        (modal
            ? style.modalBackgroundColor ?? colors.surfaceContainerLow
            : style.backgroundColor ?? colors.surface);
    Widget container(Widget content) => Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: modal
            ? const BorderRadiusDirectional.horizontal(
                start: Radius.circular(16),
              )
            : paneCorners,
      ),
      clipBehavior: modal || paneCorners != BorderRadius.zero
          ? Clip.antiAlias
          : Clip.none,
      child: content,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.dialog,
      namesRoute: modal,
      label: MaterialLayoutLocalizations.of(context).sideSheetLabel,
      child: presentation == null
          ? container(content)
          : _PredictiveBackTransform(
              progress: presentation.back,
              fromFarEdge: presentation.backFromFarEdge,
              container: container,
              content: content,
            ),
    );
  }
}

// The padding between the elements at the top of a side sheet.
const double _gap = 12;

// The style of a sheet's headline.
TextStyle _headlineStyle(ThemeData theme) =>
    theme.textTheme.titleLarge!.copyWith(color: theme.colorScheme.onSurface);

class _ModalPresentation extends InheritedWidget {
  const new({
    required this.close,
    required this.back,
    required this.backFromFarEdge,
    required super.child,
  });

  final VoidCallback close;

  // The progress of a system back gesture, from 0 to 1.
  final Animation<double> back;

  // Whether the gesture started from the edge away from the sheet.
  final bool backFromFarEdge;

  @override
  bool updateShouldNotify(_ModalPresentation oldWidget) =>
      back != oldWidget.back || backFromFarEdge != oldWidget.backFromFarEdge;
}

// How a modal sheet follows a system back gesture, as on Android: the
// container detaches from the top and bottom edges and, for a gesture from
// the far edge, narrows towards its own edge; the content keeps its
// proportions and its place at the top of the container, which clips it.
class _PredictiveBackTransform extends StatelessWidget {
  const new({
    required this.progress,
    required this.fromFarEdge,
    required this.container,
    required this.content,
  });

  final Animation<double> progress;
  final bool fromFarEdge;
  final Widget Function(Widget content) container;
  final Widget content;

  // Android's progress curve and distances for side containers.
  static const Curve _curve = Cubic(0.1, 0.1, 0, 1);
  static const double _narrowing = 24;
  static const double _detachment = 48;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: progress,
        child: content,
        builder: (context, content) {
          final size = constraints.biggest;
          final t = _curve.transform(clampDouble(progress.value, 0, 1));
          final scaleX = fromFarEdge && size.width.isFinite && size.width > 0
              ? 1 - _narrowing * t / size.width
              : 1.0;
          final scaleY = size.height.isFinite && size.height > 0
              ? 1 - _detachment * t / size.height
              : 1.0;
          return Transform(
            alignment: rtl ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
            child: container(
              Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.diagonal3Values(1, scaleX / scaleY, 1),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shows a modal side sheet on the trailing edge of the window.
///
/// [builder] returns the [SideSheet]; its close button, a tap on the scrim
/// when [barrierDismissible] is true, and the back button all close it. The
/// scrim is [barrierColor], or [SideSheetStyle.modalBarrierColor], or black
/// at 54% opacity. The
/// sheet slides in from the trailing edge — the left in a right-to-left
/// layout — on the enter motion of [motion], and slides out on its exit
/// motion, and the scrim fades on the default effects token; both
/// are skipped when the platform asks for reduced motion. On a
/// window a hinge or fold divides, the sheet takes the screen on the
/// trailing side.
///
/// The sheet is a modal route: the content behind it takes no input, focus
/// moves to the sheet's first element when it opens and returns to where it
/// was when it closes. On Android it follows the system back gesture,
/// which is how it is swiped away: the sheet detaches from the top and bottom
/// edges and shrinks as the gesture progresses, and closes when the gesture
/// completes. It cannot be dragged.
///
/// Returns a future that completes with the value the sheet is popped with.
Future<T?> showSideSheet<T extends Object?>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  PaneMotion? motion,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final resolved = PaneMotion.resolve(context, motion);
  final layoutTheme = MaterialLayoutTheme.of(context);
  final effects = layoutTheme.motionScheme.defaultEffects.unlessReduced(
    context,
  );
  // The share of the sheet's slide that the scrim fades over, on the
  // effects token.
  double fadeShare(Motion slide) {
    final seconds = slide.duration.inMicroseconds;
    return seconds == 0
        ? 1.0
        : math.min(1.0, effects.duration.inMicroseconds / seconds);
  }

  final fadeIn = fadeShare(resolved.enter);
  final fadeOut = fadeShare(resolved.exit);
  final scrim =
      barrierColor ??
      layoutTheme.sideSheetStyle.modalBarrierColor ??
      Colors.black54;
  final rtl = Directionality.of(context) == TextDirection.rtl;

  return navigator.push<T>(
    _SideSheetRoute<T>(
      settings: routeSettings,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      enter: resolved.enter.duration,
      exit: resolved.exit.duration,
      // On a window a hinge or fold divides, the screen on the trailing side.
      anchorPoint: rtl
          ? Offset.zero
          : Offset(MediaQuery.sizeOf(context).width, 0),
      pageBuilder: (context, animation, secondaryAnimation) {
        final sheet = builder(context);
        assert(
          sheet is SideSheet,
          "showSideSheet's builder must return a SideSheet, which draws the "
          'close button a side sheet requires.',
        );
        return themes.wrap(
          _SideSheetTransition(
            animation: animation,
            slideIn: resolved.enter.curve,
            slideOut: resolved.exit.curve,
            fade: Interval(0, fadeIn, curve: effects.curve),
            unfade: Interval(
              1 - fadeOut,
              1,
              curve: FlippedCurve(effects.curve),
            ),
            scrim: scrim,
            width: sheet is PreferredSizeWidget
                ? sheet.preferredSize.width
                : SideSheet.maxWidth,
            child: sheet,
          ),
        );
      },
    ),
  );
}

// The route of a modal side sheet: it enters for as long as the enter
// motion takes and leaves for as long as the exit motion does, and adds no
// transition of its own to the sheet's slide and the scrim's fade.
class _SideSheetRoute<T> extends RawDialogRoute<T> {
  new({
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierLabel,
    required Duration enter,
    required this._exit,
    super.anchorPoint,
    super.settings,
  }) : super(
         // The scrim is drawn by the transition, so that it fades on the
         // effects token rather than the route's curve; the barrier still
         // takes the taps.
         barrierColor: const Color(0x00000000),
         transitionDuration: enter,
         transitionBuilder: _noTransition,
       );

  final Duration _exit;

  @override
  Duration get reverseTransitionDuration => _exit;

  static Widget _noTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

// Slides the sheet in from the trailing edge and fades the scrim behind it,
// focuses the sheet's first element, and follows the system back gesture.
class _SideSheetTransition extends StatefulWidget {
  const new({
    required this.animation,
    required this.slideIn,
    required this.slideOut,
    required this.fade,
    required this.unfade,
    required this.scrim,
    required this.width,
    required this.child,
  });

  final Animation<double> animation;
  final Curve slideIn;
  final Curve slideOut;
  final Curve fade;
  final Curve unfade;
  final Color scrim;
  final double width;
  final Widget child;

  @override
  State<_SideSheetTransition> createState() => _SideSheetTransitionState();
}

class _SideSheetTransitionState extends State<_SideSheetTransition>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CurvedAnimation _slide = CurvedAnimation(
    parent: widget.animation,
    curve: widget.slideIn,
    reverseCurve: FlippedCurve(widget.slideOut),
  );
  late final CurvedAnimation _opacity = CurvedAnimation(
    parent: widget.animation,
    curve: widget.fade,
    reverseCurve: widget.unfade,
  );
  late final AnimationController _back = AnimationController(vsync: this);
  ModalRoute<Object?>? _route;
  bool _backFromFarEdge = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _back.dispose();
    _slide.dispose();
    _opacity.dispose();
    super.dispose();
  }

  void _close() => Navigator.maybePop(context);

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = _route;
    if (backEvent.isButtonEvent ||
        route == null ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fromFarEdge =
        backEvent.swipeEdge == (rtl ? SwipeEdge.right : SwipeEdge.left);
    if (fromFarEdge != _backFromFarEdge) {
      setState(() => _backFromFarEdge = fromFarEdge);
    }
    // The route stays fully shown while the gesture lasts; the sheet shows
    // the gesture's progress instead.
    route.handleStartBackGesture(progress: 1);
    _back.value = backEvent.progress;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    _route?.handleUpdateBackGestureProgress(progress: 1);
    _back.value = backEvent.progress;
  }

  @override
  void handleCancelBackGesture() {
    _route?.handleCancelBackGesture();
    _back.animateOn(
      MotionScheme.of(context).fastSpatial.unlessReduced(context),
      0,
    );
  }

  // The sheet slides out from where the gesture left it.
  @override
  void handleCommitBackGesture() => _route?.handleCommitBackGesture();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _opacity,
              child: ColoredBox(color: widget.scrim),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final extent = math.min(widget.width, constraints.maxWidth);
            return AnimatedBuilder(
              animation: _slide,
              child: SizedBox(
                width: extent,
                child: _ModalPresentation(
                  close: _close,
                  back: _back,
                  backFromFarEdge: _backFromFarEdge,
                  child: widget.child,
                ),
              ),
              builder: (context, child) {
                // An overshooting spring would pull the sheet off the edge,
                // so it stops at the edge instead.
                final hidden = (1 - math.min(1.0, _slide.value)) * extent;
                return Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Transform.translate(
                    offset: Offset(rtl ? -hidden : hidden, 0),
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Shows a modal sheet in the form that suits the window: a side sheet at
/// expanded and wider, a bottom sheet below.
///
/// The form is chosen from the width of the window, not of the region the
/// caller is in: a sheet is a window-level surface. [builder] builds
/// the content, which goes inside a [SideSheet] or into
/// [showModalBottomSheet], inset from the sheet's edges by 24dp in either
/// form; [headline] titles either. Either form scrolls the content, so build
/// content that does not scroll itself, such as a [Column].
///
/// [isDismissible] lets a tap on the scrim close the sheet, and
/// [useRootNavigator] shows it above every navigator, as a window-level
/// surface. The side sheet's scrim is [SideSheetStyle.modalBarrierColor]'s,
/// and the bottom sheet's the app's bottom sheet theme's. [motion] moves the
/// side sheet, as [showSideSheet] does; the bottom sheet moves as
/// Material's does, and neither moves where the platform asks for reduced
/// motion.
///
/// Returns a future that completes with the value the sheet is popped with.
Future<T?> showAdaptiveSheet<T extends Object?>({
  required BuildContext context,
  required WidgetBuilder builder,
  Widget? headline,
  bool isDismissible = true,
  bool useRootNavigator = true,
  PaneMotion? motion,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final breakpoint = MaterialLayoutTheme.of(context).breakpoints
      .forWidth(width);
  if (breakpoint >= Breakpoint.expanded) {
    return showSideSheet<T>(
      context: context,
      barrierDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      motion: motion,
      builder: (context) =>
          SideSheet(headline: headline, child: builder(context)),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    showDragHandle: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      // The content keeps the side sheet's insets, and scrolls as it does, so
      // that it looks and behaves the same in either form; its end
      // scrolls clear of the bottom inset.
      final content = SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          start: 24,
          end: 24,
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: builder(context),
      );
      final title = headline;
      if (title == null) return content;
      final theme = Theme.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, _gap),
            child: DefaultTextStyle(style: _headlineStyle(theme), child: title),
          ),
          Flexible(child: content),
        ],
      );
    },
  );
}
