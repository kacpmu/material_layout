// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A widget that keeps the lines of the text inside it to a readable length.
///
/// Material asks for lines of 40 to 60 characters. The limit is a measure in
/// characters, not a width in dp: it is the width of [characters]
/// characters of running text in [style], so it follows the type scale and
/// the platform's text scaling. The child is no wider than that, and
/// narrower when the space is.
///
/// ```dart
/// LineLength(
///   style: theme.textTheme.bodyLarge,
///   child: Text(article.body, style: theme.textTheme.bodyLarge),
/// )
/// ```
class LineLength extends StatelessWidget {
  /// Limits [child] to lines of [characters] characters.
  const new({
    super.key,
    this.characters = 60,
    this.style,
    this.alignment = AlignmentDirectional.topStart,
    required this.child,
  }) : assert(characters > 0);

  /// The most characters a line may hold. 60 by default, the longest line
  /// Material recommends.
  final int characters;

  /// The text style to measure in, or null for the ambient
  /// [DefaultTextStyle].
  final TextStyle? style;

  /// Where the child sits in the space when that space is wider than the
  /// limit.
  final AlignmentGeometry alignment;

  /// The widget below this widget in the tree.
  final Widget child;

  // Running English text, so that the measure reflects the mix of narrow and
  // wide letters and spaces in a line rather than one letter's width.
  static const _sample = 'the quick brown fox jumps over the lazy dog ';

  /// The width of [characters] characters of running text in [style], at
  /// [textScaler].
  static double widthOf(
    int characters,
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final text = List.filled(
      characters ~/ _sample.length + 1,
      _sample,
    ).join().substring(0, characters);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final measured = widthOf(
      characters,
      DefaultTextStyle.of(context).style.merge(style),
      textScaler: MediaQuery.textScalerOf(context),
    );
    return Align(
      alignment: alignment,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: measured),
        child: child,
      ),
    );
  }
}
