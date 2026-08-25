/// Sample content for the demo: a small mail/reader corpus.
///
/// No package APIs here — just the data the screens render.
class DemoItem {
  const DemoItem({
    required this.id,
    required this.sender,
    required this.subject,
    required this.sentAt,
    required this.preview,
    required this.body,
  });

  final int id;
  final String sender;
  final String subject;

  /// When the message arrived. Shown beside the sender in the detail pane and
  /// as the trailing stamp on each list tile.
  final DateTime sentAt;

  /// The one-line summary shown under the subject in the list.
  final String preview;

  final String body;
}

/// Newest first, the way an inbox is ordered.
///
/// Not `const`: [DemoItem.sentAt] is a [DateTime], which has no const
/// constructor.
final List<DemoItem> demoItems = [
  DemoItem(
    id: 1,
    sender: 'Ada Lovelace',
    subject: 'Analytical Engine notes',
    sentAt: DateTime(2026, 8, 24, 9, 12),
    preview: 'I have completed the notes on the Analytical Engine.',
    body: 'I have completed the notes on the Analytical Engine. Note G '
        'contains the algorithm for computing Bernoulli numbers, worked '
        'through in full so that the machine\'s operations can be followed '
        'step by step. The engine might act upon things besides number, '
        'were objects found whose mutual relations could be expressed by '
        'the abstract science of operations. It could compose elaborate '
        'pieces of music of any degree of complexity.',
  ),
  DemoItem(
    id: 2,
    sender: 'Grace Hopper',
    subject: 'Found a bug (literally)',
    sentAt: DateTime(2026, 8, 24, 8, 3),
    preview: 'The Mark II stopped again this morning and it took us most of an '
        'hour to find the cause.',
    body: 'The Mark II stopped again this morning and it took us most of an '
        'hour to find the cause. It was a moth, trapped in relay 70 of '
        'panel F. I have taped it into the logbook with the time it was '
        'found, so from now on, when the machine misbehaves, we are quite '
        'literally debugging it.',
  ),
  DemoItem(
    id: 3,
    sender: 'Alan Turing',
    subject: 'On computable numbers',
    sentAt: DateTime(2026, 8, 23, 17, 41),
    preview: 'The paper is ready for your comments.',
    body: 'The paper is ready for your comments. The machine I describe need '
        'not be complicated: a tape, a head, and a table of behaviour are '
        'enough to compute anything that can be computed at all. What '
        'matters is the negative result — some numbers cannot be computed '
        'by any such machine, and no cleverness of engineering will change '
        'that.',
  ),
  DemoItem(
    id: 4,
    sender: 'Katherine Johnson',
    subject: 'Trajectory verification',
    sentAt: DateTime(2026, 8, 23, 14, 20),
    preview: 'He would not fly until I had checked the figures myself, so I ran '
        'the whole re-entry by hand.',
    body: 'He would not fly until I had checked the figures myself, so I ran '
        'the whole re-entry by hand. They agree with the machine to the '
        'fifth decimal place. Tell him the capsule will come down where we '
        'said it would, and that the arithmetic does not care who does it.',
  ),
  DemoItem(
    id: 5,
    sender: 'Margaret Hamilton',
    subject: 'Priority displays saved the landing',
    sentAt: DateTime(2026, 8, 23, 11, 7),
    preview: 'The 1202 alarms during descent were the computer telling us it was '
        'overloaded with rendezvous radar data it did not need.',
    body: 'The 1202 alarms during descent were the computer telling us it was '
        'overloaded with rendezvous radar data it did not need. Because the '
        'software knew which tasks mattered, it shed the rest and kept the '
        'landing programs running. The alarm was not a failure; it was the '
        'design working exactly as intended.',
  ),
  DemoItem(
    id: 6,
    sender: 'Dennis Ritchie',
    subject: 'C and Unix update',
    sentAt: DateTime(2026, 8, 22, 16, 55),
    preview: 'The language is small enough to fit in one head and close enough '
        'to the machine to stay fast, which is the whole trick.',
    body: 'The language is small enough to fit in one head and close enough '
        'to the machine to stay fast, which is the whole trick. We have '
        'rewritten the kernel in it, which we are told is either brave or '
        'foolish. It compiles, it boots, and it is a great deal easier to '
        'move to another machine than assembler ever was.',
  ),
  DemoItem(
    id: 7,
    sender: 'Barbara Liskov',
    subject: 'Substitution principle draft',
    sentAt: DateTime(2026, 8, 22, 10, 38),
    preview: 'Here is the draft.',
    body: 'Here is the draft. What is wanted is a substitution property: if S '
        'is a subtype of T, then objects of type T may be replaced with '
        'objects of type S without altering any of the desirable properties '
        'of the program. Inheritance that violates this is not abstraction '
        '— it is a trap laid for whoever maintains the code next.',
  ),
  DemoItem(
    id: 8,
    sender: 'Tim Berners-Lee',
    subject: 'A proposal: the Web',
    sentAt: DateTime(2026, 8, 21, 15, 12),
    preview: 'The proposal is for a linked information system, so that a reader '
        'can move from one document to another without knowing or caring '
        'where either one lives.',
    body: 'The proposal is for a linked information system, so that a reader '
        'can move from one document to another without knowing or caring '
        'where either one lives. Universality is the entire point: a web '
        'that only works inside one building, or one vendor\'s software, is '
        'not a web at all.',
  ),
  DemoItem(
    id: 9,
    sender: 'Donald Knuth',
    subject: 'Volume 4 is taking a while',
    sentAt: DateTime(2026, 8, 21, 9, 44),
    preview: 'Volume 4 has grown into several fascicles, because combinatorial '
        'algorithms refuse to be brief and I refuse to hand-wave.',
    body: 'Volume 4 has grown into several fascicles, because combinatorial '
        'algorithms refuse to be brief and I refuse to hand-wave. I would '
        'rather be late and right than prompt and approximate. In the '
        'meantime the exercises are numbered by difficulty, and I have paid '
        'out rather more reward cheques than I expected.',
  ),
  DemoItem(
    id: 10,
    sender: 'Edsger Dijkstra',
    subject: 'A case against the goto',
    sentAt: DateTime(2026, 8, 20, 13, 29),
    preview: 'My thesis is that the go to statement should be abolished from all '
        'higher level programming languages.',
    body: 'My thesis is that the go to statement should be abolished from all '
        'higher level programming languages. The quality of programmers is '
        'a decreasing function of the density of go to statements in the '
        'programs they produce. Our powers to visualise processes evolving '
        'in time are poorly developed; we should not squander them.',
  ),
  DemoItem(
    id: 11,
    sender: 'Claude Shannon',
    subject: 'A mathematical theory of communication',
    sentAt: DateTime(2026, 8, 20, 8, 15),
    preview: 'The fundamental problem of communication is that of reproducing at '
        'one point, either exactly or approximately, a message selected at '
        'another point.',
    body: 'The fundamental problem of communication is that of reproducing at '
        'one point, either exactly or approximately, a message selected at '
        'another point. The semantic aspects are irrelevant to the '
        'engineering problem. Once you measure information in bits, noise '
        'stops being a nuisance and becomes something you can budget for.',
  ),
  DemoItem(
    id: 12,
    sender: 'John von Neumann',
    subject: 'Storing the program as data',
    sentAt: DateTime(2026, 8, 19, 18, 2),
    preview: 'If the instructions live in the same memory as the data they act '
        'upon, then a machine can read and even modify its own programme.',
    body: 'If the instructions live in the same memory as the data they act '
        'upon, then a machine can read and even modify its own programme. '
        'One store, one addressing scheme, and the machine stops being a '
        'fixed calculator and becomes something we can point at any problem '
        'we can describe.',
  ),
  DemoItem(
    id: 13,
    sender: 'Hedy Lamarr',
    subject: 'Frequency hopping for secure signals',
    sentAt: DateTime(2026, 8, 19, 12, 47),
    preview: 'If the transmitter and the receiver change frequency together on a '
        'shared schedule, a jammer cannot follow them and a listener hears '
        'only fragments.',
    body: 'If the transmitter and the receiver change frequency together on a '
        'shared schedule, a jammer cannot follow them and a listener hears '
        'only fragments. The piano roll suggested the mechanism to us: '
        'eighty-eight frequencies, changed in step. The patent is filed; '
        'whether the Navy reads it is another matter.',
  ),
  DemoItem(
    id: 14,
    sender: 'Vint Cerf',
    subject: 'A protocol for interconnecting networks',
    sentAt: DateTime(2026, 8, 18, 16, 30),
    preview: 'The trick is not to make the networks the same, but to let them '
        'stay different.',
    body: 'The trick is not to make the networks the same, but to let them '
        'stay different. A common protocol at the gateway is enough, '
        'provided every network agrees on how a packet is addressed and who '
        'is responsible when one goes missing. Keep the middle simple and '
        'let the edges be clever.',
  ),
  DemoItem(
    id: 15,
    sender: 'Radia Perlman',
    subject: 'Spanning tree keeps the bridges sane',
    sentAt: DateTime(2026, 8, 18, 10, 11),
    preview: 'Bridges that forward everything will happily forward it forever, '
        'and one loop takes down the whole network.',
    body: 'Bridges that forward everything will happily forward it forever, '
        'and one loop takes down the whole network. Compute a spanning '
        'tree, disable the redundant links, and keep them ready for the '
        'moment the topology changes. The algorithm fits on the back of an '
        'envelope, which is rather the point.',
  ),
  DemoItem(
    id: 16,
    sender: 'Linus Torvalds',
    subject: 'Doing a (free) operating system',
    sentAt: DateTime(2026, 8, 17, 20, 58),
    preview: 'I\'m doing a free operating system — just a hobby, won\'t be big '
        'and professional like GNU — for 386 AT clones.',
    body: 'I\'m doing a free operating system — just a hobby, won\'t be big '
        'and professional like GNU — for 386 AT clones. It has been brewing '
        'since April and has finally reached the stage where it is even '
        'usable. I\'d like any feedback on things people like or dislike, '
        'and on what features you would want.',
  ),
];

DemoItem demoItemById(Object id) =>
    demoItems.firstWhere((e) => e.id == id, orElse: () => demoItems.first);

/// A longer-form article used by the supporting-pane screen.
const String demoArticleTitle = 'The people who built computing';
const String demoArticleKicker = 'A short, opinionated history';
const String demoArticleBody =
    'Modern computing was not the work of one person but of many, each solving '
    'a piece of a puzzle that none of them could see in full.\n\n'
    'Ada Lovelace, working with Charles Babbage\'s designs, saw that a machine '
    'for manipulating numbers could in principle manipulate anything that could '
    'be represented by numbers — music, symbols, ideas. A century before the '
    'first electronic computer, she had glimpsed the general-purpose machine.\n\n'
    'When electronics finally caught up, the problems became practical: a moth '
    'in a relay, a memory unit the size of a wardrobe, a guidance computer that '
    'had to keep flying even as it ran out of room to think. The people who '
    'solved them — Hopper, Hamilton, Johnson, and many more — turned '
    'mathematics into engineering and engineering into something we now carry '
    'in a pocket.\n\n'
    'The story is still being written. Every layout that reflows to fit a new '
    'screen is a small continuation of the same idea: that a machine should '
    'adapt to the person using it, and not the other way around.';
