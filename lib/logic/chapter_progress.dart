/// Progreso guardado dentro de un capítulo.
class ChapterProgress {
  const ChapterProgress({
    required this.stageIndex,
    required this.stepsInStage,
    required this.inventory,
    required this.sinceLast,
  });

  const ChapterProgress.initial()
    : stageIndex = 0,
      stepsInStage = 0,
      inventory = const {},
      sinceLast = const {};

  /// Etapa actual (0 = la primera). Si es igual a la cantidad de etapas,
  /// el capítulo está terminado.
  final int stageIndex;

  /// Pasos dentro de la etapa actual, contando el tramo de "llegar".
  final int stepsInStage;

  /// Cuántos objetos de cada tipo hay (por id).
  final Map<String, int> inventory;

  /// Para la garantía de mala suerte: pasos desde la última vez que salió
  /// cada aparición al azar de la etapa actual (por [Spawn.key]).
  final Map<String, int> sinceLast;

  int count(String itemId) => inventory[itemId] ?? 0;

  bool has(String itemId) => count(itemId) > 0;

  Map<String, Object?> toJson() => {
    'stageIndex': stageIndex,
    'stepsInStage': stepsInStage,
    'inventory': inventory,
    'sinceLast': sinceLast,
  };

  /// Lanza una excepción si el JSON no tiene la forma esperada.
  static ChapterProgress fromJson(Map<String, dynamic> json) {
    Map<String, int> ints(Object? value) => Map.unmodifiable(
      (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
    );
    return ChapterProgress(
      stageIndex: json['stageIndex'] as int,
      stepsInStage: json['stepsInStage'] as int,
      inventory: ints(json['inventory']),
      sinceLast: ints(json['sinceLast']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChapterProgress &&
      other.stageIndex == stageIndex &&
      other.stepsInStage == stepsInStage &&
      _sameMap(other.inventory, inventory) &&
      _sameMap(other.sinceLast, sinceLast);

  @override
  int get hashCode => Object.hash(
    stageIndex,
    stepsInStage,
    Object.hashAllUnordered(
      inventory.entries.map((e) => '${e.key}=${e.value}'),
    ),
    Object.hashAllUnordered(
      sinceLast.entries.map((e) => '${e.key}=${e.value}'),
    ),
  );

  @override
  String toString() =>
      'ChapterProgress(stage: $stageIndex, steps: $stepsInStage, '
      'inventory: $inventory, sinceLast: $sinceLast)';
}

bool _sameMap(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
