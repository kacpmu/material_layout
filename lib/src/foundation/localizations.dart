// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The strings this package shows or announces.
///
/// They are read from the ambient [Localizations], and fall back to English
/// when the app supplies none. To translate them, implement this interface —
/// or extend [DefaultMaterialLayoutLocalizations] — and add a delegate for it
/// to the app's `localizationsDelegates`.
abstract interface class MaterialLayoutLocalizations {
  /// The strings for [context], or English when the app supplies none.
  static MaterialLayoutLocalizations of(BuildContext context) =>
      Localizations.of<MaterialLayoutLocalizations>(
        context,
        MaterialLayoutLocalizations,
      ) ??
      const DefaultMaterialLayoutLocalizations();

  /// A delegate that loads [DefaultMaterialLayoutLocalizations], the English
  /// strings, for every locale.
  ///
  /// It stands in wherever the app has no translation, so it supports every
  /// locale the app does. List the app's own delegates for these strings
  /// before it: the first delegate that supports a locale supplies them.
  static const LocalizationsDelegate<MaterialLayoutLocalizations> delegate =
      _MaterialLayoutLocalizationsDelegate();

  /// The accessibility label of the control that resizes panes.
  String get paneResizerLabel;

  /// The accessibility value of the control that resizes panes: the share of
  /// the space, as a whole percentage, that the resizable pane occupies.
  String paneResizerValue(int percent);

  /// The action that hides the resizable pane.
  String get collapsePaneAction;

  /// The action that returns to the default split, showing a collapsed pane
  /// again.
  String get restorePaneAction;

  /// The action that widens the resizable pane to fill the space, hiding the
  /// other pane.
  String get expandPaneAction;

  /// The action that divides the space evenly between two panes.
  String get splitPanesEvenlyAction;

  /// The action that sets the resizable pane to [width] logical pixels.
  String setPaneWidthAction(int width);

  /// The action that dismisses a pane that can be closed.
  String get closePaneAction;

  /// The announcement made when the resizable pane is hidden.
  String get paneCollapsedAnnouncement;

  /// The announcement made when the resizable pane fills the space.
  String get paneExpandedAnnouncement;

  /// The accessibility label of a side sheet.
  String get sideSheetLabel;
}

/// The English strings of [MaterialLayoutLocalizations].
class DefaultMaterialLayoutLocalizations
    implements MaterialLayoutLocalizations {
  /// Creates the English strings.
  const new();

  @override
  String get paneResizerLabel => 'Resize panes';

  @override
  String paneResizerValue(int percent) => '$percent%';

  @override
  String get collapsePaneAction => 'Collapse pane';

  @override
  String get restorePaneAction => 'Restore pane';

  @override
  String get expandPaneAction => 'Expand pane to full width';

  @override
  String get splitPanesEvenlyAction => 'Split panes evenly';

  @override
  String setPaneWidthAction(int width) => 'Set pane width to $width';

  @override
  String get closePaneAction => 'Close pane';

  @override
  String get paneCollapsedAnnouncement => 'Pane collapsed';

  @override
  String get paneExpandedAnnouncement => 'Pane expanded to full width';

  @override
  String get sideSheetLabel => 'Side sheet';
}

class _MaterialLayoutLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLayoutLocalizations> {
  const new();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLayoutLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLayoutLocalizations>(
        const DefaultMaterialLayoutLocalizations(),
      );

  @override
  bool shouldReload(_MaterialLayoutLocalizationsDelegate old) => false;
}
