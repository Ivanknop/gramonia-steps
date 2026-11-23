import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/music.dart';
import 'package:rpg/ui/music_controller.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late FakeMusicPlayer player;
  late FakeSilentMode silent;
  late FakeMusicPrefs prefs;
  late FakeStorage storage;
  late StepController steps;
  late MusicController music;

  String play(MusicTrack t) => 'play:${musicAssets[t]}';

  Future<void> make({int stage = 0, int stepsInStage = 0}) async {
    storage = FakeStorage();
    storage.saved = storage.saved.copyWith(
      chapter: ChapterProgress(
        stageIndex: stage,
        stepsInStage: stepsInStage,
        inventory: const {},
        sinceLast: const {},
      ),
    );
    steps = StepController(
      sensor: FakeSensor(),
      storage: storage,
      saveDelay: Duration.zero,
    );
    await steps.start();
    music = MusicController(
      player: player,
      steps: steps,
      silentMode: silent,
      prefs: prefs,
    );
    await music.start();
  }

  setUp(() {
    player = FakeMusicPlayer();
    silent = FakeSilentMode();
    prefs = FakeMusicPrefs();
  });

  tearDown(() {
    music.dispose();
    steps.dispose();
  });

  test('la portada empieza con el tema tierno', () async {
    await make();
    expect(player.calls, [play(MusicTrack.intro)]);
    expect(music.playing, MusicTrack.intro);
  });

  test('si el tema no cambia, no se reinicia', () async {
    await make();
    music.setScene(MusicScene.presentation);
    music.setScene(MusicScene.intro);
    await pumpEventQueue();
    expect(player.calls, [play(MusicTrack.intro)]);
  });

  test('al entrar al juego, el tema de la etapa; al pasar a otra etapa con '
      'el mismo tema, sigue sonando', () async {
    await make();
    music.setScene(MusicScene.game);
    await pumpEventQueue();
    expect(player.calls.last, play(MusicTrack.aventura));
    await steps.addDebugSteps(1500); // Termina el jardín.
    await pumpEventQueue();
    expect(steps.game.chapter.stageIndex, 1);
    expect(player.calls, [play(MusicTrack.intro), play(MusicTrack.aventura)]);
  });

  test(
    'tramo hasta el muelle: tensión desde el principio de la caminata',
    () async {
      await make(stage: 4);
      music.setScene(MusicScene.game);
      await pumpEventQueue();
      expect(steps.engine.isTraveling(steps.game.chapter), isTrue);
      expect(player.calls.last, play(MusicTrack.tension));
    },
  );

  test('cierre y créditos: el tema del final; al cerrarlos, vuelve', () async {
    await make();
    music.setScene(MusicScene.game);
    music.setEnding(true);
    await pumpEventQueue();
    expect(music.playing, MusicTrack.finale);
    music.setEnding(false);
    music.openCredits();
    await pumpEventQueue();
    expect(music.playing, MusicTrack.finale);
    music.closeCredits();
    await pumpEventQueue();
    expect(music.playing, MusicTrack.aventura);
  });

  test(
    'silenciar: se apaga con fundido, se guarda y vuelve al activar',
    () async {
      await make();
      await music.setMuted(true);
      expect(player.calls.last, 'fadeOut');
      expect(prefs.muted, isTrue);
      expect(music.playing, isNull);
      music.setScene(MusicScene.game);
      await pumpEventQueue();
      expect(player.calls.last, 'fadeOut'); // Silenciada: no suena nada.
      await music.toggleMuted();
      expect(prefs.muted, isFalse);
      expect(player.calls.last, play(MusicTrack.aventura));
    },
  );

  test('si estaba silenciada, al abrir la app no suena', () async {
    prefs.muted = true;
    await make();
    expect(player.calls, isEmpty);
    expect(music.muted, isTrue);
  });

  test('con el celular en silencio no suena; al volver se revisa', () async {
    silent.silent = true;
    await make();
    expect(player.calls, isEmpty);
    silent.silent = false;
    await music.onPause();
    await music.onResume();
    expect(player.calls, [play(MusicTrack.intro)]);
    silent.silent = true;
    await music.onPause();
    await music.onResume();
    expect(player.calls.last, 'fadeOut');
  });

  test('en segundo plano se pausa y al volver sigue (sin reiniciar)', () async {
    await make();
    await music.onPause();
    expect(player.calls.last, 'pause');
    expect(music.playing, isNull);
    // Mientras está en segundo plano, los pasos no la despiertan.
    await steps.addDebugSteps(1000);
    await pumpEventQueue();
    expect(player.calls.last, 'pause');
    await music.onResume();
    expect(player.calls, [play(MusicTrack.intro), 'pause', 'resume']);
  });

  test(
    'si cambió de tema en segundo plano, al volver suena el nuevo',
    () async {
      await make();
      await music.onPause();
      music.setScene(MusicScene.game);
      await music.onResume();
      expect(player.calls.last, play(MusicTrack.aventura));
    },
  );
}
