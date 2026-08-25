import 'package:flutter/widgets.dart';

import 'adaptive_layout_theme.dart';
import 'window_size.dart';
import 'window_size_class.dart';

/// Convenience accessors for adaptive layout state on a [BuildContext].
///
/// These read the window size from [MediaQuery] (so they reflect the app
/// window, including split-screen/multi-window) and classify it using the
/// breakpoints from the nearest [AdaptiveLayoutTheme]. Reading any of them
/// registers a dependency, so the widget rebuilds when the window resizes.
extension AdaptiveLayoutContext on BuildContext {
  /// The resolved configuration from the nearest [AdaptiveLayoutTheme]
  /// (or the Material 3 default).
  AdaptiveLayoutThemeData get adaptiveTheme => AdaptiveLayoutTheme.of(this);

  /// A snapshot of the current window size with its resolved size classes.
  WindowSize get windowSize =>
      WindowSize.fromSize(MediaQuery.sizeOf(this), adaptiveTheme.breakpoints);

  /// The current window **width** size class.
  WindowSizeClass get windowSizeClass => windowSize.widthClass;

  /// The current window **height** size class.
  WindowHeightSizeClass get windowHeightSizeClass => windowSize.heightClass;
}
