/// Qué música suena en cada momento.
library;

/// Los temas del juego. Los archivos están en chapter1.dart.
enum MusicTrack {
  /// Tierno: portada, presentación e introducción.
  intro,

  /// Caminata y aventura: la mayoría de las etapas y sus tramos.
  aventura,

  /// Tensión: la tormenta en el muelle y la Montaña Dragón.
  tension,

  /// Tierno: "Continuará..." y créditos.
  finale,
}

/// La pantalla grande que se ve.
enum MusicScene { title, presentation, intro, game }

/// Tema que corresponde.
///
/// - [stageMusic] es el tema de la etapa actual (vale también para su tramo
///   de caminata), o null si el capítulo terminó.
/// - Encima de todo, el cierre ("Continuará...") y los créditos.
MusicTrack musicFor({
  required MusicScene scene,
  required MusicTrack? stageMusic,
  bool ending = false,
  bool credits = false,
}) {
  if (ending || credits) return MusicTrack.finale;
  return switch (scene) {
    MusicScene.title ||
    MusicScene.presentation ||
    MusicScene.intro => MusicTrack.intro,
    MusicScene.game => stageMusic ?? MusicTrack.finale,
  };
}
