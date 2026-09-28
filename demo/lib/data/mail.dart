// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:material_ui/material_ui.dart';

/// A message in the demo inbox.
@immutable
class Message {
  const new({
    required this.id,
    required this.sender,
    required this.address,
    required this.subject,
    required this.body,
    required this.received,
    this.labels = const [],
  });

  final int id;
  final String sender;
  final String address;
  final String subject;
  final List<String> body;
  final String received;
  final List<String> labels;

  String get preview => body.first;

  String get initials =>
      sender.split(' ').take(2).map((word) => word[0]).join();
}

/// The inbox, and which messages have been read.
///
/// Read state lives here, outside the layout, so that it survives moving
/// between messages and between one and two panes.
class MailStore extends ChangeNotifier {
  final _read = <int>{2, 5, 6, 9, 11};

  List<Message> get messages => _messages;

  Message byId(int id) => _messages.firstWhere((message) => message.id == id);

  bool isRead(int id) => _read.contains(id);

  void markRead(int id) {
    if (_read.add(id)) notifyListeners();
  }
}

const _messages = [
  Message(
    id: 1,
    sender: 'Ada Okafor',
    address: 'ada@example.com',
    subject: 'Layout review on Thursday',
    received: '09:41',
    labels: ['Work'],
    body: [
      'Can we walk through the new pane layout on Thursday? I would like to '
          'see the list and the detail side by side on the large display.',
      'Bring the foldable if you still have it. The hinge case is the one '
          'I want to understand: whether the spacer lands on the fold, and '
          'what happens to the drag handle there.',
      'I have booked the small meeting room from two until three.',
    ],
  ),
  Message(
    id: 2,
    sender: 'Bruno Lindqvist',
    address: 'bruno@example.com',
    subject: 'Photos from the trip',
    received: '08:15',
    labels: ['Personal'],
    body: [
      'The photos from the coast are up. The ones from the lighthouse came '
          'out better than I expected, given the wind.',
      'I sorted them by day. The last album is mostly the ferry back.',
    ],
  ),
  Message(
    id: 3,
    sender: 'Chen Wei',
    address: 'chen@example.com',
    subject: 'Draft of the accessibility notes',
    received: 'Yesterday',
    labels: ['Work'],
    body: [
      'Here is the first draft of the accessibility notes for the release.',
      'Focus order now follows the panes as they appear on screen, and the '
          'drag handle can be moved with the arrow keys. Screen readers '
          'announce it as a slider, with an action for each stop.',
      'Could you check the right-to-left section? I am not sure the wording '
          'about mirrored icons is right.',
    ],
  ),
  Message(
    id: 4,
    sender: 'Dana Moreau',
    address: 'dana@example.com',
    subject: 'Lunch next week?',
    received: 'Yesterday',
    body: [
      'Are you free for lunch next week? Tuesday or Wednesday works for me.',
      'There is a new place near the station that does good soup.',
    ],
  ),
  Message(
    id: 5,
    sender: 'Emeka Nwosu',
    address: 'emeka@example.com',
    subject: 'Invoice for September',
    received: 'Mon',
    labels: ['Finance'],
    body: [
      'Please find the invoice for September attached.',
      'Payment terms are thirty days, as before. Let me know if anything '
          'looks wrong.',
    ],
  ),
  Message(
    id: 6,
    sender: 'Farah Haddad',
    address: 'farah@example.com',
    subject: 'Reading list',
    received: 'Mon',
    labels: ['Personal'],
    body: [
      'You asked for the reading list from the workshop. The first three '
          'are the ones most people found useful.',
      'The book on typography is long, but the chapters stand on their own.',
    ],
  ),
  Message(
    id: 7,
    sender: 'Gustavo Pereira',
    address: 'gustavo@example.com',
    subject: 'Release checklist',
    received: 'Sun',
    labels: ['Work'],
    body: [
      'The release checklist is ready for review.',
      'Formatting, analysis and tests pass on the branch, with leak tracking '
          'on. The downgrade check still needs a run against the oldest '
          'supported versions.',
      'Once that is green I will tag the release.',
    ],
  ),
  Message(
    id: 8,
    sender: 'Hana Sato',
    address: 'hana@example.com',
    subject: 'Tickets for Saturday',
    received: 'Sat',
    body: [
      'I have two spare tickets for the concert on Saturday. Would you like '
          'them?',
    ],
  ),
  Message(
    id: 9,
    sender: 'Ivan Petrov',
    address: 'ivan@example.com',
    subject: 'Updated floor plan',
    received: 'Fri',
    labels: ['Work'],
    body: [
      'The updated floor plan for the third floor is attached. Desks move on '
          'the first of the month.',
    ],
  ),
  Message(
    id: 10,
    sender: 'Julia Novak',
    address: 'julia@example.com',
    subject: 'Recipe you asked about',
    received: 'Fri',
    labels: ['Personal'],
    body: [
      'Here is the recipe. The trick is to let the dough rest overnight.',
      'Use less sugar than it says; the fruit is sweet enough.',
    ],
  ),
  Message(
    id: 11,
    sender: 'Kofi Mensah',
    address: 'kofi@example.com',
    subject: 'Workshop feedback',
    received: 'Thu',
    labels: ['Work'],
    body: [
      'Thanks for running the workshop. The section on breakpoints was the '
          'clearest explanation I have seen.',
      'One request for next time: more time on the supporting pane layout.',
    ],
  ),
  Message(
    id: 12,
    sender: 'Lena Fischer',
    address: 'lena@example.com',
    subject: 'Garden allotment',
    received: 'Thu',
    body: [
      'The allotment committee meets on Sunday. We need to decide what to '
          'plant along the east fence.',
    ],
  ),
  Message(
    id: 13,
    sender: 'Mateo Ruiz',
    address: 'mateo@example.com',
    subject: 'Bike repair',
    received: 'Wed',
    labels: ['Personal'],
    body: ['Your bike is ready. The chain needed replacing as well.'],
  ),
  Message(
    id: 14,
    sender: 'Nadia Karim',
    address: 'nadia@example.com',
    subject: 'Quarterly report',
    received: 'Wed',
    labels: ['Finance'],
    body: [
      'The quarterly report is due on Friday. I have filled in the first '
          'two sections.',
      'Could you add the figures for the design team?',
    ],
  ),
];
