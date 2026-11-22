/// Textos visibles del juego, en español.
abstract final class Strings {
  static const appTitle = 'Gramonia';
  static const loading = 'Cargando…';
  static const todayLabel = 'Pasos de hoy';
  static String total(int steps) => 'Total: ${formatNumber(steps)} pasos';
  static const needsPermission =
      'Para contar tus pasos, Gramonia necesita el permiso de actividad física.';
  static const grantPermission = 'Dar permiso';
  static const permissionBlocked =
      'El permiso de actividad física está bloqueado. '
      'Activalo en los Ajustes de la app.';
  static const openSettings = 'Abrir ajustes';
  static const noSensor = 'Este celular no tiene sensor de pasos.';
  static String debugAdd(int steps) => '+${formatNumber(steps)} pasos';

  // Etapas y objetos.
  static String stageOf(int number, int count) => 'Etapa $number de $count';
  static String stageProgress(int steps, int goal) =>
      '${formatNumber(steps)} / ${formatNumber(goal)} pasos';
  static String reward(String reward) => 'Recompensa: $reward';
  static const itemsTitle = 'Objetos para juntar';
  static String stepsToNext(int steps) =>
      steps == 1 ? 'Falta 1 paso' : 'Faltan ${formatNumber(steps)} pasos';
  static String itemAt(int steps) => 'A los ${formatNumber(steps)} pasos';
  static const journeyTitle = 'El viaje';
  static const chapterDoneTitle = '¡El barco zarpó!';
  static const chapterDoneBody =
      'Terminaste el Capítulo 1. La Isla Negra te espera en el próximo.';

  // Avisos.
  static String itemCollected(String item) => '¡Conseguiste: $item!';
  static String stageCompleted(String stage, String reward) =>
      '¡Terminaste $stage! Recompensa: $reward';
  static const chapterCompleted = '¡El barco zarpó! Fin del Capítulo 1';
  static String collectedSummary(int items, int stages) {
    final itemsText = items == 1 ? '1 objeto' : '$items objetos';
    if (stages == 0) return '¡Conseguiste $itemsText!';
    final stagesText = stages == 1 ? '1 etapa' : '$stages etapas';
    return '¡Conseguiste $itemsText y terminaste $stagesText!';
  }

  /// 12345 → "12.345".
  static String formatNumber(int n) {
    final digits = n.abs().toString();
    final buffer = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
