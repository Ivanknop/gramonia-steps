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
