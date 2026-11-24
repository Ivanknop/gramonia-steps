/// Estructura de un capítulo: tipos de objeto, etapas y reglas de aparición.
/// Los valores concretos están en `lib/data/`.
library;

import 'music.dart';
import 'story.dart';
import 'wallet.dart';

/// Textos de un objeto (se escriben en lib/data/textos.dart).
class TextoObjeto {
  const TextoObjeto({
    required this.nombre,
    required this.conArticulo,
    required this.mensaje,
  });

  final String nombre;

  /// Para "¡Encontraste `conArticulo`!".
  final String conArticulo;

  /// Lo que dice el cartel al encontrarlo.
  final String mensaje;
}

/// Textos de una etapa (se escriben en lib/data/textos.dart).
class TextoEtapa {
  const TextoEtapa({
    required this.nombre,
    required this.lugar,
    this.articulo = '',
    this.camino = '',
    required this.tarjeta,
    required this.alTerminar,
  });

  final String nombre;

  /// Lugar al que se llega (`Caminando hasta <lugar>`).
  final String lugar;

  /// Artículo del lugar ("el", "la" o nada), para "Llegaste al Muelle".
  final String articulo;

  /// Texto durante el tramo de caminata (si la etapa tiene).
  final String camino;

  /// Recordatorio de qué hay que juntar, en la tarjeta de la etapa.
  final String tarjeta;

  /// Texto de la ventana de fin de etapa.
  final String alTerminar;
}

/// Un tipo de objeto que se puede tener en el inventario.
class ItemType {
  const ItemType({
    required this.id,
    required this.texto,
    this.notify = true,
    this._image,
  });

  /// Se guarda en el celular: no cambiarlo sin migrar la partida.
  final String id;
  final TextoObjeto texto;

  String get name => texto.nombre;

  /// Nombre con artículo, para "¡Encontraste `foundName`!".
  String get foundName => texto.conArticulo;

  final String? _image;

  /// Dibujo (ruta del asset). Por defecto, `assets/items/<id>.webp`.
  String get image => _image ?? 'assets/items/$id.webp';

  /// Texto del aviso al conseguirlo.
  String get message => texto.mensaje;

  /// Si es falso, no hay aviso propio (objetos muy frecuentes, como gemas).
  final bool notify;
}

/// Lo que se gana al terminar una etapa. No se guarda en el celular: se
/// deduce de la etapa en la que va la partida.
class Reward {
  const Reward({required this.id, required this.name, this._image});

  final String id;
  final String name;
  final String? _image;

  /// Dibujo (ruta del asset). Por defecto, `assets/items/<id>.webp`.
  String get image => _image ?? 'assets/items/$id.webp';
}

/// Un personaje que aparece junto a los textos de la historia.
class Character {
  const Character({required this.id, required this.name, this.animation});

  final String id;
  final String name;

  /// Nombre del dibujo animado (sale de un GIF de arte/personajes/). Se usa
  /// en los diálogos y, el del personaje que camina, en la caminata. Si no
  /// hay, se ve el dibujo quieto.
  final String? animation;

  String get image => 'assets/characters/$id.webp';

  String? get animatedImage =>
      animation == null ? null : 'assets/characters/$animation.webp';
}

/// Cómo aparece un objeto mientras se camina.
///
/// Si todos los [items] son objetos que pide la etapa, sale el primero que
/// falte, y deja de salir cuando ya no falta ninguno. Si son objetos comunes
/// (no los pide la etapa), sale uno de ellos al azar y sigue saliendo.
sealed class Spawn {
  const Spawn({required this.items, required this.every});

  final List<String> items;

  /// Cada cuántos pasos se tira (o sale, si es fijo).
  final int every;

  /// Identifica a la aparición dentro de la etapa (para la garantía).
  String get key => items.first;
}

/// Cada [every] pasos se tira un número del 1 al [oneIn]; si sale 1, aparece.
/// Si pasan 3 × [oneIn] × [every] pasos sin que salga, sale seguro.
class RandomSpawn extends Spawn {
  const RandomSpawn({
    required super.items,
    required super.every,
    required this.oneIn,
  });

  final int oneIn;

  /// Pasos sin aparecer después de los cuales sale seguro.
  int get guaranteeSteps => 3 * oneIn * every;
}

/// Sale uno cada [every] pasos, sin azar.
class FixedSpawn extends Spawn {
  const FixedSpawn({required super.items, required super.every});
}

/// Cada [every] pasos se tira un número del 1 al [oneIn]; si sale 1, suma
/// [coins] monedas a la billetera. No es un objeto: no va a la bolsa, no
/// tiene garantía y, si no sale, no da las monedas de la tirada fallida.
/// Sale mientras a la etapa le falte algo.
class CoinSpawn extends Spawn {
  const CoinSpawn({required super.every, required this.oneIn, this.coins = 1})
    : super(items: const []);

  final int oneIn;
  final int coins;

  @override
  String get key => 'monedas';
}

/// Los objetos de [outputs] se compran con monedas de la billetera, [price]
/// cada uno, con un botón en la etapa (no es automático). Se compra el
/// primero que falte.
class CoinPurchase {
  const CoinPurchase({
    required this.price,
    required this.outputs,
    required this.message,
  });

  final int price;
  final List<String> outputs;

  /// Texto del cartel. `{objeto}` se reemplaza por lo que se compró.
  final String message;
}

/// Al juntar [count] objetos de [inputs], se cambian solos por el primero que
/// falte de [outputs].
class Exchange {
  const Exchange({
    required this.inputs,
    required this.count,
    required this.outputs,
    required this.message,
  });

  final List<String> inputs;
  final int count;
  final List<String> outputs;

  /// Texto del aviso. `{objeto}` se reemplaza por el objeto que se recibe.
  final String message;
}

/// Un objeto que pide la etapa, y cuántos.
class Requirement {
  const Requirement(this.item, [this.count = 1]);

  final String item;
  final int count;
}

class Stage {
  const Stage({
    required this.id,
    required this.texto,
    this.dialogue = const [],
    this.music = MusicTrack.aventura,
    this.travelSteps = 0,
    required this.requirements,
    required this.spawns,
    this.exchanges = const [],
    this.coinPurchase,
    required this.reward,
    required this.background,
    required this.introCharacter,
    required this.completeCharacter,
  });

  /// Se guarda en el celular: no cambiarlo sin migrar la partida.
  final String id;
  final TextoEtapa texto;

  String get name => texto.nombre;

  /// Ilustración de fondo (ruta del asset).
  final String background;

  /// Lugar al que se llega en esta etapa (`Caminando hasta <lugar>`).
  String get place => texto.lugar;

  /// Artículo del lugar ("el", "la" o nada), para "Llegaste al Muelle".
  String get placeArticle => texto.articulo;

  /// Imagen de la pantalla de llegada (puede ser animada). Si no existe, se
  /// usa [background].
  String get arrivalImage => 'assets/places/$id.webp';

  /// Diálogo al entrar a la etapa (después de llegar). Puede no haber.
  final List<Linea> dialogue;

  bool get hasDialogue => dialogue.isNotEmpty;

  /// Música de la etapa, también durante su tramo de caminata.
  final MusicTrack music;

  /// Al terminar la etapa anterior hay que "entrar" a esta: con la pantalla
  /// de llegada (si hay tramo) y el diálogo (si hay).
  bool get hasEntrance => hasTravel || hasDialogue;

  /// Recordatorio de qué juntar (en la tarjeta de la etapa).
  String get intro => texto.tarjeta;

  /// Tramo de viaje al principio de la etapa: no aparece ningún objeto.
  final int travelSteps;
  String get travelText => texto.camino;

  final List<Requirement> requirements;
  final List<Spawn> spawns;
  final List<Exchange> exchanges;

  /// Bienes que se compran con monedas, con su botón (el barco).
  final CoinPurchase? coinPurchase;
  final Reward reward;
  String get completeMessage => texto.alTerminar;

  /// Personajes (por id) junto a la intro y en la ventana de fin de etapa.
  final String introCharacter;
  final String completeCharacter;

  bool get hasTravel => travelSteps > 0;

  bool isRequired(String itemId) => requirements.any((r) => r.item == itemId);

  int requiredCount(String itemId) {
    for (final r in requirements) {
      if (r.item == itemId) return r.count;
    }
    return 0;
  }
}

class Chapter {
  const Chapter({
    required this.name,
    required this.items,
    required this.stages,
    required this.walkingBackground,
    required this.islandBackground,
    required this.characters,
    required this.walkingCharacter,
    this.coinsPerMiss = CoinRange.none,
  });

  final String name;

  /// Monedas en cada tirada al azar en la que no sale el objeto (mientras
  /// a la etapa le falte algo).
  final CoinRange coinsPerMiss;
  final List<ItemType> items;
  final List<Stage> stages;
  final List<Character> characters;

  /// Fondo de los tramos de caminata (el mapa).
  final String walkingBackground;

  /// La Isla Negra: introducción y cierre del capítulo.
  final String islandBackground;

  /// Personaje (por id) que se ve mientras se camina hasta un lugar.
  final String walkingCharacter;

  Character character(String id) => characters.firstWhere(
    (c) => c.id == id,
    orElse: () => throw ArgumentError('Personaje desconocido: $id'),
  );

  /// Etapa (índice) donde aparece el objeto, o null si no aparece en
  /// ninguna.
  int? stageWhereFound(String itemId) {
    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];
      if (stage.spawns.any((s) => s.items.contains(itemId)) ||
          stage.exchanges.any((e) => e.outputs.contains(itemId))) {
        return i;
      }
    }
    return null;
  }

  /// Para qué sirve un objeto (en la bolsa).
  List<ItemUse> usesOf(String itemId) => [
    for (final stage in stages) ...[
      if (stage.isRequired(itemId))
        NeededFor(stage, stage.requiredCount(itemId)),
      for (final exchange in stage.exchanges)
        if (exchange.inputs.contains(itemId)) TradedIn(stage, exchange),
    ],
  ];

  ItemType item(String id) => items.firstWhere(
    (i) => i.id == id,
    orElse: () => throw ArgumentError('Objeto desconocido: $id'),
  );
}

/// Para qué sirve un objeto.
sealed class ItemUse {
  const ItemUse(this.stage);
  final Stage stage;
}

/// La etapa pide [count] de este objeto.
class NeededFor extends ItemUse {
  const NeededFor(super.stage, this.count);
  final int count;
}

/// Se junta para un canje de la etapa.
class TradedIn extends ItemUse {
  const TradedIn(super.stage, this.exchange);
  final Exchange exchange;
}
