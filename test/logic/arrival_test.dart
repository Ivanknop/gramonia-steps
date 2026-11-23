import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:test/test.dart';

import '../fakes/fake_random.dart';

void main() {
  const engine = ChapterEngine(chapter1);
  final puerto = chapter1.stages[4];

  ChapterProgress at(int stage, int steps, {bool entered = false}) =>
      ChapterProgress(
        stageIndex: stage,
        stepsInStage: steps,
        inventory: const {},
        sinceLast: const {},
        entered: entered,
      );

  test('durante el tramo todavía no se puede entrar', () {
    expect(engine.needsEntering(at(4, puerto.travelSteps - 1)), isFalse);
  });

  test('al terminar el tramo, falta tocar "Entrar"', () {
    final p = at(4, puerto.travelSteps);
    expect(engine.needsEntering(p), isTrue);
    final entered = engine.enter(p);
    expect(entered.entered, isTrue);
    expect(engine.needsEntering(entered), isFalse);
  });

  test('las etapas sin tramo no tienen pantalla de llegada', () {
    expect(engine.needsEntering(at(1, 500)), isFalse);
    expect(engine.enter(at(1, 500)), at(1, 500));
  });

  test('sin entrar, los pasos siguen sumando y salen objetos', () {
    final r = engine.advance(at(4, puerto.travelSteps), 49, FixedRandom(1));
    expect(r.progress.stepsInStage, puerto.travelSteps + 49);
    expect(r.progress.entered, isFalse);
    final found = engine.advance(r.progress, 1, FixedRandom(0));
    // Salió la pista: la etapa terminó aunque no se entró.
    expect(found.events.whereType<StageCompleted>(), hasLength(1));
  });

  test('al pasar a otra etapa, hay que volver a entrar', () {
    final p = at(4, puerto.travelSteps + 10, entered: true);
    final r = engine.advance(p, 40, FixedRandom(0)); // sale la pista
    expect(r.progress.stageIndex, 5);
    expect(r.progress.entered, isFalse);
    expect(engine.isTraveling(r.progress), isTrue);
  });

  test('se guarda; las partidas de antes cuentan como que ya entraron', () {
    final p = at(4, puerto.travelSteps);
    expect(ChapterProgress.fromJson(p.toJson()), p);
    final old = p.toJson()..remove('entered');
    expect(ChapterProgress.fromJson(old).entered, isTrue);
  });
}
