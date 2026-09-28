// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

/// @docImport '../layouts/list_detail_layout.dart';
/// @docImport '../layouts/supporting_pane_layout.dart';
/// @docImport '../layouts/two_pane_layout.dart';
/// @docImport '../panes/pane_resizer.dart';
/// @docImport '../panes/pane_surface.dart';
/// @docImport '../sheets/side_sheet.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'breakpoints.dart';
import 'margins.dart';
import 'motion.dart';

/// The appearance of the default pane drag handle, [PaneDragHandle].
///
/// Material's drag handle is a pill 4dp thick and 48dp long that grows to
/// 12dp by 52dp while it is pressed or dragged, in the colour scheme's
/// outline, and its on-surface colour while pressed. A value left null is
/// taken from the style the handle falls back to, and in the end from
/// Material's.
@immutable
final class DragHandleStyle with Diagnosticable {
  /// Creates a drag handle style.
  const new({
    this.thickness,
    this.length,
    this.pressedThickness,
    this.pressedLength,
    this.color,
    this.pressedColor,
  }) : assert(thickness == null || thickness > 0),
       assert(length == null || length > 0),
       assert(pressedThickness == null || pressedThickness > 0),
       assert(pressedLength == null || pressedLength > 0);

  /// The grip's extent across the spacer, at rest: 4dp by default.
  final double? thickness;

  /// The grip's extent along the spacer, at rest: 48dp by default.
  final double? length;

  /// The grip's extent across the spacer while pressed or dragged: 12dp by
  /// default.
  final double? pressedThickness;

  /// The grip's extent along the spacer while pressed or dragged: 52dp by
  /// default.
  final double? pressedLength;

  /// The grip's colour at rest: the colour scheme's outline by default.
  final Color? color;

  /// The grip's colour while pressed or dragged: the colour scheme's
  /// on-surface colour by default.
  final Color? pressedColor;

  /// Creates a copy of this style with the given fields replaced.
  DragHandleStyle copyWith({
    double? thickness,
    double? length,
    double? pressedThickness,
    double? pressedLength,
    Color? color,
    Color? pressedColor,
  }) => DragHandleStyle(
    thickness: thickness ?? this.thickness,
    length: length ?? this.length,
    pressedThickness: pressedThickness ?? this.pressedThickness,
    pressedLength: pressedLength ?? this.pressedLength,
    color: color ?? this.color,
    pressedColor: pressedColor ?? this.pressedColor,
  );

  /// Linearly interpolates between two drag handle styles.
  static DragHandleStyle lerp(DragHandleStyle a, DragHandleStyle b, double t) {
    if (identical(a, b)) return a;
    return DragHandleStyle(
      thickness: _lerpExtent(a.thickness, b.thickness, t),
      length: _lerpExtent(a.length, b.length, t),
      pressedThickness: _lerpExtent(a.pressedThickness, b.pressedThickness, t),
      pressedLength: _lerpExtent(a.pressedLength, b.pressedLength, t),
      color: Color.lerp(a.color, b.color, t),
      pressedColor: Color.lerp(a.pressedColor, b.pressedColor, t),
    );
  }

  // An extent left to the default has no value to pass through on the way
  // to one that is set, so the two switch halfway.
  static double? _lerpExtent(double? a, double? b, double t) =>
      a == null || b == null ? (t < 0.5 ? a : b) : lerpDouble(a, b, t);

  @override
  bool operator ==(Object other) =>
      other is DragHandleStyle &&
      other.thickness == thickness &&
      other.length == length &&
      other.pressedThickness == pressedThickness &&
      other.pressedLength == pressedLength &&
      other.color == color &&
      other.pressedColor == pressedColor;

  @override
  int get hashCode => Object.hash(
    thickness,
    length,
    pressedThickness,
    pressedLength,
    color,
    pressedColor,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('thickness', thickness, defaultValue: null))
      ..add(DoubleProperty('length', length, defaultValue: null))
      ..add(
        DoubleProperty(
          'pressedThickness',
          pressedThickness,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('pressedLength', pressedLength, defaultValue: null))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(ColorProperty('pressedColor', pressedColor, defaultValue: null));
  }
}

/// The appearance of a [PaneSurface].
///
/// Material groups the content of a pane in one of two ways: implicitly,
/// on a surface that blends in with the background, or explicitly, with a
/// distinct colour or an outline. A value left null is Material's: the
/// colour scheme's surface colour, and no outline.
@immutable
final class PaneSurfaceStyle with Diagnosticable {
  /// Creates a pane surface style.
  const new({this.color, this.outline});

  /// The surface's colour: the colour scheme's surface colour by default.
  final Color? color;

  /// The line around the surface: none by default.
  final BorderSide? outline;

  /// Creates a copy of this style with the given fields replaced.
  PaneSurfaceStyle copyWith({Color? color, BorderSide? outline}) =>
      PaneSurfaceStyle(
        color: color ?? this.color,
        outline: outline ?? this.outline,
      );

  /// Linearly interpolates between two pane surface styles.
  static PaneSurfaceStyle lerp(
    PaneSurfaceStyle a,
    PaneSurfaceStyle b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return PaneSurfaceStyle(
      color: Color.lerp(a.color, b.color, t),
      outline: _lerpOutline(a.outline, b.outline, t),
    );
  }

  // An outline that is not there fades in or out in the colour of the one
  // that is, rather than from black.
  static BorderSide? _lerpOutline(BorderSide? a, BorderSide? b, double t) {
    if (a == null && b == null) return null;
    final from = a ?? b!.copyWith(width: 0, color: b.color.withAlpha(0));
    final to = b ?? a!.copyWith(width: 0, color: a.color.withAlpha(0));
    return BorderSide.lerp(from, to, t);
  }

  @override
  bool operator ==(Object other) =>
      other is PaneSurfaceStyle &&
      other.color == color &&
      other.outline == outline;

  @override
  int get hashCode => Object.hash(color, outline);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(
        DiagnosticsProperty<BorderSide>('outline', outline, defaultValue: null),
      );
  }
}

/// The appearance of a [SideSheet] and of the scrim behind a modal one.
///
/// A value left null is Material's: a standard sheet in the colour
/// scheme's surface colour, a modal sheet in its surface container low
/// colour, and a scrim of black at 54% opacity.
@immutable
final class SideSheetStyle with Diagnosticable {
  /// Creates a side sheet style.
  const new({
    this.backgroundColor,
    this.modalBackgroundColor,
    this.modalBarrierColor,
  });

  /// The colour of a standard side sheet, placed as a pane: the colour
  /// scheme's surface colour by default.
  final Color? backgroundColor;

  /// The colour of a modal side sheet: the colour scheme's surface container
  /// low colour by default.
  final Color? modalBackgroundColor;

  /// The scrim behind a modal side sheet: black at 54% opacity by default.
  final Color? modalBarrierColor;

  /// Creates a copy of this style with the given fields replaced.
  SideSheetStyle copyWith({
    Color? backgroundColor,
    Color? modalBackgroundColor,
    Color? modalBarrierColor,
  }) => SideSheetStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    modalBackgroundColor: modalBackgroundColor ?? this.modalBackgroundColor,
    modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
  );

  /// Linearly interpolates between two side sheet styles.
  static SideSheetStyle lerp(SideSheetStyle a, SideSheetStyle b, double t) {
    if (identical(a, b)) return a;
    return SideSheetStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      modalBackgroundColor: Color.lerp(
        a.modalBackgroundColor,
        b.modalBackgroundColor,
        t,
      ),
      modalBarrierColor: Color.lerp(
        a.modalBarrierColor,
        b.modalBarrierColor,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SideSheetStyle &&
      other.backgroundColor == backgroundColor &&
      other.modalBackgroundColor == modalBackgroundColor &&
      other.modalBarrierColor == modalBarrierColor;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, modalBackgroundColor, modalBarrierColor);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ColorProperty('backgroundColor', backgroundColor, defaultValue: null),
      )
      ..add(
        ColorProperty(
          'modalBackgroundColor',
          modalBackgroundColor,
          defaultValue: null,
        ),
      )
      ..add(
        ColorProperty(
          'modalBarrierColor',
          modalBarrierColor,
          defaultValue: null,
        ),
      );
  }
}

/// How this package's layouts and components look: breakpoints, where
/// margins are kept, the panes' corners, motion, and the styles of the drag
/// handle, pane surfaces and side sheets.
///
/// Configure it once with the rest of the theme, as a theme extension:
///
/// ```dart
/// ThemeData(
///   extensions: const [
///     MaterialLayoutThemeData(motionScheme: MotionScheme.standard()),
///   ],
/// )
/// ```
///
/// or for a subtree, with a [MaterialLayoutTheme].
///
/// A value a widget takes resolves as Flutter's own do: the widget's
/// argument, then this theme, then Material's default. The theme holds only
/// how things look. What they do is set on each widget, and nowhere else:
/// callbacks and gestures, whether panes resize and which of them collapse,
/// what a resize remembers, where a layout changes arrangement, and where
/// navigation shows.
@immutable
final class MaterialLayoutThemeData
    extends ThemeExtension<MaterialLayoutThemeData>
    with Diagnosticable {
  /// Creates layout tokens.
  const new({
    this.breakpoints = const Breakpoints(),
    this.marginPlacement = MarginPlacement.outside,
    this.paneBorderRadius = BorderRadius.zero,
    this.motionScheme = const MotionScheme.expressive(),
    this.dragHandleStyle = const DragHandleStyle(),
    this.paneSurfaceStyle = const PaneSurfaceStyle(),
    this.sideSheetStyle = const SideSheetStyle(),
  });

  /// The widths and heights at which breakpoints change.
  final Breakpoints breakpoints;

  /// Where layouts keep their margins, unless a layout is told
  /// otherwise or is nested in one that keeps them elsewhere.
  ///
  /// Around the panes by default: the only placement in which layouts keep
  /// all content clear of the window's edges by themselves. Choose it by how
  /// the app paints its panes. An app whose panes are flat in a compact
  /// window and cards in wider ones sets it from the window's width:
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: (context, child) {
  ///     final theme = MaterialLayoutTheme.of(context);
  ///     final width = MediaQuery.sizeOf(context).width;
  ///     final flat = theme.breakpoints.forWidth(width) == Breakpoint.compact;
  ///     return MaterialLayoutTheme(
  ///       data: theme.copyWith(
  ///         marginPlacement: flat
  ///             ? MarginPlacement.inside
  ///             : MarginPlacement.outside,
  ///         paneBorderRadius: flat
  ///             ? BorderRadius.zero
  ///             : BorderRadius.circular(16),
  ///       ),
  ///       child: child!,
  ///     );
  ///   },
  ///   // …
  /// );
  /// ```
  ///
  /// [ListDetailLayout.marginPlacement], [SupportingPaneLayout.marginPlacement]
  /// and [TwoPaneLayout.marginPlacement] override it for one layout. A
  /// [PaneSurface] is a card where the margins are around the panes, and flat
  /// where they are within them.
  final MarginPlacement marginPlacement;

  /// The corners of the panes as the app paints them, such as the radius of
  /// its cards.
  ///
  /// A [PaneSurface] has these corners. A pane that enters or leaves is
  /// clipped to the space it occupies, and a list-detail layout at one pane
  /// clips the detail's page to the pane's place while it comes and goes.
  /// The clip keeps these corners, so that a card keeps its shape while it
  /// moves. Square by default, for panes painted flat. A side sheet used as a
  /// pane takes these corners too.
  final BorderRadiusGeometry paneBorderRadius;

  /// The motion tokens that panes, sheets and navigation use.
  final MotionScheme motionScheme;

  /// The appearance of the default drag handle, which
  /// [PaneDragHandle.style] overrides for one handle.
  final DragHandleStyle dragHandleStyle;

  /// The appearance of a [PaneSurface], which its own arguments override.
  final PaneSurfaceStyle paneSurfaceStyle;

  /// The appearance of a [SideSheet], which its own arguments override, and
  /// of the scrim behind a modal one.
  final SideSheetStyle sideSheetStyle;

  @override
  MaterialLayoutThemeData copyWith({
    Breakpoints? breakpoints,
    MarginPlacement? marginPlacement,
    BorderRadiusGeometry? paneBorderRadius,
    MotionScheme? motionScheme,
    DragHandleStyle? dragHandleStyle,
    PaneSurfaceStyle? paneSurfaceStyle,
    SideSheetStyle? sideSheetStyle,
  }) => MaterialLayoutThemeData(
    breakpoints: breakpoints ?? this.breakpoints,
    marginPlacement: marginPlacement ?? this.marginPlacement,
    paneBorderRadius: paneBorderRadius ?? this.paneBorderRadius,
    motionScheme: motionScheme ?? this.motionScheme,
    dragHandleStyle: dragHandleStyle ?? this.dragHandleStyle,
    paneSurfaceStyle: paneSurfaceStyle ?? this.paneSurfaceStyle,
    sideSheetStyle: sideSheetStyle ?? this.sideSheetStyle,
  );

  @override
  MaterialLayoutThemeData lerp(
    covariant MaterialLayoutThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    // Breakpoints, placements and motion tokens have no meaningful midpoint,
    // so they switch halfway through a theme animation.
    return MaterialLayoutThemeData(
      breakpoints: t < 0.5 ? breakpoints : other.breakpoints,
      marginPlacement: t < 0.5 ? marginPlacement : other.marginPlacement,
      paneBorderRadius: BorderRadiusGeometry.lerp(
        paneBorderRadius,
        other.paneBorderRadius,
        t,
      )!,
      motionScheme: t < 0.5 ? motionScheme : other.motionScheme,
      dragHandleStyle: DragHandleStyle.lerp(
        dragHandleStyle,
        other.dragHandleStyle,
        t,
      ),
      paneSurfaceStyle: PaneSurfaceStyle.lerp(
        paneSurfaceStyle,
        other.paneSurfaceStyle,
        t,
      ),
      sideSheetStyle: SideSheetStyle.lerp(
        sideSheetStyle,
        other.sideSheetStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialLayoutThemeData &&
      other.breakpoints == breakpoints &&
      other.marginPlacement == marginPlacement &&
      other.paneBorderRadius == paneBorderRadius &&
      other.motionScheme == motionScheme &&
      other.dragHandleStyle == dragHandleStyle &&
      other.paneSurfaceStyle == paneSurfaceStyle &&
      other.sideSheetStyle == sideSheetStyle;

  @override
  int get hashCode => Object.hash(
    breakpoints,
    marginPlacement,
    paneBorderRadius,
    motionScheme,
    dragHandleStyle,
    paneSurfaceStyle,
    sideSheetStyle,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Breakpoints>('breakpoints', breakpoints))
      ..add(
        EnumProperty<MarginPlacement>(
          'marginPlacement',
          marginPlacement,
          defaultValue: MarginPlacement.outside,
        ),
      )
      ..add(
        DiagnosticsProperty<BorderRadiusGeometry>(
          'paneBorderRadius',
          paneBorderRadius,
          defaultValue: BorderRadius.zero,
        ),
      )
      ..add(DiagnosticsProperty<MotionScheme>('motionScheme', motionScheme))
      ..add(
        DiagnosticsProperty<DragHandleStyle>(
          'dragHandleStyle',
          dragHandleStyle,
        ),
      )
      ..add(
        DiagnosticsProperty<PaneSurfaceStyle>(
          'paneSurfaceStyle',
          paneSurfaceStyle,
        ),
      )
      ..add(
        DiagnosticsProperty<SideSheetStyle>('sideSheetStyle', sideSheetStyle),
      );
  }
}

/// A widget that overrides the layout tokens for a subtree.
///
/// [MaterialLayoutTheme.of] prefers the nearest [MaterialLayoutTheme], then a
/// [MaterialLayoutThemeData] extension on the ambient [ThemeData], then the
/// defaults.
class MaterialLayoutTheme extends InheritedTheme {
  /// Creates a layout theme for [child].
  const new({super.key, required this.data, required super.child});

  /// The layout tokens for this subtree.
  final MaterialLayoutThemeData data;

  /// The layout tokens in effect for [context].
  static MaterialLayoutThemeData of(BuildContext context) {
    final theme = context
        .dependOnInheritedWidgetOfExactType<MaterialLayoutTheme>();
    return theme?.data ??
        Theme.of(context).extension<MaterialLayoutThemeData>() ??
        const MaterialLayoutThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) =>
      MaterialLayoutTheme(data: data, child: child);

  @override
  bool updateShouldNotify(MaterialLayoutTheme oldWidget) =>
      data != oldWidget.data;
}
