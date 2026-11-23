/// Progreso guardado dentro de un capítulo.
class ChapterProgress {
  const ChapterProgress({
    required this.stageIndex,
    required this.stepsInStage,
    required this.inventory,
    required this.sinceLast,
    this.found = const {},
    this.unseen = 0,
  });

  const ChapterProgress.initial()
    : stageIndex = 0,
      stepsInStage = 0,
      inventory = const {},
      sinceLast = const {},
      found = const {},
      unseen = 0;

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

  /// Cuántos de cada objeto se consiguieron en todo el capítulo (los canjes
  /// descuentan del inventario, pero no de acá). Para la bolsa.
  final Map<String, int> found;

  /// Objetos nuevos que todavía no se vieron en la bolsa.
  final int unseen;

  int count(String itemId) => inventory[itemId] ?? 0;

  bool has(String itemId) => count(itemId) > 0;

  int foundCount(String itemId) => found[itemId] ?? 0;

  /// La misma partida, con [count] etapas nuevas agregadas antes.
  ChapterProgress shiftStages(int count) => ChapterProgress(
    stageIndex: stageIndex + count,
    stepsInStage: stepsInStage,
    inventory: inventory,
    sinceLast: sinceLast,
    found: found,
    unseen: unseen,
  );

  /// La misma partida, con otros pasos dentro de la etapa.
  ChapterProgress withStepsInStage(int steps) => ChapterProgress(
    stageIndex: stageIndex,
    stepsInStage: steps,
    inventory: inventory,
    sinceLast: sinceLast,
    found: found,
    unseen: unseen,
  );

  ChapterProgress copyWith({int? unseen}) => ChapterProgress(
    stageIndex: stageIndex,
    stepsInStage: stepsInStage,
    inventory: inventory,
    sinceLast: sinceLast,
    found: found,
    unseen: unseen ?? this.unseen,
  );

  Map<String, Object?> toJson() => {
    'stageIndex': stageIndex,
    'stepsInStage': stepsInStage,
    'inventory': inventory,
    'sinceLast': sinceLast,
    'found': found,
    'unseen': unseen,
  };

  /// Lanza una excepción si el JSON no tiene la forma esperada.
  ///
  /// Las partidas guardadas antes de la bolsa no tienen `found` ni `unseen`:
  /// lo conseguido arranca igual al inventario y no hay nada sin ver.
  static ChapterProgress fromJson(Map<String, dynamic> json) {
    Map<String, int> ints(Object? value) => Map.unmodifiable(
      (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
    );
    final inventory = ints(json['inventory']);
    return ChapterProgress(
      stageIndex: json['stageIndex'] as int,
      stepsInStage: json['stepsInStage'] as int,
      inventory: inventory,
      sinceLast: ints(json['sinceLast']),
      found: json['found'] == null ? inventory : ints(json['found']),
      unseen: json['unseen'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChapterProgress &&
      other.stageIndex == stageIndex &&
      other.stepsInStage == stepsInStage &&
      _sameMap(other.inventory, inventory) &&
      _sameMap(other.sinceLast, sinceLast) &&
      _sameMap(other.found, found) &&
      other.unseen == unseen;

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
    Object.hashAllUnordered(found.entries.map((e) => '${e.key}=${e.value}')),
    unseen,
  );

  @override
  String toString() =>
      'ChapterProgress(stage: $stageIndex, steps: $stepsInStage, '
      'inventory: $inventory, sinceLast: $sinceLast, found: $found, '
      'unseen: $unseen)';
}

bool _sameMap(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
