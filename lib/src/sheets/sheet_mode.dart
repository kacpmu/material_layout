/// Whether a sheet is **standard** (persistent, coexists with content, no
/// scrim) or **modal** (temporary, blocks content behind a scrim).
enum SheetMode {
  /// Persistent; coexists with the underlying content (no scrim).
  standard,

  /// Temporary; appears over content behind a scrim and is dismissed after use.
  modal,
}
