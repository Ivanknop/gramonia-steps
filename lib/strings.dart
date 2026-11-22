/// Textos visibles del juego, en español.
abstract final class Strings {
  static const appTitle = 'Gramonia';
  static const loading = 'Cargando…';
  static String today(int steps) => 'Pasos de hoy: $steps';
  static String total(int steps) => 'Total: $steps';
  static const tracking = 'Contando pasos';
  static const needsPermission = 'Falta el permiso de actividad física.';
  static const permissionBlocked =
      'El permiso está bloqueado. Activalo en los Ajustes de la app.';
  static const noSensor = 'Este celular no tiene sensor de pasos.';
}
