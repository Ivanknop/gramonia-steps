import 'dart:convert';
import 'dart:math';

import 'chapter_engine.dart';
import 'chapter_progress.dart';
import 'step_state.dart';
import 'story.dart';
import 'wallet.dart';

/// Toda la partida guardada en el celular: pasos, progreso del capítulo y
/// monedas.
///
/// Ninguna actualización puede perder pasos, objetos ni etapas: si cambia lo
/// que se guarda, subir [version] y convertir la partida vieja en [decode]
/// (con un test que cargue una partida real de la versión anterior). El
/// historial de pasos por día se guarda aparte (StepHistoryStorage).
class GameSave {
  const GameSave({
    required this.steps,
    required this.chapter,
    this.playerName,
    this.introSeen = false,
    this.wallet = Wallet.initial,
    this.genero,
  });

  const GameSave.initial()
    : steps = const StepState.initial(),
      chapter = const ChapterProgress.initial(),
      playerName = null,
      introSeen = false,
      wallet = Wallet.initial,
      genero = null;

  /// Versión del formato guardado (no es la versión de la app).
  ///
  /// - 3: etapas con inventario por cantidades (azar, fijos, canjes).
  /// - 4: se sumó una etapa al principio (el paseo por el jardín).
  /// - 5: el nido y el laberinto empiezan con un tramo de caminata.
  ///   Es la de la app 1.0.0 y 1.1.0.
  /// - 6: monedas, bono diario y bono de bienvenida (app 1.2.0). En la
  ///   1.2.0 también se suma `player.gender`, opcional: si falta, se
  ///   pregunta.
  static const int version = 6;

  /// Versión en la que llegaron las monedas. Las partidas de antes reciben
  /// el bono de bienvenida.
  static const int _coinsSince = 6;

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

  /// Monedas y bonos cobrados.
  final Wallet wallet;

  /// Chico, chica o "prefiero no decir". Nulo si todavía no se preguntó
  /// (partidas de antes de la 1.2.0: se pregunta una vez al abrir).
  final Genero? genero;

  GameSave copyWith({
    StepState? steps,
    ChapterProgress? chapter,
    String? playerName,
    bool? introSeen,
    Wallet? wallet,
    Genero? genero,
  }) => GameSave(
    steps: steps ?? this.steps,
    chapter: chapter ?? this.chapter,
    playerName: playerName ?? this.playerName,
    introSeen: introSeen ?? this.introSeen,
    wallet: wallet ?? this.wallet,
    genero: genero ?? this.genero,
  );

  String encode() => jsonEncode({
    'version': version,
    'steps': steps.toJson(),
    'chapter': chapter.toJson(),
    'player': {
      'name': playerName,
      'introSeen': introSeen,
      'gender': genero?.name,
    },
    'wallet': wallet.toJson(),
  });

  /// Lee la partida guardada.
  ///
  /// - [source] es la partida guardada (formato actual o el de la versión 2).
  /// - [legacySource] es la partida de la versión 1 (solo pasos), si existe.
  ///
  /// Si el progreso del capítulo falta, está roto o es de una versión vieja
  /// (que tenía otras etapas y objetos), se reconstruye aplicando el total de
  /// pasos a las reglas actuales: así no se pierde lo caminado.
  ///
  /// Las partidas de antes de las monedas (versión 5 o anterior) reciben
  /// una sola vez el bono de bienvenida: [welcomeCoinsPer100Steps] monedas
  /// por cada 100 pasos caminados. Las partidas nuevas no.
  static GameSave decode(
    String? source, {
    String? legacySource,
    required ChapterEngine engine,
    required int welcomeCoinsPer100Steps,
    Random? random,
  }) {
    StepState? steps;
    ChapterProgress? chapter;
    String? playerName;
    var introSeen = false;
    Genero? genero;
    Wallet? wallet;
    // Hay una partida de una versión anterior (y no es una instalación nueva).
    var isOld = legacySource != null && legacySource.isNotEmpty;

    final json = _tryDecodeMap(source);
    if (json != null) {
      final savedVersion = json['version'];
      isOld = savedVersion is! int || savedVersion < _coinsSince;
      if (!isOld) {
        wallet = _tryParse(() => Wallet.fromJson(_map(json['wallet'])));
      }
      steps = _tryParse(() => StepState.fromJson(_map(json['steps'])));
      // Las partidas de antes no tienen nombre: Sofía lo pregunta.
      final player = _tryParse(() => _map(json['player']));
      playerName = _tryParse<String?>(() => player?['name'] as String?);
      introSeen =
          _tryParse<bool?>(() => player?['introSeen'] as bool?) ?? false;
      genero = _tryParse(
        () => Genero.values.byName(player?['gender'] as String),
      );
      final saved = switch (json['version']) {
        3 || 4 || 5 || version => _tryParse(
          () => ChapterProgress.fromJson(_map(json['chapter'])),
        ),
        _ => null,
      };
      chapter = switch ((json['version'], saved)) {
        (_, null) => null,
        (5 || version, final p?) => p,
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

    wallet ??= Wallet.initial;
    // Sin pasos no hay nada que agradecer (por ejemplo, una partida rota).
    if (isOld && steps.totalSteps > 0) {
      wallet = wallet.payWelcome(steps.totalSteps, welcomeCoinsPer100Steps);
    }

    return GameSave(
      steps: steps,
      chapter: chapter,
      playerName: playerName,
      introSeen: introSeen,
      wallet: wallet,
      genero: genero,
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
      other.introSeen == introSeen &&
      other.wallet == wallet &&
      other.genero == genero;

  @override
  int get hashCode =>
      Object.hash(steps, chapter, playerName, introSeen, wallet, genero);

  @override
  String toString() =>
      'GameSave($steps, $chapter, player: $playerName, intro: $introSeen, '
      '$wallet, $genero)';
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
