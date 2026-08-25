import 'window_size_class.dart';

/// Selects a value for the current [sizeClass], falling back to the
/// nearest-smaller provided value.
///
/// Only [compact] is required; any omitted class resolves down the chain
/// (extraLarge → large → expanded → medium → compact). This makes it easy to
/// specify a value only at the breakpoints where it changes:
///
/// ```dart
/// final columns = adaptiveValue<int>(
///   context.windowSizeClass,
///   compact: 1,
///   medium: 2,
///   expanded: 3,
///   // large & extraLarge inherit 3
/// );
/// ```
T adaptiveValue<T>(
  WindowSizeClass sizeClass, {
  required T compact,
  T? medium,
  T? expanded,
  T? large,
  T? extraLarge,
}) {
  return switch (sizeClass) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium ?? compact,
    WindowSizeClass.expanded => expanded ?? medium ?? compact,
    WindowSizeClass.large => large ?? expanded ?? medium ?? compact,
    WindowSizeClass.extraLarge =>
      extraLarge ?? large ?? expanded ?? medium ?? compact,
  };
}
