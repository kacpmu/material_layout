// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:material_layout/material_layout.dart';
import 'package:material_navigation/material_navigation.dart';
import 'package:material_ui/material_ui.dart'
    hide NavigationBar, NavigationDestination, NavigationRail;

import '../app/demo_app.dart';
import '../app/shell.dart';

/// Opens the demo settings.
class SettingsButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Demo settings',
    icon: const Icon(Icons.tune),
    onPressed: () => showSettings(context),
  );
}

/// Opens the demo settings as they were left: in a side sheet from expanded
/// upwards, and below it in a bottom sheet that can be dragged taller, the
/// forms [showAdaptiveSheet] chooses between.
///
/// Either form keeps the button that resets the settings in view below
/// them, and keeps the platform's text scale, whatever the settings make
/// the demo's.
void showSettings(BuildContext context) {
  final settings = Settings.of(context);
  final window = MediaQuery.sizeOf(context).width;
  final breakpoints = MaterialLayoutTheme.of(context).breakpoints;
  if (breakpoints.forWidth(window) >= Breakpoint.expanded) {
    showSideSheet<void>(
      context: context,
      barrierDismissible: settings.scrimDismisses,
      motion: settings.paneMotion,
      builder: (context) => SideSheet(
        width: Settings.of(context).sideSheetWidth,
        headline: const _PlatformTextScale(child: Text('Demo settings')),
        actions: const [_PlatformTextScale(child: ResetSettingsButton())],
        child: const _PlatformTextScale(child: SettingsPanel()),
      ),
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: settings.scrimDismisses,
    builder: (context) =>
        const _PlatformTextScale(child: _SettingsBottomSheet()),
  );
}

// The platform's text scale, which the settings keep so that they stay
// readable whatever they make the demo's.
class _PlatformTextScale extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQueryData.fromView(View.of(context)).textScaler,
    ),
    child: child,
  );
}

// The settings in a bottom sheet, which opens as tall as it was left and
// can be dragged taller, to the whole window, or shorter, to close it.
class _SettingsBottomSheet extends StatefulWidget {
  const new();

  @override
  State<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<_SettingsBottomSheet> {
  final _sheet = DraggableScrollableController();
  late final SettingsSheetMemory _memory = SettingsSheetMemory.of(context);
  late final double _initialSize = _memory.bottomSheetSize;

  // The size the sheet opens at the first time, and snaps to between its
  // smallest and the whole window.
  static const double _halfway = 0.6;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_rememberSize);
  }

  // Only the sizes the sheet rests at, not those it passes on its way to
  // closing.
  void _rememberSize() {
    final size = _sheet.size;
    if (size >= _halfway - 0.01) _memory.bottomSheetSize = size;
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetColor =
        theme.bottomSheetTheme.modalBackgroundColor ??
        theme.bottomSheetTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerLow;
    return DraggableScrollableSheet(
      expand: false,
      controller: _sheet,
      initialChildSize: _initialSize,
      minChildSize: 0.3,
      snap: true,
      snapSizes: const [_halfway],
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // The headline stays, and drags the sheet as the settings
                // do.
                SliverAppBar(
                  pinned: true,
                  primary: false,
                  automaticallyImplyLeading: false,
                  titleSpacing: 24,
                  backgroundColor: sheetColor,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  title: const Text('Demo settings'),
                ),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(child: SettingsPanel()),
                ),
              ],
            ),
          ),
          const _BottomSheetFooter(),
        ],
      ),
    );
  }
}

// The reset button below the settings in a bottom sheet, placed as a side
// sheet places its actions.
class _BottomSheetFooter extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      const SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ResetSettingsButton(),
          ),
        ),
      ),
    ],
  );
}

/// Resets every setting to its default, and the inbox's split with them.
class ResetSettingsButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () {
      Settings.controllerOf(context).value = const DemoSettings();
      InboxSplit.of(context).value = PaneSplit.automatic;
    },
    child: const Text('Reset all settings'),
  );
}

/// Every setting of the package that shapes the demo, every setting of the
/// navigation bar and rail, and the platform settings the package follows,
/// in sections that open and close.
///
/// Each setting names the parameter it sets. The settings open as they were
/// left: the same sections open, and scrolled as far, which the sheet's
/// memory keeps between openings.
class SettingsPanel extends StatefulWidget {
  const new({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final SettingsSheetMemory _memory = SettingsSheetMemory.of(context);
  ScrollPosition? _position;
  var _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The scroll view the sheet puts the settings in.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_rememberOffset);
      _position = position?..addListener(_rememberOffset);
    }
    if (!_restored) {
      _restored = true;
      // Scrolled back to where they were left, once they are laid out with
      // the sections that were open.
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreOffset());
    }
  }

  void _restoreOffset() {
    final position = _position;
    if (!mounted || position == null || !position.hasContentDimensions) {
      return;
    }
    position.jumpTo(
      clampDouble(
        _memory.scrollOffset,
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void _rememberOffset() {
    final position = _position;
    if (position != null && position.hasPixels) {
      _memory.scrollOffset = position.pixels;
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_rememberOffset);
    super.dispose();
  }

  static String _dp(double value) => '${value.round()}dp';

  static String _decimal(double value) => value.toStringAsFixed(2);

  static String _count(double value) => '${value.round()}';

  // The destinations that the demo shows, and the most either component
  // can carry.
  static final _mostDestinations = Destination.values.length.toDouble();

  // The sliders of a component's style tokens, under a heading for each
  // group, and a button that puts them all back. [before] puts settings of
  // a group ahead of its tokens.
  static List<Widget> _tokens<T extends StyleToken>({
    required List<T> tokens,
    required Map<T, double> values,
    required double? Function(T token) byDefault,
    Map<String, List<Widget>> before = const {},
    required ValueChanged<Map<T, double>> onChanged,
  }) => [
    for (final group in {for (final token in tokens) token.group}) ...[
      _Subheading(group),
      ...?before[group],
      for (final token in tokens.where((token) => token.group == group))
        _OptionalSlider(
          title: token.title,
          subtitle: token.hint,
          value: values[token],
          fallback: byDefault(token),
          byDefault: token.byDefault,
          min: token.min,
          max: token.max,
          step: token.step,
          format: token.step < 1 ? _decimal : _dp,
          onChanged: (value) => onChanged(
            value == null
                ? (Map.of(values)..remove(token))
                : {...values, token: value},
          ),
        ),
    ],
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: values.isEmpty ? null : () => onChanged(const {}),
        child: const Text('Use the default tokens'),
      ),
    ),
  ];

  // How many lines a label takes before the rest is cut, and how it is cut:
  // the settings of a component's labels, beside their tokens.
  static List<Widget> _labelLines({
    required String component,
    required int? maxLines,
    required int? byDefault,
    required ValueChanged<int?> onMaxLines,
    required TextOverflow? overflow,
    required ValueChanged<TextOverflow?> onOverflow,
  }) => [
    _OptionalSlider(
      title: 'labelMaxLines',
      subtitle:
          'The most lines a label takes. A label that does not fit wraps '
          'rather than being cut, up to this many lines '
          '($component.labelMaxLines).',
      value: maxLines?.toDouble(),
      fallback: byDefault?.toDouble(),
      byDefault: byDefault == null ? 'no limit' : 'default',
      min: 1,
      max: 4,
      step: 1,
      format: _count,
      onChanged: (value) => onMaxLines(value?.round()),
    ),
    _Choice<TextOverflow?>(
      title: 'labelOverflow',
      value: overflow,
      options: const [
        (null, 'Default'),
        (TextOverflow.clip, 'Clip'),
        (TextOverflow.fade, 'Fade'),
        (TextOverflow.ellipsis, 'Ellipsis'),
        (TextOverflow.visible, 'Visible'),
      ],
      describe: (value) {
        final cut = switch (value) {
          null => 'is clipped, never ellipsized, as Material 3 asks',
          TextOverflow.clip => 'is clipped',
          TextOverflow.fade => 'fades out',
          TextOverflow.ellipsis => 'ends in an ellipsis',
          TextOverflow.visible => 'runs past its room',
        };
        return 'A label that does not fit its lines $cut '
            '($component.labelOverflow).';
      },
      onChanged: onOverflow,
    ),
  ];

  static const _railLabelTypes = [
    (NavigationRailLabelType.all, 'All'),
    (NavigationRailLabelType.selected, 'Selected'),
    (NavigationRailLabelType.none, 'None'),
  ];

  static const _barLabelBehaviors = [
    (NavigationDestinationLabelBehavior.alwaysShow, 'All'),
    (NavigationDestinationLabelBehavior.onlyShowSelected, 'Selected'),
    (NavigationDestinationLabelBehavior.alwaysHide, 'None'),
  ];

  // What the drag handle may do to a pane: Material's by default, or what
  // the setting chooses. [dismissible] offers dismissing it, where the pane
  // can be closed.
  static Widget _collapse({
    required String title,
    required PaneCollapse? value,
    bool dismissible = false,
    bool enabled = true,
    required String Function(PaneCollapse? value) describe,
    required ValueChanged<PaneCollapse?> onChanged,
  }) => _Choice<PaneCollapse?>(
    title: title,
    value: value,
    options: [
      (null, 'Default'),
      (PaneCollapse.never, 'Never'),
      (PaneCollapse.collapse, 'Collapse'),
      if (dismissible) (PaneCollapse.dismiss, 'Dismiss'),
    ],
    describe: describe,
    enabled: enabled,
    onChanged: onChanged,
  );

  // What a gesture on the drag handle does.
  static Widget _gesture({
    required String title,
    required String parameter,
    required HandleAction value,
    required bool enabled,
    required ValueChanged<HandleAction> onChanged,
  }) => _Choice<HandleAction>(
    title: title,
    value: value,
    options: const [
      (HandleAction.nothing, 'Nothing'),
      (HandleAction.toggle, 'Toggle'),
      (HandleAction.splitEvenly, 'Split evenly'),
      (HandleAction.restore, 'Restore'),
    ],
    describe: (action) => switch (action) {
      HandleAction.nothing => 'Nothing ($parameter).',
      HandleAction.toggle => 'Hides a pane, or shows both again ($parameter).',
      HandleAction.splitEvenly => 'Splits the panes evenly ($parameter).',
      HandleAction.restore => 'Returns to the default split ($parameter).',
    },
    enabled: enabled,
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final controller = Settings.controllerOf(context);
    final settings = controller.value;
    final split = InboxSplit.of(context);
    void update(DemoSettings value) => controller.value = value;
    Widget group(SettingsSection section, List<Widget> children) =>
        _Section(section: section, children: children);

    final breakpoints = settings.breakpoints;
    void setBreakpoints(Breakpoints value) =>
        update(settings.copyWith(breakpoints: value));
    final handle = settings.handle;
    void setHandle(DragHandleStyle value) =>
        update(settings.copyWith(handle: value));
    final railDefaults = settings.railDefaultsIn(context);
    final barDefaults = settings.barDefaultsIn(context);

    // The sheet scrolls the settings, in either form.
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          group(SettingsSection.app, [
            _Switch(
              title: 'Dark theme',
              subtitle: 'Panes, sheets and navigation follow the theme.',
              value: settings.dark,
              onChanged: (value) => update(settings.copyWith(dark: value)),
            ),
            _Switch(
              title: 'Right to left',
              subtitle:
                  'Layouts mirror: the rail and the list move to the right.',
              value: settings.rtl,
              onChanged: (value) => update(settings.copyWith(rtl: value)),
            ),
            _Switch(
              title: 'Reduce motion',
              subtitle:
                  'As the platform setting does: panes, sheets and navigation '
                  'change at once.',
              value: settings.reduceMotion,
              onChanged: (value) =>
                  update(settings.copyWith(reduceMotion: value)),
            ),
            _OptionalSlider(
              title: 'Text scale',
              subtitle:
                  'As the platform setting does, for the demo; these settings '
                  "keep the platform's, to stay readable "
                  '(MediaQuery.textScaler).',
              value: settings.textScale,
              fallback: MediaQuery.textScalerOf(context).scale(1),
              byDefault: 'system',
              min: 0.5,
              max: 3.2,
              step: 0.05,
              format: _decimal,
              onChanged: (value) => update(settings.copyWith(textScale: value)),
            ),
          ]),
          group(SettingsSection.breakpoints, [
            const _Note(
              'The widths and heights at which breakpoints change, which every '
              'layout resolves against its region (breakpoints).',
            ),
            _Slider(
              title: 'Medium from',
              value: breakpoints.mediumMinWidth,
              min: 300,
              max: breakpoints.expandedMinWidth - 10,
              step: 10,
              format: _dp,
              onChanged: (value) =>
                  setBreakpoints(breakpoints.copyWith(mediumMinWidth: value)),
            ),
            _Slider(
              title: 'Expanded from',
              value: breakpoints.expandedMinWidth,
              min: breakpoints.mediumMinWidth + 10,
              max: breakpoints.largeMinWidth - 10,
              step: 10,
              format: _dp,
              onChanged: (value) =>
                  setBreakpoints(breakpoints.copyWith(expandedMinWidth: value)),
            ),
            _Slider(
              title: 'Large from',
              value: breakpoints.largeMinWidth,
              min: breakpoints.expandedMinWidth + 10,
              max: breakpoints.extraLargeMinWidth - 10,
              step: 10,
              format: _dp,
              onChanged: (value) =>
                  setBreakpoints(breakpoints.copyWith(largeMinWidth: value)),
            ),
            _Slider(
              title: 'Extra-large from',
              value: breakpoints.extraLargeMinWidth,
              min: breakpoints.largeMinWidth + 10,
              max: 2400,
              step: 10,
              format: _dp,
              onChanged: (value) => setBreakpoints(
                breakpoints.copyWith(extraLargeMinWidth: value),
              ),
            ),
            _Slider(
              title: 'Medium height from',
              value: breakpoints.mediumMinHeight,
              min: 200,
              max: breakpoints.expandedMinHeight - 10,
              step: 10,
              format: _dp,
              onChanged: (value) =>
                  setBreakpoints(breakpoints.copyWith(mediumMinHeight: value)),
            ),
            _Slider(
              title: 'Expanded height from',
              value: breakpoints.expandedMinHeight,
              min: breakpoints.mediumMinHeight + 10,
              max: 1400,
              step: 10,
              format: _dp,
              onChanged: (value) => setBreakpoints(
                breakpoints.copyWith(expandedMinHeight: value),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: breakpoints == const Breakpoints()
                    ? null
                    : () => setBreakpoints(const Breakpoints()),
                child: const Text("Use Material's breakpoints"),
              ),
            ),
          ]),
          group(SettingsSection.panes, [
            _Choice<PaneStyle>(
              title: 'Pane style',
              value: settings.paneStyle,
              options: const [
                (PaneStyle.byWindow, 'By window'),
                (PaneStyle.cards, 'Cards'),
                (PaneStyle.flat, 'Flat'),
              ],
              describe: (style) => switch (style) {
                PaneStyle.byWindow =>
                  'Flat where one pane fills a compact window, cards from '
                      'medium up. The layouts keep their margins to match '
                      '(marginPlacement).',
                PaneStyle.cards =>
                  'Cards set in by the margins, which the layouts keep around '
                      'the panes (MarginPlacement.outside).',
                PaneStyle.flat =>
                  'Flat panes that reach the edges, whose content keeps the '
                      'margins (MarginPlacement.inside).',
              },
              onChanged: (value) => update(settings.copyWith(paneStyle: value)),
            ),
            _Slider(
              title: 'Card corners',
              subtitle:
                  'Which the layouts keep while panes and pages move '
                  '(paneBorderRadius).',
              value: settings.cardRadius,
              min: 0,
              max: 28,
              step: 2,
              format: _dp,
              enabled: settings.paneStyle != PaneStyle.flat,
              onChanged: (value) =>
                  update(settings.copyWith(cardRadius: value)),
            ),
            _Choice<PaneColor>(
              title: 'Pane colour',
              value: settings.paneColor,
              options: const [
                (PaneColor.surface, 'Surface'),
                (PaneColor.lowest, 'Lowest'),
                (PaneColor.high, 'High'),
              ],
              describe: (color) => switch (color) {
                PaneColor.surface =>
                  "Material's: the surface colour, in which flat panes blend "
                      'in with the background (PaneSurfaceStyle.color).',
                PaneColor.lowest =>
                  'The surface container lowest colour: a colour of their '
                      'own sets the panes apart (PaneSurfaceStyle.color).',
                PaneColor.high =>
                  'The surface container high colour '
                      '(PaneSurfaceStyle.color).',
              },
              onChanged: (value) => update(settings.copyWith(paneColor: value)),
            ),
            _Switch(
              title: 'Pane outline',
              subtitle:
                  'An outline sets each pane apart '
                  '(PaneSurfaceStyle.outline).',
              value: settings.paneOutline,
              onChanged: (value) =>
                  update(settings.copyWith(paneOutline: value)),
            ),
          ]),
          group(SettingsSection.motion, [
            _Choice<MotionChoice>(
              title: 'Motion scheme',
              value: settings.motion,
              options: const [
                (MotionChoice.expressive, 'Expressive'),
                (MotionChoice.standard, 'Standard'),
                (MotionChoice.spring, 'Spring'),
                (MotionChoice.curve, 'Curve'),
              ],
              describe: (motion) => switch (motion) {
                MotionChoice.expressive =>
                  'Springs with a slight overshoot: the default '
                      '(MotionScheme.expressive).',
                MotionChoice.standard =>
                  'Springs close to critically damped (MotionScheme.standard).',
                MotionChoice.spring =>
                  'Panes, sheets and navigation on a spring of your own, as '
                      "the scheme's default spatial token (Motion.spring).",
                MotionChoice.curve =>
                  'Panes, sheets and navigation on a timed curve instead of a '
                      'spring (Motion.curved).',
              },
              onChanged: (value) => update(settings.copyWith(motion: value)),
            ),
            if (settings.motion == MotionChoice.spring) ...[
              _Slider(
                title: 'Damping ratio',
                subtitle: 'Below 1 the spring overshoots.',
                value: settings.springDamping,
                min: 0.3,
                max: 1,
                step: 0.05,
                format: (value) => value.toStringAsFixed(2),
                onChanged: (value) =>
                    update(settings.copyWith(springDamping: value)),
              ),
              _Slider(
                title: 'Stiffness',
                value: settings.springStiffness,
                min: 100,
                max: 1600,
                step: 50,
                format: (value) => '${value.round()}',
                onChanged: (value) =>
                    update(settings.copyWith(springStiffness: value)),
              ),
            ],
            if (settings.motion == MotionChoice.curve)
              _Slider(
                title: 'Duration',
                value: settings.curveDuration.inMilliseconds.toDouble(),
                min: 100,
                max: 1000,
                step: 50,
                format: (value) => '${value.round()}ms',
                onChanged: (value) => update(
                  settings.copyWith(
                    curveDuration: Duration(milliseconds: value.round()),
                  ),
                ),
              ),
            _Switch(
              title: 'Animate panes and sheets',
              subtitle: 'Off gives the layouts and sheets PaneMotion.none().',
              value: settings.animatePanes,
              onChanged: (value) =>
                  update(settings.copyWith(animatePanes: value)),
            ),
            _Switch(
              title: 'Animate navigation',
              subtitle: 'Off gives the navigation scaffold PaneMotion.none().',
              value: settings.animateNavigation,
              onChanged: (value) =>
                  update(settings.copyWith(animateNavigation: value)),
            ),
            _Choice<double>(
              title: 'Slow animations',
              value: settings.slowAnimations,
              options: const [(1, 'Off'), (2, '2×'), (5, '5×'), (10, '10×')],
              describe: (factor) => factor == 1
                  ? 'Every animation runs at its normal speed (timeDilation).'
                  : 'Every animation runs ${factor.round()} times slower, '
                        "these settings' own included (timeDilation).",
              onChanged: (value) =>
                  update(settings.copyWith(slowAnimations: value)),
            ),
          ]),
          group(SettingsSection.resizing, [
            _Switch(
              title: 'Resizable panes',
              subtitle:
                  'A drag handle between two panes: tap it to restore the '
                  'split, double-tap it to hide a pane, and long-press it to '
                  'split the panes evenly (resizable).',
              value: settings.resizable,
              onChanged: (value) => update(settings.copyWith(resizable: value)),
            ),
            _gesture(
              title: 'Double tap',
              parameter: 'PaneResizer.onDoubleTap',
              value: settings.handleDoubleTap,
              enabled: settings.resizable,
              onChanged: (value) =>
                  update(settings.copyWith(handleDoubleTap: value)),
            ),
            _gesture(
              title: 'Tap',
              parameter: 'PaneResizer.onTap',
              value: settings.handleTap,
              enabled: settings.resizable,
              onChanged: (value) => update(settings.copyWith(handleTap: value)),
            ),
            _gesture(
              title: 'Long press',
              parameter: 'PaneResizer.onLongPress',
              value: settings.handleLongPress,
              enabled: settings.resizable,
              onChanged: (value) =>
                  update(settings.copyWith(handleLongPress: value)),
            ),
            _Switch(
              title: "Snap to Material's stops",
              subtitle:
                  "Off lets a resize rest anywhere between the panes' minimum "
                  'widths (PaneResizer.snapStops).',
              value: settings.snapToStops,
              enabled: settings.resizable,
              onChanged: (value) =>
                  update(settings.copyWith(snapToStops: value)),
            ),
            _Slider(
              title: 'Handle thickness',
              subtitle:
                  'The drag handle at rest, and while pressed '
                  '(dragHandleStyle).',
              value: handle.thickness ?? 4,
              min: 2,
              max: 8,
              step: 1,
              format: _dp,
              enabled: settings.resizable,
              onChanged: (value) =>
                  setHandle(handle.copyWith(thickness: value)),
            ),
            _Slider(
              title: 'Handle length',
              value: handle.length ?? 48,
              min: 24,
              max: 64,
              step: 4,
              format: _dp,
              enabled: settings.resizable,
              onChanged: (value) => setHandle(handle.copyWith(length: value)),
            ),
            _Slider(
              title: 'Pressed thickness',
              value: handle.pressedThickness ?? 12,
              min: 4,
              max: 16,
              step: 1,
              format: _dp,
              enabled: settings.resizable,
              onChanged: (value) =>
                  setHandle(handle.copyWith(pressedThickness: value)),
            ),
            _Slider(
              title: 'Pressed length',
              value: handle.pressedLength ?? 52,
              min: 32,
              max: 72,
              step: 4,
              format: _dp,
              enabled: settings.resizable,
              onChanged: (value) =>
                  setHandle(handle.copyWith(pressedLength: value)),
            ),
            _Choice<HandleColor>(
              title: 'Handle colour',
              value: settings.handleColor,
              options: const [
                (HandleColor.outline, 'Outline'),
                (HandleColor.primary, 'Primary'),
                (HandleColor.tertiary, 'Tertiary'),
              ],
              enabled: settings.resizable,
              onChanged: (value) =>
                  update(settings.copyWith(handleColor: value)),
            ),
          ]),
          group(SettingsSection.inbox, [
            _Choice<Breakpoint>(
              title: 'Two panes from',
              value: settings.twoPanesFrom,
              options: const [
                (Breakpoint.medium, 'Medium'),
                (Breakpoint.expanded, 'Expanded'),
                (Breakpoint.large, 'Large'),
                (Breakpoint.extraLarge, 'Extra-large'),
              ],
              describe: (breakpoint) => breakpoint == Breakpoint.medium
                  ? 'At medium the panes split evenly (twoPaneBreakpoint).'
                  : 'The list keeps a fixed width beside the message '
                        '(twoPaneBreakpoint).',
              onChanged: (value) =>
                  update(settings.copyWith(twoPanesFrom: value)),
            ),
            _Choice<NothingSelected>(
              title: 'With no message selected',
              value: settings.nothingSelected,
              options: const [
                (NothingSelected.placeholder, 'Placeholder'),
                (NothingSelected.listOnly, 'List alone'),
                (NothingSelected.firstMessage, 'First message'),
              ],
              describe: (value) => switch (value) {
                NothingSelected.placeholder =>
                  'A placeholder beside the list, which back from a message '
                      'shows again (emptyBehavior).',
                NothingSelected.listOnly =>
                  'The list alone; the message pane opens on selection, and '
                      'back closes it (emptyBehavior).',
                NothingSelected.firstMessage =>
                  'The first message always shows, with no back beside the '
                      'list (emptyBehavior).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(nothingSelected: value)),
            ),
            ValueListenableBuilder<PaneSplit>(
              valueListenable: split,
              builder: (context, value, _) => _Choice<PaneSplit>(
                title: 'Split',
                value: value,
                options: const [
                  (PaneSplit.automatic, 'Automatic'),
                  (PaneSplit.width(360), '360dp'),
                  (PaneSplit.width(412), '412dp'),
                  (PaneSplit.centered, 'Centred'),
                  (PaneSplit.collapsed, 'List hidden'),
                  (PaneSplit.expanded, 'Message hidden'),
                ],
                describe: (value) {
                  final width = value.width;
                  final dragged = width != null && width != 360 && width != 412;
                  return '${dragged ? 'The list is ${width.round()}dp. ' : ''}'
                      'A drag of the handle changes it too, where the inbox '
                      'shows two panes (PaneSplitController).';
                },
                onChanged: (value) => split.value = value,
              ),
            ),
            _Switch(
              title: 'Remember resizes',
              subtitle:
                  'Off returns the split to its default at another breakpoint '
                  '(resizeMemory).',
              value: settings.inboxRemembersResize,
              onChanged: (value) =>
                  update(settings.copyWith(inboxRemembersResize: value)),
            ),
            _collapse(
              title: 'The handle hides the list',
              value: settings.listCollapse,
              enabled: settings.resizable,
              describe: (value) => value == PaneCollapse.never
                  ? 'Never (listCollapse).'
                  : 'The message then takes the whole width (listCollapse).',
              onChanged: (value) =>
                  update(settings.copyWith(listCollapse: value)),
            ),
            _collapse(
              title: 'The handle hides the message',
              value: settings.messageCollapse,
              // Only a message that leaves the list alone can be dismissed.
              dismissible: settings.nothingSelected == NothingSelected.listOnly,
              enabled: settings.resizable,
              describe: (value) => switch (value) {
                null =>
                  'Only where the panes split evenly, at medium '
                      '(detailCollapse).',
                PaneCollapse.never => 'Never (detailCollapse).',
                PaneCollapse.collapse =>
                  'The list then takes the whole width, until a message is '
                      'selected (detailCollapse).',
                PaneCollapse.dismiss =>
                  'Hiding it closes the message, as its close button does, '
                      'and leaves the list alone (detailCollapse).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(messageCollapse: value)),
            ),
          ]),
          group(SettingsSection.articles, [
            _Choice<RelatedPlacement>(
              title: 'Related articles',
              value: settings.related,
              options: const [
                (RelatedPlacement.sheet, 'Side sheet'),
                (RelatedPlacement.trailingPane, 'Trailing pane'),
                (RelatedPlacement.leadingPane, 'Leading pane'),
              ],
              describe: (value) => switch (value) {
                RelatedPlacement.sheet =>
                  'A standard side sheet beside the article from expanded up, '
                      'which keeps to the trailing side.',
                RelatedPlacement.trailingPane =>
                  'A pane after the article from expanded up '
                      '(supportingSide).',
                RelatedPlacement.leadingPane =>
                  'A pane before the article from expanded up '
                      '(supportingSide).',
              },
              onChanged: (value) => update(settings.copyWith(related: value)),
            ),
            _Switch(
              title: 'Resizable',
              subtitle:
                  'A drag handle between the article and the related '
                  'articles, where they can be closed, which resizes and '
                  'closes them (resizable).',
              value: settings.articlesResizable,
              enabled: settings.resizable,
              onChanged: (value) =>
                  update(settings.copyWith(articlesResizable: value)),
            ),
            _Switch(
              title: 'Related articles can be closed',
              subtitle:
                  'On, a temporary pane: its close button and the handle '
                  'close it. Off, a permanent one, which always shows, with '
                  'no close button and no handle (onSupportingDismissed).',
              value: settings.relatedDismissible,
              onChanged: (value) =>
                  update(settings.copyWith(relatedDismissible: value)),
            ),
            _Switch(
              title: 'Remember resizes',
              subtitle:
                  'Off returns the related articles to their width when they '
                  'reopen (resizeMemory).',
              value: settings.articlesRememberResize,
              onChanged: (value) =>
                  update(settings.copyWith(articlesRememberResize: value)),
            ),
          ]),
          group(SettingsSection.feed, [
            _Slider(
              title: 'Minimum card width',
              subtitle: 'As many columns as fit at this width (minItemWidth).',
              value: settings.feedMinItemWidth,
              min: 200,
              max: 400,
              step: 20,
              format: _dp,
              onChanged: (value) =>
                  update(settings.copyWith(feedMinItemWidth: value)),
            ),
            _Slider(
              title: 'Gap',
              value: settings.feedGap,
              min: 0,
              max: 32,
              step: 4,
              format: _dp,
              onChanged: (value) => update(settings.copyWith(feedGap: value)),
            ),
            _Switch(
              title: 'First card spans two columns',
              subtitle: 'Where there are two columns or more (spanBuilder).',
              value: settings.feedLeadSpansTwo,
              onChanged: (value) =>
                  update(settings.copyWith(feedLeadSpansTwo: value)),
            ),
          ]),
          group(SettingsSection.layoutScreen, [
            const _Note(
              'The Layout screen is a two-pane layout of its own, on the '
              'engine the inbox and the articles are built on '
              '(TwoPaneLayout).',
            ),
            _Choice<LayoutArrangement>(
              title: 'Arrangement',
              value: settings.layoutArrangement,
              options: const [
                (LayoutArrangement.fixedFirst, 'Fixed first'),
                (LayoutArrangement.fixedSecond, 'Fixed second'),
                (LayoutArrangement.splitPane, 'Split pane'),
              ],
              describe: (value) => switch (value) {
                LayoutArrangement.fixedFirst =>
                  'A fixed first pane beside a flexible second one '
                      '(PaneArrangement.fixedAndFlexible).',
                LayoutArrangement.fixedSecond =>
                  'A flexible first pane beside a fixed second one '
                      '(PaneArrangement.fixedAndFlexible).',
                LayoutArrangement.splitPane =>
                  'Two flexible panes, the spacer centred in the window '
                      '(PaneArrangement.splitPane).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(layoutArrangement: value)),
            ),
            if (settings.layoutArrangement != LayoutArrangement.splitPane)
              _OptionalSlider(
                title: 'Fixed pane width',
                subtitle:
                    'Left alone, 360dp at expanded and 412dp above '
                    '(PaneArrangement.width).',
                value: settings.layoutPaneWidth,
                byDefault: "Material's",
                min: 200,
                max: 600,
                step: 20,
                format: _dp,
                onChanged: (value) =>
                    update(settings.copyWith(layoutPaneWidth: value)),
              ),
            _Choice<Breakpoint>(
              title: 'Two panes from',
              value: settings.layoutTwoPanesFrom,
              options: const [
                (Breakpoint.medium, 'Medium'),
                (Breakpoint.expanded, 'Expanded'),
                (Breakpoint.large, 'Large'),
                (Breakpoint.extraLarge, 'Extra-large'),
              ],
              describe: (breakpoint) => breakpoint == Breakpoint.medium
                  ? 'At medium the panes split evenly (twoPaneBreakpoint).'
                  : 'Side by side from there up (twoPaneBreakpoint).',
              onChanged: (value) =>
                  update(settings.copyWith(layoutTwoPanesFrom: value)),
            ),
            _Choice<PaneReflow>(
              title: 'Below that',
              value: settings.layoutReflow,
              options: const [
                (PaneReflow.stack, 'Stack'),
                (PaneReflow.first, 'First pane'),
                (PaneReflow.second, 'Second pane'),
              ],
              describe: (reflow) => switch (reflow) {
                PaneReflow.stack =>
                  'The panes stack, the first above the second (reflow).',
                PaneReflow.first => 'Only the first pane shows (reflow).',
                PaneReflow.second => 'Only the second pane shows (reflow).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(layoutReflow: value)),
            ),
            _collapse(
              title: 'The handle hides the first pane',
              value: settings.layoutFirstCollapse,
              enabled: settings.resizable,
              describe: (value) => switch (value) {
                null =>
                  'Where it is the fixed pane, or the panes split evenly '
                      '(firstCollapse).',
                PaneCollapse.never => 'Never (firstCollapse).',
                _ =>
                  'The second pane then takes the whole width '
                      '(firstCollapse).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(layoutFirstCollapse: value)),
            ),
            _collapse(
              title: 'The handle hides the second pane',
              value: settings.layoutSecondCollapse,
              dismissible: settings.layoutSecondClosable,
              enabled: settings.resizable,
              describe: (value) => switch (value) {
                null =>
                  'Where it is the fixed pane, or the panes split evenly, '
                      'closing it where it can be closed (secondCollapse).',
                PaneCollapse.never => 'Never (secondCollapse).',
                PaneCollapse.collapse =>
                  'The first pane then takes the whole width '
                      '(secondCollapse).',
                PaneCollapse.dismiss => 'Hiding it closes it (secondCollapse).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(layoutSecondCollapse: value)),
            ),
            _Switch(
              title: 'The second pane can be closed',
              subtitle:
                  'A close button in the pane, and one beside the title to '
                  'open it again (onSecondDismissed).',
              value: settings.layoutSecondClosable,
              onChanged: (value) => update(
                settings.copyWith(
                  layoutSecondClosable: value,
                  layoutSecondCollapse:
                      !value &&
                          settings.layoutSecondCollapse == PaneCollapse.dismiss
                      ? null
                      : settings.layoutSecondCollapse,
                ),
              ),
            ),
          ]),
          group(SettingsSection.navigation, [
            _Choice<NavigationRule>(
              title: 'Placement',
              value: settings.navigationRule,
              options: const [
                (NavigationRule.material, "Material's"),
                (NavigationRule.barOnly, 'Bar only'),
                (NavigationRule.railOnly, 'Rail only'),
                (NavigationRule.railFrom, 'Rail from'),
                (NavigationRule.barFrom, 'Bar from'),
              ],
              describe: (value) => switch (value) {
                NavigationRule.material =>
                  'A bar at compact; at medium, a rail beside one pane and a '
                      'bar below two; a rail from expanded upwards '
                      '(NavigationPlacementRule.material).',
                NavigationRule.barOnly =>
                  'The bar at every breakpoint '
                      '(NavigationPlacementRule.only).',
                NavigationRule.railOnly =>
                  'The rail at every breakpoint, compact included '
                      '(NavigationPlacementRule.only).',
                NavigationRule.railFrom =>
                  'The bar below the breakpoint chosen, and the rail from it '
                      'upwards (NavigationPlacementRule.from).',
                NavigationRule.barFrom =>
                  'The rail below the breakpoint chosen, and the bar from it '
                      'upwards (NavigationPlacementRule.from).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(navigationRule: value)),
            ),
            if (settings.navigationRule
                case NavigationRule.railFrom || NavigationRule.barFrom)
              _Choice<Breakpoint>(
                title: 'From',
                value: settings.navigationRuleFrom,
                options: const [
                  (Breakpoint.medium, 'Medium'),
                  (Breakpoint.expanded, 'Expanded'),
                  (Breakpoint.large, 'Large'),
                  (Breakpoint.extraLarge, 'Extra-large'),
                ],
                onChanged: (value) =>
                    update(settings.copyWith(navigationRuleFrom: value)),
              ),
            _Choice<NavigationPanes>(
              title: 'Navigation follows',
              value: settings.navigationPanes,
              options: const [
                (NavigationPanes.layouts, 'The layouts'),
                (NavigationPanes.one, 'One pane'),
                (NavigationPanes.two, 'Two panes'),
              ],
              enabled: settings.navigationRule == NavigationRule.material,
              describe: (value) => switch (value) {
                _ when settings.navigationRule != NavigationRule.material =>
                  "Only Material's placement goes by the panes (paneCount).",
                NavigationPanes.layouts =>
                  'At medium, a navigation bar sits beside two panes and a '
                      'rail beside one, as the layouts report.',
                NavigationPanes.one || NavigationPanes.two =>
                  'At medium, a navigation bar sits beside two panes and a '
                      'rail beside one, as the scaffold is told '
                      '(paneCount).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(navigationPanes: value)),
            ),
            _Switch(
              title: 'Long labels',
              subtitle:
                  'Every destination has a longer label, to try labels that '
                  'do not fit (NavigationDestination.label).',
              value: settings.navigationLongLabels,
              onChanged: (value) =>
                  update(settings.copyWith(navigationLongLabels: value)),
            ),
            _Switch(
              title: 'Tooltips of their own',
              subtitle:
                  "Each destination's tooltip is its own text rather than its "
                  'label. A tooltip shows only where the label is hidden or '
                  'cut off (NavigationDestination.tooltip).',
              value: settings.navigationTooltips,
              onChanged: (value) =>
                  update(settings.copyWith(navigationTooltips: value)),
            ),
            _Switch(
              title: 'Disable Articles',
              subtitle:
                  'The second destination cannot be chosen '
                  '(NavigationDestination.enabled).',
              value: settings.navigationSecondDisabled,
              onChanged: (value) =>
                  update(settings.copyWith(navigationSecondDisabled: value)),
            ),
          ]),
          group(SettingsSection.navigationRail, [
            _Slider(
              title: 'Destinations',
              subtitle:
                  "Material recommends three to seven; past the demo's four, "
                  'placeholders. Where the current destination is past them, '
                  'the rail marks none (destinations).',
              value: settings.railCount.toDouble(),
              min: 0,
              max: _mostDestinations,
              step: 1,
              format: _count,
              onChanged: (value) =>
                  update(settings.copyWith(railCount: value.round())),
            ),
            _Choice<RailMenu>(
              title: 'Menu button',
              value: settings.railMenu,
              options: const [
                (RailMenu.byWindow, 'By window'),
                (RailMenu.modal, 'Modal'),
                (RailMenu.inPlace, 'In place'),
              ],
              describe: (value) => switch (value) {
                RailMenu.byWindow =>
                  'Expands the rail in place from large up, and below large '
                      'opens it as a modal over the content, so that the '
                      'panes do not reflow (expanded, NavigationMenuButton).',
                RailMenu.modal =>
                  'Opens the rail as a modal over the content, which '
                      'choosing a destination closes (NavigationMenuButton, '
                      'NavigationRailController.openModal).',
                RailMenu.inPlace =>
                  'Expands the rail in place, and the content beside it '
                      'reflows (expanded).',
              },
              onChanged: (value) => update(settings.copyWith(railMenu: value)),
            ),
            _Choice<RailExpansion>(
              title: 'Expanded',
              value: settings.railExpansion,
              options: const [
                (RailExpansion.byWindow, 'By window'),
                (RailExpansion.expanded, 'Expanded'),
                (RailExpansion.collapsed, 'Collapsed'),
              ],
              describe: (value) => switch (value) {
                RailExpansion.byWindow =>
                  'Expanded from large up, and collapsed below; the menu '
                      'button changes it in between (expanded).',
                RailExpansion.expanded || RailExpansion.collapsed =>
                  'Until the menu button changes it, which this setting then '
                      'follows (expanded).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(railExpansion: value)),
            ),
            _Choice<NavigationRailLabelType>(
              title: 'Labels',
              value: settings.railLabelType,
              options: _railLabelTypes,
              describe: (value) =>
                  'Which destinations show their label below the icon while '
                  'the rail is collapsed; expanded, each shows it beside the '
                  'icon (labelType).',
              onChanged: (value) =>
                  update(settings.copyWith(railLabelType: value)),
            ),
            _Choice<NavigationIndicatorSize?>(
              title: 'Expanded indicator',
              value: settings.railIndicatorSize,
              options: const [
                (null, 'Default'),
                (NavigationIndicatorSize.fill, 'Fill'),
                (NavigationIndicatorSize.hug, 'Hug'),
              ],
              describe: (value) => switch (value) {
                null =>
                  "Material's: around the icon and the label "
                      '(NavigationRailStyle.expandedIndicatorSize).',
                NavigationIndicatorSize.fill =>
                  'Across the expanded rail, as a drawer item is '
                      '(NavigationRailStyle.expandedIndicatorSize).',
                NavigationIndicatorSize.hug =>
                  'Around the icon and the label '
                      '(NavigationRailStyle.expandedIndicatorSize).',
              },
              onChanged: (value) =>
                  update(settings.copyWith(railIndicatorSize: value)),
            ),
            _Switch(
              title: 'Floating action button',
              subtitle:
                  "The inbox's compose button, and room for it on the other "
                  'screens (floatingActionButton).',
              value: settings.railFab,
              onChanged: (value) => update(settings.copyWith(railFab: value)),
            ),
            _Switch(
              title: 'Theme switch',
              subtitle:
                  'A destination below the others, which switches between '
                  'the light and dark themes (trailing).',
              value: settings.railTrailing,
              onChanged: (value) =>
                  update(settings.copyWith(railTrailing: value)),
            ),
            _Switch(
              title: 'Mailboxes and labels',
              subtitle:
                  'Secondary destinations below the others, while the rail '
                  'is expanded (expandedBody).',
              value: settings.railExpandedBody,
              onChanged: (value) =>
                  update(settings.copyWith(railExpandedBody: value)),
            ),
            _Switch(
              title: 'Scrollable',
              subtitle:
                  'Off, destinations that do not fit overflow '
                  '(NavigationRailStyle.scrollable).',
              value: settings.railScrollable,
              onChanged: (value) =>
                  update(settings.copyWith(railScrollable: value)),
            ),
            _Switch(
              title: 'Bottom inset',
              subtitle:
                  "Keeps the rail's content, the theme switch included, clear "
                  'of a system gesture bar '
                  '(NavigationRailStyle.applyBottomInset).',
              value: settings.railBottomInset,
              onChanged: (value) =>
                  update(settings.copyWith(railBottomInset: value)),
            ),
          ]),
          group(SettingsSection.railStyle, [
            const _Note(
              "Every size of the rail's style, named as in code. One left to "
              "its default is Material 3 Expressive's; the ranges go well "
              "past Material's (NavigationRailStyle).",
            ),
            ..._tokens(
              tokens: RailToken.values,
              values: settings.railTokens,
              byDefault: (token) => token.read(railDefaults),
              before: {
                'Label': _labelLines(
                  component: 'NavigationRailStyle',
                  maxLines: settings.railLabelMaxLines,
                  byDefault: railDefaults.labelMaxLines,
                  onMaxLines: (value) =>
                      update(settings.copyWith(railLabelMaxLines: value)),
                  overflow: settings.railLabelOverflow,
                  onOverflow: (value) =>
                      update(settings.copyWith(railLabelOverflow: value)),
                ),
              },
              onChanged: (value) =>
                  update(settings.copyWith(railTokens: value)),
            ),
          ]),
          group(SettingsSection.navigationBar, [
            _Slider(
              title: 'Destinations',
              subtitle:
                  "Material recommends three to five; past the demo's four, "
                  'placeholders. Where the current destination is past them, '
                  'the bar marks none (destinations).',
              value: settings.barCount.toDouble(),
              min: 0,
              max: _mostDestinations,
              step: 1,
              format: _count,
              onChanged: (value) =>
                  update(settings.copyWith(barCount: value.round())),
            ),
            _Slider(
              title: 'Width',
              subtitle:
                  "A share of the window's width, to try the bar narrow in "
                  'any window.',
              value: settings.barWidthFactor,
              min: 0,
              max: 1,
              step: 0.01,
              format: (value) => '${(value * 100).round()}%',
              onChanged: (value) =>
                  update(settings.copyWith(barWidthFactor: value)),
            ),
            _Choice<BarLayout>(
              title: 'Layout',
              value: settings.barLayout,
              options: const [
                (BarLayout.byWindow, 'By window'),
                (BarLayout.vertical, 'Labels below'),
                (BarLayout.horizontal, 'Labels beside'),
              ],
              describe: (value) => switch (value) {
                BarLayout.byWindow =>
                  'Labels beside the icons from medium up, and below them in '
                      'a compact window (itemLayout).',
                BarLayout.vertical =>
                  'Labels below the icons '
                      '(NavigationBarItemLayout.vertical).',
                BarLayout.horizontal =>
                  'Labels beside the icons '
                      '(NavigationBarItemLayout.horizontal).',
              },
              onChanged: (value) => update(settings.copyWith(barLayout: value)),
            ),
            _Choice<NavigationDestinationLabelBehavior>(
              title: 'Labels',
              value: settings.barLabelBehavior,
              options: _barLabelBehaviors,
              describe: (value) =>
                  'Which destinations show their label, below the icons and '
                  'beside them alike. A hidden label is still the '
                  "destination's name, and its tooltip (labelBehavior).",
              onChanged: (value) =>
                  update(settings.copyWith(barLabelBehavior: value)),
            ),
          ]),
          group(SettingsSection.barStyle, [
            const _Note(
              "Every size of the bar's style, named as in code. One left to "
              "its default is Material 3 Expressive's; the ranges go well "
              "past Material's (NavigationBarStyle).",
            ),
            ..._tokens(
              tokens: BarToken.values,
              values: settings.barTokens,
              byDefault: (token) => token.read(barDefaults),
              before: {
                'Label': _labelLines(
                  component: 'NavigationBarStyle',
                  maxLines: settings.barLabelMaxLines,
                  byDefault: barDefaults.labelMaxLines,
                  onMaxLines: (value) =>
                      update(settings.copyWith(barLabelMaxLines: value)),
                  overflow: settings.barLabelOverflow,
                  onOverflow: (value) =>
                      update(settings.copyWith(barLabelOverflow: value)),
                ),
              },
              onChanged: (value) => update(settings.copyWith(barTokens: value)),
            ),
          ]),
          group(SettingsSection.sheets, [
            _Slider(
              title: 'Side sheet width',
              subtitle:
                  'Every side sheet in the demo, these settings included, at '
                  'most 400dp (SideSheet.width).',
              value: settings.sideSheetWidth,
              min: 256,
              max: SideSheet.maxWidth,
              step: 8,
              format: _dp,
              onChanged: (value) =>
                  update(settings.copyWith(sideSheetWidth: value)),
            ),
            _Switch(
              title: 'Tinted side sheets',
              subtitle:
                  'Standard and modal side sheets in container colours of the '
                  'colour scheme (SideSheetStyle).',
              value: settings.tintedSheets,
              onChanged: (value) =>
                  update(settings.copyWith(tintedSheets: value)),
            ),
            _Switch(
              title: 'Tapping the scrim closes sheets',
              subtitle:
                  'Off leaves the close button and back '
                  '(barrierDismissible, isDismissible).',
              value: settings.scrimDismisses,
              onChanged: (value) =>
                  update(settings.copyWith(scrimDismisses: value)),
            ),
            _Slider(
              title: 'Modal side sheet scrim',
              subtitle:
                  'Behind every modal side sheet, these settings and the '
                  'adaptive sheets included, from expanded up '
                  '(SideSheetStyle.modalBarrierColor).',
              value: settings.scrimOpacity,
              min: 0,
              max: 0.8,
              step: 0.02,
              format: (value) => '${(value * 100).round()}%',
              onChanged: (value) =>
                  update(settings.copyWith(scrimOpacity: value)),
            ),
          ]),
          group(SettingsSection.text, [
            _Slider(
              title: 'Line length',
              subtitle:
                  'The articles, the messages and the layout report keep lines '
                  'to this many characters, 40 to 60 as Material recommends '
                  '(LineLength.characters).',
              value: settings.lineLength.toDouble(),
              min: 30,
              max: 90,
              step: 5,
              format: (value) => '${value.round()}',
              onChanged: (value) =>
                  update(settings.copyWith(lineLength: value.round())),
            ),
          ]),
        ],
      ),
    );
  }
}

// A section of the settings: a card that opens to show them, and stays
// open or closed from one opening of the sheet to the next.
class _Section extends StatelessWidget {
  const new({required this.section, required this.children});

  final SettingsSection section;
  final List<Widget> children;

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memory = SettingsSheetMemory.of(context);
    final color = theme.colorScheme.surfaceContainerHigh;
    return ExpansionTile(
      key: PageStorageKey<SettingsSection>(section),
      initiallyExpanded: memory.openSections.contains(section),
      onExpansionChanged: (open) {
        if (open) {
          memory.openSections.add(section);
        } else {
          memory.openSections.remove(section);
        }
      },
      leading: Icon(section.icon),
      title: Text(section.title, style: theme.textTheme.titleMedium),
      backgroundColor: color,
      collapsedBackgroundColor: color,
      shape: _shape,
      collapsedShape: _shape,
      clipBehavior: Clip.antiAlias,
      tilePadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          child,
        ],
      ],
    );
  }
}

// A line of explanation.
class _Note extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// A heading within a section, above the settings of one group.
class _Subheading extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _Slider extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    this.enabled = true,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final double step;
  final String Function(double value) format;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    // A range its neighbours have closed leaves nothing to choose.
    final open = max - min >= step / 2;
    final top = open ? max : min + step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            Text(format(value), style: theme.textTheme.labelLarge),
          ],
        ),
        if (subtitle != null) _Note(subtitle),
        Slider(
          value: clampDouble(value, min, top),
          min: min,
          max: top,
          divisions: math.max(1, ((top - min) / step).round()),
          label: format(value),
          onChanged: enabled && open ? onChanged : null,
        ),
      ],
    );
  }
}

// A slider for a setting with a default of its own: until it is moved, it
// shows what the default comes to, and its button puts the default back.
class _OptionalSlider extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    required this.value,
    this.fallback,
    this.byDefault = 'default',
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;

  /// The value set, or null for the default.
  final double? value;

  /// What the default comes to, where it is a number.
  final double? fallback;

  /// How the default is described: beside [fallback], or alone without one.
  final String byDefault;

  final double min;
  final double max;
  final double step;
  final String Function(double value) format;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = this.subtitle;
    final value = this.value;
    final fallback = this.fallback;
    // The thumb stays on the track where the default is past it, as the
    // platform's text scale can be.
    final shown = clampDouble(value ?? fallback ?? min, min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            Text(
              switch ((value, fallback)) {
                (final double value, _) => format(value),
                (null, final double fallback) =>
                  '${format(fallback)} ($byDefault)',
                (null, null) => byDefault,
              },
              style: theme.textTheme.labelLarge?.copyWith(
                color: value == null ? colors.onSurfaceVariant : colors.primary,
              ),
            ),
            IconButton(
              tooltip: 'Back to default',
              icon: const Icon(Icons.restart_alt),
              onPressed: value == null ? null : () => onChanged(null),
            ),
          ],
        ),
        if (subtitle != null) _Note(subtitle),
        Slider(
          value: shown,
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          label: format(shown),
          onChanged: (value) =>
              onChanged(step >= 1 ? value.roundToDouble() : value),
        ),
      ],
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.options,
    this.describe,
    this.enabled = true,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<(T, String)> options;
  final String Function(T value)? describe;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final describe = this.describe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (option, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: option == value,
                onSelected: enabled ? (_) => onChanged(option) : null,
              ),
          ],
        ),
        if (describe != null) ...[
          const SizedBox(height: 8),
          _Note(describe(value)),
        ],
      ],
    );
  }
}
