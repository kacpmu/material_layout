import 'package:flutter/material.dart';

/// The package's default sheet drag handle: a Material 3 pill that advertises
/// "you can drag this away".
///
/// Used by [showAppBottomSheet], [showSideSheet], and [showAdaptiveSheet]
/// whenever no `dragHandle` is supplied, so both sheet forms wear the same mark
/// — laid across the top edge of a bottom sheet, and stood upright on the
/// leading edge of a side sheet.
///
/// It is purely decorative: the drag gesture lives on the whole sheet, and
/// assistive tech dismisses through the modal barrier, which already carries a
/// label. Pass your own widget as `dragHandle` to replace it — including with
/// something interactive, whose semantics are then yours to define.
class SheetDragHandle extends StatelessWidget {
  /// Creates a sheet drag handle.
  const SheetDragHandle({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.extent = 24,
    this.length = 32,
    this.thickness = 4,
  });

  /// The axis the pill is elongated along.
  ///
  /// [Axis.horizontal] — wide and short, as on a bottom sheet.
  /// [Axis.vertical] — narrow and tall, as on a side sheet.
  final Axis axis;

  /// The pill's colour. Defaults to `onSurfaceVariant` at 40% opacity.
  final Color? color;

  /// How much room the handle reserves *across* the pill — the strip's height
  /// on a bottom sheet, its width on a side sheet. Defaults to 24.
  final double extent;

  /// The pill's long dimension. Defaults to 32.
  final double length;

  /// The pill's short dimension. Defaults to 4.
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final bool lengthwise = axis == Axis.horizontal;
    final Color resolved = color ??
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return ExcludeSemantics(
      child: SizedBox(
        width: lengthwise ? null : extent,
        height: lengthwise ? extent : null,
        child: Center(
          child: Container(
            width: lengthwise ? length : thickness,
            height: lengthwise ? thickness : length,
            decoration: BoxDecoration(
              color: resolved,
              borderRadius: BorderRadius.circular(thickness / 2),
            ),
          ),
        ),
      ),
    );
  }
}
