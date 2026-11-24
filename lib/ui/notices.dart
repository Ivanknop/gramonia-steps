import '../logic/chapter.dart';
import '../logic/chapter_engine.dart';
import '../data/textos.dart';
import '../logic/wallet.dart';

/// Algo para mostrar en grande, uno después del otro.
sealed class Moment {
  const Moment();
}

/// Cartel "¡Encontraste…!" que después vuela a la bolsa.
class FoundMoment extends Moment {
  const FoundMoment(this.item, this.count, this.message);
  final ItemType item;
  final int count;

  /// El texto del objeto, o el del canje si salió de un canje.
  final String message;

  String get title => count == 1
      ? Strings.found(item.foundName)
      : Strings.foundMany(item.name, count);
}

/// Ventana de fin de etapa, con el personaje y la recompensa.
class StageMoment extends Moment {
  const StageMoment(this.stage);
  final Stage stage;
}

/// Pantalla de llegada al final de un tramo de caminata, con "Entrar".
class ArrivalMoment extends Moment {
  const ArrivalMoment(this.stage);
  final Stage stage;
}

/// Diálogo al entrar a una etapa (tipo historieta).
class DialogueMoment extends Moment {
  const DialogueMoment(this.stage);
  final Stage stage;
}

/// Cierre del capítulo: la Isla Negra y "Continuará...".
class EndingMoment extends Moment {
  const EndingMoment();
}

/// Aviso de monedas recibidas (bono del día o de bienvenida).
class CoinMoment extends Moment {
  const CoinMoment(this.notice);
  final CoinNotice notice;
}

/// Como mucho se muestran estos carteles de objetos por cada avance (por
/// ejemplo, al abrir la app después de caminar mucho). El resto va directo
/// a la bolsa.
const maxFoundMoments = 3;

/// Arma los momentos de un grupo de eventos, en el orden en que pasaron.
///
/// - Los objetos iguales de una misma etapa se juntan en un cartel (×N).
/// - Los objetos sin aviso (gemas) no tienen cartel.
/// - Si hay más de [maxFoundMoments] carteles, quedan primero los objetos
///   que pide la etapa.
List<Moment> momentsFor(Chapter chapter, List<ChapterEvent> events) {
  // Carteles agrupados por etapa y objeto, en orden de aparición.
  final groups = <(Stage, String), _Group>{};
  final order = <Object>[]; // _Group o StageMoment.
  for (final event in events) {
    switch (event) {
      case ItemFound(:final stage, :final item) when item.notify:
        _add(groups, order, stage, item, item.message);
      case ExchangeMade(:final stage, :final exchange, :final item):
        final message = exchange.message.replaceAll('{objeto}', item.name);
        _add(groups, order, stage, item, message);
      case StageCompleted(:final stage):
        order.add(StageMoment(stage));
        // La etapa siguiente no tiene tramo pero sí diálogo: va enseguida.
        // (Si tiene tramo, el diálogo viene después de "Entrar".)
        final i = chapter.stages.indexOf(stage) + 1;
        if (i < chapter.stages.length) {
          final next = chapter.stages[i];
          if (!next.hasTravel && next.hasDialogue) {
            order.add(DialogueMoment(next));
          }
        }
      case Arrived(:final stage):
        order.add(ArrivalMoment(stage));
      case ChapterCompleted():
        order.add(const EndingMoment());
      case ItemFound():
        break;
    }
  }

  final all = order.whereType<_Group>().toList();
  final shown = <_Group>{
    ...all.where((g) => g.stage.isRequired(g.item.id)),
    ...all,
  }.take(maxFoundMoments).toSet();

  return [
    for (final entry in order)
      switch (entry) {
        final _Group g when shown.contains(g) => FoundMoment(
          g.item,
          g.count,
          g.message,
        ),
        final Moment m => m,
        _ => null,
      },
  ].nonNulls.toList();
}

void _add(
  Map<(Stage, String), _Group> groups,
  List<Object> order,
  Stage stage,
  ItemType item,
  String message,
) {
  final group = groups[(stage, item.id)];
  if (group == null) {
    final created = _Group(stage, item, message);
    groups[(stage, item.id)] = created;
    order.add(created);
  } else {
    group.count++;
    // Si llegó por un canje, el texto del canje cuenta más la historia.
    if (message != item.message) group.message = message;
  }
}

class _Group {
  _Group(this.stage, this.item, this.message);
  final Stage stage;
  final ItemType item;
  String message;
  int count = 1;
}
