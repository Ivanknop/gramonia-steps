/// Progreso guardado dentro de un capítulo.
class ChapterProgress {
  const ChapterProgress({
    required this.stageIndex,
    required this.stepsInStage,
    required this.collected,
  });

  const ChapterProgress.initial()
    : stageIndex = 0,
      stepsInStage = 0,
      collected = const [];

  /// Etapa actual (0 = la primera). Si es igual a la cantidad de etapas,
  /// el capítulo está terminado.
  final int stageIndex;

  /// Pasos acumulados dentro de la etapa actual.
  final int stepsInStage;

  /// Ids de los objetos conseguidos, en el orden en que se consiguieron.
  final List<String> collected;

  bool has(String itemId) => collected.contains(itemId);

  Map<String, Object?> toJson() => {
    'stageIndex': stageIndex,
    'stepsInStage': stepsInStage,
    'collected': collected,
  };

  /// Lanza una excepción si el JSON no tiene la forma esperada.
  static ChapterProgress fromJson(Map<String, dynamic> json) {
    return ChapterProgress(
      stageIndex: json['stageIndex'] as int,
      stepsInStage: json['stepsInStage'] as int,
      collected: List<String>.unmodifiable(json['collected'] as List),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChapterProgress &&
      other.stageIndex == stageIndex &&
      other.stepsInStage == stepsInStage &&
      _sameList(other.collected, collected);

  @override
  int get hashCode =>
      Object.hash(stageIndex, stepsInStage, Object.hashAll(collected));

  @override
  String toString() =>
      'ChapterProgress(stage: $stageIndex, steps: $stepsInStage, '
      'collected: $collected)';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
