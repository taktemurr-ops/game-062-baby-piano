import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'piano_engine.dart';

class PianoRules extends GameRules<PianoLevel> {
  @override
  String get gameId => 'game-062-baby-piano';

  @override
  List<String> get optionalMechanics => const ['echo'];

  @override
  List<GameModeId> get modes => const [GameModeId.campaign, GameModeId.endless, GameModeId.timeAttack, GameModeId.daily, GameModeId.weekly, GameModeId.challenge, GameModeId.zen];

  @override
  List<GameStat> get gameStats => const [
        GameStat('notes_played', 'Çalınan nota', 'Notes played', scale: 300),
        GameStat('songs_finished', 'Biten şarkı', 'Songs finished', scale: 10),
        GameStat('perfect_songs', 'Hatasız şarkı', 'Perfect songs', scale: 3),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('m1', 'notes_played', [10, 25, 50]),
        MissionTemplate('m2', 'songs_finished', [1, 3, 5], coinReward: 80),
      ];

  @override
  PianoLevel generate(LevelSpec spec) => generatePiano(spec);

  @override
  Validation validate(PianoLevel l, LevelSpec spec) {
    final e = checkPiano(l);
    return e == null ? Validation.ok(l.notes.length) : Validation.fail(e);
  }
}

GameRules createRules() => PianoRules();
