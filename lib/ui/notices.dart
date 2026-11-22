import '../logic/chapter_engine.dart';
import '../strings.dart';

/// Arma un solo aviso para un grupo de eventos que pasaron juntos.
String noticeFor(List<ChapterEvent> events) {
  if (events.any((e) => e is ChapterCompleted)) {
    return Strings.chapterCompleted;
  }
  final items = events.whereType<ItemCollected>().toList();
  final stages = events.whereType<StageCompleted>().toList();

  if (stages.isEmpty && items.length == 1) {
    return Strings.itemCollected(items.single.item.name);
  }
  // Terminar una etapa casi siempre llega junto con su último objeto.
  if (stages.length == 1 && items.length <= 1) {
    final stage = stages.single.stage;
    return Strings.stageCompleted(stage.name, stage.reward);
  }
  return Strings.collectedSummary(items.length, stages.length);
}
