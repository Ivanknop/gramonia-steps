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

  ChapterProgress at(int stage, int steps, [Map<String, int> inv = const {}]) =>
      ChapterProgress(
        stageIndex: stage,
        stepsInStage: steps,
        inventory: inv,
        sinceLast: const {},
      );

  test('un objeto: su mensaje', () {
    expect(noticeFor(events(start, 50)), chapter1.item('flor_lila').message);
  });

  test('terminar una etapa con su último objeto: el mensaje final', () {
    final p = at(0, 700, {'flor_lila': 14});
    expect(noticeFor(events(p, 50)), stages[0].completeMessage);
  });

  test('un canje con el común que lo completa: el mensaje del canje', () {
    final p = at(1, 0, {'semilla_agua': 9});
    // A los 50 pasos sale una semilla común (no la de fuego, que es cada 200).
    expect(noticeFor(events(p, 50)), stages[1].exchanges.single.message);
  });

  test('el canje reemplaza {item} por el objeto que se recibe', () {
    final p = at(4, 15000, {'gema': 99});
    expect(
      noticeFor(events(p, 50, dice: 1)),
      'Los dragones cuentan tus 100 gemas, sonríen con todos sus dientes y te '
      'dan a cambio: Piedra de fuego.',
    );
  });

  test('las gemas solas no tienen aviso', () {
    final p = at(4, 15000);
    expect(noticeFor(events(p, 50, dice: 1)), isNull);
  });

  test('al terminar el tramo de llegar: aviso de llegada', () {
    final p = at(3, 9900);
    expect(noticeFor(events(p, 100, dice: 1)), Strings.arrived('El puerto'));
  });

  test('muchas cosas juntas: un resumen', () {
    expect(noticeFor(events(start, 2000)), startsWith('¡Conseguiste'));
  });

  test('fin del capítulo: el mensaje del barco', () {
    expect(noticeFor(events(start, 1000000)), stages.last.completeMessage);
  });
}
