// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

class _German extends DefaultMaterialLayoutLocalizations {
  const new();

  @override
  String get sideSheetLabel => 'Seitenblatt';
}

class _GermanDelegate
    extends LocalizationsDelegate<MaterialLayoutLocalizations> {
  const new();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'de';

  @override
  Future<MaterialLayoutLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLayoutLocalizations>(const _German());

  @override
  bool shouldReload(_GermanDelegate old) => false;
}

void main() {
  testWidgets("an app's own translation comes before them", (tester) async {
    late MaterialLayoutLocalizations strings;
    Widget app(Locale locale) => Localizations(
      locale: locale,
      delegates: const [
        _GermanDelegate(),
        MaterialLayoutLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Builder(
        builder: (context) {
          strings = MaterialLayoutLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(app(const Locale('de')));
    expect(strings.sideSheetLabel, 'Seitenblatt');
    await tester.pumpWidget(app(const Locale('fr')));
    expect(strings.sideSheetLabel, 'Side sheet');
  });
}
