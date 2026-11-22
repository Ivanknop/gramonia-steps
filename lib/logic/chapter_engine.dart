import 'dart:math';

import 'chapter.dart';
import 'chapter_progress.dart';

/// Algo que pasó al avanzar: se muestra como aviso en pantalla.
sealed class ChapterEvent {
  const ChapterEvent(this.stage);
  final Stage stage;
}

/// Apareció un objeto mientras se caminaba.
class ItemFound extends ChapterEvent {
  const ItemFound(super.stage, this.item);
  final ItemType item;
}

/// Se canjearon objetos comunes por un objeto de la etapa.
class ExchangeMade extends ChapterEvent {
  const ExchangeMade(super.stage, this.exchange, this.item);
  final Exchange exchange;
  final ItemType item;
}

/// Terminó el tramo de "llegar": empiezan a aparecer objetos.
class Arrived extends ChapterEvent {
  const Arrived(super.stage);
}

class StageCompleted extends ChapterEvent {
  const StageCompleted(super.stage);
}

class ChapterCompleted extends ChapterEvent {
  const ChapterCompleted(super.stage);
}

class ChapterAdvance {
  const ChapterAdvance(this.progress, this.events);
  final ChapterProgress progress;
  final List<ChapterEvent> events;
}

enum StageStatus { done, current, locked }

/// Reglas del capítulo (ver docs/diseno.md).
class ChapterEngine {
  const ChapterEngine(this.chapter);

  final Chapter chapter;

  bool isFinished(ChapterProgress p) => p.stageIndex >= chapter.stages.length;

  Stage? currentStage(ChapterProgress p) =>
      isFinished(p) ? null : chapter.stages[p.stageIndex];

  StageStatus statusOf(int stageIndex, ChapterProgress p) {
    if (stageIndex < p.stageIndex) return StageStatus.done;
    if (stageIndex == p.stageIndex) return StageStatus.current;
    return StageStatus.locked;
  }

  /// Si la etapa actual todavía está en el tramo de "llegar".
  bool isTraveling(ChapterProgress p) {
    final stage = currentStage(p);
    return stage != null && p.stepsInStage < stage.travelSteps;
  }

  /// Pasos que faltan para que salga el próximo objeto fijo de [spawn]
  /// (para mostrar "Faltan X pasos").
  int stepsToNextFixed(ChapterProgress p, FixedSpawn spawn) {
    final stage = currentStage(p)!;
    final walked = max(0, p.stepsInStage - stage.travelSteps);
    return spawn.every - walked % spawn.every;
  }

  /// Suma [steps] al capítulo. Recorre tirada por tirada: un salto grande
  /// pasa por todas las tiradas en orden y puede completar varias etapas.
  /// Después del final, los pasos ya no cambian nada.
  ChapterAdvance advance(ChapterProgress p, int steps, Random random) {
    final run = _Run(p);
    var remaining = max(0, steps);

    while (run.stageIndex < chapter.stages.length) {
      final stage = chapter.stages[run.stageIndex];

      if (_isComplete(stage, run.inventory)) {
        run.events.add(StageCompleted(stage));
        run.stageIndex++;
        run.inStage = 0;
        run.sinceLast.clear();
        if (run.stageIndex == chapter.stages.length) {
          run.events.add(ChapterCompleted(stage));
        }
        continue;
      }
      if (remaining == 0) break;

      // Tramo de "llegar": no aparece nada.
      if (run.inStage < stage.travelSteps) {
        final take = min(stage.travelSteps - run.inStage, remaining);
        run.inStage += take;
        remaining -= take;
        if (run.inStage == stage.travelSteps) run.events.add(Arrived(stage));
        continue;
      }

      // Avanzar hasta la próxima tirada de alguna aparición activa.
      final walked = run.inStage - stage.travelSteps;
      final active = [
        for (final s in stage.spawns)
          if (_isActive(stage, s, run.inventory)) s,
      ];
      if (active.isEmpty) break; // Datos mal armados (lo atrapa un test).
      final next = active
          .map((s) => (walked ~/ s.every + 1) * s.every)
          .reduce(min);
      final need = next - walked;
      if (need > remaining) {
        run.inStage += remaining;
        remaining = 0;
        break;
      }
      run.inStage += need;
      remaining -= need;

      for (final spawn in active) {
        if (next % spawn.every != 0) continue;
        if (!_isActive(stage, spawn, run.inventory)) continue;
        if (_rolls(spawn, run, random)) {
          _give(stage, _pick(stage, spawn, run.inventory, random), run);
        }
      }
    }

    return ChapterAdvance(run.toProgress(), List.unmodifiable(run.events));
  }

  /// Tira el dado de una aparición. Lleva la cuenta para la garantía.
  bool _rolls(Spawn spawn, _Run run, Random random) {
    switch (spawn) {
      case FixedSpawn():
        return true;
      case RandomSpawn():
        final since = (run.sinceLast[spawn.key] ?? 0) + spawn.every;
        final hit =
            random.nextInt(spawn.oneIn) == 0 || since >= spawn.guaranteeSteps;
        run.sinceLast[spawn.key] = hit ? 0 : since;
        return hit;
    }
  }

  String _pick(
    Stage stage,
    Spawn spawn,
    Map<String, int> inventory,
    Random random,
  ) {
    if (_isGoalSpawn(stage, spawn)) {
      return _firstMissing(stage, spawn.items, inventory)!;
    }
    return spawn.items.length == 1
        ? spawn.items.single
        : spawn.items[random.nextInt(spawn.items.length)];
  }

  void _give(Stage stage, String itemId, _Run run) {
    run.inventory[itemId] = (run.inventory[itemId] ?? 0) + 1;
    run.events.add(ItemFound(stage, chapter.item(itemId)));
    _applyExchanges(stage, run);
  }

  void _applyExchanges(Stage stage, _Run run) {
    for (final exchange in stage.exchanges) {
      while (true) {
        final output = _firstMissing(stage, exchange.outputs, run.inventory);
        final available = exchange.inputs.fold(
          0,
          (sum, id) => sum + (run.inventory[id] ?? 0),
        );
        if (output == null || available < exchange.count) break;
        var toTake = exchange.count;
        for (final id in exchange.inputs) {
          final take = min(toTake, run.inventory[id] ?? 0);
          run.inventory[id] = (run.inventory[id] ?? 0) - take;
          toTake -= take;
        }
        run.inventory[output] = (run.inventory[output] ?? 0) + 1;
        run.events.add(ExchangeMade(stage, exchange, chapter.item(output)));
      }
    }
  }

  bool _isGoalSpawn(Stage stage, Spawn spawn) =>
      spawn.items.every(stage.isRequired);

  /// Una aparición de objetos de la etapa deja de salir cuando ya no falta
  /// ninguno; una de objetos comunes sigue saliendo.
  bool _isActive(Stage stage, Spawn spawn, Map<String, int> inventory) =>
      !_isGoalSpawn(stage, spawn) ||
      _firstMissing(stage, spawn.items, inventory) != null;

  String? _firstMissing(
    Stage stage,
    List<String> items,
    Map<String, int> inventory,
  ) {
    for (final id in items) {
      if ((inventory[id] ?? 0) < stage.requiredCount(id)) return id;
    }
    return null;
  }

  bool _isComplete(Stage stage, Map<String, int> inventory) =>
      stage.requirements.every((r) => (inventory[r.item] ?? 0) >= r.count);
}

/// Estado de trabajo mientras se avanza.
class _Run {
  _Run(ChapterProgress p)
    : stageIndex = p.stageIndex,
      inStage = p.stepsInStage,
      inventory = {...p.inventory},
      sinceLast = {...p.sinceLast};

  int stageIndex;
  int inStage;
  final Map<String, int> inventory;
  final Map<String, int> sinceLast;
  final events = <ChapterEvent>[];

  ChapterProgress toProgress() => ChapterProgress(
    stageIndex: stageIndex,
    stepsInStage: inStage,
    inventory: Map.unmodifiable(inventory),
    sinceLast: Map.unmodifiable(sinceLast),
  );
}
