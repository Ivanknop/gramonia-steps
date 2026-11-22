import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart';
import '../logic/chapter.dart';
import '../logic/chapter_engine.dart';
import '../logic/chapter_progress.dart';
import '../strings.dart';
import 'notices.dart';
import 'step_controller.dart';

/// Pantalla única: pasos, etapa actual con lo que hay que juntar y el viaje.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.showDebug = kDebugMode,
  });

  final StepController controller;

  /// El botón "+1.000 pasos" solo aparece en builds de debug.
  final bool showDebug;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ChapterEvent>>? _events;

  @override
  void initState() {
    super.initState();
    _events = widget.controller.events.listen(_showNotice);
  }

  void _showNotice(List<ChapterEvent> events) {
    final text = noticeFor(events);
    if (!mounted || text == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        // Los textos largos (fin de etapa) quedan más tiempo.
        duration: Duration(seconds: max(4, text.length ~/ 15)),
        showCloseIcon: true,
      ),
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final engine = controller.engine;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final chapter = controller.game.chapter;
          final stage = engine.currentStage(chapter);
          // Después del final queda el fondo de la última etapa.
          final background = (stage ?? engine.chapter.stages.last).background;
          _precacheNext(chapter.stageIndex);
          return Stack(
            fit: StackFit.expand,
            children: [
              StageBackground(asset: background),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StepsHeader(controller: controller),
                      _StatusNotice(controller: controller),
                      const SizedBox(height: 12),
                      if (stage == null)
                        _ChapterDoneCard(engine: engine)
                      else ...[
                        _StageCard(
                          engine: engine,
                          stage: stage,
                          progress: chapter,
                        ),
                        const SizedBox(height: 12),
                        _GoalsCard(
                          engine: engine,
                          stage: stage,
                          progress: chapter,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _JourneyCard(engine: engine, progress: chapter),
                      if (widget.showDebug) ...[
                        const SizedBox(height: 12),
                        _Panel(
                          padding: const EdgeInsets.all(8),
                          child: OutlinedButton(
                            onPressed: () =>
                                controller.addDebugSteps(debugStepBonus),
                            child: Text(Strings.debugAdd(debugStepBonus)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int? _precached;

  /// Carga de antemano el fondo de la etapa siguiente, para que el fundido
  /// no titile al cambiar de etapa.
  void _precacheNext(int stageIndex) {
    if (_precached == stageIndex) return;
    _precached = stageIndex;
    final stages = widget.controller.engine.chapter.stages;
    if (stageIndex + 1 >= stages.length) return;
    final next = AssetImage(stages[stageIndex + 1].background);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheImage(next, context);
    });
  }
}

/// Ilustración de la etapa a pantalla completa. Al cambiar de etapa, la
/// nueva aparece con un fundido suave sobre la anterior.
class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.asset});

  final String asset;

  static const fadeDuration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: fadeDuration,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Panel semitransparente con bordes redondeados, para que el texto se lea
/// bien sobre la ilustración.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StepsHeader extends StatelessWidget {
  const _StepsHeader({required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = controller.state;
    return _Panel(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Text(Strings.todayLabel, style: text.titleMedium),
          Text(
            Strings.formatNumber(state.todaySteps),
            style: text.displayMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(Strings.total(state.totalSteps), style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.engine,
    required this.stage,
    required this.progress,
  });

  final ChapterEngine engine;
  final Stage stage;
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = engine.chapter.stages.length;
    final traveling = engine.isTraveling(progress);

    // Barra: durante el viaje, pasos del tramo; después, objetos juntados.
    final double value;
    if (traveling) {
      value = progress.stepsInStage / stage.travelSteps;
    } else {
      var have = 0, need = 0;
      for (final r in stage.requirements) {
        have += min(progress.count(r.item), r.count);
        need += r.count;
      }
      value = have / need;
    }

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.stageOf(progress.stageIndex + 1, count),
              style: text.labelLarge,
            ),
            Text(
              traveling ? Strings.travelingTo(stage.name) : stage.name,
              style: text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(traveling ? stage.travelText : stage.intro),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            if (traveling) ...[
              const SizedBox(height: 6),
              Text(
                Strings.stageProgress(progress.stepsInStage, stage.travelSteps),
              ),
            ],
            const SizedBox(height: 6),
            Text(Strings.reward(stage.reward), style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Lo que pide la etapa, con cuánto hay, y el avance de cada canje.
class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.engine,
    required this.stage,
    required this.progress,
  });

  final ChapterEngine engine;
  final Stage stage;
  final ChapterProgress progress;

  /// Debajo de cada objeto: cómo o cuándo aparece.
  String? _hint(Requirement r, bool traveling) {
    if (progress.count(r.item) >= r.count) return null;
    for (final spawn in stage.spawns) {
      if (!spawn.items.contains(r.item)) continue;
      if (traveling) return Strings.afterArriving;
      if (spawn is RandomSpawn) return Strings.appearsRandomly;
      // Fijos: solo el próximo de la lista sabe cuántos pasos faltan.
      final next = spawn.items.firstWhere(
        (id) => progress.count(id) < stage.requiredCount(id),
      );
      if (next == r.item) {
        return Strings.stepsToNext(
          engine.stepsToNextFixed(progress, spawn as FixedSpawn),
        );
      }
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chapter = engine.chapter;
    final traveling = engine.isTraveling(progress);
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                Strings.goalsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final r in stage.requirements)
              ListTile(
                dense: true,
                leading: progress.count(r.item) >= r.count
                    ? Icon(Icons.check_circle, color: colors.primary)
                    : Icon(Icons.radio_button_unchecked, color: colors.outline),
                title: Text(chapter.item(r.item).name),
                subtitle: switch (_hint(r, traveling)) {
                  final hint? => Text(hint),
                  null => null,
                },
                trailing: r.count > 1
                    ? Text(
                        Strings.countOf(
                          min(progress.count(r.item), r.count),
                          r.count,
                        ),
                      )
                    : null,
              ),
            for (final exchange in stage.exchanges)
              if (_firstMissingOutput(exchange) case final output?)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.swap_horiz, color: colors.tertiary),
                  title: Text(
                    Strings.exchangeProgress(
                      exchange.inputs
                          .map((id) => chapter.item(id).name)
                          .join(Strings.or),
                      exchange.inputs.fold(
                        0,
                        (s, id) => s + progress.count(id),
                      ),
                      exchange.count,
                      chapter.item(output).name,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String? _firstMissingOutput(Exchange exchange) {
    for (final id in exchange.outputs) {
      if (progress.count(id) < stage.requiredCount(id)) return id;
    }
    return null;
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.engine, required this.progress});

  final ChapterEngine engine;
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stages = engine.chapter.stages;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                Strings.journeyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < stages.length; i++)
              ListTile(
                dense: true,
                leading: switch (engine.statusOf(i, progress)) {
                  StageStatus.done => Icon(
                    Icons.check_circle,
                    color: colors.primary,
                  ),
                  StageStatus.current => Icon(
                    Icons.directions_walk,
                    color: colors.tertiary,
                  ),
                  StageStatus.locked => Icon(Icons.lock, color: colors.outline),
                },
                title: Text('${i + 1}. ${stages[i].name}'),
                subtitle: engine.statusOf(i, progress) == StageStatus.done
                    ? Text(Strings.reward(stages[i].reward))
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChapterDoneCard extends StatelessWidget {
  const _ChapterDoneCard({required this.engine});

  final ChapterEngine engine;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.sailing, size: 48),
            Text(Strings.chapterDoneTitle, style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              engine.chapter.stages.last.completeMessage,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) {
    final (message, action) = switch (controller.status) {
      StepStatus.loading => (Strings.loading, null),
      StepStatus.tracking => (null, null),
      StepStatus.needsPermission => (
        Strings.needsPermission,
        Strings.grantPermission,
      ),
      StepStatus.permissionBlocked => (
        Strings.permissionBlocked,
        Strings.openSettings,
      ),
      StepStatus.noSensor => (Strings.noSensor, null),
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _Panel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.askPermission,
                  child: Text(action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
