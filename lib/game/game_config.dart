import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'piano_view.dart';
import 'rules.dart';

/// Kids & Family game: kidsMode treats every player as a child (no
/// personalized ads, no analytics, child-directed ad requests, parental
/// gate in the shop).
final gameConfig = GameConfig(
  gameId: 'game-062-baby-piano',
  title: const ['Bebek Piyano', 'Baby Piano', 'Baby Klavier', 'Piano Bebé', 'Piano Bébé'],
  tagline: const ['Renkli tuşlarla şarkıları çal!', 'Play songs on colorful keys!', 'Spiele Lieder auf bunten Tasten!', '¡Toca canciones en teclas de colores!', 'Joue des chansons sur des touches colorées !'],
  seedColor: const Color(0xFFE63946),
  icon: Icons.piano,
  rules: PianoRules(),
  buildPlay: (ctx) => PianoView(ctx: ctx),
  kidsMode: true,
  tutorial: const [
    TutorialStep(Icons.piano, ['Parlayan tuşa bas.', 'Press the glowing key.', 'Drücke die leuchtende Taste.', 'Pulsa la tecla que brilla.', 'Appuie sur la touche qui brille.']),
    TutorialStep(Icons.hearing, ['Yankı: dinle, sonra aynısını çal.', 'Echo: listen, then play it back.', 'Echo: hören und nachspielen.', 'Eco: escucha y repite.', 'Écho : écoute puis rejoue.']),
    TutorialStep(Icons.music_note, ['Serbest modda istediğin gibi çal!', 'Free play: play anything you like!', 'Freies Spiel!', '¡Toca libremente!', 'Jeu libre !']),
  ],
);
