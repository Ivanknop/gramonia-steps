/// TODOS los textos visibles del juego, en un solo lugar, para revisarlos y
/// corregirlos fácil.
///
/// - Arriba, los textos de las pantallas (botones, avisos, "Mis pasos").
/// - Abajo, la historia del Capítulo 1: personajes, etapas y objetos.
///
/// Estilo (como los Cuentos de Gramonia): frases cortas, para chicas y
/// chicos de primaria. A quien juega se le habla de "vos", sin género:
/// nada de "lista/listo" ni "bienvenido/a".
library;

import '../logic/chapter.dart';

// ════════════════════════════════════════════════════════════════════════
// PANTALLAS
// ════════════════════════════════════════════════════════════════════════

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
  static String walkingTo(String place, [String article = '']) =>
      'Caminando hasta ${_withArticle(article, place)}';

  /// "Llegaste al Muelle", "Llegaste a la Montaña Dragón".
  static String arrivedAt(String place, [String article = '']) =>
      article == 'el'
      ? 'Llegaste al $place'
      : 'Llegaste a ${_withArticle(article, place)}';
  static const enterButton = 'Entrar';
  static String _withArticle(String article, String place) =>
      article.isEmpty ? place : '$article $place';
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

// ════════════════════════════════════════════════════════════════════════
// CAPÍTULO 1: personajes, etapas, objetos y canjes.
//
// - Se puede cambiar cualquier texto entre comillas.
// - Si un texto lleva comillas simples adentro, escribilas así: \'
// - Los números (cuántas flores, cuántos pasos) están en chapter1.dart. Si
//   cambiás un número allá, revisá que el texto de acá diga lo mismo.
// ════════════════════════════════════════════════════════════════════════

const capitulo1 = 'Capítulo 1: La pluma del Rocanón';

// ── Personajes ──────────────────────────────────────────────────────────

const sofia = 'Sofía';
const hadaMadrina = 'Hada Madrina';
const rocanon = 'Rocanón';
const hormigas = 'Hormigas guardianas';
const dragones = 'Dragones';
const papa = 'Papá';

// ── Etapa 1: Un paseo por el jardín ─────────────────────────────────────

const jardin = TextoEtapa(
  nombre: 'Un paseo por el jardín',
  lugar: 'Campo de Caperucitas',
  articulo: 'el',
  tarjeta:
      'Hoy Sofía visita a su abuelita. El jardín está lleno de flores '
      'amarillas. ¡Juntemos 15 para regalarle un ramo!',
  alTerminar:
      'La abuelita pone el ramo en un florero. ¡Le encanta! De pronto, algo '
      'brilla entre las flores…',
);
const recompensaJardin = 'Ramo de flores amarillas';

const florAmarilla = TextoObjeto(
  nombre: 'Flor amarilla',
  conArticulo: 'una flor amarilla',
  mensaje: '¡Una flor amarilla! Brilla como un pedacito de sol.',
);

// ── Etapa 2: La caperuza lila ───────────────────────────────────────────

const caperuza = TextoEtapa(
  nombre: 'La caperuza lila',
  lugar: 'Campo de Caperucitas',
  articulo: 'el',
  tarjeta:
      'Juntá 15 flores lilas. Con ellas, la abuelita tiñe la caperuza de '
      'Sofía.',
  alTerminar:
      'La abuelita teje toda la noche. A la mañana, ¡Sofía tiene su caperuza '
      'lila de aprendiz! Ahora, al Árbol Mágico.',
);
const recompensaCaperuza = 'Caperuza de aprendiz';

const florLila = TextoObjeto(
  nombre: 'Flor lila',
  conArticulo: 'una flor lila',
  mensaje: 'Una flor lila. Huele a lavanda y a aventura.',
);

// ── Etapa 3: El nido del Rocanón ────────────────────────────────────────

const nido = TextoEtapa(
  nombre: 'El nido del Rocanón',
  lugar: 'Árbol Mágico',
  articulo: 'el',
  camino:
      'En Gramonia todos lo saben: todos los caminos conducen al Árbol '
      'Mágico. Solo hay que caminar.',
  tarjeta:
      'El Rocanón quiere 3 semillas de fuego. 10 semillas de agua o de hielo '
      'se vuelven una de fuego.',
  alTerminar:
      'El Rocanón se come las semillas. ¡Ñam! Sus alas brillan como el sol y '
      'una pluma cae despacito. ¡Es la Pluma del Rocanón!',
);
const recompensaNido = 'Pluma del Rocanón';

const semillaFuego = TextoObjeto(
  nombre: 'Semilla de fuego',
  conArticulo: 'una semilla de fuego',
  mensaje: '¡Una semilla de fuego! Está tibia y brilla como una brasa.',
);
const semillaAgua = TextoObjeto(
  nombre: 'Semilla de agua',
  conArticulo: 'una semilla de agua',
  mensaje: 'Una semilla de agua. Hace glu glu cuando la sacudís.',
);
const semillaHielo = TextoObjeto(
  nombre: 'Semilla de hielo',
  conArticulo: 'una semilla de hielo',
  mensaje: 'Una semilla de hielo. ¡Está fresquita!',
);
const canjeSemillas =
    'Las 10 semillas giran en un remolino… ¡y se encienden! Ahora hay una '
    'semilla de fuego.';

// ── Etapa 4: El laberinto de las hormigas ───────────────────────────────

const laberinto = TextoEtapa(
  nombre: 'El laberinto de las hormigas',
  lugar: 'Bosque Mágico',
  articulo: 'el',
  camino:
      'El Bosque rodea al Árbol Mágico. Cada árbol se parece a otro árbol. '
      'Cada piedra, a otra piedra.',
  tarjeta:
      'Juntá las 6 piezas del acertijo. Las hormigas guardianas te muestran '
      'la salida.',
  alTerminar:
      'Las hormigas arman el acertijo y aplauden con sus seis patitas. '
      'Bailan, dan tres vueltas y un saltito: en hormigués, eso quiere decir '
      '"por acá". A lo lejos se escucha el mar.',
);
const recompensaLaberinto = 'Salida a la costa';

const piezaHoja = TextoObjeto(
  nombre: 'Pieza de la hoja',
  conArticulo: 'la pieza de la hoja',
  mensaje: 'Debajo de una hoja gigante aparece una pieza del acertijo.',
);
const piezaGota = TextoObjeto(
  nombre: 'Pieza de la gota',
  conArticulo: 'la pieza de la gota',
  mensaje: 'Una gota de rocío guardaba otra pieza del acertijo.',
);
const piezaPiedra = TextoObjeto(
  nombre: 'Pieza de la piedra',
  conArticulo: 'la pieza de la piedra',
  mensaje: 'Detrás de una piedra con musgo, una pieza te guiña un ojo.',
);
const piezaSol = TextoObjeto(
  nombre: 'Pieza del sol',
  conArticulo: 'la pieza del sol',
  mensaje: 'Un rayo de sol ilumina una pieza dorada entre los yuyos.',
);
const piezaLuna = TextoObjeto(
  nombre: 'Pieza de la luna',
  conArticulo: 'la pieza de la luna',
  mensaje: 'Una hormiga trae en la espalda una pieza con forma de luna.',
);
const piezaEstrella = TextoObjeto(
  nombre: 'Pieza de la estrella',
  conArticulo: 'la pieza de la estrella',
  mensaje: '¡Una pieza con forma de estrella! Brilla en tu mano.',
);

// ── Etapa 5: El puerto ──────────────────────────────────────────────────

const puerto = TextoEtapa(
  nombre: 'El puerto',
  lugar: 'Muelle',
  articulo: 'el',
  camino:
      'El camino hasta el Muelle es largo. Hay que bajar colinas, cruzar '
      'arroyos y seguir el olor a sal.',
  tarjeta:
      'La tormenta no deja salir a ningún barco. Buscá la pista en el Muelle.',
  alTerminar: 'Ya sabés qué hacer: ¡hay que subir a la Montaña Dragón!',
);
const recompensaPuerto = 'Pista: "los dragones pueden calmarla"';

const pista = TextoObjeto(
  nombre: 'Pista del viejo marinero',
  conArticulo: 'la pista del viejo marinero',
  mensaje:
      'Un viejo marinero cuenta un secreto: «Solo los dragones de la montaña '
      'pueden calmar esta tormenta».',
);

// ── Etapa 6: La Montaña Dragón ──────────────────────────────────────────

const montana = TextoEtapa(
  nombre: 'La Montaña Dragón',
  lugar: 'Montaña Dragón',
  articulo: 'la',
  camino:
      'La Montaña Dragón es la más alta de Gramonia. El sendero sube y sube '
      'entre piedras y nubes. Respirá hondo y seguí, paso a paso.',
  tarjeta: 'Los dragones piden 4 ofrendas. Por 100 gemas te dan una.',
  alTerminar:
      'Los dragones reciben las ofrendas, abren sus alas enormes y vuelan '
      'hacia el mar. Con un gran soplido… ¡la tormenta se calma!',
);
const recompensaMontana = 'Los dragones calman la tormenta';

const gema = TextoObjeto(
  nombre: 'Gema preciosa',
  conArticulo: 'una gema preciosa',
  mensaje: 'Una gema preciosa: brilla de todos los colores.',
);
const piedraFuego = TextoObjeto(
  nombre: 'Piedra de fuego',
  conArticulo: 'la piedra de fuego',
  mensaje: 'Una piedra de fuego. Calentita, como un abrazo de dragón.',
);
const aguaCascada = TextoObjeto(
  nombre: 'Agua de la cascada',
  conArticulo: 'el agua de la cascada',
  mensaje: 'Un frasco con agua de la cascada que canta.',
);
const escama = TextoObjeto(
  nombre: 'Escama brillante',
  conArticulo: 'una escama brillante',
  mensaje: 'Una escama brillante cae del cielo. ¿Será de un dragón bebé?',
);
const florNubes = TextoObjeto(
  nombre: 'Flor de las nubes',
  conArticulo: 'la flor de las nubes',
  mensaje:
      'Entre las nubes crece una flor blanca y suave: ¡la flor de las nubes!',
);
const canjeGemas =
    'Los dragones cuentan tus 100 gemas, sonríen con todos sus dientes y te '
    'dan a cambio: {objeto}.';

// ── Etapa 7: La casa de papá ────────────────────────────────────────────

const casaPapa = TextoEtapa(
  nombre: 'La casa de papá',
  lugar: 'Ciudad',
  articulo: 'la',
  camino:
      'Antes de embarcar, Sofía quiere ver a su papá. El sendero baja de la '
      'montaña hasta la Ciudad.',
  tarjeta: 'Prepará la mochila con papá: farol, manta, pan y mermelada.',
  alTerminar:
      'La mochila está lista. Papá le da un beso a Sofía y le dice: «Una '
      'Caperucita no nace: se hace». ¡Al barco!',
);
const recompensaCasaPapa = 'Mochila con insumos';

const farol = TextoObjeto(
  nombre: 'Farol de luciérnagas',
  conArticulo: 'el farol de luciérnagas',
  mensaje: 'Papá presta su farol de luciérnagas, para las noches en alta mar.',
);
const manta = TextoObjeto(
  nombre: 'Manta tejida',
  conArticulo: 'una manta tejida',
  mensaje: 'Una manta tejida, abrigada y con olor a casa.',
);
const pan = TextoObjeto(
  nombre: 'Pan casero',
  conArticulo: 'pan casero',
  mensaje: 'Pan casero recién horneado, ¡crujiente!',
);
const mermelada = TextoObjeto(
  nombre: 'Frasco de mermelada',
  conArticulo: 'un frasco de mermelada',
  mensaje: 'Un frasco de mermelada de frutillas, la favorita de papá.',
);

// ── Etapa 8: El barco ───────────────────────────────────────────────────

const barco = TextoEtapa(
  nombre: 'El barco',
  lugar: 'Muelle',
  articulo: 'el',
  camino:
      'De vuelta al Muelle. Ahora que la tormenta se calmó, el mar está '
      'tranquilo y brillante.',
  tarjeta:
      'Arreglá el barco: madera, clavos, cuerdas, bandera pirata y ancla. '
      'Con 20 monedas de oro, el vendedor te da lo que falte.',
  alTerminar:
      'El barco está listo. Suben las velas y flamea la bandera pirata. ¡El '
      'barco zarpa hacia la Isla Negra!',
);
const recompensaBarco = 'El barco zarpa';

const madera = TextoObjeto(
  nombre: 'Madera',
  conArticulo: 'madera',
  mensaje: 'Tablas de madera para arreglar el casco.',
);
const clavos = TextoObjeto(
  nombre: 'Clavos',
  conArticulo: 'clavos',
  mensaje: 'Un puñado de clavos brillantes. ¡Toc, toc, toc!',
);
const cuerdas = TextoObjeto(
  nombre: 'Cuerdas',
  conArticulo: 'cuerdas',
  mensaje: 'Cuerdas de marinero, fuertes como trenzas de gigante.',
);
const bandera = TextoObjeto(
  nombre: 'Bandera pirata',
  conArticulo: 'una bandera pirata',
  mensaje: '¡Una bandera pirata! Flamea con el viento.',
);
const ancla = TextoObjeto(
  nombre: 'Ancla',
  conArticulo: 'un ancla',
  mensaje: 'Un ancla pesada, para que el barco no se escape.',
);
const monedaOro = TextoObjeto(
  nombre: 'Moneda de oro',
  conArticulo: 'una moneda de oro',
  mensaje: '¡Una moneda de oro! Suena tilín al caer en el bolsillo.',
);
const canjeMonedas =
    'Con 20 monedas de oro, el vendedor del puerto te da: {objeto}.';
