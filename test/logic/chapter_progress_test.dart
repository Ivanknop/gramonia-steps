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

  test('lo conseguido y lo nuevo sin ver van y vuelven por JSON', () {
    const withBag = ChapterProgress(
      stageIndex: 1,
      stepsInStage: 10,
      inventory: {'semilla_agua': 2},
      sinceLast: {},
      found: {'semilla_agua': 12, 'flor_lila': 15},
      unseen: 3,
    );
    expect(ChapterProgress.fromJson(withBag.toJson()), withBag);
    expect(withBag.foundCount('semilla_agua'), 12);
    expect(withBag.foundCount('nada'), 0);
  });

  test('una partida de antes de la bolsa: lo conseguido es el inventario', () {
    final old = {
      'stageIndex': 2,
      'stepsInStage': 1234,
      'inventory': {'flor_lila': 15, 'semilla_agua': 3},
      'sinceLast': {'semilla_fuego': 800},
    };
    final loaded = ChapterProgress.fromJson(old);
    expect(loaded.found, {'flor_lila': 15, 'semilla_agua': 3});
    expect(loaded.unseen, 0);
    expect(loaded.inventory, p.inventory);
  });

  test('copyWith cambia solo el número de nuevos', () {
    final seen = p.copyWith(unseen: 0);
    expect(seen.unseen, 0);
    expect(seen.inventory, p.inventory);
    expect(seen.stageIndex, p.stageIndex);
  });
}
