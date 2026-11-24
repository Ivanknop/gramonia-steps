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

/// Cómo prefiere quien juega que le hablen. [neutro] es "prefiero no
/// decir": los textos quedan sin género.
enum Genero { chico, chica, neutro }

/// Elige entre las tres variantes de un texto con género. Sin respuesta
/// (null), la neutra.
String segunGenero(
  Genero? genero, {
  required String chico,
  required String chica,
  required String neutro,
}) => switch (genero) {
  Genero.chico => chico,
  Genero.chica => chica,
  Genero.neutro || null => neutro,
};

/// Variantes con género dentro de un texto: `{chico|chica|neutro}`, por
/// ejemplo `lo damos {juntos|juntas|en equipo}`.
final _variantes = RegExp(r'\{([^{}|]*)\|([^{}|]*)\|([^{}|]*)\}');

/// Elige la variante de género de cada `{chico|chica|neutro}` del texto.
String conGenero(String texto, Genero? genero) => texto.replaceAllMapped(
  _variantes,
  (m) => segunGenero(genero, chico: m[1]!, chica: m[2]!, neutro: m[3]!),
);

/// Un texto listo para quien juega: su nombre y su género.
String paraQuienJuega(String texto, String nombre, Genero? genero) =>
    conNombre(conGenero(texto, genero), nombre);

/// Largo máximo del nombre de quien juega.
const maxNombre = 20;

/// Limpia el nombre que se escribió: sin espacios de más y no muy largo.
/// Devuelve null si queda vacío.
String? limpiarNombre(String escrito) {
  final limpio = escrito.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (limpio.isEmpty) return null;
  return limpio.length > maxNombre ? limpio.substring(0, maxNombre) : limpio;
}
