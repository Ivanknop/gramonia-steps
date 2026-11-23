import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:test/test.dart';

import '../fakes/fake_random.dart';

ItemType _item(String id) =>
    ItemType(id: id, name: id, foundName: id, message: 'msg $id');

/// Capítulo chico para probar cada mecánica por separado.
final testChapter = Chapter(
  name: 'Prueba',
  walkingBackground: 'test',
  walkingCharacter: 'nena',
  characters: const [Character(id: 'nena', name: 'Nena')],
  items: [
    for (final id in [
      'flor',
      'fuego',
      'agua',
      'pieza1',
      'pieza2',
      'gema',
      'oro1',
      'oro2',
    ])
      _item(id),
  ],
  stages: const [
    // 0: al azar, 3 flores, cada 10 pasos, 1 en 5 (garantía a los 150).
    Stage(
      id: 'azar',
      name: 'Azar',
      intro: 'i',
      requirements: [Requirement('flor', 3)],
      spawns: [
        RandomSpawn(items: ['flor'], every: 10, oneIn: 5),
      ],
      reward: Reward(id: 'r', name: 'r'),
      completeMessage: 'c',
      background: 'test',
      place: 'lugar',
      introCharacter: 'nena',
      completeCharacter: 'nena',
    ),
    // 1: fijos en orden, cada 100.
    Stage(
      id: 'fijo',
      name: 'Fijo',
      intro: 'i',
      requirements: [Requirement('pieza1'), Requirement('pieza2')],
      spawns: [
        FixedSpawn(items: ['pieza1', 'pieza2'], every: 100),
      ],
      reward: Reward(id: 'r', name: 'r'),
      completeMessage: 'c',
      background: 'test',
      place: 'lugar',
      introCharacter: 'nena',
      completeCharacter: 'nena',
    ),
    // 2: llegar 50, fuego muy raro, agua común; 3 aguas → 1 fuego.
    Stage(
      id: 'canje',
      name: 'Canje',
      intro: 'i',
      travelSteps: 50,
      travelText: 't',
      requirements: [Requirement('fuego', 2)],
      spawns: [
        RandomSpawn(items: ['fuego'], every: 10, oneIn: 1000),
        FixedSpawn(items: ['agua'], every: 10),
      ],
      exchanges: [
        Exchange(inputs: ['agua'], count: 3, outputs: ['fuego'], message: 'm'),
      ],
      reward: Reward(id: 'r', name: 'r'),
      completeMessage: 'c',
      background: 'test',
      place: 'lugar',
      introCharacter: 'nena',
      completeCharacter: 'nena',
    ),
    // 3: canje que da el primero que falte de varios.
    Stage(
      id: 'compra',
      name: 'Compra',
      intro: 'i',
      requirements: [Requirement('oro1'), Requirement('oro2')],
      spawns: [
        FixedSpawn(items: ['gema'], every: 10),
      ],
      exchanges: [
        Exchange(
          inputs: ['gema'],
          count: 2,
          outputs: ['oro1', 'oro2'],
          message: '{item}',
        ),
      ],
      reward: Reward(id: 'r', name: 'r'),
      completeMessage: 'c',
      background: 'test',
      place: 'lugar',
      introCharacter: 'nena',
      completeCharacter: 'nena',
    ),
  ],
);

List<String> describe(List<ChapterEvent> events) => [
  for (final e in events)
    switch (e) {
      ItemFound(:final item) => 'objeto:${item.id}',
      ExchangeMade(:final item) => 'canje:${item.id}',
      Arrived(:final stage) => 'llegó:${stage.id}',
      StageCompleted(:final stage) => 'etapa:${stage.id}',
      ChapterCompleted() => 'fin',
    },
];

ChapterProgress at(
  int stage, {
  int steps = 0,
  Map<String, int> inv = const {},
}) => ChapterProgress(
  stageIndex: stage,
  stepsInStage: steps,
  inventory: inv,
  sinceLast: const {},
);

void main() {
  final engine = ChapterEngine(testChapter);
  const start = ChapterProgress.initial();

  group('aparición al azar', () {
    test('se tira una vez cada K pasos', () {
      final random = FixedRandom(1); // nunca sale
      engine.advance(start, 49, random);
      expect(random.rolls, 4);
      engine.advance(start, 50, random);
      expect(random.rolls, 4 + 5);
    });

    test('si sale 1, aparece el objeto', () {
      final r = engine.advance(start, 10, FixedRandom(0));
      expect(describe(r.events), ['objeto:flor']);
      expect(r.progress.count('flor'), 1);
    });

    test('si no sale, no aparece y se cuenta para la garantía', () {
      final r = engine.advance(start, 30, FixedRandom(1));
      expect(r.events, isEmpty);
      expect(r.progress.sinceLast['flor'], 30);
    });

    test('garantía: a los 3×N×K pasos sin salir, sale seguro', () {
      // N=5, K=10: garantía a los 150 pasos.
      var r = engine.advance(start, 140, FixedRandom(1));
      expect(r.events, isEmpty);
      r = engine.advance(r.progress, 10, FixedRandom(1));
      expect(describe(r.events), ['objeto:flor']);
      expect(r.progress.sinceLast['flor'], 0);
    });

    test('la garantía vuelve a empezar después de cada aparición', () {
      final r = engine.advance(start, 300, FixedRandom(1));
      expect(r.progress.count('flor'), 2); // a los 150 y a los 300
    });

    test('con la misma semilla, el mismo resultado', () {
      final a = engine.advance(start, 500, Random(42));
      final b = engine.advance(start, 500, Random(42));
      expect(a.progress, b.progress);
      expect(describe(a.events), describe(b.events));
    });

    test('de a un paso da lo mismo que de golpe', () {
      final once = engine.advance(start, 2000, Random(7));
      final random = Random(7);
      var p = start;
      final events = <ChapterEvent>[];
      for (var i = 0; i < 2000; i++) {
        final r = engine.advance(p, 1, random);
        p = r.progress;
        events.addAll(r.events);
      }
      expect(p, once.progress);
      expect(describe(events), describe(once.events));
    });
  });

  group('objetos fijos', () {
    test('salen cada M pasos, en orden', () {
      var r = engine.advance(at(1), 99, FixedRandom(0));
      expect(r.events, isEmpty);
      expect(
        engine.stepsToNextFixed(
          r.progress,
          testChapter.stages[1].spawns.single as FixedSpawn,
        ),
        1,
      );
      r = engine.advance(r.progress, 1, FixedRandom(0));
      expect(describe(r.events), ['objeto:pieza1']);
      r = engine.advance(r.progress, 100, FixedRandom(0));
      expect(describe(r.events), ['objeto:pieza2', 'etapa:fijo']);
    });
  });

  group('llegar', () {
    test('durante el viaje no aparece nada', () {
      final r = engine.advance(at(2), 49, FixedRandom(0));
      expect(r.events, isEmpty);
      expect(engine.isTraveling(r.progress), isTrue);
    });

    test('al llegar hay aviso y lo que sobra cuenta para juntar', () {
      final r = engine.advance(at(2), 70, FixedRandom(1));
      expect(describe(r.events), ['llegó:canje', 'objeto:agua', 'objeto:agua']);
      expect(engine.isTraveling(r.progress), isFalse);
    });
  });

  group('canje', () {
    test('al juntar X comunes se cambian solos por el objeto', () {
      final r = engine.advance(at(2, steps: 50), 30, FixedRandom(1));
      expect(describe(r.events), [
        'objeto:agua',
        'objeto:agua',
        'objeto:agua',
        'canje:fuego',
      ]);
      expect(r.progress.count('agua'), 0);
      expect(r.progress.count('fuego'), 1);
    });

    test('no canjea si el objeto ya no hace falta', () {
      // Ya hay 1 fuego; con otro de canje se completa la etapa.
      final r = engine.advance(
        at(2, steps: 50, inv: {'fuego': 1}),
        30,
        FixedRandom(1),
      );
      expect(describe(r.events).last, 'etapa:canje');
      expect(r.progress.stageIndex, 3);
      // Las aguas sobrantes no siguen canjeándose en la etapa siguiente.
      expect(r.progress.count('fuego'), 2);
    });

    test('con varios objetos, da el primero que falte', () {
      final r = engine.advance(at(3, inv: {'oro1': 1}), 20, FixedRandom(0));
      expect(describe(r.events), [
        'objeto:gema',
        'objeto:gema',
        'canje:oro2',
        'etapa:compra',
        'fin',
      ]);
    });

    test('un objeto de la etapa que ya no hace falta deja de aparecer', () {
      final r = engine.advance(at(2, steps: 50), 10000, FixedRandom(0));
      // El fuego sale en las 2 primeras tiradas; después termina la etapa.
      expect(r.progress.count('fuego'), 2);
      expect(r.progress.stageIndex, greaterThan(2));
    });
  });

  group('avance general', () {
    test('un salto grande completa varias etapas y el sobrante pasa', () {
      final r = engine.advance(start, 30 + 200 + 5, FixedRandom(0));
      expect(describe(r.events), [
        'objeto:flor',
        'objeto:flor',
        'objeto:flor',
        'etapa:azar',
        'objeto:pieza1',
        'objeto:pieza2',
        'etapa:fijo',
      ]);
      expect(r.progress.stageIndex, 2);
      expect(r.progress.stepsInStage, 5);
    });

    test('al pasar de etapa se reinicia la cuenta de la garantía', () {
      final r = engine.advance(start, 100, FixedRandom(0));
      expect(r.progress.stageIndex, 1);
      expect(r.progress.sinceLast, isEmpty);
    });

    test('fin del capítulo y pasos después del fin', () {
      final done = engine.advance(start, 100000, Random(1));
      expect(engine.isFinished(done.progress), isTrue);
      expect(describe(done.events).last, 'fin');
      final after = engine.advance(done.progress, 5000, Random(1));
      expect(after.events, isEmpty);
      expect(after.progress, done.progress);
    });

    test('0 o pasos negativos no cambian nada', () {
      final p = engine.advance(start, 25, FixedRandom(1)).progress;
      expect(engine.advance(p, 0, FixedRandom(0)).progress, p);
      expect(engine.advance(p, -5, FixedRandom(0)).progress, p);
    });

    test('estado de cada etapa: hecha, actual y bloqueada', () {
      final p = at(1);
      expect(engine.statusOf(0, p), StageStatus.done);
      expect(engine.statusOf(1, p), StageStatus.current);
      expect(engine.statusOf(2, p), StageStatus.locked);
    });
  });

  group('capítulo 1 real', () {
    const real = ChapterEngine(chapter1);

    test('con suerte total (todo sale) termina y da cada recompensa', () {
      final r = real.advance(start, 1000000, FixedRandom(0));
      expect(real.isFinished(r.progress), isTrue);
      expect(
        r.events.whereType<StageCompleted>().map((e) => e.stage.id),
        chapter1.stages.map((s) => s.id),
      );
    });

    test('con mala suerte total, la garantía y los canjes lo terminan', () {
      final r = real.advance(start, 1000000, FixedRandom(999999));
      expect(real.isFinished(r.progress), isTrue);
    });

    test('balance: 300 partidas promedian entre 90.000 y 120.000 pasos', () {
      final random = Random(2026);
      var total = 0;
      for (var game = 0; game < 300; game++) {
        var p = start;
        var steps = 0;
        while (!real.isFinished(p)) {
          p = real.advance(p, 500, random).progress;
          steps += 500;
        }
        total += steps;
      }
      final average = total / 300;
      expect(average, inInclusiveRange(90000, 120000));
    });
  });

  group('bolsa', () {
    test('cada objeto suma a lo conseguido y a lo nuevo sin ver', () {
      final p = engine.advance(start, 30, FixedRandom(0)).progress;
      expect(p.foundCount('flor'), 3);
      expect(p.unseen, 3);
    });

    test('los canjes descuentan del inventario pero no de lo conseguido', () {
      const p = ChapterProgress(
        stageIndex: 2,
        stepsInStage: 50,
        inventory: {},
        sinceLast: {},
      );
      final after = engine.advance(p, 30, FixedRandom(1)).progress;
      expect(after.count('agua'), 0);
      expect(after.foundCount('agua'), 3);
      expect(after.foundCount('fuego'), 1); // El del canje también cuenta.
      expect(after.unseen, 4);
    });

    test('los objetos sin aviso no suman a lo nuevo sin ver', () {
      final quiet = Chapter(
        name: 'Gemas',
        walkingBackground: 'test',
        walkingCharacter: 'nena',
        characters: const [Character(id: 'nena', name: 'Nena')],
        items: const [
          ItemType(
            id: 'gema',
            name: 'Gema',
            foundName: 'una gema',
            message: 'm',
            notify: false,
          ),
          ItemType(id: 'oro', name: 'Oro', foundName: 'oro', message: 'm'),
        ],
        stages: const [
          Stage(
            id: 's',
            name: 'S',
            intro: 'i',
            requirements: [Requirement('oro')],
            spawns: [
              FixedSpawn(items: ['gema'], every: 10),
            ],
            exchanges: [
              Exchange(
                inputs: ['gema'],
                count: 5,
                outputs: ['oro'],
                message: 'm',
              ),
            ],
            reward: Reward(id: 'r', name: 'r'),
            completeMessage: 'c',
            background: 'test',
            place: 'lugar',
            introCharacter: 'nena',
            completeCharacter: 'nena',
          ),
        ],
      );
      final p = ChapterEngine(quiet)
          .advance(start, 50, FixedRandom(0))
          .progress;
      expect(p.foundCount('gema'), 5);
      expect(p.unseen, 1); // Solo el oro del canje.
    });

    test('al abrir la bolsa, no queda nada nuevo', () {
      final p = engine.advance(start, 30, FixedRandom(0)).progress;
      final seen = engine.markSeen(p);
      expect(seen.unseen, 0);
      expect(seen.found, p.found);
    });

    test('las recompensas son las de las etapas terminadas', () {
      expect(engine.rewardsEarned(start), isEmpty);
      final p = engine.advance(start, 1000000, FixedRandom(0)).progress;
      expect(
        engine.rewardsEarned(p),
        testChapter.stages.map((s) => s.reward).toList(),
      );
    });
  });
}
