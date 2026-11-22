import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:test/test.dart';

/// Capítulo chico para probar reglas sin depender de los números reales.
const testChapter = Chapter(
  name: 'Prueba',
  stages: [
    Stage(
      id: 'a',
      name: 'Etapa A',
      steps: 100,
      reward: 'Premio A',
      items: [
        StageItem(id: 'a1', name: 'A1', atSteps: 30),
        StageItem(id: 'a2', name: 'A2', atSteps: 60),
        StageItem(id: 'a3', name: 'A3', atSteps: 100),
      ],
    ),
    Stage(
      id: 'b',
      name: 'Etapa B',
      steps: 50,
      reward: 'Premio B',
      items: [
        StageItem(id: 'b1', name: 'B1', atSteps: 20),
        StageItem(id: 'b2', name: 'B2', atSteps: 50),
      ],
    ),
    Stage(
      id: 'c',
      name: 'Etapa C',
      steps: 40,
      reward: 'Premio C',
      items: [StageItem(id: 'c1', name: 'C1', atSteps: 40)],
    ),
  ],
);

List<String> describe(List<ChapterEvent> events) => [
  for (final e in events)
    switch (e) {
      ItemCollected(:final item) => 'objeto:${item.id}',
      StageCompleted(:final stage) => 'etapa:${stage.id}',
      ChapterCompleted() => 'fin',
    },
];

void main() {
  const engine = ChapterEngine(testChapter);
  const start = ChapterProgress.initial();

  test('un paso antes del umbral no da el objeto', () {
    final r = engine.advance(start, 29);
    expect(r.events, isEmpty);
    expect(r.progress.stepsInStage, 29);
    expect(engine.stepsToNextItem(r.progress), 1);
  });

  test('al llegar justo al umbral se consigue el objeto', () {
    final r = engine.advance(engine.advance(start, 29).progress, 1);
    expect(describe(r.events), ['objeto:a1']);
    expect(r.progress.collected, ['a1']);
    expect(engine.nextItem(r.progress)?.id, 'a2');
    expect(engine.stepsToNextItem(r.progress), 30);
  });

  test('cruzar varios umbrales de golpe da todos los objetos', () {
    final r = engine.advance(start, 70);
    expect(describe(r.events), ['objeto:a1', 'objeto:a2']);
    expect(r.progress.stepsInStage, 70);
  });

  test('al completar la etapa se pasa a la siguiente y sobra lo justo', () {
    final r = engine.advance(start, 125);
    expect(describe(r.events), [
      'objeto:a1',
      'objeto:a2',
      'objeto:a3',
      'etapa:a',
      'objeto:b1',
    ]);
    expect(r.progress.stageIndex, 1);
    expect(r.progress.stepsInStage, 25);
  });

  test('llegar exacto a la meta deja la etapa siguiente en 0', () {
    final r = engine.advance(start, 100);
    expect(r.progress.stageIndex, 1);
    expect(r.progress.stepsInStage, 0);
    expect(describe(r.events).last, 'etapa:a');
  });

  test('un salto grande completa varias etapas', () {
    final r = engine.advance(start, 160);
    expect(describe(r.events), [
      'objeto:a1',
      'objeto:a2',
      'objeto:a3',
      'etapa:a',
      'objeto:b1',
      'objeto:b2',
      'etapa:b',
    ]);
    expect(r.progress.stageIndex, 2);
    expect(r.progress.stepsInStage, 10);
  });

  test('el fin del capítulo da todos los eventos y descarta el sobrante', () {
    final r = engine.advance(start, 1000);
    expect(describe(r.events).sublist(r.events.length - 3), [
      'objeto:c1',
      'etapa:c',
      'fin',
    ]);
    expect(engine.isFinished(r.progress), isTrue);
    expect(r.progress.collected, hasLength(6));
    expect(r.progress.stepsInStage, 0);
    expect(engine.currentStage(r.progress), isNull);
    expect(engine.nextItem(r.progress), isNull);
  });

  test('después del fin, los pasos no cambian nada', () {
    final done = engine.advance(start, 190).progress;
    expect(engine.isFinished(done), isTrue);
    final r = engine.advance(done, 500);
    expect(r.events, isEmpty);
    expect(r.progress, done);
  });

  test('avanzar 0 o pasos negativos no cambia nada', () {
    final p = engine.advance(start, 40).progress;
    expect(engine.advance(p, 0).progress, p);
    expect(engine.advance(p, -5).progress, p);
    expect(engine.advance(p, 0).events, isEmpty);
  });

  test('avanzar de a poco da lo mismo que de golpe', () {
    var p = start;
    final events = <ChapterEvent>[];
    for (var i = 0; i < 175; i++) {
      final r = engine.advance(p, 1);
      p = r.progress;
      events.addAll(r.events);
    }
    final once = engine.advance(start, 175);
    expect(p, once.progress);
    expect(describe(events), describe(once.events));
  });

  test('estado de cada etapa: hecha, actual y bloqueada', () {
    final p = engine.advance(start, 110).progress;
    expect(engine.statusOf(0, p), StageStatus.done);
    expect(engine.statusOf(1, p), StageStatus.current);
    expect(engine.statusOf(2, p), StageStatus.locked);
  });

  test('si cambian los datos, recoge objetos que quedaron atrás', () {
    // Partida guardada con 70 pasos pero sin el objeto a2 (umbral 60).
    const p = ChapterProgress(
      stageIndex: 0,
      stepsInStage: 70,
      collected: ['a1'],
    );
    final r = engine.advance(p, 0);
    expect(describe(r.events), ['objeto:a2']);
  });

  group('capítulo 1 real', () {
    const real = ChapterEngine(chapter1);

    test('30.000 pasos terminan el capítulo con los 42 objetos', () {
      final r = real.advance(start, 30000);
      expect(real.isFinished(r.progress), isTrue);
      expect(r.progress.collected, hasLength(42));
      expect(describe(r.events).last, 'fin');
    });

    test('29.999 pasos dejan el barco a un paso de zarpar', () {
      final r = real.advance(start, 29999);
      expect(real.isFinished(r.progress), isFalse);
      expect(real.currentStage(r.progress)?.id, 'barco');
      expect(real.stepsToNextItem(r.progress), 1);
    });

    test('1.000 pasos completan el árbol mágico', () {
      final r = real.advance(start, debugStepBonus);
      expect(describe(r.events), contains('etapa:arbol_magico'));
      expect(r.progress.stageIndex, 1);
    });
  });
}
