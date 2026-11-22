import 'dart:convert';

import 'chapter_engine.dart';
import 'chapter_progress.dart';
import 'step_state.dart';

/// Toda la partida guardada en el celular: pasos y progreso del capítulo.
class GameSave {
  const GameSave({required this.steps, required this.chapter});

  const GameSave.initial()
    : steps = const StepState.initial(),
      chapter = const ChapterProgress.initial();

  static const int version = 2;

  final StepState steps;
  final ChapterProgress chapter;

  GameSave copyWith({StepState? steps, ChapterProgress? chapter}) =>
      GameSave(steps: steps ?? this.steps, chapter: chapter ?? this.chapter);

  String encode() => jsonEncode({
    'version': version,
    'steps': steps.toJson(),
    'chapter': chapter.toJson(),
  });

  /// Lee la partida guardada.
  ///
  /// - [source] es la partida en el formato actual.
  /// - [legacySource] es la partida vieja (solo pasos), si existe.
  ///
  /// Si el progreso del capítulo falta o está roto, se reconstruye con el
  /// total de pasos: así una partida vieja no pierde lo caminado.
  static GameSave decode(
    String? source, {
    String? legacySource,
    required ChapterEngine engine,
  }) {
    StepState? steps;
    ChapterProgress? chapter;

    final json = _tryDecodeMap(source);
    if (json != null) {
      steps = _tryParse(() => StepState.fromJson(_map(json['steps'])));
      chapter = _tryParse(
        () => ChapterProgress.fromJson(_map(json['chapter'])),
      );
    }

    steps ??= StepState.decode(legacySource);
    chapter ??= engine
        .advance(const ChapterProgress.initial(), steps.totalSteps)
        .progress;

    return GameSave(steps: steps, chapter: chapter);
  }

  @override
  bool operator ==(Object other) =>
      other is GameSave && other.steps == steps && other.chapter == chapter;

  @override
  int get hashCode => Object.hash(steps, chapter);

  @override
  String toString() => 'GameSave($steps, $chapter)';
}

Map<String, dynamic>? _tryDecodeMap(String? source) {
  if (source == null || source.isEmpty) return null;
  try {
    return jsonDecode(source) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _map(Object? value) => value as Map<String, dynamic>;

T? _tryParse<T>(T Function() parse) {
  try {
    return parse();
  } catch (_) {
    return null;
  }
}
