import 'package:rpg/data/chapter1.dart';
import 'package:test/test.dart';

void main() {
  test('el capítulo tiene 7 etapas y 30.000 pasos', () {
    expect(chapter1.stages, hasLength(7));
    expect(chapter1.totalSteps, 30000);
  });

  for (final stage in chapter1.stages) {
    group(stage.name, () {
      test('tiene objetos y el último está en la meta', () {
        expect(stage.items, isNotEmpty);
        expect(stage.items.last.atSteps, stage.steps);
      });

      test('los umbrales van en orden creciente y son positivos', () {
        var previous = 0;
        for (final item in stage.items) {
          expect(item.atSteps, greaterThan(previous), reason: item.name);
          previous = item.atSteps;
        }
      });
    });
  }

  test('los ids de etapas y objetos no se repiten', () {
    final stageIds = chapter1.stages.map((s) => s.id).toList();
    expect(stageIds.toSet(), hasLength(stageIds.length));
    final itemIds = [
      for (final s in chapter1.stages) ...s.items.map((i) => i.id),
    ];
    expect(itemIds.toSet(), hasLength(itemIds.length));
    expect(itemIds, hasLength(42));
  });
}
