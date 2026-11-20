import 'package:flutter/material.dart';

import '../app/game_api.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';
import 'kids_ui.dart';
import 'piano_engine.dart';
import 'rules.dart';

const _keyColors = [
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF29B6F6),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
];

class PianoView extends StatefulWidget {
  final PlayContext ctx;
  const PianoView({super.key, required this.ctx});

  @override
  State<PianoView> createState() => _PianoViewState();
}

class _PianoViewState extends State<PianoView> with RoundClock {
  late PianoLevel level;
  late PianoGame game;
  int _hints = 0;
  int _rounds = 0;
  int _notesTotal = 0;
  int _songsTotal = 0;
  int? _lit;
  int? _flash;
  bool _free = false;
  bool _listening = false;
  bool _ended = false;
  String _msg = '';
  bool _ok = true;
  int _gen = 0;

  PlayContext get ctx => widget.ctx;
  bool get _tr => isTr(ctx);
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    level = (ctx.generated as GeneratedLevel<PianoLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? PianoGame.restore(level, snap) : PianoGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _rounds = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    _free = ctx.spec.mode == GameModeId.zen && ctx.resume['free'] == true;
    startClock(
      initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0,
      limit: ctx.spec.mode == GameModeId.timeAttack ? 150 : 0,
    );
    if (level.echo) WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  @override
  void dispose() {
    _gen++;
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end();

  void _persist() =>
      ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _rounds, 'free': _free});

  void _note(int k) => ctx.sound('note_${kPianoNotes[k]}');

  /// Echo mode: play the current phrase with glowing keys, then it's your turn.
  Future<void> _listen() async {
    if (game.done || !mounted) return;
    final my = ++_gen;
    setState(() {
      _listening = true;
      _msg = _tr ? 'Dinle…' : 'Listen…';
      _ok = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final k in game.phraseNotes(game.phrase)) {
      if (!mounted || my != _gen) return;
      _note(k);
      setState(() => _flash = k);
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted || my != _gen) return;
      setState(() => _flash = null);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!mounted || my != _gen) return;
    setState(() {
      _listening = false;
      _msg = _tr ? 'Şimdi sen çal!' : 'Your turn!';
    });
  }

  Future<void> _press(int k) async {
    if (_ended) return;
    _note(k);
    setState(() => _lit = k);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted && _lit == k) setState(() => _lit = null);
    });
    if (_free || _listening || game.done) return;
    final res = game.press(k);
    if (res == 0) {
      ctx.sfx(Sfx.error);
      setState(() {
        _msg = tryAgain(ctx, game.mistakes);
        _ok = false;
      });
      if (level.echo) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) _listen();
      }
    } else {
      _notesTotal++;
      setState(() {
        if (res == 2) {
          _msg = cheer(ctx, game.phrase);
          _ok = true;
        } else if (!_ok) {
          _msg = '';
          _ok = true;
        }
      });
      if (game.done) {
        _songDone();
      } else if (res == 2 && level.echo) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) _listen();
      }
    }
    _persist();
  }

  Future<void> _songDone() async {
    _songsTotal++;
    ctx.sfx(Sfx.win);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_chain) {
      _rounds++;
      final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _rounds]));
      setState(() {
        level = createRules().build(next).puzzle as PianoLevel;
        game = PianoGame(level);
        _msg = '';
      });
      _persist();
      if (level.echo) _listen();
      return;
    }
    _end();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _gen++;
    stopClock();
    final m = game.mistakes;
    var stars = m <= 1 ? 3 : (m <= 5 ? 2 : 1);
    if (_chain) stars = _rounds >= 3 ? 3 : (_rounds >= 1 ? 2 : 1);
    ctx.finish(
      RoundResult(
        won: game.done || _songsTotal > 0 || (_chain && _notesTotal > 0),
        score: _notesTotal * 20 + _songsTotal * 500 + (m == 0 ? 300 : 0),
        stars: stars,
        seconds: seconds,
        moves: game.played,
        hintsUsed: _hints,
        gameStats: {
          'notes_played': _notesTotal,
          'songs_finished': _songsTotal,
          'perfect_songs': game.done && m == 0 ? 1 : 0,
        },
      ),
    );
  }

  Future<void> _hint() async {
    if (game.done || _listening || !await ctx.requestHint()) return;
    _hints++;
    if (level.echo) {
      _listen();
      return;
    }
    final k = game.next;
    _note(k);
    setState(() => _flash = k);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _flash = null);
  }

  Future<void> _autoplay() async {
    if (game.done || _listening || !await ctx.requestBooster()) return;
    final end = game.phraseStart(game.phrase) + level.phrases[game.phrase.clamp(0, level.phrases.length - 1)];
    final my = ++_gen;
    while (mounted && my == _gen && !game.done && game.pos < end) {
      final k = game.next;
      setState(() => _flash = k);
      await _press(k);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() => _flash = null);
    }
  }

  Widget _strip() {
    final from = game.pos;
    final upcoming = level.notes.sublist(from, (from + 8).clamp(0, level.notes.length));
    return SizedBox(
      height: 64,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < upcoming.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == 0 ? 52 : 34,
                  height: i == 0 ? 52 : 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (level.echo && i > 0)
                        ? Colors.black12
                        : _keyColors[upcoming[i] % 7].withValues(alpha: i == 0 ? 1 : .55),
                    shape: BoxShape.circle,
                    border: i == 0 ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: level.showNames && !(level.echo && i > 0)
                      ? Text(
                          noteLabel(upcoming[i]),
                          style: TextStyle(
                            fontSize: i == 0 ? 16 : 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _keyboard() => LayoutBuilder(
    builder: (context, c) {
      final n = level.keys;
      final w = c.maxWidth / n;
      final glow = (_free || _listening || game.done || level.echo) ? null : game.next;
      return Row(
        children: [
          for (var k = 0; k < n; k++)
            SizedBox(
              width: w,
              height: c.maxHeight,
              child: Semantics(
                button: true,
                label: noteLabel(k),
                child: GestureDetector(
                  onTapDown: (_) => _press(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: (_lit == k || _flash == k) ? _keyColors[k % 7].withValues(alpha: .55) : Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      border: Border.all(
                        color: glow == k ? _keyColors[k % 7] : Colors.black26,
                        width: glow == k ? 5 : 1.5,
                      ),
                      boxShadow: const [BoxShadow(blurRadius: 3, offset: Offset(0, 3), color: Colors.black26)],
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: w * .55,
                          height: w * .55,
                          decoration: BoxDecoration(color: _keyColors[k % 7], shape: BoxShape.circle),
                        ),
                        if (level.showNames)
                          FittedBox(
                            child: Text(
                              noteLabel(k),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return KidsBackdrop(
      colors: ctx.background,
      child: Column(
        children: [
          PlayHud(
            items: [
              if (ctx.spec.mode == GameModeId.timeAttack) (Icons.timer, timeText),
              (Icons.music_note, '${game.pos}/${level.notes.length}'),
              (Icons.queue_music, '${game.phrase.clamp(0, level.phrases.length)}/${level.phrases.length}'),
              if (_chain) (Icons.emoji_events, '$_rounds'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '🎵 ${level.title(_tr)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: LinearProgressIndicator(value: game.progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          ),
          if (!_free) _strip(),
          CheerLine(_free ? (_tr ? 'Serbest çalma 🎹' : 'Free play 🎹') : _msg, good: _ok),
          const Spacer(),
          SizedBox(
            height: 230,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _keyboard()),
          ),
          BoosterBar(
            buttons: [
              BoosterButton(Icons.lightbulb, ctx.t('hint'), _hint),
              BoosterButton(Icons.play_circle, _tr ? 'Otomatik çal' : 'Autoplay', _autoplay),
              BoosterButton(Icons.piano, _tr ? 'Serbest' : 'Free play', () {
                setState(() => _free = !_free);
                _persist();
              }, active: _free),
            ],
          ),
        ],
      ),
    );
  }
}
