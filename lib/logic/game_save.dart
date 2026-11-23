import 'dart:convert';
import 'dart:math';

import 'chapter_engine.dart';
import 'chapter_progress.dart';
import 'step_state.dart';

/// Toda la partida guardada en el celular: pasos y progreso del capítulo.
class GameSave {
  const GameSave({
    required this.steps,
    required this.chapter,
    this.playerName,
    this.introSeen = false,
  });

  const GameSave.initial()
    : steps = const StepState.initial(),
      chapter = const ChapterProgress.initial(),
      playerName = null,
      introSeen = false;

  /// 3: etapas con inventario por cantidades (azar, fijos, canjes).
  /// 4: se sumó una etapa al principio (el paseo por el jardín).
  /// 5: el nido y el laberinto empiezan con un tramo de caminata.
  static const int version = 5;

  /// Etapas que se agregaron al principio del capítulo en la versión 4.
  static const int _stagesAddedInV4 = 1;

  /// Etapas que en la versión 4 no tenían tramo de caminata y en la 5 sí.
  static const _travelAddedInV5 = {'nido_rocanron', 'laberinto_hormigas'};

  final StepState steps;
  final ChapterProgress chapter;

  /// Nombre de quien juega (lo pregunta Sofía). Nulo hasta que lo escribe.
  final String? playerName;

  /// Si ya se vio la introducción (Mututu despierta).
  final bool introSeen;

  GameSave copyWith({
    StepState? steps,
    ChapterProgress? chapter,
    String? playerName,
    bool? introSeen,
  }) => GameSave(
    steps: steps ?? this.steps,
    chapter: chapter ?? this.chapter,
    playerName: playerName ?? this.playerName,
    introSeen: introSeen ?? this.introSeen,
  );

  String encode() => jsonEncode({
    'version': version,
    'steps': steps.toJson(),
    'chapter': chapter.toJson(),
    'player': {'name': playerName, 'introSeen': introSeen},
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
    String? playerName;
    var introSeen = false;

    final json = _tryDecodeMap(source);
    if (json != null) {
      steps = _tryParse(() => StepState.fromJson(_map(json['steps'])));
      // Las partidas de antes no tienen nombre: Sofía lo pregunta.
      final player = _tryParse(() => _map(json['player']));
      playerName = _tryParse<String?>(() => player?['name'] as String?);
      introSeen =
          _tryParse<bool?>(() => player?['introSeen'] as bool?) ?? false;
      final saved = switch (json['version']) {
        3 || 4 || version => _tryParse(
          () => ChapterProgress.fromJson(_map(json['chapter'])),
        ),
        _ => null,
      };
      chapter = switch ((json['version'], saved)) {
        (_, null) => null,
        (version, final p?) => p,
        (4, final p?) => _addTravelV5(p, engine),
        // La partida ya había empezado: el paseo por el jardín cuenta como
        // hecho y sigue en la misma etapa que tenía.
        (_, final p?) => _addTravelV5(p.shiftStages(_stagesAddedInV4), engine),
      };
    }

    steps ??= StepState.decode(legacySource);
    chapter ??= engine
        .advance(
          const ChapterProgress.initial(),
          steps.totalSteps,
          random ?? Random(),
        )
        .progress;

    return GameSave(
      steps: steps,
      chapter: chapter,
      playerName: playerName,
      introSeen: introSeen,
    );
  }

  /// Si la partida estaba en una etapa que ganó su tramo de caminata, ese
  /// tramo ya se caminó: se suma a los pasos de la etapa (así sigue juntando
  /// objetos donde estaba).
  static ChapterProgress _addTravelV5(ChapterProgress p, ChapterEngine engine) {
    final stage = engine.currentStage(p);
    if (stage == null || !_travelAddedInV5.contains(stage.id)) return p;
    return p.withStepsInStage(p.stepsInStage + stage.travelSteps);
  }

  @override
  bool operator ==(Object other) =>
      other is GameSave &&
      other.steps == steps &&
      other.chapter == chapter &&
      other.playerName == playerName &&
      other.introSeen == introSeen;

  @override
  int get hashCode => Object.hash(steps, chapter, playerName, introSeen);

  @override
  String toString() =>
      'GameSave($steps, $chapter, player: $playerName, intro: $introSeen)';
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
