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
  static String walkingTo(String place) => 'Caminando hasta $place';
  static String reward(String reward) => 'Recompensa: $reward';
  static const goalsTitle = 'Para juntar';
  static String countOf(int have, int need) => '$have / $need';
  static String stepsToNext(int steps) =>
      steps == 1 ? 'Falta 1 paso' : 'Faltan ${formatNumber(steps)} pasos';
  static const appearsRandomly = 'Aparece al azar';
  static const afterArriving = 'Aparece al llegar';
  static String exchangeProgress(
    String inputs,
    int have,
    int need,
    String output,
  ) => '$inputs: $have / $need → $output';
  static const or = ' o ';
  static const journeyTitle = 'El viaje';
  static const chapterDoneTitle = '¡El barco zarpó!';

  // Objetos conseguidos.
  static String found(String foundName) => '¡Encontraste $foundName!';
  static String foundMany(String name, int count) =>
      '¡Encontraste $name ×$count!';
  static const tapToContinue = 'Tocá para seguir';

  // Fin de etapa.
  static const stageDoneTitle = '¡Etapa completada!';
  static String youGot(String reward) => 'Conseguiste: $reward';
  static const continueButton = '¡Seguir!';

  // Bolsa.
  static const bagTitle = 'Tu bolsa';
  static const bagButton = 'Abrir la bolsa';
  static const bagItems = 'Objetos';
  static const bagRewards = 'Recompensas';
  static const bagEmpty = 'Todavía no conseguiste nada. ¡A caminar!';
  static const noRewardsYet = 'Las recompensas llegan al terminar cada etapa.';
  static String times(int count) => '×$count';
  static String neededFor(int count, String stage) => count == 1
      ? 'Lo pide la etapa «$stage».'
      : 'Hay que juntar $count para la etapa «$stage».';
  static String tradedFor(int count, String output, String? together) =>
      together == null
      ? 'Juntá $count y se cambian por $output.'
      : 'Junto con $together, juntá $count y se cambian por $output.';
  static String whatIsMissing(String stage) => 'lo que falte para «$stage»';
  static String foundIn(int number, String stage) =>
      'Se consigue en la etapa $number: $stage.';
  static String rewardOf(int number, String stage) =>
      'Recompensa de la etapa $number: $stage.';
  static const close = 'Cerrar';

  // Pestañas.
  static const tabGame = 'Juego';
  static const tabSteps = 'Mis pasos';

  // Mis pasos.
  static const historyTitle = 'Mis pasos';
  static const periodWeek = 'Semana';
  static const periodMonth = 'Mes';
  static const periodMonths = 'Meses';
  static const historySince =
      'El historial empieza el día que instalaste esta versión.';
  static String periodTotal(int steps) =>
      'En total: ${formatNumber(steps)} pasos';
  static const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// 1 = lunes … 7 = domingo (como [DateTime.weekday]).
  static String weekdayShort(int weekday) => _weekdays[weekday - 1];
  static String monthName(int month) => _months[month - 1];
  static String monthShort(int month) => _months[month - 1].substring(0, 3);
  static String monthTitle(int month, int year) =>
      '${monthName(month)[0].toUpperCase()}${monthName(month).substring(1)} '
      '$year';
  static String weekOfMonth(int week) => 'Sem. $week';
  static const lastSevenDays = 'Últimos 7 días';
  static String lastMonths(int count) => 'Últimos $count meses';

  // Avisos.
  static String arrived(String stage) => '¡Llegaste! $stage';

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
