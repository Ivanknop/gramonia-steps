import 'package:rpg/logic/chapter_progress.dart';
import 'package:test/test.dart';

void main() {
  const p = ChapterProgress(
    stageIndex: 2,
    stepsInStage: 1234,
    inventory: {'flor_lila': 15, 'semilla_agua': 3},
    sinceLast: {'semilla_fuego': 800},
  );

  test('ida y vuelta por JSON', () {
    expect(ChapterProgress.fromJson(p.toJson()), p);
  });

  test('count() y has() leen el inventario', () {
    expect(p.count('flor_lila'), 15);
    expect(p.count('nada'), 0);
    expect(p.has('semilla_agua'), isTrue);
    expect(p.has('nada'), isFalse);
  });

  test('el formato viejo (lista de objetos) no se acepta', () {
    expect(
      () => ChapterProgress.fromJson({
        'stageIndex': 1,
        'stepsInStage': 10,
        'collected': ['hoja_dorada'],
      }),
      throwsA(anything),
    );
  });
}
