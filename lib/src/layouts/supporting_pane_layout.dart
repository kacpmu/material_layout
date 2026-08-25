import 'package:flutter/material.dart';

import '../foundation/adaptive_layout_theme.dart';
import '../foundation/window_size_class.dart';
import '../sheets/adaptive_sheet.dart';
import 'pane_controller.dart';
import 'pane_drag_handle.dart';
import 'two_pane.dart';

/// Where/how a [SupportingPaneLayout] presents its supporting pane for the
/// current region. Resolved deterministically by a [SupportingPaneResolver].
enum SupportingPanePresentation {
  /// Inline, on the leading edge (before the content). Built on [TwoPane].
  leading,

  /// Inline, on the trailing edge (after the content). Built on [TwoPane];
  /// this is the only presentation with the full width-reveal + resize.
  trailing,

  /// Stacked **below** the content, spanning the full width — Material 3's
  /// *reflow* strategy, and what the spec asks for at compact and medium:
  /// "The supporting pane should appear below the focus pane."
  below,

  /// Not part of the layout — the content fills the region. Surface the pane on
  /// demand instead (e.g. a button calling
  /// `SupportingPane.of(context).presentAsSheet(context)`). Not a Material
  /// default at any width; use it when the pane is genuinely optional.
  hidden;

  /// Whether this is an inline side-by-side ([leading] or [trailing])
  /// presentation, as opposed to [below] or [hidden].
  bool get isBeside =>
      this == SupportingPanePresentation.leading ||
      this == SupportingPanePresentation.trailing;

  /// Whether the pane occupies layout space at all — anything but [hidden].
  bool get isVisible => this != SupportingPanePresentation.hidden;
}

/// Decides, deterministically, how the supporting pane should be presented for
/// a given region. Pure function of the region size and its width/height
/// classes, so a window resize simply re-evaluates it — no surprises.
typedef SupportingPaneResolver = SupportingPanePresentation Function(
  BuildContext context,
  BoxConstraints region,
  WindowSizeClass widthClass,
  WindowHeightSizeClass heightClass,
);

/// The Material 3 default resolver.
///
/// Follows the spec's placement table exactly:
///
/// | Placement | Pane width | Breakpoint |
/// | --- | --- | --- |
/// | Below | Flexible | Compact or Medium |
/// | Leading or trailing | Fixed (360dp) | Expanded and wider |
///
/// The pane is never dropped for lack of width — at compact and medium it
/// reflows underneath the content instead. On a **short** window (compact
/// height, e.g. a phone in landscape) there is no room to stack, so it falls
/// back to [SupportingPanePresentation.hidden]; surface it as a sheet there.
SupportingPanePresentation defaultSupportingPaneResolver(
  BuildContext context,
  BoxConstraints region,
  WindowSizeClass widthClass,
  WindowHeightSizeClass heightClass,
) {
  if (widthClass.isExpandedOrWider) return SupportingPanePresentation.trailing;
  if (heightClass.isCompact) return SupportingPanePresentation.hidden;
  return SupportingPanePresentation.below;
}

/// Controls whether a [SupportingPaneLayout]'s pane is shown (for a
/// [SupportingPaneLayout.dismissible] pane). A [ChangeNotifier], so the same
/// object can drive the layout and be toggled from a button.
class SupportingPaneController extends ChangeNotifier {
  /// Creates a controller. [visible] is the initial shown state.
  // ignore: prefer_initializing_formals — private field, public parameter.
  SupportingPaneController({bool visible = false}) : _visible = visible;

  bool _visible;

  /// Whether the supporting pane is currently requested to show.
  bool get visible => _visible;

  set visible(bool value) {
    if (value == _visible) return;
    _visible = value;
    notifyListeners();
  }

  /// Shows the supporting pane.
  void show() => visible = true;

  /// Hides the supporting pane.
  void hide() => visible = false;

  /// Toggles the supporting pane.
  void toggle() => visible = !_visible;
}

/// A handle on the enclosing [SupportingPaneLayout], obtained via
/// [SupportingPane.of]. Lets descendants (e.g. an app-bar button) show/hide the
/// pane or present it as a sheet when it's [SupportingPanePresentation.hidden].
abstract class SupportingPaneHandle {
  /// Whether the supporting pane is currently shown inline.
  bool get visible;

  /// How the pane is presented for the current region.
  SupportingPanePresentation get presentation;

  /// Requests the supporting pane to show inline (no-op if the current
  /// [presentation] is hidden — use [presentAsSheet] there).
  void show();

  /// Hides the supporting pane inline.
  void hide();

  /// Toggles [visible].
  void toggle();

  /// Presents the supporting content as an adaptive sheet (a side sheet on wide
  /// windows, a bottom sheet on narrow ones). The one-liner for surfacing the
  /// pane when [presentation] is [SupportingPanePresentation.hidden].
  Future<T?> presentAsSheet<T>(BuildContext context);
}

/// Look up the enclosing [SupportingPaneLayout]'s handle.
class SupportingPane {
  const SupportingPane._();

  /// Returns the nearest [SupportingPaneHandle]. Asserts if there is none.
  static SupportingPaneHandle of(BuildContext context) {
    final handle = maybeOf(context);
    assert(handle != null,
        'SupportingPane.of() was called outside a SupportingPaneLayout.');
    return handle!;
  }

  /// Returns the nearest [SupportingPaneHandle], or `null` if there is none.
  static SupportingPaneHandle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SupportingPaneScope>()
        ?.handle;
  }
}

class _SupportingPaneScope extends InheritedWidget {
  const _SupportingPaneScope({
    required this.handle,
    required this.visible,
    required this.presentation,
    required super.child,
  });

  final SupportingPaneHandle handle;
  final bool visible;
  final SupportingPanePresentation presentation;

  @override
  bool updateShouldNotify(_SupportingPaneScope old) =>
      visible != old.visible || presentation != old.presentation;
}

/// The Material 3 supporting-pane canonical layout.
///
/// A primary [content] area plus a [supporting] pane that holds supplementary,
/// non-standalone content (tools, comments, related items). Its placement —
/// beside (leading/trailing), stacked below, or hidden — is chosen by a
/// deterministic [resolver] from the region's size classes (defaulting to
/// [defaultSupportingPaneResolver]); a resize simply re-evaluates it.
///
/// Following Material 3, the default resolver puts the pane **beside** the
/// content at expanded and wider, and **below** it at compact and medium — it
/// is not dropped for lack of width. The pane **never auto-opens a modal
/// sheet**; when a resolver does return
/// [SupportingPanePresentation.hidden] you surface it yourself (e.g. a button
/// calling `SupportingPane.of(context).presentAsSheet(context)`).
///
/// * [dismissible] `false` (default) → the pane is always shown wherever the
///   resolver places it. `true` → it starts hidden and is shown on demand
///   (`SupportingPane.of(context).show()` / a [controller]).
/// * [resizable] applies to the beside presentations (via [TwoPane]) and is
///   **temporary** (Material 3): the width resets to its default whenever the
///   pane is hidden, so it always reopens at a sensible size.
///
/// The layout is composable — [content] or [supporting] may themselves be other
/// layouts (nest a [TwoPane]/[SupportingPaneLayout] for a third pane at extra
/// large widths).
class SupportingPaneLayout extends StatefulWidget {
  /// Creates a supporting-pane layout.
  const SupportingPaneLayout({
    super.key,
    required this.content,
    required this.supporting,
    this.resolver,
    this.dismissible = false,
    this.controller,
    this.ratio,
    this.supportingWidth,
    this.gutter,
    this.minPaneWidth = 280,
    this.belowRatio = 0.6,
    this.resizable = false,
    this.spring = kExpressiveSpring,
    this.onPresentationChanged,
  })  : assert(ratio == null || (ratio > 0 && ratio < 1)),
        assert(supportingWidth == null || supportingWidth > 0),
        assert(
          ratio == null || supportingWidth == null,
          'Give either a proportional ratio or a fixed supportingWidth, not '
          'both — they describe the same dimension.',
        ),
        assert(belowRatio > 0 && belowRatio < 1);

  /// The primary content (the focus area).
  final Widget content;

  /// The supporting/supplementary pane.
  final Widget supporting;

  /// Chooses the presentation for the current region. Defaults to
  /// [defaultSupportingPaneResolver].
  final SupportingPaneResolver? resolver;

  /// Whether the pane is shown on demand. `false` (default) keeps it always
  /// present; `true` starts it hidden (show via [controller] / [SupportingPane.of]).
  final bool dismissible;

  /// Drives the shown/hidden state of a [dismissible] pane. Optional — an
  /// internal one is used when omitted.
  final SupportingPaneController? controller;

  /// The content's share of the width in beside mode, as a fraction.
  ///
  /// Leave it null (the default) for the Material 3 behaviour: a **fixed**
  /// supporting pane of [supportingWidth], which itself defaults to 360dp at
  /// expanded and 412dp at large and extra-large. Set a ratio only when you
  /// deliberately want a proportional split instead.
  final double? ratio;

  /// The supporting pane's fixed width in beside mode.
  ///
  /// Defaults to the Material 3 fixed-pane width for the current breakpoint
  /// (360dp at expanded, 412dp at large and extra-large). Ignored when [ratio]
  /// is set.
  final double? supportingWidth;

  /// The content's share of the **height** when the pane reflows [below] it.
  /// Defaults to 0.6, keeping the focus pane dominant.
  final double belowRatio;

  /// The gap between the panes.
  ///
  /// Defaults to the ambient [AdaptiveLayoutThemeData.spacing]'s
  /// `paneGutter` (24 out of the box).
  final double? gutter;

  /// The minimum pane width in beside mode. Defaults to 280.
  final double minPaneWidth;

  /// Whether the beside split is user-resizable (temporary). Defaults to false.
  final bool resizable;

  /// The spring driving the beside reveal/resize. Defaults to [kExpressiveSpring].
  final SpringDescription spring;

  /// Called (after layout) when the resolved [SupportingPanePresentation]
  /// changes — e.g. to offer a "show" button when it becomes hidden.
  final ValueChanged<SupportingPanePresentation>? onPresentationChanged;

  @override
  State<SupportingPaneLayout> createState() => _SupportingPaneLayoutState();
}

class _SupportingPaneLayoutState extends State<SupportingPaneLayout>
    implements SupportingPaneHandle {
  // Keeps the supporting widget's state alive as it moves between presentations
  // (e.g. a leading vs trailing TwoPane slot).
  final GlobalKey _supportingKey = GlobalKey();

  // Temporary resize state for the beside presentations; reset whenever the
  // pane is hidden (Material 3 temporary-resize behaviour).
  final PaneController _resize = PaneController();

  bool _internalVisible = false;
  // Null until the first layout resolves it, so the initial presentation is
  // always reported to onPresentationChanged.
  SupportingPanePresentation? _presentation;

  @override
  void initState() {
    super.initState();
    _internalVisible = !widget.dismissible;
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(SupportingPaneLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (oldWidget.dismissible != widget.dismissible && !widget.dismissible) {
      _internalVisible = true;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _resize.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  // --- SupportingPaneHandle ---------------------------------------------

  @override
  bool get visible {
    if (!widget.dismissible) return true; // always shown when not dismissible
    return widget.controller?.visible ?? _internalVisible;
  }

  @override
  SupportingPanePresentation get presentation =>
      _presentation ?? SupportingPanePresentation.hidden;

  @override
  void show() => _setVisible(true);

  @override
  void hide() => _setVisible(false);

  @override
  void toggle() => _setVisible(!visible);

  void _setVisible(bool value) {
    if (widget.controller != null) {
      widget.controller!.visible = value;
    } else if (_internalVisible != value) {
      setState(() => _internalVisible = value);
    }
    if (!value) _resize.reset(); // temporary: forget the width on close
  }

  @override
  Future<T?> presentAsSheet<T>(BuildContext context) {
    return showAdaptiveSheet<T>(context, builder: (_) => widget.supporting);
  }

  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final breakpoints = AdaptiveLayoutTheme.of(context).breakpoints;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthClass = breakpoints.resolve(constraints.maxWidth);
        final heightClass = constraints.maxHeight.isFinite
            ? breakpoints.resolveHeight(constraints.maxHeight)
            : WindowHeightSizeClass.expanded;
        final resolver = widget.resolver ?? defaultSupportingPaneResolver;
        final presentation =
            resolver(context, constraints, widthClass, heightClass);

        if (presentation != _presentation) {
          _presentation = presentation;
          final cb = widget.onPresentationChanged;
          if (cb != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) cb(presentation);
            });
          }
        }

        final show = visible && presentation.isVisible;
        // Temporary resizing (Material 3): forget the width whenever the beside
        // split is not the active presentation — hidden, or not shown —
        // so the pane always returns to its default split when it next appears
        // beside. A mounted TwoPane animates the divider back; a remount opens at
        // the default directly.
        final besideActive = show && presentation.isBeside;
        if (!besideActive && (_resize.fraction != null || _resize.isCollapsed)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _resize.reset();
          });
        }

        final supporting = KeyedSubtree(key: _supportingKey, child: widget.supporting);

        return _SupportingPaneScope(
          handle: this,
          visible: visible,
          presentation: presentation,
          child: _buildPresentation(presentation, show, supporting),
        );
      },
    );
  }

  Widget _buildPresentation(
    SupportingPanePresentation presentation,
    bool show,
    Widget supporting,
  ) {
    switch (presentation) {
      case SupportingPanePresentation.below:
        // Reflow: full-width, stacked, focus pane on top. No TwoPane here —
        // that engine splits horizontally, and this is the vertical case.
        if (!show) return widget.content;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: (belowRatioPercent), child: widget.content),
            SizedBox(height: _gutter(context)),
            Expanded(flex: 100 - belowRatioPercent, child: supporting),
          ],
        );

      case SupportingPanePresentation.hidden:
        // Keep the TwoPane mounted with a null secondary rather than dropping
        // to bare content: that reveals the supporting pane *out* (sliding it
        // and its drag handle off the trailing edge) instead of having it
        // vanish the frame the region got too narrow. Once the exit finishes a
        // TwoPane with no secondary is exactly its primary, so the hidden
        // layout is unchanged.
        return _besideTwoPane(supporting, show: false);

      case SupportingPanePresentation.trailing:
        // The premium path: TwoPane reveals the supporting pane in/out.
        return _besideTwoPane(supporting, show: show);

      case SupportingPanePresentation.leading:
        if (!show) return widget.content;
        return TwoPane(
          primary: supporting,
          secondary: widget.content,
          strategy: TwoPaneStrategy.fixedFlexible,
          ratio: widget.ratio == null ? null : 1 - widget.ratio!,
          fixedPaneWidth: widget.supportingWidth,
          fixedSide: PaneSide.primary,
          gutter: widget.gutter,
          minPaneWidth: widget.minPaneWidth,
          resizable: widget.resizable,
          temporaryResize: true,
          spring: widget.spring,
          controller: _resize,
        );
    }
  }

  /// [SupportingPaneLayout.belowRatio] as an integer flex, so the Column can
  /// split without floating-point flex weights.
  int get belowRatioPercent => (widget.belowRatio * 100).round().clamp(1, 99);

  /// The gutter in effect, matching what [TwoPane] would use.
  double _gutter(BuildContext context) =>
      widget.gutter ?? AdaptiveLayoutTheme.of(context).spacing.paneGutter;

  /// The trailing beside-presentation, and the shape the pane retreats into
  /// when it is hidden. [show] false hands [TwoPane] a null secondary, which
  /// reveals the pane (and its drag handle) out over the trailing edge.
  Widget _besideTwoPane(Widget supporting, {required bool show}) {
    return TwoPane(
      primary: widget.content,
      secondary: show ? supporting : null,
      strategy: TwoPaneStrategy.fixedFlexible,
      // Null ratio + null fixedPaneWidth = TwoPane's own breakpoint default
      // (360dp expanded, 412dp large+), which is exactly the spec's rule.
      ratio: widget.ratio,
      fixedPaneWidth: widget.supportingWidth,
      fixedSide: PaneSide.secondary,
      gutter: widget.gutter,
      minPaneWidth: widget.minPaneWidth,
      // Left on even while the pane is leaving, so the handle travels off the
      // edge with it. TwoPane stops the handle responding to drags the moment
      // the exit starts, and drops it entirely once there is no secondary.
      resizable: widget.resizable,
      temporaryResize: true,
      spring: widget.spring,
      controller: _resize,
      onSecondaryDismissed: show && widget.dismissible ? hide : null,
    );
  }
}
