import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:test/test.dart';

void main() {
  const engine = ChapterEngine(chapter1);
  const steps = StepState(
    lastReading: 82018,
    totalSteps: 1300,
    todaySteps: 400,
    todayDate: '2026-11-22',
  );

  test('ida y vuelta en el formato nuevo', () {
    const game = GameSave(
      steps: steps,
      chapter: ChapterProgress(
        stageIndex: 1,
        stepsInStage: 300,
        collected: ['hoja_dorada', 'mapa_gramonia'],
      ),
    );
    expect(GameSave.decode(game.encode(), engine: engine), game);
  });

  test('sin nada guardado arranca de cero', () {
    expect(GameSave.decode(null, engine: engine), const GameSave.initial());
  });

  test(
    'una partida vieja (solo pasos) se carga y aplica el total al capítulo',
    () {
      final game = GameSave.decode(
        null,
        legacySource: steps.encode(),
        engine: engine,
      );
      expect(game.steps, steps);
      // 1.300 pasos: árbol mágico completo (1.000) y 300 en el nido.
      expect(game.chapter.stageIndex, 1);
      expect(game.chapter.stepsInStage, 300);
      expect(game.chapter.collected, [
        'hoja_dorada',
        'mapa_gramonia',
        'farol_luciernagas',
        'carta_mision',
      ]);
    },
  );

  test('el formato nuevo tiene prioridad sobre la partida vieja', () {
    const game = GameSave(steps: steps, chapter: ChapterProgress.initial());
    final loaded = GameSave.decode(
      game.encode(),
      legacySource: const StepState.initial().encode(),
      engine: engine,
    );
    expect(loaded, game);
  });

  test('si el capítulo guardado está roto, se reconstruye con los pasos', () {
    final source =
        '{"version":2,"steps":${steps.encode()},"chapter":{"stageIndex":"x"}}';
    final game = GameSave.decode(source, engine: engine);
    expect(game.steps, steps);
    expect(game.chapter.stageIndex, 1);
  });

  test('todo roto arranca de cero sin romperse', () {
    expect(
      GameSave.decode('{roto', legacySource: 'roto', engine: engine),
      const GameSave.initial(),
    );
  });
}
