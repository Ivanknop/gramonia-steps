/// Diálogos de la historia, tipo historieta.
library;

/// Una línea de diálogo: quién habla y qué dice.
///
/// [quien] es el id de un personaje del capítulo, o [jugador] (quien juega)
/// o [narracion] (sin personaje). En el texto, `{nombre}` se reemplaza por el
/// nombre de quien juega.
class Linea {
  const Linea(this.quien, this.texto);

  static const jugador = 'jugador';
  static const narracion = 'narracion';

  final String quien;
  final String texto;

  bool get esJugador => quien == jugador;
  bool get esNarracion => quien == narracion;
}

/// Reemplaza `{nombre}` por el nombre de quien juega.
String conNombre(String texto, String nombre) =>
    texto.replaceAll('{nombre}', nombre);

/// Largo máximo del nombre de quien juega.
const maxNombre = 20;

/// Limpia el nombre que se escribió: sin espacios de más y no muy largo.
/// Devuelve null si queda vacío.
String? limpiarNombre(String escrito) {
  final limpio = escrito.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (limpio.isEmpty) return null;
  return limpio.length > maxNombre ? limpio.substring(0, maxNombre) : limpio;
}
