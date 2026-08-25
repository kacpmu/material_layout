/// Material 3 window size classes.
///
/// A *window size class* is an opinionated breakpoint that buckets the
/// available size of the app **window** (not the physical device) into
/// categories where the layout is expected to change. Width and height are
/// classified independently — see [WindowHeightSizeClass].
///
/// The numeric thresholds are intentionally *not* baked into these enums; they
/// live in a single, overridable source of truth — [Breakpoints] — so callers
/// can retune them. Use `breakpoints.resolve(width)` to obtain a value.
///
/// Width ranges with the default Material 3 breakpoints
/// ([Breakpoints.material]):
///
/// | Class        | Width (dp)      | Typical device                 |
/// | ------------ | --------------- | ------------------------------ |
/// | [compact]    | `0 – 599`       | Phone in portrait              |
/// | [medium]     | `600 – 839`     | Tablet/foldable portrait       |
/// | [expanded]   | `840 – 1199`    | Tablet landscape, small desktop|
/// | [large]      | `1200 – 1599`   | Desktop                        |
/// | [extraLarge] | `1600+`         | Large/ultra-wide desktop       |
///
/// Boundaries are half-open: the lower bound is inclusive and the upper bound
/// is exclusive (e.g. a width of exactly `600` is [medium], not [compact]).
///
/// See also:
/// * <https://m3.material.io/foundations/layout/applying-layout/window-size-classes>
enum WindowSizeClass {
  /// Width `< 600dp`. A single pane with a bottom navigation bar.
  compact,

  /// Width `600 – 839dp`. The first adaptation point; a navigation rail.
  medium,

  /// Width `840 – 1199dp`. Two side-by-side panes become viable.
  expanded,

  /// Width `1200 – 1599dp`. Desktop; an expanded rail or standard drawer.
  large,

  /// Width `>= 1600dp`. Large desktop; up to three panes.
  extraLarge;

  /// Whether this class is exactly [WindowSizeClass.compact].
  bool get isCompact => this == compact;

  /// Whether this class is exactly [WindowSizeClass.medium].
  bool get isMedium => this == medium;

  /// Whether this class is exactly [WindowSizeClass.expanded].
  bool get isExpanded => this == expanded;

  /// Whether this class is exactly [WindowSizeClass.large].
  bool get isLarge => this == large;

  /// Whether this class is exactly [WindowSizeClass.extraLarge].
  bool get isExtraLarge => this == extraLarge;

  /// Whether this is [compact] or [medium] — the single-pane, touch-first
  /// range where Material recommends one pane at a time.
  bool get isCompactOrMedium => index <= medium.index;

  /// Whether this is [expanded] or wider — where multi-pane canonical layouts
  /// and a navigation rail/drawer are recommended.
  bool get isExpandedOrWider => index >= expanded.index;

  /// Whether this class is at least as wide as [other] (inclusive).
  ///
  /// ```dart
  /// WindowSizeClass.large.isAtLeast(WindowSizeClass.expanded); // true
  /// WindowSizeClass.medium.isAtLeast(WindowSizeClass.expanded); // false
  /// ```
  bool isAtLeast(WindowSizeClass other) => index >= other.index;

  /// Whether this class is at most as wide as [other] (inclusive).
  bool isAtMost(WindowSizeClass other) => index <= other.index;
}

/// Material 3 window **height** size classes.
///
/// Height is rarely the primary layout driver (most content scrolls
/// vertically), but a [compact] height — e.g. a phone in landscape — should
/// still surface a bottom navigation bar rather than a tall rail.
///
/// Height ranges with the default breakpoints ([Breakpoints.material]):
///
/// | Class      | Height (dp)   |
/// | ---------- | ------------- |
/// | [compact]  | `0 – 479`     |
/// | [medium]   | `480 – 899`   |
/// | [expanded] | `900+`        |
enum WindowHeightSizeClass {
  /// Height `< 480dp`, e.g. a phone in landscape.
  compact,

  /// Height `480 – 899dp`.
  medium,

  /// Height `>= 900dp`.
  expanded;

  /// Whether this class is exactly [WindowHeightSizeClass.compact].
  bool get isCompact => this == compact;

  /// Whether this class is exactly [WindowHeightSizeClass.medium].
  bool get isMedium => this == medium;

  /// Whether this class is exactly [WindowHeightSizeClass.expanded].
  bool get isExpanded => this == expanded;

  /// Whether this class is at least as tall as [other] (inclusive).
  bool isAtLeast(WindowHeightSizeClass other) => index >= other.index;
}
