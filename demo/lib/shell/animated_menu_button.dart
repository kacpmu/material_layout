import 'package:flutter/material.dart' hide NavigationRail;
import 'package:material_navigation/material_navigation.dart';

/// A menu / hamburger button for a [NavigationRail]'s [leading] slot;
/// the glyph rotates between "menu" and "menu open" as the rail morphs.
///
/// It reads the rail's extend animation from context for the rotation. Tapping
/// it runs [onPressed] — left null, it toggles the rail **inline**
/// (`NavigationRail.of(context).toggle()`); pass your own to open it
/// modally or to choose per width, e.g.:
///
/// ```dart
/// NavigationRail(
///   leading: Builder(
///     builder: (context) => AnimatedMenuButton(
///       onPressed: () => NavigationRail.of(context).toggleModal(),
///     ),
///   ),
///   destinations: ...,
/// );
/// ```
///
/// Must be a descendant of a [NavigationRail] (the `leading` slot
/// qualifies).
class AnimatedMenuButton extends StatelessWidget {
  const AnimatedMenuButton({super.key, this.onPressed});

  /// Called when the button is tapped. Defaults to toggling the rail inline
  /// (`NavigationRail.of(context).toggle()`).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final animation = NavigationRail.of(context).expandAnimation;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final open = animation.value > 0.5;
        return IconButton(
          onPressed:
              onPressed ?? () => NavigationRail.of(context).toggle(),
          tooltip: open ? 'Collapse' : 'Expand',
          padding: const EdgeInsets.all(16),
          icon: Transform.rotate(
            angle: (ltr ? 1 : -1) * 3.1415926 * animation.value,
            child: Transform.flip(
              flipX: ltr,
              child: Icon(open ? Icons.menu_open : Icons.menu),
            ),
          ),
        );
      },
    );
  }
}
