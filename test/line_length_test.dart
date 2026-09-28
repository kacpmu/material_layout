// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  const style = TextStyle(fontSize: 16);
  final text = 'word ' * 200;

  Widget host({double scale = 1, double width = 1200}) => MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: LineLength(
            style: style,
            child: Text(text, key: const ValueKey('text'), style: style),
          ),
        ),
      ),
    ),
  );

  // The characters on each line the text is laid out in.
  List<int> lineLengths(WidgetTester tester) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const ValueKey('text')),
    );
    // The text broken as the paragraph breaks it, at the paragraph's width.
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    final plain = paragraph.text.toPlainText();
    final lengths = <int>[];
    var offset = 0;
    while (offset < plain.length) {
      final line = painter.getLineBoundary(TextPosition(offset: offset));
      lengths.add(plain.substring(line.start, line.end).trimRight().length);
      if (line.end <= offset) break;
      offset = line.end;
    }
    painter.dispose();
    return lengths;
  }

  testWidgets('lines hold at most 60 characters', (tester) async {
    setWindowSize(tester, const Size(2000, 800));
    await tester.pumpWidget(host());
    final width = tester.getSize(find.byKey(const ValueKey('text'))).width;
    expect(width, LineLength.widthOf(60, style));
    expect(width, lessThan(1200));
    // Counted in the text as laid out: twelve words of five characters,
    // less the last space, fill a line of 60.
    final lengths = lineLengths(tester);
    expect(lengths.first, 59);
    expect(lengths, everyElement(lessThanOrEqualTo(60)));
  });

  testWidgets('holds the number of characters it is given, in the ambient '
      'text style', (tester) async {
    setWindowSize(tester, const Size(2000, 800));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: style,
          child: Align(
            alignment: Alignment.topLeft,
            child: LineLength(
              characters: 40,
              child: Text(text, key: const ValueKey('text')),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('text'))).width,
      LineLength.widthOf(40, style),
    );
    // Eight words, less the last space.
    expect(lineLengths(tester).first, 39);
    expect(lineLengths(tester), everyElement(lessThanOrEqualTo(40)));
  });

  testWidgets('the measure follows the text scale', (tester) async {
    setWindowSize(tester, const Size(2000, 800));
    await tester.pumpWidget(host(width: 2000));
    final normal = tester.getSize(find.byKey(const ValueKey('text'))).width;
    await tester.pumpWidget(host(scale: 1.5, width: 2000));
    final scaled = tester.getSize(find.byKey(const ValueKey('text'))).width;
    expect(scaled, closeTo(normal * 1.5, 1));
  });

  testWidgets('a narrower space wins', (tester) async {
    await tester.pumpWidget(host(width: 200));
    expect(tester.getSize(find.byKey(const ValueKey('text'))).width, 200);
  });

  testWidgets('it sits at the start of a wider space, mirrored in '
      'right-to-left', (tester) async {
    setWindowSize(tester, const Size(1200, 800));
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: LineLength(
            style: style,
            child: Text(text, key: const ValueKey('text'), style: style),
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const ValueKey('text')));
      if (direction == TextDirection.ltr) {
        expect(rect.left, 0);
      } else {
        expect(rect.right, 1200);
      }
      expect(rect.top, 0);
    }
  });
}
