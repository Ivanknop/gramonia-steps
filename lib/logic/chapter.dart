/// Estructura de un capítulo: etapas con objetos para juntar.
/// Los valores concretos están en `lib/data/`.
library;

class StageItem {
  const StageItem({
    required this.id,
    required this.name,
    required this.atSteps,
  });

  final String id;
  final String name;

  /// Pasos dentro de la etapa en los que se consigue el objeto.
  final int atSteps;
}

class Stage {
  const Stage({
    required this.id,
    required this.name,
    required this.steps,
    required this.items,
    required this.reward,
  });

  final String id;
  final String name;

  /// Meta de pasos de la etapa. El último objeto está justo en este número.
  final int steps;

  /// Objetos ordenados por [StageItem.atSteps].
  final List<StageItem> items;
  final String reward;
}

class Chapter {
  const Chapter({required this.name, required this.stages});

  final String name;
  final List<Stage> stages;

  int get totalSteps => stages.fold(0, (sum, s) => sum + s.steps);
}
