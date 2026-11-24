import '../data/textos.dart';
import 'chapter.dart';
import 'chapter_engine.dart';

/// Lo que dice la notificación del celular.
class GameNotification {
  const GameNotification({
    required this.title,
    required this.lines,
    required this.alert,
  });

  final String title;

  /// Un renglón por cosa: "Flor lila ×3", "Llegaste al Muelle"...
  final List<String> lines;

  /// Si suena y vibra. Si es falso, se actualiza en silencio.
  final bool alert;

  String get body => lines.join(' · ');

  @override
  String toString() => 'GameNotification($title, $lines, alert: $alert)';
}

/// Junta todo lo que pasó mientras el juego no estaba a la vista, para
/// mostrarlo en UNA sola notificación que se va actualizando (nunca diez
/// seguidas).
///
/// Suena la primera vez y cada vez que se completa una etapa. Si solo
/// aparecen más objetos, se actualiza en silencio.
class NotificationSummary {
  /// Objetos conseguidos (por id), en el orden en que aparecieron.
  final _items = <String, (ItemType, int)>{};

  /// Llegadas, etapas completadas y el final, en orden.
  final _milestones = <String>[];
  var _stages = 0;
  Stage? _lastStage;
  var _finished = false;

  var _posted = false;
  var _stageSincePost = false;

  bool get isEmpty => _items.isEmpty && _milestones.isEmpty;

  void add(List<ChapterEvent> events) {
    for (final event in events) {
      switch (event) {
        case ItemFound(:final item) when item.notify:
          _count(item);
        case ExchangeMade(:final item):
          _count(item);
        case ItemFound():
          break; // Gemas: sin aviso.
        case Arrived(:final stage):
          _milestones.add(Strings.arrivedAt(stage.place, stage.placeArticle));
        case StageCompleted(:final stage):
          _stages++;
          _lastStage = stage;
          _stageSincePost = true;
          _milestones.add(Strings.notificationStageDone(stage.name));
        case ChapterCompleted():
          _finished = true;
          _stageSincePost = true;
          _milestones.add(Strings.chapterDoneTitle);
      }
    }
  }

  void _count(ItemType item) {
    final (_, n) = _items[item.id] ?? (item, 0);
    _items[item.id] = (item, n + 1);
  }

  /// La notificación con todo lo juntado hasta ahora. Recuerda que ya se
  /// mostró, para que la próxima solo suene si hay una etapa nueva.
  GameNotification build() {
    final alert = !_posted || _stageSincePost;
    _posted = true;
    _stageSincePost = false;
    final count = _items.values.fold(0, (sum, e) => sum + e.$2);
    final title = switch ((_finished, _stages, _lastStage)) {
      (true, _, _) => Strings.chapterDoneTitle,
      (_, 1, final stage?) => Strings.notificationStageDone(stage.name),
      (_, > 1, _) => Strings.notificationStages(_stages),
      _ when _items.length == 1 && count == 1 => Strings.found(
        _items.values.single.$1.foundName,
      ),
      _ when count > 0 => Strings.notificationItems(count),
      _ => _milestones.last,
    };
    return GameNotification(
      title: title,
      lines: [
        ..._milestones,
        for (final (item, n) in _items.values)
          n == 1 ? item.name : '${item.name} ${Strings.times(n)}',
      ],
      alert: alert,
    );
  }

  /// Se abrió el juego: se empieza de cero.
  void clear() {
    _items.clear();
    _milestones.clear();
    _stages = 0;
    _lastStage = null;
    _finished = false;
    _posted = false;
    _stageSincePost = false;
  }
}
