/// Estructura de un capítulo: tipos de objeto, etapas y reglas de aparición.
/// Los valores concretos están en `lib/data/`.
library;

/// Un tipo de objeto que se puede tener en el inventario.
class ItemType {
  const ItemType({
    required this.id,
    required this.name,
    required this.message,
    this.notify = true,
  });

  /// Se guarda en el celular: no cambiarlo sin migrar la partida.
  final String id;
  final String name;

  /// Texto del aviso al conseguirlo.
  final String message;

  /// Si es falso, no hay aviso propio (objetos muy frecuentes, como gemas).
  final bool notify;
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

  /// Texto del aviso. `{item}` se reemplaza por el objeto que se recibe.
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
    required this.name,
    required this.intro,
    this.travelSteps = 0,
    this.travelText = '',
    required this.requirements,
    required this.spawns,
    this.exchanges = const [],
    required this.reward,
    required this.completeMessage,
  });

  /// Se guarda en el celular: no cambiarlo sin migrar la partida.
  final String id;
  final String name;

  /// Texto al empezar a juntar objetos (después de llegar).
  final String intro;

  /// Tramo de viaje al principio de la etapa: no aparece ningún objeto.
  final int travelSteps;
  final String travelText;

  final List<Requirement> requirements;
  final List<Spawn> spawns;
  final List<Exchange> exchanges;
  final String reward;
  final String completeMessage;

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
  });

  final String name;
  final List<ItemType> items;
  final List<Stage> stages;

  ItemType item(String id) => items.firstWhere(
    (i) => i.id == id,
    orElse: () => throw ArgumentError('Objeto desconocido: $id'),
  );
}
