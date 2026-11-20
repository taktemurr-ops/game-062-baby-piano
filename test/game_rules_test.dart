import 'package:flutter_test/flutter_test.dart';
import 'package:game_062_baby_piano/core/level_plan.dart';
import 'package:game_062_baby_piano/game/piano_engine.dart';
import 'package:game_062_baby_piano/game/rules.dart';

void main() {
  final rules = PianoRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('every melody uses keys of the toy piano and its phrases cover it', () {
    for (final m in kMelodies) {
      final notes = m.$3.split(' ');
      expect(notes.every(kPianoNotes.contains), isTrue, reason: m.$1);
      expect(m.$4.fold<int>(0, (a, b) => a + b), notes.length, reason: m.$1);
    }
  });

  test('levels are valid and reproducible', () {
    for (final n in [1, 2, 10, 99, 1234, 20000, 49999, 52000]) {
      final a = rules.build(planner.spec(n));
      final b = rules.build(planner.spec(n));
      expect(a.validation.ok, isTrue, reason: 'level $n');
      expect(checkPiano(a.puzzle), isNull);
      expect(a.puzzle.notes, b.puzzle.notes);
    }
  });

  test('follow mode: right keys finish the song, wrong keys only count', () {
    final l = PianoLevel(0, const [0, 0, 4, 4, 5, 5, 4], const [7], false, 8, true);
    final g = PianoGame(l);
    expect(g.press(1), 0);
    expect(g.mistakes, 1);
    expect(g.pos, 0);
    for (final n in l.notes) {
      expect(g.press(n), isNot(0));
    }
    expect(g.done, isTrue);
  });

  test('echo mode: a wrong key restarts the phrase', () {
    final l = PianoLevel(1, const [2, 1, 0, 1, 2, 2, 2], const [4, 3], true, 8, true);
    final g = PianoGame(l);
    g.press(2);
    g.press(1);
    expect(g.press(5), 0);
    expect(g.pos, 0);
    for (final n in [2, 1, 0]) {
      expect(g.press(n), 1);
    }
    expect(g.press(1), 2);
    expect(g.phrase, 1);
    final r = PianoGame.restore(l, g.serialize());
    expect(r.pos, 4);
    expect(r.phrase, 1);
  });

  test('levels 1..80 valid', () {
    for (var n = 1; n <= 80; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
