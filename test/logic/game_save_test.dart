import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/logic/story.dart';
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
    welcomeBonus: welcomeBonus,
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

    test('recibe el bono de bienvenida: 20 monedas cada 500 pasos', () {
      final wallet = decode(v110).wallet;
      // 21.437 pasos → 42 veces 500 → 840 monedas.
      expect(wallet.coins, 840);
      expect(wallet.welcomeBonusPaid, isTrue);
      expect(wallet.notices, [const CoinNotice(CoinNoticeKind.welcome, 840)]);
      // El bono del día se cobra al abrir (no en la conversión).
      expect(wallet.dailyBonusDate, isNull);
    });

    test('el bono de bienvenida no se cobra dos veces', () {
      final first = decode(v110);
      // Se guarda en la versión nueva y se vuelve a abrir.
      final again = decode(first.encode());
      expect(again, first);
      expect(again.wallet.coins, 840);
      expect(again.wallet.welcomeBonusPaid, isTrue);
      // Ya gastó, vio el aviso y caminó más: sigue sin cobrarse de nuevo.
      final later = first.copyWith(
        steps: first.steps.copyWith(totalSteps: 60000),
        wallet: first.wallet.spend(300).dismiss(first.wallet.notices.single),
      );
      var reopened = decode(later.encode());
      for (var i = 0; i < 3; i++) {
        reopened = decode(reopened.encode());
      }
      expect(reopened.wallet.coins, 540);
      expect(reopened.wallet.notices, isEmpty);
    });

    test('lo convertido se guarda en la versión actual', () {
      expect(GameSave.version, 7);
      expect(decode(v110).encode(), contains('"version":7'));
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

  test('el género se guarda; las partidas de antes no lo tienen', () {
    for (final genero in Genero.values) {
      final game = const GameSave.initial().copyWith(
        playerName: 'Regi',
        genero: genero,
      );
      expect(decode(game.encode()).genero, genero);
    }
    expect(decode(const GameSave.initial().encode()).genero, isNull);
  });

  group('versión 7: las monedas de oro pasan a la billetera', () {
    // Una partida guardada por la 1.2.0 (versión 6), tal cual la escribe: en
    // el barco, con 13 monedas de oro, un canje hecho y monedas en la
    // billetera.
    const v6 =
        '{"version":6,'
        '"steps":{"lastReading":402311,"totalSteps":104220,"todaySteps":5120,'
        '"todayDate":"2026-12-15","lastReadingAt":"2026-12-15T19:03:44.120"},'
        '"chapter":{"stageIndex":7,"stepsInStage":9350,'
        '"inventory":{"flor_amarilla":15,"flor_lila":15,"semilla_fuego":3,'
        '"semilla_agua":2,"semilla_hielo":5,"pieza_hoja":1,"pieza_gota":1,'
        '"pieza_piedra":1,"pieza_sol":1,"pieza_luna":1,"pieza_estrella":1,'
        '"pista":1,"gema":40,"piedra_fuego":1,"agua_cascada":1,"escama":1,'
        '"flor_nubes":1,"farol_luciernagas":1,"manta":1,"pan":1,'
        '"mermelada":1,"madera":1,"clavos":1,"moneda_oro":13},'
        '"sinceLast":{"cuerdas":4300,"bandera":4300,"ancla":4300,'
        '"moneda_oro":50},'
        '"found":{"flor_amarilla":15,"flor_lila":15,"semilla_fuego":3,'
        '"semilla_agua":14,"semilla_hielo":13,"pieza_hoja":1,"pieza_gota":1,'
        '"pieza_piedra":1,"pieza_sol":1,"pieza_luna":1,"pieza_estrella":1,'
        '"pista":1,"gema":340,"piedra_fuego":1,"agua_cascada":1,"escama":1,'
        '"flor_nubes":1,"farol_luciernagas":1,"manta":1,"pan":1,'
        '"mermelada":1,"madera":1,"clavos":1,"moneda_oro":33},'
        '"unseen":2,"entered":true},'
        '"player":{"name":"Regi","introSeen":true,"gender":"chica"},'
        '"wallet":{"coins":512,"dailyBonusDate":"2026-12-15",'
        '"welcomeBonusPaid":true,"notices":[]}}';

    test('v6: 13 monedas de oro → 13 monedas más; lo demás, igual', () {
      final game = decode(v6);
      expect(game.wallet.coins, 512 + 13);
      expect(game.chapter.count('moneda_oro'), 0);
      expect(game.chapter.inventory.containsKey('moneda_oro'), isFalse);
      // La bolsa ya no las muestra.
      expect(game.chapter.found.containsKey('moneda_oro'), isFalse);
      // Lo demás no cambia.
      expect(game.chapter.stageIndex, 7);
      expect(engine.currentStage(game.chapter)!.id, 'barco');
      expect(game.chapter.stepsInStage, 9350);
      expect(game.chapter.count('madera'), 1);
      expect(game.chapter.count('clavos'), 1);
      expect(game.chapter.count('gema'), 40);
      expect(game.chapter.foundCount('gema'), 340);
      expect(game.chapter.unseen, 2);
      expect(game.chapter.sinceLast['ancla'], 4300);
      expect(game.steps.totalSteps, 104220);
      expect(game.playerName, 'Regi');
      expect(game.genero, Genero.chica);
      expect(game.wallet.dailyBonusDate, '2026-12-15');
      expect(game.wallet.welcomeBonusPaid, isTrue);
      expect(game.wallet.notices, isEmpty); // Sin bono de bienvenida.
      expect(game.notificationsAsked, isFalse); // Se pregunta al abrir.
    });

    test('v6: guardada y vuelta a abrir, no se suman otra vez', () {
      final first = decode(v6);
      final again = decode(first.encode());
      expect(again, first);
      expect(again.wallet.coins, 525);
    });

    // Una partida de la 1.1.0 (versión 5) en el barco con monedas de oro.
    const v5 =
        '{"version":5,'
        '"steps":{"lastReading":90000,"totalSteps":100050,"todaySteps":4000,'
        '"todayDate":"2026-11-23","lastReadingAt":"2026-11-23T20:00:00.000"},'
        '"chapter":{"stageIndex":7,"stepsInStage":6000,'
        '"inventory":{"madera":1,"moneda_oro":7},"sinceLast":{},'
        '"found":{"madera":1,"moneda_oro":7},"unseen":0,"entered":true},'
        '"player":{"name":"Regi","introSeen":true}}';

    test('v5 (1.1.0): bono de bienvenida más las monedas de oro', () {
      final game = decode(v5);
      // 100.050 pasos → 200 × 20 = 4.000, más 7 monedas de oro.
      expect(game.wallet.coins, 4000 + 7);
      expect(game.wallet.notices, [
        const CoinNotice(CoinNoticeKind.welcome, 4000),
      ]);
      expect(game.chapter.count('moneda_oro'), 0);
      expect(game.chapter.found.containsKey('moneda_oro'), isFalse);
      expect(game.chapter.count('madera'), 1);
      expect(game.chapter.stepsInStage, 6000);
      expect(decode(game.encode()).wallet.coins, 4007);
    });

    test('sin monedas de oro, la partida queda igual', () {
      const game = GameSave(
        steps: steps,
        chapter: ChapterProgress(
          stageIndex: 7,
          stepsInStage: 5000,
          inventory: {'madera': 1},
          sinceLast: {},
        ),
        wallet: Wallet(coins: 40),
      );
      expect(decode(game.encode()), game);
    });

    test('la pregunta de los avisos se guarda', () {
      final game = const GameSave.initial().copyWith(notificationsAsked: true);
      expect(decode(game.encode()).notificationsAsked, isTrue);
    });
  });
}
