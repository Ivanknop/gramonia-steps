import 'dart:io';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/music.dart';
import 'package:test/test.dart';

void main() {
  test('portada, presentación e introducción: el tema tierno', () {
    for (final scene in [
      MusicScene.title,
      MusicScene.presentation,
      MusicScene.intro,
    ]) {
      expect(
        musicFor(scene: scene, stageMusic: MusicTrack.tension),
        MusicTrack.intro,
      );
    }
  });

  test('en el juego, el tema de la etapa (también en su caminata)', () {
    expect(
      musicFor(scene: MusicScene.game, stageMusic: MusicTrack.tension),
      MusicTrack.tension,
    );
  });

  test('el cierre y los créditos tapan a todo lo demás', () {
    for (final scene in MusicScene.values) {
      expect(
        musicFor(scene: scene, stageMusic: null, ending: true),
        MusicTrack.finale,
      );
      expect(
        musicFor(scene: scene, stageMusic: null, credits: true),
        MusicTrack.finale,
      );
    }
  });

  test('con el capítulo terminado, el tema del final', () {
    expect(
      musicFor(scene: MusicScene.game, stageMusic: null),
      MusicTrack.finale,
    );
  });

  test('tensión en el muelle de la tormenta y la Montaña Dragón', () {
    expect(chapter1.stages.map((s) => s.music), [
      MusicTrack.aventura, // jardín
      MusicTrack.aventura, // caperuza
      MusicTrack.aventura, // nido
      MusicTrack.aventura, // laberinto
      MusicTrack.tension, // puerto
      MusicTrack.tension, // montaña
      MusicTrack.aventura, // papá
      MusicTrack.aventura, // barco
    ]);
  });

  test('cada tema tiene su archivo, existe y está declarado', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final track in MusicTrack.values) {
      final path = musicAssets[track]!;
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains('- assets/music/'));
    }
  });

  test('volumen moderado', () {
    expect(musicVolume, inInclusiveRange(0.3, 0.7));
  });
}
