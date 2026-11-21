import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

/// Keys of the toy piano: white keys C4 .. C6 (15 keys).
const kPianoNotes = ['c4', 'd4', 'e4', 'f4', 'g4', 'a4', 'b4', 'c5', 'd5', 'e5', 'f5', 'g5', 'a5', 'b5', 'c6'];
const kSolfege = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'];

/// Public-domain children's melodies (traditional / folk).
/// (en title, tr title, notes, phrase lengths)
const List<(String, String, String, List<int>)> kMelodies = [
  (
    'Twinkle Twinkle Little Star',
    'Parla Parla Küçük Yıldız',
    'c4 c4 g4 g4 a4 a4 g4 f4 f4 e4 e4 d4 d4 c4 g4 g4 f4 f4 e4 e4 d4 g4 g4 f4 f4 e4 e4 d4 c4 c4 g4 g4 a4 a4 g4 f4 f4 e4 e4 d4 d4 c4',
    [7, 7, 7, 7, 7, 7],
  ),
  (
    'Mary Had a Little Lamb',
    'Mary\'nin Kuzusu',
    'e4 d4 c4 d4 e4 e4 e4 d4 d4 d4 e4 g4 g4 e4 d4 c4 d4 e4 e4 e4 e4 d4 d4 e4 d4 c4',
    [7, 3, 3, 7, 6],
  ),
  (
    'Ode to Joy',
    'Neşeye Övgü',
    'e4 e4 f4 g4 g4 f4 e4 d4 c4 c4 d4 e4 e4 d4 d4 e4 e4 f4 g4 g4 f4 e4 d4 c4 c4 d4 e4 d4 c4 c4',
    [8, 7, 8, 7],
  ),
  (
    'Frère Jacques',
    'Tembel Çocuk',
    'c5 d5 e5 c5 c5 d5 e5 c5 e5 f5 g5 e5 f5 g5 g5 a5 g5 f5 e5 c5 g5 a5 g5 f5 e5 c5 c5 g4 c5 c5 g4 c5',
    [4, 4, 3, 3, 6, 6, 3, 3],
  ),
  (
    'Row, Row, Row Your Boat',
    'Kayığını Kürekle',
    'c4 c4 c4 d4 e4 e4 d4 e4 f4 g4 c5 c5 c5 g4 g4 g4 e4 e4 e4 c4 c4 c4 g4 f4 e4 d4 c4',
    [5, 5, 12, 5],
  ),
  (
    'London Bridge',
    'Londra Köprüsü',
    'g4 a4 g4 f4 e4 f4 g4 d4 e4 f4 e4 f4 g4 g4 a4 g4 f4 e4 f4 g4 d4 g4 e4 c4',
    [7, 3, 3, 7, 4],
  ),
  (
    'Old MacDonald',
    'Yaşlı MacDonald\'ın Çiftliği',
    'c5 c5 c5 g4 a4 a4 g4 e5 e5 d5 d5 c5 g4 c5 c5 c5 g4 a4 a4 g4 e5 e5 d5 d5 c5',
    [7, 5, 8, 5],
  ),
  ('Hot Cross Buns', 'Sıcak Çörekler', 'e4 d4 c4 e4 d4 c4 c4 c4 c4 c4 d4 d4 d4 d4 e4 d4 c4', [3, 3, 4, 4, 3]),
  (
    'Jingle Bells',
    'Çan Sesleri',
    'e4 e4 e4 e4 e4 e4 e4 g4 c4 d4 e4 f4 f4 f4 f4 f4 e4 e4 e4 e4 d4 d4 e4 d4 g4',
    [3, 3, 5, 5, 4, 5],
  ),
  (
    'Happy Birthday',
    'İyi ki Doğdun',
    'g4 g4 a4 g4 c5 b4 g4 g4 a4 g4 d5 c5 g4 g4 g5 e5 c5 b4 a4 f5 f5 e5 c5 d5 c5',
    [6, 6, 7, 6],
  ),
  (
    'Hänschen klein',
    'Daha Dün Annemizin',
    'g4 e4 e4 f4 d4 d4 c4 d4 e4 f4 g4 g4 g4 g4 e4 e4 f4 d4 d4 c4 e4 g4 g4 c4',
    [3, 3, 7, 3, 3, 5],
  ),
  (
    'Au Clair de la Lune',
    'Ay Işığında',
    'c4 c4 c4 d4 e4 d4 c4 e4 d4 d4 c4 c4 c4 c4 d4 e4 d4 c4 e4 d4 d4 c4',
    [5, 6, 5, 6],
  ),
];

class PianoLevel {
  final int song;
  final List<int> notes;

  /// Phrase boundaries (lengths) used by echo mode and hints.
  final List<int> phrases;

  /// follow: the next key glows. echo: listen to a phrase, then repeat it.
  final bool echo;

  /// Number of keys on screen (8 or 15).
  final int keys;
  final bool showNames;
  const PianoLevel(this.song, this.notes, this.phrases, this.echo, this.keys, this.showNames);

  String title(bool tr) => tr ? kMelodies[song].$2 : kMelodies[song].$1;
}

String noteLabel(int i, {bool solfege = true}) => solfege ? kSolfege[i % 7] : 'CDEFGAB'[i % 7];

PianoLevel generatePiano(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  final song = r.nextInt(kMelodies.length);
  final m = kMelodies[song];
  final all = [for (final n in m.$3.split(' ')) kPianoNotes.indexOf(n)];
  final phrases = [...m.$4];
  // Easy levels play the opening phrases, harder ones the whole song.
  final takePhrases = d <= 2 ? 2 : (d <= 4 ? (phrases.length / 2).ceil() : phrases.length);
  final from = d <= 4 && r.chance(0.3) ? phrases.length - takePhrases : 0;
  var start = 0;
  for (var i = 0; i < from; i++) {
    start += phrases[i];
  }
  final ph = phrases.sublist(from, from + takePhrases);
  final len = ph.fold<int>(0, (a, b) => a + b);
  final notes = all.sublist(start, start + len);
  final hiNote = notes.reduce((a, b) => a > b ? a : b);
  final echo = spec.has('echo') || d >= 8;
  return PianoLevel(song, notes, ph, echo, hiNote <= 7 && d <= 5 ? 8 : 15, d <= 6);
}

String? checkPiano(PianoLevel l) {
  if (l.notes.length < 3) return 'too short';
  if (l.notes.any((n) => n < 0 || n >= l.keys)) return 'note outside keyboard';
  if (l.phrases.fold<int>(0, (a, b) => a + b) != l.notes.length) return 'phrases do not cover melody';
  if (l.phrases.any((p) => p <= 0)) return 'empty phrase';
  return null;
}

class PianoGame {
  final PianoLevel level;
  int pos = 0;
  int mistakes = 0;
  int played = 0;

  /// Echo mode: index of the phrase being learned and whether it was shown.
  int phrase = 0;
  PianoGame(this.level);

  bool get done => pos >= level.notes.length;
  int get next => level.notes[pos.clamp(0, level.notes.length - 1)];

  int phraseStart(int p) {
    var s = 0;
    for (var i = 0; i < p && i < level.phrases.length; i++) {
      s += level.phrases[i];
    }
    return s;
  }

  List<int> phraseNotes(int p) {
    final s = phraseStart(p);
    return level.notes.sublist(s, s + level.phrases[p]);
  }

  /// Returns 1 = right note, 0 = wrong note, 2 = phrase completed.
  int press(int key) {
    played++;
    if (done) return 0;
    if (key != next) {
      mistakes++;
      if (level.echo) pos = phraseStart(phrase); // repeat the phrase from its start
      return 0;
    }
    pos++;
    if (pos >= phraseStart(phrase) + level.phrases[phrase]) {
      phrase++;
      return 2;
    }
    return 1;
  }

  double get progress => pos / level.notes.length;

  String serialize() => '$pos;$mistakes;$played;$phrase';

  static PianoGame restore(PianoLevel l, String s) {
    final g = PianoGame(l);
    final p = s.split(';');
    if (p.length == 4) {
      g
        ..pos = (int.tryParse(p[0]) ?? 0).clamp(0, l.notes.length)
        ..mistakes = int.tryParse(p[1]) ?? 0
        ..played = int.tryParse(p[2]) ?? 0
        ..phrase = (int.tryParse(p[3]) ?? 0).clamp(0, l.phrases.length);
      g.pos = g.phraseStart(g.phrase.clamp(0, l.phrases.length - 1)).clamp(0, g.pos);
      if (g.phrase >= l.phrases.length) g.pos = l.notes.length;
    }
    return g;
  }
}
