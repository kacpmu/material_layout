import 'package:flutter/material.dart';

/// A floating action button that morphs between a square and an extended shape.
///
/// As [animation] advances from 0 to 1, the button grows from a square FAB into
/// an extended FAB whose [label] is revealed beside the [icon]. The icon holds
/// its position while the label slides in, so the two shapes share a common
/// anchor.
///
/// Drive it with any [Animation], such as an [AnimationController] or a
/// [CurvedAnimation]:
///
/// ```dart
/// AnimatedFab(
///   animation: _controller,
///   icon: const Icon(Icons.add),
///   label: const Text('Compose'),
///   onPressed: () {},
/// );
/// ```
///
/// A common use is inside a [NavigationRail], wired to the rail's expand
/// animation so the button extends as the rail expands. Obtain the animation
/// from a [Builder] whose context is below the rail:
///
/// ```dart
/// NavigationRail(
///   floatingActionButton: Builder(
///     builder: (context) => AnimatedFab(
///       animation: NavigationRail.of(context).expandAnimation,
///       icon: const Icon(Icons.edit_outlined),
///       label: const Text('Compose'),
///     ),
///   ),
///   destinations: ...,
/// );
/// ```
class AnimatedFab extends StatelessWidget {
  /// Creates an [AnimatedFab].
  ///
  /// The [icon], [label], and [animation] arguments are required.
  const AnimatedFab({
    super.key,
    required this.icon,
    required this.label,
    required this.animation,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  /// The widget shown at the leading edge of the button, in both the square and
  /// extended shapes.
  final Widget icon;

  /// The widget revealed beside the [icon] as [animation] advances toward 1.
  ///
  /// Typically a [Text]. It is clipped and faded out while the button is
  /// collapsed, and fully visible once the button is extended.
  final Widget label;

  /// Drives the morph between the square and extended shapes.
  ///
  /// A value of 0 collapses the button to a square; 1 extends it to show the
  /// [label]. Values are clamped to the 0 to 1 range.
  final Animation<double> animation;

  /// Called when the button is tapped.
  ///
  /// If null, the button is shown but does not respond to taps.
  final VoidCallback? onPressed;

  /// The message shown in a [Tooltip] while the button is collapsed.
  ///
  /// The tooltip is omitted once the button is more than half extended, since
  /// the [label] is then visible. Defaults to null, which shows no tooltip.
  final String? tooltip;

  /// The button's background color.
  ///
  /// Defaults to [ColorScheme.primaryContainer].
  final Color? backgroundColor;

  /// The color of the [icon] and [label].
  ///
  /// Defaults to [ColorScheme.onPrimaryContainer].
  final Color? foregroundColor;

  /// The z-coordinate at which to place the button.
  ///
  /// Defaults to 0.
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colors.primaryContainer;
    final fg = foregroundColor ?? colors.onPrimaryContainer;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        // Fade the label in over the same window the rail uses for its labels.
        final labelOpacity = const Interval(0.25, 0.5).transform(t);
        Widget fab = Material(
          color: bg,
          elevation: elevation,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: IconTheme.merge(
                        data: IconThemeData(color: fg, size: 24),
                        child: icon,
                      ),
                    ),
                  ),
                  // Reveals horizontally as the rail extends.
                  ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: t,
                      child: Opacity(
                        opacity: labelOpacity,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(
                                color: fg, fontWeight: FontWeight.w500),
                            child: label,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // Drop the tooltip once extended: the visible label makes it redundant.
        if (tooltip != null && t < 0.5) {
          fab = Tooltip(message: tooltip!, child: fab);
        }
        return fab;
      },
    );
  }
}
