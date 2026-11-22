import 'dart:convert';
import 'dart:math';

import 'chapter_engine.dart';
import 'chapter_progress.dart';
import 'step_state.dart';

/// Toda la partida guardada en el celular: pasos y progreso del capítulo.
class GameSave {
  const GameSave({required this.steps, required this.chapter});

  const GameSave.initial()
    : steps = const StepState.initial(),
      chapter = const ChapterProgress.initial();

  /// 3: etapas con inventario por cantidades (azar, fijos, canjes).
  static const int version = 3;

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
  /// - [source] es la partida guardada (formato actual o el de la versión 2).
  /// - [legacySource] es la partida de la versión 1 (solo pasos), si existe.
  ///
  /// Si el progreso del capítulo falta, está roto o es de una versión vieja
  /// (que tenía otras etapas y objetos), se reconstruye aplicando el total de
  /// pasos a las reglas actuales: así no se pierde lo caminado.
  static GameSave decode(
    String? source, {
    String? legacySource,
    required ChapterEngine engine,
    Random? random,
  }) {
    StepState? steps;
    ChapterProgress? chapter;

    final json = _tryDecodeMap(source);
    if (json != null) {
      steps = _tryParse(() => StepState.fromJson(_map(json['steps'])));
      if (json['version'] == version) {
        chapter = _tryParse(
          () => ChapterProgress.fromJson(_map(json['chapter'])),
        );
      }
    }

    steps ??= StepState.decode(legacySource);
    chapter ??= engine
        .advance(
          const ChapterProgress.initial(),
          steps.totalSteps,
          random ?? Random(),
        )
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
