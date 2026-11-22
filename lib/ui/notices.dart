import '../logic/chapter_engine.dart';
import '../strings.dart';

/// Texto del aviso para un evento suelto.
String noticeText(ChapterEvent event) => switch (event) {
  ItemFound(:final item) => item.message,
  ExchangeMade(:final exchange, :final item) => exchange.message.replaceAll(
    '{item}',
    item.name,
  ),
  Arrived(:final stage) => Strings.arrived(stage.name),
  StageCompleted(:final stage) => stage.completeMessage,
  ChapterCompleted(:final stage) => stage.completeMessage,
};

/// Arma un solo aviso para un grupo de eventos que pasaron juntos.
/// Devuelve null si no hay nada para avisar (por ejemplo, solo gemas).
String? noticeFor(List<ChapterEvent> events) {
  final shown = [
    for (final e in events)
      if (e is! ItemFound || e.item.notify) e,
  ];
  if (shown.isEmpty) return null;

  final finale = shown.whereType<ChapterCompleted>();
  if (finale.isNotEmpty) return noticeText(finale.first);
  if (shown.length == 1) return noticeText(shown.single);

  final stages = shown.whereType<StageCompleted>().toList();
  // Terminar una etapa suele llegar junto con su último objeto o canje.
  if (stages.length == 1 && shown.length <= 3) return noticeText(stages.single);
  // Un canje suele llegar junto con el objeto común que lo completó.
  final exchanges = shown.whereType<ExchangeMade>().toList();
  if (stages.isEmpty && exchanges.length == 1 && shown.length <= 2) {
    return noticeText(exchanges.single);
  }

  final items = shown.where((e) => e is ItemFound || e is ExchangeMade).length;
  return Strings.collectedSummary(items, stages.length);
}
