// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_ui/material_ui.dart';

/// An article in the demo's reader and feed.
@immutable
class Article {
  const new({
    required this.id,
    required this.title,
    required this.author,
    required this.topic,
    required this.minutes,
    required this.paragraphs,
    required this.hue,
  });

  final int id;
  final String title;
  final String author;
  final String topic;
  final int minutes;
  final List<String> paragraphs;

  /// The hue of the article's illustration, in degrees.
  final double hue;

  String get summary => paragraphs.first;

  Color color(Brightness brightness) => HSLColor.fromAHSL(
    1,
    hue,
    0.45,
    brightness == Brightness.light ? 0.78 : 0.32,
  ).toColor();
}

const articles = [
  Article(
    id: 1,
    title: 'Designing for every window',
    author: 'Priya Raman',
    topic: 'Design',
    minutes: 6,
    hue: 210,
    paragraphs: [
      'A window is not a device. The same phone becomes a small tablet when '
          'it unfolds, and a desktop window can be any width its user drags '
          'it to. Layouts that follow the space they are given, rather than '
          'the hardware they run on, keep working as that space changes.',
      'Material divides widths at five breakpoints: compact, medium, '
          'expanded, large and extra-large. Each breakpoint comes with '
          'defaults for margins, for the number of panes, and for where '
          'navigation sits.',
      'At compact there is room for one pane, and navigation belongs at the '
          'bottom, where a thumb can reach it. At medium a navigation rail '
          'moves to the leading edge. From expanded upwards two panes sit '
          'side by side, a fixed pane beside a flexible one.',
      'Breakpoints are resolved against the region a layout occupies, not '
          'the whole window. A layout nested in a pane adapts to the pane.',
    ],
  ),
  Article(
    id: 2,
    title: 'Panes, spacers and margins',
    author: 'Tomas Berg',
    topic: 'Layout',
    minutes: 4,
    hue: 150,
    paragraphs: [
      'Every piece of content lives in a pane. A fixed pane keeps its width; '
          'a flexible pane grows and shrinks with the window. A layout always '
          'has at least one flexible pane, and never more than three panes.',
      'Between panes sits a 24dp spacer, which holds the drag handle when '
          'the panes can be resized. Margins keep the panes 16dp from the '
          'edges of a compact window and 24dp from anything wider.',
      'The fixed pane is 360dp wide at expanded and 412dp at large. A side '
          'sheet used as a pane stops at 400dp.',
    ],
  ),
  Article(
    id: 3,
    title: 'When the list meets the detail',
    author: 'Aiko Tanaka',
    topic: 'Patterns',
    minutes: 5,
    hue: 20,
    paragraphs: [
      'The list-detail layout shows a collection beside the item selected '
          'from it. With one pane, the detail replaces the list and brings a '
          'back button; with two, the list marks the selected item.',
      'Widening the window with an item selected shows both panes; narrowing '
          'it shows the detail. Resizing never loses the selection or the '
          'scroll position of the detail.',
    ],
  ),
  Article(
    id: 4,
    title: 'Motion that settles',
    author: 'Marcus Webb',
    topic: 'Motion',
    minutes: 3,
    hue: 280,
    paragraphs: [
      'Material motion runs on springs. A spring does not have a duration; '
          'it has a stiffness and a damping ratio, and it settles when its '
          'energy is spent.',
      'The expressive scheme overshoots slightly. The standard scheme is '
          'close to critically damped. Both slow down to nothing when the '
          'platform asks for reduced motion.',
    ],
  ),
  Article(
    id: 5,
    title: 'Folds and hinges',
    author: 'Lucia Ferreira',
    topic: 'Devices',
    minutes: 4,
    hue: 45,
    paragraphs: [
      'A foldable reports its fold as a display feature. A flat fold does '
          'not separate content, but a half-open fold or a physical hinge '
          'does, and panes should sit on either side of it.',
      'In tabletop posture the supporting pane moves below the fold.',
    ],
  ),
  Article(
    id: 6,
    title: 'Right to left',
    author: 'Omar Haddad',
    topic: 'Localisation',
    minutes: 3,
    hue: 330,
    paragraphs: [
      'Layouts mirror in right-to-left languages: the navigation rail moves '
          'to the right, the list-detail list moves to the right, and side '
          'sheets open from the left.',
      'Some things never mirror: clocks, media controls and charts keep '
          'their direction.',
    ],
  ),
  Article(
    id: 7,
    title: 'A feed that reflows',
    author: 'Sara Lindgren',
    topic: 'Patterns',
    minutes: 2,
    hue: 100,
    paragraphs: [
      'A feed is a single column at compact. As the window widens, columns '
          'are added, and the items reflow in order.',
      'Items need not share a size: a featured story can span two columns.',
    ],
  ),
  Article(
    id: 8,
    title: 'Sheets at the edge',
    author: 'Daniel Kim',
    topic: 'Components',
    minutes: 3,
    hue: 250,
    paragraphs: [
      'A side sheet sits on the trailing edge. As a standard sheet it is a '
          'pane: the content beside it shrinks to make room. As a modal sheet '
          'it covers the content and blocks it until it is closed.',
      'Below expanded, a bottom sheet carries the same content.',
    ],
  ),
];
