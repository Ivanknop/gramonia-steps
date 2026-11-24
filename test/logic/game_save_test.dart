import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/logic/wallet.dart';
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
    welcomeCoinsPer100Steps: welcomeCoinsPer100Steps,
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

  group('de la 1.1.0 (partida versión 5) a la 1.2.0 (versión 6)', () {
    // Una partida guardada por la app 1.1.0, tal cual la escribe: en el nido
    // del Rocanón, con canjes hechos, la bolsa sin ver y el nombre puesto.
    const v110 =
        '{"version":5,'
        '"steps":{"lastReading":182345,"totalSteps":21437,"todaySteps":3412,'
        '"todayDate":"2026-11-23","lastReadingAt":"2026-11-23T18:42:07.512"},'
        '"chapter":{"stageIndex":2,"stepsInStage":7250,'
        '"inventory":{"flor_amarilla":15,"flor_lila":15,"semilla_fuego":1,'
        '"semilla_agua":3,"semilla_hielo":4},'
        '"sinceLast":{"semilla_fuego":4200,"semilla_agua":100},'
        '"found":{"flor_amarilla":15,"flor_lila":15,"semilla_fuego":1,'
        '"semilla_agua":9,"semilla_hielo":8},'
        '"unseen":3,"entered":true},'
        '"player":{"name":"Regi","introSeen":true}}';

    test('queda todo igual: pasos, etapa, objetos, bolsa y nombre', () {
      final game = decode(v110);
      expect(
        game.steps,
        StepState(
          lastReading: 182345,
          totalSteps: 21437,
          todaySteps: 3412,
          todayDate: '2026-11-23',
          lastReadingAt: DateTime.parse('2026-11-23T18:42:07.512'),
        ),
      );
      expect(
        game.chapter,
        const ChapterProgress(
          stageIndex: 2,
          stepsInStage: 7250,
          inventory: {
            'flor_amarilla': 15,
            'flor_lila': 15,
            'semilla_fuego': 1,
            'semilla_agua': 3,
            'semilla_hielo': 4,
          },
          sinceLast: {'semilla_fuego': 4200, 'semilla_agua': 100},
          found: {
            'flor_amarilla': 15,
            'flor_lila': 15,
            'semilla_fuego': 1,
            'semilla_agua': 9,
            'semilla_hielo': 8,
          },
          unseen: 3,
        ),
      );
      expect(game.playerName, 'Regi');
      expect(game.introSeen, isTrue);
      expect(engine.currentStage(game.chapter)!.id, 'nido_rocanron');
    });

    test('recibe el bono de bienvenida: 10 monedas cada 100 pasos', () {
      final wallet = decode(v110).wallet;
      // 21.437 pasos → 214 veces 100 → 2.140 monedas.
      expect(wallet.coins, 2140);
      expect(wallet.welcomeBonusPaid, isTrue);
      expect(wallet.notices, [const CoinNotice(CoinNoticeKind.welcome, 2140)]);
      // El bono del día se cobra al abrir (no en la conversión).
      expect(wallet.dailyBonusDate, isNull);
    });

    test('el bono de bienvenida no se cobra dos veces', () {
      final first = decode(v110);
      // Se guarda en la versión nueva y se vuelve a abrir.
      final again = decode(first.encode());
      expect(again, first);
      expect(again.wallet.coins, 2140);
      // Ya gastó y vio el aviso: sigue sin cobrarse de nuevo.
      final later = first.copyWith(
        wallet: first.wallet.spend(1200).dismiss(first.wallet.notices.single),
      );
      final reopened = decode(later.encode());
      expect(reopened.wallet.coins, 940);
      expect(reopened.wallet.notices, isEmpty);
    });

    test('lo convertido se guarda como versión 6', () {
      expect(decode(v110).encode(), contains('"version":6'));
      expect(GameSave.version, 6);
    });

    test('las partidas de versiones más viejas también lo reciben', () {
      final game = decode(null, legacy: steps.encode()); // 64 pasos (v1)
      expect(game.wallet.welcomeBonusPaid, isTrue);
      expect(game.wallet.coins, 0);
    });

    test('las partidas nuevas no reciben el bono de bienvenida', () {
      final fresh = decode(null);
      expect(fresh.wallet, Wallet.initial);
      // Una partida nueva que ya caminó mucho, guardada y vuelta a abrir.
      final walked = const GameSave.initial().copyWith(
        steps: const StepState(
          lastReading: 1,
          totalSteps: 50000,
          todaySteps: 0,
          todayDate: '2026-11-24',
        ),
      );
      expect(decode(walked.encode()).wallet.coins, 0);
    });
  });

  test('las monedas y los bonos se guardan', () {
    const game = GameSave(
      steps: steps,
      chapter: ChapterProgress.initial(),
      wallet: Wallet(
        coins: 777,
        dailyBonusDate: '2026-11-24',
        welcomeBonusPaid: true,
        notices: [CoinNotice(CoinNoticeKind.daily, 40)],
      ),
    );
    expect(decode(game.encode()), game);
  });
}
