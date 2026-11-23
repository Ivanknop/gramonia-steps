import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/strings.dart';
import 'package:rpg/ui/notices.dart';
import 'package:test/test.dart';

import '../fakes/fake_random.dart';

void main() {
  const engine = ChapterEngine(chapter1);
  final stages = chapter1.stages;
  const start = ChapterProgress.initial();

  List<ChapterEvent> events(ChapterProgress p, int steps, {int dice = 0}) =>
      engine.advance(p, steps, FixedRandom(dice)).events;

  List<Moment> moments(ChapterProgress p, int steps, {int dice = 0}) =>
      momentsFor(chapter1, events(p, steps, dice: dice));

  ChapterProgress at(int stage, int steps, [Map<String, int> inv = const {}]) =>
      ChapterProgress(
        stageIndex: stage,
        stepsInStage: steps,
        inventory: inv,
        sinceLast: const {},
      );

  /// Resumen legible de los momentos, para comparar.
  List<String> describe(List<Moment> moments) => [
    for (final m in moments)
      switch (m) {
        FoundMoment(:final item, :final count) => '${item.id}×$count',
        StageMoment(:final stage) => 'fin:${stage.id}',
        TravelMoment(:final stage) => 'camino:${stage.id}',
      },
  ];

  test('un objeto: cartel con "¡Encontraste…!" y su mensaje', () {
    final found = moments(start, 100).single as FoundMoment;
    final flor = chapter1.item('flor_amarilla');
    expect(found.item, flor);
    expect(found.title, '¡Encontraste una flor amarilla!');
    expect(found.message, flor.message);
  });

  test('varios iguales juntos: un solo cartel con la cantidad', () {
    final found = moments(start, 300).single as FoundMoment;
    expect(found.count, 3);
    expect(found.title, Strings.foundMany('Flor amarilla', 3));
  });

  test('terminar el jardín: fin de etapa, sin caminata (mismo lugar)', () {
    final p = at(0, 1400, {'flor_amarilla': 14});
    expect(describe(moments(p, 100)), [
      'flor_amarilla×1',
      'fin:jardin_abuelita',
    ]);
  });

  test('terminar las flores lilas: cartel, fin de etapa y caminata', () {
    final p = at(1, 700, {'flor_lila': 14});
    expect(describe(moments(p, 50)), [
      'flor_lila×1',
      'fin:casa_abuelita',
      'camino:nido_rocanron',
    ]);
  });

  test('sin caminata si la etapa siguiente tiene su tramo de llegar', () {
    final p = at(3, 5000, {
      for (final id in ['hoja', 'gota', 'piedra', 'sol', 'luna'])
        'pieza_$id': 1,
    });
    expect(describe(moments(p, 1000)), [
      'pieza_estrella×1',
      'fin:laberinto_hormigas',
    ]);
  });

  test('un canje: el cartel del objeto lleva el texto del canje', () {
    final p = at(2, 0, {'semilla_agua': 9});
    // A los 50 pasos sale una semilla común (no la de fuego, que es cada 200).
    final found = moments(p, 50).whereType<FoundMoment>().toList();
    expect(found.last.item.id, 'semilla_fuego');
    expect(found.last.message, stages[2].exchanges.single.message);
  });

  test('el canje reemplaza {item} por el objeto que se recibe', () {
    final p = at(5, 15000, {'gema': 99});
    final found = moments(p, 50, dice: 1).single as FoundMoment;
    expect(
      found.message,
      'Los dragones cuentan tus 100 gemas, sonríen con todos sus dientes y te '
      'dan a cambio: Piedra de fuego.',
    );
  });

  test('las gemas solas no tienen cartel', () {
    expect(moments(at(5, 15000), 50, dice: 1), isEmpty);
  });

  test('como mucho 3 carteles, primero los objetos que pide la etapa', () {
    // Con todo a favor, 3.500 pasos pasan por el jardín, las flores lilas y
    // el nido: flores, semillas comunes y semillas de fuego.
    final found = moments(start, 3500).whereType<FoundMoment>().toList();
    expect(found, hasLength(maxFoundMoments));
    expect(found.map((m) => m.item.id), isNot(contains('semilla_agua')));
  });

  test('un salto enorme: todas las etapas terminadas, en orden', () {
    final stagesDone = moments(
      start,
      1000000,
    ).whereType<StageMoment>().map((m) => m.stage).toList();
    expect(stagesDone, stages);
  });

  test('al terminar el tramo de llegar: aviso de llegada', () {
    final p = at(4, 9900);
    expect(noticeFor(events(p, 100, dice: 1)), Strings.arrived('El puerto'));
  });

  test('sin llegada no hay aviso chico', () {
    expect(noticeFor(events(start, 50)), isNull);
  });
}
