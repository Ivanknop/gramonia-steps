import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:test/test.dart';

void main() {
  const engine = ChapterEngine(chapter1);
  const steps = StepState(
    lastReading: 82018,
    totalSteps: 64,
    todaySteps: 64,
    todayDate: '2026-11-22',
  );

  GameSave decode(String? source, {String? legacy}) => GameSave.decode(
    source,
    legacySource: legacy,
    engine: engine,
    random: Random(1),
  );

  test('ida y vuelta en el formato actual', () {
    const game = GameSave(
      steps: steps,
      chapter: ChapterProgress(
        stageIndex: 1,
        stepsInStage: 300,
        inventory: {'flor_lila': 15, 'semilla_agua': 4},
        sinceLast: {'semilla_fuego': 200},
      ),
    );
    expect(decode(game.encode()), game);
  });

  test('sin nada guardado arranca de cero', () {
    expect(decode(null), const GameSave.initial());
  });

  test(
    'partida v1 (solo pasos): conserva los pasos y los aplica al capítulo',
    () {
      final game = decode(null, legacy: steps.encode());
      expect(game.steps, steps);
      expect(game.chapter.stageIndex, 0);
      expect(game.chapter.stepsInStage, 64);
    },
  );

  test(
    'partida v2 (objetos viejos): conserva los pasos y rehace el capítulo',
    () {
      const v2Steps = StepState(
        lastReading: 90000,
        totalSteps: 30000,
        todaySteps: 1000,
        todayDate: '2026-11-22',
      );
      final v2 =
          '{"version":2,"steps":${v2Steps.encode()},'
          '"chapter":{"stageIndex":7,"stepsInStage":0,'
          '"collected":["hoja_dorada","frutillas","pieza_hoja","bandera"]}}';
      final game = decode(v2);
      expect(game.steps, v2Steps);
      // Las reglas nuevas, con 30.000 pasos, no llegan al final del capítulo.
      expect(engine.isFinished(game.chapter), isFalse);
      expect(game.chapter.stageIndex, greaterThan(0));
      expect(game.chapter.has('hoja_dorada'), isFalse);
      expect(game.chapter.count('flor_lila'), 15);
    },
  );

  test('si el capítulo guardado está roto, se rehace con los pasos', () {
    final source =
        '{"version":4,"steps":${steps.encode()},"chapter":{"stageIndex":"x"}}';
    final game = decode(source);
    expect(game.steps, steps);
    expect(game.chapter.stepsInStage, 64);
  });

  test('todo roto arranca de cero sin romperse', () {
    expect(decode('{roto', legacy: 'roto'), const GameSave.initial());
  });

  test('partida v3: el paseo por el jardín cuenta como hecho', () {
    final v3 =
        '{"version":3,"steps":${steps.encode()},'
        '"chapter":{"stageIndex":1,"stepsInStage":300,'
        '"inventory":{"flor_lila":15,"semilla_agua":4},'
        '"sinceLast":{"semilla_fuego":200}}}';
    final game = decode(v3);
    // Sigue en el nido del Rocanón, que ahora es la etapa 3, y el tramo
    // de caminata hasta el Árbol Mágico (de la versión 5) ya está hecho.
    expect(game.chapter.stageIndex, 2);
    final nido = engine.currentStage(game.chapter)!;
    expect(nido.id, 'nido_rocanron');
    expect(game.chapter.stepsInStage, nido.travelSteps + 300);
    expect(engine.isTraveling(game.chapter), isFalse);
    expect(game.chapter.count('semilla_agua'), 4);
    expect(game.chapter.sinceLast, {'semilla_fuego': 200});
    expect(game.chapter.foundCount('flor_lila'), 15);
  });

  group('partida v4: el tramo nuevo de la etapa cuenta como caminado', () {
    String v4(int stageIndex, int stepsInStage) =>
        '{"version":4,"steps":${steps.encode()},'
        '"chapter":{"stageIndex":$stageIndex,"stepsInStage":$stepsInStage,'
        '"inventory":{"pieza_hoja":1},"sinceLast":{}}}';

    for (final id in ['nido_rocanron', 'laberinto_hormigas']) {
      test(id, () {
        final index = chapter1.stages.indexWhere((s) => s.id == id);
        final game = decode(v4(index, 1200));
        final stage = chapter1.stages[index];
        expect(game.chapter.stageIndex, index);
        expect(game.chapter.stepsInStage, stage.travelSteps + 1200);
        expect(engine.isTraveling(game.chapter), isFalse);
        expect(game.chapter.count('pieza_hoja'), 1);
      });
    }

    test('las demás etapas no cambian', () {
      for (final index in [0, 1, 4, 5, 6, 7]) {
        expect(decode(v4(index, 1200)).chapter.stepsInStage, 1200);
      }
    });

    test('en el laberinto, el próximo objeto fijo sale donde salía', () {
      final game = decode(v4(3, 1200));
      final spawn = chapter1.stages[3].spawns.single as FixedSpawn;
      // Con 1.200 pasos caminados en el laberinto, faltan 800 para la pieza.
      expect(engine.stepsToNextFixed(game.chapter, spawn), 800);
    });
  });

  test('el nombre y la introducción vista se guardan', () {
    const game = GameSave(
      steps: steps,
      chapter: ChapterProgress.initial(),
      playerName: 'Regi',
      introSeen: true,
    );
    expect(decode(game.encode()), game);
  });

  test('las partidas de antes no tienen nombre ni introducción vista', () {
    const old = GameSave(steps: steps, chapter: ChapterProgress.initial());
    final json = old.encode().replaceFirst(RegExp(r',"player":\{[^}]*\}'), '');
    expect(json, isNot(contains('player')));
    final game = decode(json);
    expect(game.playerName, isNull);
    expect(game.introSeen, isFalse);
  });
}
