// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

/// What the inbox shows beside the list when no message is selected, with
/// two panes.
enum NothingSelected {
  /// A placeholder in the detail pane.
  placeholder,

  /// No detail pane: the list takes the whole inbox.
  listOnly,

  /// The first message, which the list marks as selected.
  firstMessage,
}

/// How the demo paints its panes, and so where the layouts keep their
/// margins.
enum PaneStyle {
  /// Flat in a compact window, where the one pane fills the screen, and
  /// cards from medium up.
  byWindow,

  /// Cards everywhere: the layouts keep their margins around the panes.
  cards,

  /// Flat everywhere: the layouts keep their margins within the panes.
  flat,
}

/// The motion scheme of the demo's layout theme.
enum MotionChoice {
  /// Springs with a slight overshoot: the package's default.
  expressive,

  /// Springs that are close to critically damped.
  standard,

  /// The expressive scheme, with panes, sheets and navigation on a spring of
  /// the demo's own.
  spring,

  /// The expressive scheme, with panes, sheets and navigation on a timed
  /// curve rather than a spring.
  curve,
}

/// The colour the demo paints its panes in, which the layout theme's pane
/// surface style sets.
enum PaneColor {
  /// The colour scheme's surface colour: Material's, which blends in with a
  /// flat pane's background.
  surface,

  /// The colour scheme's surface container lowest colour.
  lowest,

  /// The colour scheme's surface container high colour.
  high,
}

/// What a gesture on the drag handle does.
enum HandleAction {
  /// Nothing.
  nothing,

  /// Hides a pane, or shows both again ([PaneResizer.toggle]).
  toggle,

  /// Splits the panes evenly ([PaneResizer.splitEvenly]).
  splitEvenly,

  /// Returns to the default split ([PaneResizer.restore]).
  restore;

  /// What the drag handle calls for this action, or null for nothing.
  PaneHandleCallback? get callback => switch (this) {
    nothing => null,
    toggle => PaneResizer.toggle,
    splitEvenly => PaneResizer.splitEvenly,
    restore => PaneResizer.restore,
  };
}

/// How the layout screen arranges its two panes side by side.
enum LayoutArrangement {
  /// A fixed first pane beside a flexible second one.
  fixedFirst,

  /// A flexible first pane beside a fixed second one.
  fixedSecond,

  /// Two flexible panes, split evenly.
  splitPane,
}

/// The colours of the drag handle.
enum HandleColor {
  /// The colour scheme's outline, and its on-surface colour while pressed:
  /// the package's default.
  outline,

  /// The colour scheme's primary colour.
  primary,

  /// The colour scheme's tertiary colour.
  tertiary,
}

/// What the related articles are, beside an article.
enum RelatedPlacement {
  /// A standard side sheet, which keeps to the trailing side.
  sheet,

  /// A pane on the trailing side.
  trailingPane,

  /// A pane on the leading side.
  leadingPane,
}

/// What the navigation scaffold places navigation for.
enum NavigationPanes {
  /// The panes the layouts in the body show.
  layouts,

  /// One pane, whatever the layouts show.
  one,

  /// Two panes, whatever the layouts show.
  two,
}

/// Where the navigation scaffold shows the bar and the rail.
enum NavigationRule {
  /// Material's placement ([NavigationPlacementRule.material]).
  material,

  /// The bar alone.
  barOnly,

  /// The rail alone.
  railOnly,

  /// The bar below a breakpoint, and the rail from it upwards.
  railFrom,

  /// The rail below a breakpoint, and the bar from it upwards.
  barFrom,
}

/// When the navigation rail is expanded.
enum RailExpansion {
  /// Expanded from large windows up, and collapsed below: the demo's own.
  byWindow,

  /// Always expanded.
  expanded,

  /// Always collapsed.
  collapsed,
}

/// How the rail's menu button opens the rail.
enum RailMenu {
  /// In place from large windows up, and below them as a modal over the
  /// content, so that the panes do not reflow: the demo's own.
  byWindow,

  /// As a modal over the content, which choosing a destination closes.
  modal,

  /// In place, beside the content.
  inPlace,
}

/// How the navigation bar lays its items out.
enum BarLayout {
  /// Labels beside the icons from medium windows up, and below them in
  /// compact ones: the demo's own.
  byWindow,

  /// Labels below the icons.
  vertical,

  /// Labels beside the icons.
  horizontal,
}

/// A numeric token of a navigation component's style that the settings can
/// set, with the range of its slider, which goes well past Material's values
/// to show what the component does with them.
abstract interface class StyleToken {
  /// The style property, as it is named in code.
  String get title;

  /// What the token sets.
  String get hint;

  /// The group the settings list the token in.
  String get group;

  /// How the settings describe the token left to its default.
  String get byDefault;

  double get min;
  double get max;

  /// The step of the token's slider.
  double get step;
}

/// A numeric token of the navigation rail's style that the settings can set.
enum RailToken implements StyleToken {
  minWidth(
    'The collapsed width. At 0 the collapsed rail takes no room.',
    'Width',
    0,
    200,
  ),
  expandedWidth(
    'A fixed expanded width, in place of fitting the widest label.',
    'Width',
    0,
    600,
  ),
  minExpandedWidth(
    'The least the expanded width comes to when fitting the labels.',
    'Width',
    0,
    600,
  ),
  maxExpandedWidth(
    'The most the expanded width comes to when fitting the labels.',
    'Width',
    0,
    600,
  ),
  iconSize('The icon size.', 'Indicator', 0, 64),
  verticalIndicatorWidth(
    'The collapsed indicator width. The icon is centred in it.',
    'Indicator',
    0,
    160,
  ),
  verticalIndicatorHeight(
    'The collapsed indicator height.',
    'Indicator',
    0,
    96,
  ),
  noLabelIndicatorSize(
    'The width and height of the collapsed indicator where the labels are '
        'hidden.',
    'Indicator',
    0,
    96,
  ),
  horizontalIndicatorHeight(
    'The expanded indicator height, grown around a taller label.',
    'Indicator',
    0,
    120,
  ),
  horizontalLeadingSpace(
    'The space before the icon inside the expanded indicator.',
    'Label',
    0,
    64,
  ),
  horizontalTrailingSpace(
    'The space after the label beside the icon, inside the indicator.',
    'Label',
    0,
    64,
  ),
  horizontalIconLabelSpacing(
    'The gap between the icon and the label beside it.',
    'Label',
    0,
    48,
  ),
  labelPaddingHorizontal(
    'Padding each side of the label below the icon.',
    'Label',
    0,
    32,
  ),
  labelPaddingTop(
    'The gap between the indicator and the label below it.',
    'Label',
    0,
    32,
  ),
  labelPaddingBottom('Padding below the label below the icon.', 'Label', 0, 32),
  maxLabelScale(
    'The largest text scale of the labels. Tooltips keep the full scale.',
    'Label',
    0.5,
    3.2,
    step: 0.05,
  ),
  itemSpace(
    'The space between collapsed items, closing as the rail expands.',
    'Items',
    0,
    48,
  ),
  collapsedItemMinHeight(
    'The least a collapsed item is tall.',
    'Items',
    0,
    160,
  ),
  expandedItemMinHeight('The least an expanded item is tall.', 'Items', 0, 160),
  itemHorizontalPadding(
    'The inset of the expanded indicator from the edges of the rail.',
    'Items',
    0,
    64,
  ),
  groupAlignment(
    'Where the destinations sit, from -1 (top) to 1 (bottom).',
    'Items',
    -1,
    1,
    step: 0.05,
  ),
  topSpace('The space above the menu.', 'Header', 0, 160),
  headerItemSpacing(
    'The space between the menu and the floating action button.',
    'Header',
    0,
    64,
  ),
  headerSpace(
    'The space between the header and the destinations.',
    'Header',
    0,
    160,
  ),
  modalShapeRadius(
    "The radius of the modal surface's corners.",
    'Modal',
    0,
    64,
  );

  const new(this.hint, this.group, this.min, this.max, {this.step = 1});

  @override
  final String hint;
  @override
  final String group;
  @override
  final double min;
  @override
  final double max;
  @override
  final double step;

  @override
  String get title => switch (this) {
    labelPaddingHorizontal => 'labelPadding (horizontal)',
    labelPaddingTop => 'labelPadding (top)',
    labelPaddingBottom => 'labelPadding (bottom)',
    modalShapeRadius => 'modalShape (radius)',
    _ => name,
  };

  @override
  String get byDefault => switch (this) {
    expandedWidth => 'fits the labels',
    maxLabelScale => 'no cap',
    _ => 'default',
  };

  /// The token's value in [style], or null where the rail works it out.
  double? read(NavigationRailStyle style) => switch (this) {
    minWidth => style.minWidth,
    expandedWidth => style.expandedWidth,
    minExpandedWidth => style.minExpandedWidth,
    maxExpandedWidth => style.maxExpandedWidth,
    iconSize => style.iconSize,
    verticalIndicatorWidth => style.verticalIndicatorWidth,
    verticalIndicatorHeight => style.verticalIndicatorHeight,
    noLabelIndicatorSize => style.noLabelIndicatorSize,
    horizontalIndicatorHeight => style.horizontalIndicatorHeight,
    horizontalLeadingSpace => style.horizontalLeadingSpace,
    horizontalTrailingSpace => style.horizontalTrailingSpace,
    horizontalIconLabelSpacing => style.horizontalIconLabelSpacing,
    labelPaddingHorizontal => _side(style.labelPadding, _Side.horizontal),
    labelPaddingTop => _side(style.labelPadding, _Side.top),
    labelPaddingBottom => _side(style.labelPadding, _Side.bottom),
    maxLabelScale => style.maxLabelScale,
    itemSpace => style.itemSpace,
    collapsedItemMinHeight => style.collapsedItemMinHeight,
    expandedItemMinHeight => style.expandedItemMinHeight,
    itemHorizontalPadding => style.itemHorizontalPadding,
    groupAlignment => style.groupAlignment,
    topSpace => style.topSpace,
    headerItemSpacing => style.headerItemSpacing,
    headerSpace => style.headerSpace,
    modalShapeRadius => switch (style.modalShape) {
      RoundedRectangleBorder(borderRadius: final BorderRadius radius) =>
        radius.topLeft.x,
      _ => null,
    },
  };
}

/// A numeric token of the navigation bar's style that the settings can set.
enum BarToken implements StyleToken {
  height(
    'The least the bar is tall. It grows when its content needs more.',
    'Size',
    0,
    160,
  ),
  iconSize('The icon size.', 'Size', 0, 64),
  verticalItemPadding(
    'The space above the indicator and below the label, with labels below '
        'the icons.',
    'Size',
    0,
    32,
  ),
  verticalIndicatorWidth(
    'The indicator width with labels below the icons, narrowed by a '
        'narrower item. The icon is centred in it.',
    'Indicator',
    0,
    160,
  ),
  verticalIndicatorHeight(
    'The indicator height with labels below the icons.',
    'Indicator',
    0,
    96,
  ),
  horizontalIndicatorHeight(
    'The indicator height with labels beside the icons, grown around a '
        'taller label.',
    'Indicator',
    0,
    120,
  ),
  maxLabelScale(
    'The largest text scale of the labels. Tooltips keep the full scale.',
    'Label',
    0.5,
    3.2,
    step: 0.05,
  ),
  horizontalLeadingSpace(
    'The space before the icon inside the indicator, with labels beside '
        'the icons.',
    'Label',
    0,
    64,
  ),
  horizontalTrailingSpace(
    'The space after the label beside the icon, inside the indicator.',
    'Label',
    0,
    64,
  ),
  horizontalIconLabelSpacing(
    'The gap between the icon and the label beside it.',
    'Label',
    0,
    48,
  ),
  labelPaddingHorizontal(
    'Padding each side of the label below the icon.',
    'Label',
    0,
    32,
  ),
  labelPaddingTop(
    'The gap between the indicator and the label below it.',
    'Label',
    0,
    32,
  ),
  labelPaddingBottom('Padding below the label below the icon.', 'Label', 0, 32);

  const new(this.hint, this.group, this.min, this.max, {this.step = 1});

  @override
  final String hint;
  @override
  final String group;
  @override
  final double min;
  @override
  final double max;
  @override
  final double step;

  @override
  String get title => switch (this) {
    labelPaddingHorizontal => 'labelPadding (horizontal)',
    labelPaddingTop => 'labelPadding (top)',
    labelPaddingBottom => 'labelPadding (bottom)',
    _ => name,
  };

  @override
  String get byDefault => this == maxLabelScale ? 'no cap' : 'default';

  /// The token's value in [style], or null where it has none.
  double? read(NavigationBarStyle style) => switch (this) {
    height => style.height,
    iconSize => style.iconSize,
    verticalItemPadding => style.verticalItemPadding,
    verticalIndicatorWidth => style.verticalIndicatorWidth,
    verticalIndicatorHeight => style.verticalIndicatorHeight,
    horizontalIndicatorHeight => style.horizontalIndicatorHeight,
    maxLabelScale => style.maxLabelScale,
    horizontalLeadingSpace => style.horizontalLeadingSpace,
    horizontalTrailingSpace => style.horizontalTrailingSpace,
    horizontalIconLabelSpacing => style.horizontalIconLabelSpacing,
    labelPaddingHorizontal => _side(style.labelPadding, _Side.horizontal),
    labelPaddingTop => _side(style.labelPadding, _Side.top),
    labelPaddingBottom => _side(style.labelPadding, _Side.bottom),
  };
}

// The sides of a label's padding that the settings set: both horizontal
// sides alike, the top and the bottom.
enum _Side { horizontal, top, bottom }

// A side of [padding].
double _side(EdgeInsetsGeometry? padding, _Side side) {
  final insets = (padding ?? EdgeInsets.zero).resolve(TextDirection.ltr);
  return switch (side) {
    _Side.horizontal => insets.horizontal / 2,
    _Side.top => insets.top,
    _Side.bottom => insets.bottom,
  };
}

// Label padding from the sides the settings set, each one left alone keeping
// [fallback]'s; null where none is set, so that the style's own applies.
EdgeInsetsGeometry? _labelPadding(
  double? horizontal,
  double? top,
  double? bottom,
  EdgeInsetsGeometry? fallback,
) {
  if (horizontal == null && top == null && bottom == null) return null;
  final sides = horizontal ?? _side(fallback, _Side.horizontal);
  return EdgeInsets.fromLTRB(
    sides,
    top ?? _side(fallback, _Side.top),
    sides,
    bottom ?? _side(fallback, _Side.bottom),
  );
}

/// The demo's settings, changed from the settings sheet.
///
/// Each one sets a parameter of the package, named in its documentation,
/// or a setting of the platform or of Flutter that the package follows.
@immutable
class DemoSettings {
  const new({
    this.dark = false,
    this.rtl = false,
    this.reduceMotion = false,
    this.breakpoints = const Breakpoints(),
    this.paneStyle = PaneStyle.byWindow,
    this.cardRadius = 16,
    this.motion = MotionChoice.expressive,
    this.springDamping = 0.8,
    this.springStiffness = 380,
    this.curveDuration = const Duration(milliseconds: 400),
    this.animatePanes = true,
    this.animateNavigation = true,
    this.slowAnimations = 1,
    this.paneColor = PaneColor.surface,
    this.paneOutline = false,
    this.resizable = true,
    this.snapToStops = true,
    this.handleTap = HandleAction.restore,
    this.handleDoubleTap = HandleAction.toggle,
    this.handleLongPress = HandleAction.splitEvenly,
    this.handle = defaultHandle,
    this.handleColor = HandleColor.outline,
    this.twoPanesFrom = Breakpoint.expanded,
    this.nothingSelected = NothingSelected.placeholder,
    this.inboxRemembersResize = true,
    this.listCollapse,
    this.messageCollapse,
    this.related = RelatedPlacement.sheet,
    this.relatedDismissible = true,
    this.articlesResizable = true,
    this.articlesRememberResize = false,
    this.feedMinItemWidth = 280,
    this.feedGap = 16,
    this.feedLeadSpansTwo = true,
    this.layoutArrangement = LayoutArrangement.fixedFirst,
    this.layoutPaneWidth,
    this.layoutTwoPanesFrom = Breakpoint.expanded,
    this.layoutReflow = PaneReflow.stack,
    this.layoutFirstCollapse,
    this.layoutSecondCollapse,
    this.layoutSecondClosable = false,
    this.navigationPanes = NavigationPanes.layouts,
    this.navigationRule = NavigationRule.material,
    this.navigationRuleFrom = Breakpoint.expanded,
    this.sideSheetWidth = SideSheet.maxWidth,
    this.tintedSheets = false,
    this.scrimDismisses = true,
    this.scrimOpacity = 0.54,
    this.lineLength = 60,
    this.textScale,
    this.navigationLongLabels = false,
    this.navigationTooltips = false,
    this.navigationSecondDisabled = false,
    this.railCount = 4,
    this.railMenu = RailMenu.byWindow,
    this.railExpansion = RailExpansion.byWindow,
    this.railLabelType = NavigationRailLabelType.all,
    this.railIndicatorSize,
    this.railFab = true,
    this.railTrailing = false,
    this.railExpandedBody = false,
    this.railScrollable = true,
    this.railBottomInset = true,
    this.railLabelMaxLines,
    this.railLabelOverflow,
    this.railTokens = const {},
    this.barCount = 4,
    this.barWidthFactor = 1,
    this.barLayout = BarLayout.byWindow,
    this.barLabelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
    this.barLabelMaxLines,
    this.barLabelOverflow,
    this.barTokens = const {},
  });

  /// Whether the dark colour scheme is used.
  final bool dark;

  /// Whether the app is laid out right to left.
  final bool rtl;

  /// Whether the app asks for reduced motion, as the platform's setting
  /// does ([MediaQueryData.disableAnimations]).
  final bool reduceMotion;

  /// [MaterialLayoutThemeData.breakpoints].
  final Breakpoints breakpoints;

  /// How the panes are painted, which sets
  /// [MaterialLayoutThemeData.marginPlacement].
  final PaneStyle paneStyle;

  /// The corner radius of the cards, for
  /// [MaterialLayoutThemeData.paneBorderRadius].
  final double cardRadius;

  /// The colour of [PaneSurfaceStyle.color].
  final PaneColor paneColor;

  /// Whether panes have an outline ([PaneSurfaceStyle.outline]).
  final bool paneOutline;

  /// [MaterialLayoutThemeData.motionScheme].
  final MotionChoice motion;

  /// The damping ratio of [MotionChoice.spring].
  final double springDamping;

  /// The stiffness of [MotionChoice.spring].
  final double springStiffness;

  /// The duration of [MotionChoice.curve].
  final Duration curveDuration;

  /// Whether the layouts and sheets animate their panes, or are given
  /// [PaneMotion.none].
  final bool animatePanes;

  /// Whether the navigation scaffold animates navigation, or is given
  /// [PaneMotion.none].
  final bool animateNavigation;

  /// How many times slower every animation of the app runs, as with
  /// Flutter's slow animations (`timeDilation`): 1 for normal speed.
  final double slowAnimations;

  /// The layouts' `resizable`.
  final bool resizable;

  /// Whether a resize snaps to Material's stops, or rests anywhere
  /// ([PaneResizer.snapStops]).
  final bool snapToStops;

  /// What a tap on the drag handle does ([PaneResizer.onTap]).
  final HandleAction handleTap;

  /// What a double tap on the drag handle does ([PaneResizer.onDoubleTap]).
  final HandleAction handleDoubleTap;

  /// What a long press on the drag handle does ([PaneResizer.onLongPress]).
  final HandleAction handleLongPress;

  /// The sizes of [MaterialLayoutThemeData.dragHandleStyle].
  final DragHandleStyle handle;

  /// Material's drag handle sizes, which the settings start from.
  static const defaultHandle = DragHandleStyle(
    thickness: 4,
    length: 48,
    pressedThickness: 12,
    pressedLength: 52,
  );

  /// The colours of [MaterialLayoutThemeData.dragHandleStyle].
  final HandleColor handleColor;

  /// The inbox's [ListDetailLayout.twoPaneBreakpoint].
  final Breakpoint twoPanesFrom;

  /// The inbox's [ListDetailLayout.emptyBehavior].
  final NothingSelected nothingSelected;

  /// Whether the inbox remembers a resize ([ListDetailLayout.resizeMemory]).
  final bool inboxRemembersResize;

  /// The inbox's [ListDetailLayout.listCollapse], or null for Material's.
  final PaneCollapse? listCollapse;

  /// The inbox's [ListDetailLayout.detailCollapse], or null for Material's.
  ///
  /// The handle dismisses a message only where the list then shows alone,
  /// with [NothingSelected.listOnly].
  final PaneCollapse? messageCollapse;

  /// The articles' [SupportingPaneLayout.supporting] and
  /// [SupportingPaneLayout.supportingSide].
  final RelatedPlacement related;

  /// Whether the related articles are a temporary pane, which the user can
  /// close ([SupportingPaneLayout.onSupportingDismissed]), or a permanent
  /// one, which always shows.
  final bool relatedDismissible;

  /// Whether a drag handle resizes the related articles, and closes them
  /// where they can be closed ([SupportingPaneLayout.resizable]), while
  /// [resizable] is on.
  final bool articlesResizable;

  /// Whether the articles remember a resize
  /// ([SupportingPaneLayout.resizeMemory]).
  final bool articlesRememberResize;

  /// The feed's [FeedLayout.minItemWidth].
  final double feedMinItemWidth;

  /// The feed's [FeedLayout.gap].
  final double feedGap;

  /// Whether the feed's first card spans two columns
  /// ([FeedLayout.spanBuilder]).
  final bool feedLeadSpansTwo;

  /// How the layout screen arranges its panes
  /// ([TwoPaneLayout.arrangement]).
  final LayoutArrangement layoutArrangement;

  /// The width of the layout screen's fixed pane, or null for Material's
  /// ([PaneArrangement.width]).
  final double? layoutPaneWidth;

  /// The layout screen's [TwoPaneLayout.twoPaneBreakpoint].
  final Breakpoint layoutTwoPanesFrom;

  /// The layout screen's [TwoPaneLayout.reflow].
  final PaneReflow layoutReflow;

  /// The layout screen's [TwoPaneLayout.firstCollapse], or null for
  /// Material's.
  final PaneCollapse? layoutFirstCollapse;

  /// The layout screen's [TwoPaneLayout.secondCollapse], or null for
  /// Material's.
  final PaneCollapse? layoutSecondCollapse;

  /// Whether the layout screen's second pane can be closed
  /// ([TwoPaneLayout.onSecondDismissed]).
  final bool layoutSecondClosable;

  /// The navigation scaffold's [NavigationScaffold.paneCount].
  final NavigationPanes navigationPanes;

  /// Where the navigation scaffold shows the bar and the rail
  /// ([NavigationScaffold.placementRule]).
  final NavigationRule navigationRule;

  /// The breakpoint [NavigationRule.railFrom] and [NavigationRule.barFrom]
  /// swap the bar and the rail at.
  final Breakpoint navigationRuleFrom;

  /// The [SideSheet.width] of the demo's side sheets.
  final double sideSheetWidth;

  /// Whether side sheets are tinted ([SideSheetStyle.backgroundColor] and
  /// [SideSheetStyle.modalBackgroundColor]).
  final bool tintedSheets;

  /// Whether a tap on the scrim closes a modal sheet
  /// (`barrierDismissible`, `isDismissible`).
  final bool scrimDismisses;

  /// The opacity of a modal side sheet's scrim
  /// ([SideSheetStyle.modalBarrierColor]).
  final double scrimOpacity;

  /// [LineLength.characters].
  final int lineLength;

  /// The text scale of the screens behind the settings, or null for the
  /// platform's.
  final double? textScale;

  /// Whether the destinations have long labels, to try labels that do not
  /// fit ([NavigationDestination.label]).
  final bool navigationLongLabels;

  /// Whether each destination has a tooltip of its own rather than its label
  /// ([NavigationDestination.tooltip]).
  final bool navigationTooltips;

  /// Whether the second destination is disabled
  /// ([NavigationDestination.enabled]).
  final bool navigationSecondDisabled;

  /// How many destinations the rail shows ([NavigationRail.destinations]).
  final int railCount;

  /// How the rail's menu button opens it.
  final RailMenu railMenu;

  /// When the rail is expanded ([NavigationRail.expanded]).
  final RailExpansion railExpansion;

  /// Which labels the collapsed rail shows ([NavigationRail.labelType]).
  final NavigationRailLabelType railLabelType;

  /// [NavigationRailStyle.expandedIndicatorSize], or null for the default.
  final NavigationIndicatorSize? railIndicatorSize;

  /// Whether the rail has a floating action button
  /// ([NavigationRail.floatingActionButton]).
  final bool railFab;

  /// Whether the rail has a theme switch below its destinations
  /// ([NavigationRail.trailing]).
  final bool railTrailing;

  /// Whether the expanded rail shows mailboxes and labels below its
  /// destinations ([NavigationRail.expandedBody]).
  final bool railExpandedBody;

  /// [NavigationRailStyle.scrollable].
  final bool railScrollable;

  /// [NavigationRailStyle.applyBottomInset].
  final bool railBottomInset;

  /// [NavigationRailStyle.labelMaxLines], or null for no limit.
  final int? railLabelMaxLines;

  /// [NavigationRailStyle.labelOverflow], or null for the default.
  final TextOverflow? railLabelOverflow;

  /// The tokens of the rail's style that the settings set.
  final Map<RailToken, double> railTokens;

  /// How many destinations the bar shows ([NavigationBar.destinations]).
  final int barCount;

  /// The share of the window's width the bar takes.
  final double barWidthFactor;

  /// How the bar lays its items out ([NavigationBar.itemLayout]).
  final BarLayout barLayout;

  /// [NavigationBar.labelBehavior].
  final NavigationDestinationLabelBehavior barLabelBehavior;

  /// [NavigationBarStyle.labelMaxLines], or null for no limit.
  final int? barLabelMaxLines;

  /// [NavigationBarStyle.labelOverflow], or null for the default.
  final TextOverflow? barLabelOverflow;

  /// The tokens of the bar's style that the settings set.
  final Map<BarToken, double> barTokens;

  /// The motion scheme of [motion].
  MotionScheme get motionScheme => switch (motion) {
    MotionChoice.expressive => const MotionScheme.expressive(),
    MotionChoice.standard => const MotionScheme.standard(),
    MotionChoice.spring => const MotionScheme.expressive().copyWith(
      defaultSpatial: Motion.spring(
        dampingRatio: springDamping,
        stiffness: springStiffness,
      ),
    ),
    MotionChoice.curve => const MotionScheme.expressive().copyWith(
      defaultSpatial: Motion.curved(
        duration: curveDuration,
        curve: Easing.standard,
      ),
    ),
  };

  /// The motion of the layouts' and sheets' panes: the scheme's, or none.
  PaneMotion? get paneMotion => animatePanes ? null : const PaneMotion.none();

  /// The motion of navigation: the scheme's, or none.
  PaneMotion? get navigationMotion =>
      animateNavigation ? null : const PaneMotion.none();

  /// The drag handle the layouts show while their panes are resizable.
  Widget get dragHandle => PaneResizer(
    snapStops: snapToStops ? null : const [],
    onTap: handleTap.callback,
    onDoubleTap: handleDoubleTap.callback,
    onLongPress: handleLongPress.callback,
  );

  /// The panes' surface style, in the colours of [colors].
  PaneSurfaceStyle paneSurfaceStyleIn(ColorScheme colors) => PaneSurfaceStyle(
    color: switch (paneColor) {
      PaneColor.surface => null,
      PaneColor.lowest => colors.surfaceContainerLowest,
      PaneColor.high => colors.surfaceContainerHigh,
    },
    outline: paneOutline ? BorderSide(color: colors.outlineVariant) : null,
  );

  /// The side sheets' style, in the colours of [colors].
  SideSheetStyle sideSheetStyleIn(ColorScheme colors) => SideSheetStyle(
    backgroundColor: tintedSheets ? colors.surfaceContainerHigh : null,
    modalBackgroundColor: tintedSheets ? colors.surfaceContainerHighest : null,
    modalBarrierColor: Colors.black.withValues(alpha: scrimOpacity),
  );

  /// The layout screen's arrangement.
  PaneArrangement get twoPaneArrangement => switch (layoutArrangement) {
    LayoutArrangement.fixedFirst => PaneArrangement.fixedAndFlexible(
      width: layoutPaneWidth,
    ),
    LayoutArrangement.fixedSecond => PaneArrangement.fixedAndFlexible(
      fixed: PaneSlot.second,
      width: layoutPaneWidth,
    ),
    LayoutArrangement.splitPane => const PaneArrangement.splitPane(),
  };

  /// The drag handle's style, in the colours of [colors].
  DragHandleStyle handleStyleIn(ColorScheme colors) => switch (handleColor) {
    HandleColor.outline => handle,
    HandleColor.primary => handle.copyWith(
      color: colors.primary,
      pressedColor: colors.onPrimaryContainer,
    ),
    HandleColor.tertiary => handle.copyWith(
      color: colors.tertiary,
      pressedColor: colors.onTertiaryContainer,
    ),
  };

  /// The inbox's resize memory.
  PaneResizeMemory get inboxResizeMemory => inboxRemembersResize
      ? PaneResizeMemory.persistent
      : PaneResizeMemory.temporary;

  /// The articles' resize memory.
  PaneResizeMemory get articlesResizeMemory => articlesRememberResize
      ? PaneResizeMemory.persistent
      : PaneResizeMemory.temporary;

  /// The navigation scaffold's pane count, or null to learn it from the
  /// layouts.
  int? get paneCount => switch (navigationPanes) {
    NavigationPanes.layouts => null,
    NavigationPanes.one => 1,
    NavigationPanes.two => 2,
  };

  /// The navigation scaffold's placement rule.
  NavigationPlacementRule get placementRule {
    final from = navigationRuleFrom;
    return switch (navigationRule) {
      NavigationRule.material => NavigationPlacementRule.material,
      NavigationRule.barOnly => const NavigationPlacementRule.only(
        NavigationPlacement.bar,
      ),
      NavigationRule.railOnly => const NavigationPlacementRule.only(
        NavigationPlacement.rail,
      ),
      NavigationRule.railFrom => NavigationPlacementRule.from(
        (breakpoint, paneCount) => breakpoint >= from
            ? NavigationPlacement.rail
            : NavigationPlacement.bar,
      ),
      NavigationRule.barFrom => NavigationPlacementRule.from(
        (breakpoint, paneCount) => breakpoint >= from
            ? NavigationPlacement.bar
            : NavigationPlacement.rail,
      ),
    };
  }

  /// The feed's spans.
  FeedSpanBuilder? get feedSpans => feedLeadSpansTwo ? _leadSpansTwo : null;

  static int _leadSpansTwo(int index, int columnCount) => index == 0 ? 2 : 1;

  /// The rail's defaults: Material 3 Expressive's, under the app's theme.
  NavigationRailStyle railDefaultsIn(BuildContext context) =>
      NavigationRailStyle.of(context);

  /// The rail's style: its defaults, with the tokens the settings set.
  NavigationRailStyle railStyleIn(BuildContext context) {
    final defaults = railDefaultsIn(context);
    final modalRadius = railTokens[RailToken.modalShapeRadius];
    return NavigationRailStyle(
      minWidth: railTokens[RailToken.minWidth],
      expandedWidth: railTokens[RailToken.expandedWidth],
      minExpandedWidth: railTokens[RailToken.minExpandedWidth],
      maxExpandedWidth: railTokens[RailToken.maxExpandedWidth],
      iconSize: railTokens[RailToken.iconSize],
      verticalIndicatorWidth: railTokens[RailToken.verticalIndicatorWidth],
      verticalIndicatorHeight: railTokens[RailToken.verticalIndicatorHeight],
      noLabelIndicatorSize: railTokens[RailToken.noLabelIndicatorSize],
      horizontalIndicatorHeight:
          railTokens[RailToken.horizontalIndicatorHeight],
      horizontalLeadingSpace: railTokens[RailToken.horizontalLeadingSpace],
      horizontalTrailingSpace: railTokens[RailToken.horizontalTrailingSpace],
      horizontalIconLabelSpacing:
          railTokens[RailToken.horizontalIconLabelSpacing],
      labelPadding: _labelPadding(
        railTokens[RailToken.labelPaddingHorizontal],
        railTokens[RailToken.labelPaddingTop],
        railTokens[RailToken.labelPaddingBottom],
        defaults.labelPadding,
      ),
      maxLabelScale: railTokens[RailToken.maxLabelScale],
      itemSpace: railTokens[RailToken.itemSpace],
      collapsedItemMinHeight: railTokens[RailToken.collapsedItemMinHeight],
      expandedItemMinHeight: railTokens[RailToken.expandedItemMinHeight],
      itemHorizontalPadding: railTokens[RailToken.itemHorizontalPadding],
      groupAlignment: railTokens[RailToken.groupAlignment],
      topSpace: railTokens[RailToken.topSpace],
      headerItemSpacing: railTokens[RailToken.headerItemSpacing],
      headerSpace: railTokens[RailToken.headerSpace],
      modalShape: modalRadius == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(modalRadius),
            ),
      expandedIndicatorSize: railIndicatorSize,
      labelMaxLines: railLabelMaxLines,
      labelOverflow: railLabelOverflow,
      scrollable: railScrollable,
      applyBottomInset: railBottomInset,
    );
  }

  /// The bar's defaults: Material 3 Expressive's, under the app's theme.
  NavigationBarStyle barDefaultsIn(BuildContext context) =>
      NavigationBarStyle.of(context);

  /// The bar's style: its defaults, with the tokens the settings set.
  NavigationBarStyle barStyleIn(BuildContext context) {
    final defaults = barDefaultsIn(context);
    return NavigationBarStyle(
      height: barTokens[BarToken.height],
      iconSize: barTokens[BarToken.iconSize],
      verticalItemPadding: barTokens[BarToken.verticalItemPadding],
      verticalIndicatorWidth: barTokens[BarToken.verticalIndicatorWidth],
      verticalIndicatorHeight: barTokens[BarToken.verticalIndicatorHeight],
      horizontalIndicatorHeight: barTokens[BarToken.horizontalIndicatorHeight],
      maxLabelScale: barTokens[BarToken.maxLabelScale],
      horizontalLeadingSpace: barTokens[BarToken.horizontalLeadingSpace],
      horizontalTrailingSpace: barTokens[BarToken.horizontalTrailingSpace],
      horizontalIconLabelSpacing:
          barTokens[BarToken.horizontalIconLabelSpacing],
      labelPadding: _labelPadding(
        barTokens[BarToken.labelPaddingHorizontal],
        barTokens[BarToken.labelPaddingTop],
        barTokens[BarToken.labelPaddingBottom],
        defaults.labelPadding,
      ),
      labelMaxLines: barLabelMaxLines,
      labelOverflow: barLabelOverflow,
    );
  }

  // Stands for a nullable setting that copyWith leaves as it is.
  static const Object _unchanged = Object();

  // The handle dismisses a message only where the list then shows alone;
  // elsewhere, it does what it does by default.
  static PaneCollapse? _dismissibleMessage(
    PaneCollapse? collapse,
    NothingSelected nothingSelected,
  ) =>
      collapse == PaneCollapse.dismiss &&
          nothingSelected != NothingSelected.listOnly
      ? null
      : collapse;

  DemoSettings copyWith({
    bool? dark,
    bool? rtl,
    bool? reduceMotion,
    Breakpoints? breakpoints,
    PaneStyle? paneStyle,
    double? cardRadius,
    MotionChoice? motion,
    double? springDamping,
    double? springStiffness,
    Duration? curveDuration,
    bool? animatePanes,
    bool? animateNavigation,
    double? slowAnimations,
    PaneColor? paneColor,
    bool? paneOutline,
    bool? resizable,
    bool? snapToStops,
    HandleAction? handleTap,
    HandleAction? handleDoubleTap,
    HandleAction? handleLongPress,
    DragHandleStyle? handle,
    HandleColor? handleColor,
    Breakpoint? twoPanesFrom,
    NothingSelected? nothingSelected,
    bool? inboxRemembersResize,
    Object? listCollapse = _unchanged,
    Object? messageCollapse = _unchanged,
    RelatedPlacement? related,
    bool? relatedDismissible,
    bool? articlesResizable,
    bool? articlesRememberResize,
    double? feedMinItemWidth,
    double? feedGap,
    bool? feedLeadSpansTwo,
    LayoutArrangement? layoutArrangement,
    Object? layoutPaneWidth = _unchanged,
    Breakpoint? layoutTwoPanesFrom,
    PaneReflow? layoutReflow,
    Object? layoutFirstCollapse = _unchanged,
    Object? layoutSecondCollapse = _unchanged,
    bool? layoutSecondClosable,
    NavigationPanes? navigationPanes,
    NavigationRule? navigationRule,
    Breakpoint? navigationRuleFrom,
    double? sideSheetWidth,
    bool? tintedSheets,
    bool? scrimDismisses,
    double? scrimOpacity,
    int? lineLength,
    Object? textScale = _unchanged,
    bool? navigationLongLabels,
    bool? navigationTooltips,
    bool? navigationSecondDisabled,
    int? railCount,
    RailMenu? railMenu,
    RailExpansion? railExpansion,
    NavigationRailLabelType? railLabelType,
    Object? railIndicatorSize = _unchanged,
    bool? railFab,
    bool? railTrailing,
    bool? railExpandedBody,
    bool? railScrollable,
    bool? railBottomInset,
    Object? railLabelMaxLines = _unchanged,
    Object? railLabelOverflow = _unchanged,
    Map<RailToken, double>? railTokens,
    int? barCount,
    double? barWidthFactor,
    BarLayout? barLayout,
    NavigationDestinationLabelBehavior? barLabelBehavior,
    Object? barLabelMaxLines = _unchanged,
    Object? barLabelOverflow = _unchanged,
    Map<BarToken, double>? barTokens,
  }) => DemoSettings(
    dark: dark ?? this.dark,
    rtl: rtl ?? this.rtl,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    breakpoints: breakpoints ?? this.breakpoints,
    paneStyle: paneStyle ?? this.paneStyle,
    cardRadius: cardRadius ?? this.cardRadius,
    motion: motion ?? this.motion,
    springDamping: springDamping ?? this.springDamping,
    springStiffness: springStiffness ?? this.springStiffness,
    curveDuration: curveDuration ?? this.curveDuration,
    animatePanes: animatePanes ?? this.animatePanes,
    animateNavigation: animateNavigation ?? this.animateNavigation,
    slowAnimations: slowAnimations ?? this.slowAnimations,
    paneColor: paneColor ?? this.paneColor,
    paneOutline: paneOutline ?? this.paneOutline,
    resizable: resizable ?? this.resizable,
    snapToStops: snapToStops ?? this.snapToStops,
    handleTap: handleTap ?? this.handleTap,
    handleDoubleTap: handleDoubleTap ?? this.handleDoubleTap,
    handleLongPress: handleLongPress ?? this.handleLongPress,
    handle: handle ?? this.handle,
    handleColor: handleColor ?? this.handleColor,
    twoPanesFrom: twoPanesFrom ?? this.twoPanesFrom,
    nothingSelected: nothingSelected ?? this.nothingSelected,
    inboxRemembersResize: inboxRemembersResize ?? this.inboxRemembersResize,
    listCollapse: identical(listCollapse, _unchanged)
        ? this.listCollapse
        : listCollapse as PaneCollapse?,
    messageCollapse: _dismissibleMessage(
      identical(messageCollapse, _unchanged)
          ? this.messageCollapse
          : messageCollapse as PaneCollapse?,
      nothingSelected ?? this.nothingSelected,
    ),
    related: related ?? this.related,
    relatedDismissible: relatedDismissible ?? this.relatedDismissible,
    articlesResizable: articlesResizable ?? this.articlesResizable,
    articlesRememberResize:
        articlesRememberResize ?? this.articlesRememberResize,
    feedMinItemWidth: feedMinItemWidth ?? this.feedMinItemWidth,
    feedGap: feedGap ?? this.feedGap,
    feedLeadSpansTwo: feedLeadSpansTwo ?? this.feedLeadSpansTwo,
    layoutArrangement: layoutArrangement ?? this.layoutArrangement,
    layoutPaneWidth: identical(layoutPaneWidth, _unchanged)
        ? this.layoutPaneWidth
        : (layoutPaneWidth as num?)?.toDouble(),
    layoutTwoPanesFrom: layoutTwoPanesFrom ?? this.layoutTwoPanesFrom,
    layoutReflow: layoutReflow ?? this.layoutReflow,
    layoutFirstCollapse: identical(layoutFirstCollapse, _unchanged)
        ? this.layoutFirstCollapse
        : layoutFirstCollapse as PaneCollapse?,
    layoutSecondCollapse: identical(layoutSecondCollapse, _unchanged)
        ? this.layoutSecondCollapse
        : layoutSecondCollapse as PaneCollapse?,
    layoutSecondClosable: layoutSecondClosable ?? this.layoutSecondClosable,
    navigationPanes: navigationPanes ?? this.navigationPanes,
    navigationRule: navigationRule ?? this.navigationRule,
    navigationRuleFrom: navigationRuleFrom ?? this.navigationRuleFrom,
    sideSheetWidth: sideSheetWidth ?? this.sideSheetWidth,
    tintedSheets: tintedSheets ?? this.tintedSheets,
    scrimDismisses: scrimDismisses ?? this.scrimDismisses,
    scrimOpacity: scrimOpacity ?? this.scrimOpacity,
    lineLength: lineLength ?? this.lineLength,
    textScale: identical(textScale, _unchanged)
        ? this.textScale
        : (textScale as num?)?.toDouble(),
    navigationLongLabels: navigationLongLabels ?? this.navigationLongLabels,
    navigationTooltips: navigationTooltips ?? this.navigationTooltips,
    navigationSecondDisabled:
        navigationSecondDisabled ?? this.navigationSecondDisabled,
    railCount: railCount ?? this.railCount,
    railMenu: railMenu ?? this.railMenu,
    railExpansion: railExpansion ?? this.railExpansion,
    railLabelType: railLabelType ?? this.railLabelType,
    railIndicatorSize: identical(railIndicatorSize, _unchanged)
        ? this.railIndicatorSize
        : railIndicatorSize as NavigationIndicatorSize?,
    railFab: railFab ?? this.railFab,
    railTrailing: railTrailing ?? this.railTrailing,
    railExpandedBody: railExpandedBody ?? this.railExpandedBody,
    railScrollable: railScrollable ?? this.railScrollable,
    railBottomInset: railBottomInset ?? this.railBottomInset,
    railLabelMaxLines: identical(railLabelMaxLines, _unchanged)
        ? this.railLabelMaxLines
        : railLabelMaxLines as int?,
    railLabelOverflow: identical(railLabelOverflow, _unchanged)
        ? this.railLabelOverflow
        : railLabelOverflow as TextOverflow?,
    railTokens: railTokens ?? this.railTokens,
    barCount: barCount ?? this.barCount,
    barWidthFactor: barWidthFactor ?? this.barWidthFactor,
    barLayout: barLayout ?? this.barLayout,
    barLabelBehavior: barLabelBehavior ?? this.barLabelBehavior,
    barLabelMaxLines: identical(barLabelMaxLines, _unchanged)
        ? this.barLabelMaxLines
        : barLabelMaxLines as int?,
    barLabelOverflow: identical(barLabelOverflow, _unchanged)
        ? this.barLabelOverflow
        : barLabelOverflow as TextOverflow?,
    barTokens: barTokens ?? this.barTokens,
  );
}

/// Publishes the settings to the whole app, routes included.
class Settings extends InheritedNotifier<ValueNotifier<DemoSettings>> {
  const new({super.key, required super.notifier, required super.child});

  static ValueNotifier<DemoSettings> controllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Settings>()!.notifier!;

  static DemoSettings of(BuildContext context) => controllerOf(context).value;
}

/// The sections of the demo settings.
enum SettingsSection {
  app('App', Icons.settings_outlined),
  breakpoints('Breakpoints', Icons.aspect_ratio_outlined),
  panes('Panes', Icons.vertical_split_outlined),
  motion('Motion', Icons.animation),
  resizing('Resizing', Icons.drag_indicator),
  inbox('Inbox', Icons.inbox_outlined),
  articles('Articles', Icons.article_outlined),
  feed('Feed', Icons.dashboard_outlined),
  layoutScreen('Layout screen', Icons.view_quilt_outlined),
  navigation('Navigation', Icons.navigation_outlined),
  navigationRail('Navigation rail', Icons.menu_open),
  railStyle('Rail style', Icons.design_services_outlined),
  navigationBar('Navigation bar', Icons.call_to_action_outlined),
  barStyle('Bar style', Icons.format_shapes_outlined),
  sheets('Sheets', Icons.view_sidebar_outlined),
  text('Text', Icons.text_fields);

  const new(this.title, this.icon);

  final String title;
  final IconData icon;
}

/// How the settings sheet was when it last closed, so that it opens as it
/// was left: the same sections open, scrolled as far, and as a bottom sheet,
/// as tall.
class SettingsSheetMemory {
  /// The sections that are open.
  final openSections = <SettingsSection>{};

  /// How far the settings are scrolled.
  double scrollOffset = 0;

  /// How much of the window's height the bottom sheet takes.
  double bottomSheetSize = 0.6;

  /// The memory published above [context].
  static SettingsSheetMemory of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsSheetMemoryScope>()!.memory;
}

/// Publishes the memory of the settings sheet to the whole app, routes
/// included.
class SettingsSheetMemoryScope extends InheritedWidget {
  const new({super.key, required this.memory, required super.child});

  final SettingsSheetMemory memory;

  @override
  bool updateShouldNotify(SettingsSheetMemoryScope oldWidget) =>
      memory != oldWidget.memory;
}

/// Publishes the split of the inbox's panes, which the settings set and a
/// drag of the handle changes ([ListDetailLayout.splitController]).
class InboxSplit extends InheritedWidget {
  const new({super.key, required this.controller, required super.child});

  final PaneSplitController controller;

  static PaneSplitController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InboxSplit>()!.controller;

  @override
  bool updateShouldNotify(InboxSplit oldWidget) =>
      controller != oldWidget.controller;
}
