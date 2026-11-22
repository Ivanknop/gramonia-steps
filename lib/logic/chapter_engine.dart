import 'dart:math';

import 'chapter.dart';
import 'chapter_progress.dart';

/// Algo que pasó al avanzar: se muestra como aviso en pantalla.
sealed class ChapterEvent {
  const ChapterEvent();
}

class ItemCollected extends ChapterEvent {
  const ItemCollected(this.stage, this.item);
  final Stage stage;
  final StageItem item;
}

class StageCompleted extends ChapterEvent {
  const StageCompleted(this.stage);
  final Stage stage;
}

class ChapterCompleted extends ChapterEvent {
  const ChapterCompleted();
}

class ChapterAdvance {
  const ChapterAdvance(this.progress, this.events);
  final ChapterProgress progress;
  final List<ChapterEvent> events;
}

enum StageStatus { done, current, locked }

/// Reglas del capítulo: los pasos llenan la etapa actual, cada objeto se
/// consigue al cruzar su umbral y al llegar a la meta se pasa a la siguiente.
class ChapterEngine {
  const ChapterEngine(this.chapter);

  final Chapter chapter;

  bool isFinished(ChapterProgress p) => p.stageIndex >= chapter.stages.length;

  Stage? currentStage(ChapterProgress p) =>
      isFinished(p) ? null : chapter.stages[p.stageIndex];

  /// Próximo objeto que falta en la etapa actual.
  StageItem? nextItem(ChapterProgress p) {
    final stage = currentStage(p);
    if (stage == null) return null;
    for (final item in stage.items) {
      if (!p.has(item.id)) return item;
    }
    return null;
  }

  /// Pasos que faltan para el próximo objeto (0 si no hay).
  int stepsToNextItem(ChapterProgress p) {
    final item = nextItem(p);
    if (item == null) return 0;
    return max(0, item.atSteps - p.stepsInStage);
  }

  StageStatus statusOf(int stageIndex, ChapterProgress p) {
    if (stageIndex < p.stageIndex) return StageStatus.done;
    if (stageIndex == p.stageIndex) return StageStatus.current;
    return StageStatus.locked;
  }

  /// Suma [steps] al capítulo. Puede conseguir varios objetos y completar
  /// varias etapas de una vez; lo que sobra de una etapa pasa a la siguiente.
  /// Después del final, los pasos ya no cambian nada.
  ChapterAdvance advance(ChapterProgress p, int steps) {
    final events = <ChapterEvent>[];
    final collected = [...p.collected];
    var stageIndex = p.stageIndex;
    var inStage = p.stepsInStage;
    var remaining = max(0, steps);

    while (stageIndex < chapter.stages.length) {
      final stage = chapter.stages[stageIndex];
      final take = min(max(0, stage.steps - inStage), remaining);
      inStage += take;
      remaining -= take;

      // También recoge objetos que quedaron atrás si se cambiaron los datos.
      for (final item in stage.items) {
        if (item.atSteps <= inStage && !collected.contains(item.id)) {
          collected.add(item.id);
          events.add(ItemCollected(stage, item));
        }
      }

      if (inStage < stage.steps) break;

      events.add(StageCompleted(stage));
      stageIndex++;
      inStage = 0;
      if (stageIndex == chapter.stages.length) {
        events.add(const ChapterCompleted());
      }
      if (remaining == 0) break;
    }

    return ChapterAdvance(
      ChapterProgress(
        stageIndex: stageIndex,
        stepsInStage: inStage,
        collected: List.unmodifiable(collected),
      ),
      List.unmodifiable(events),
    );
  }
}
