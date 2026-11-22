import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart';
import '../logic/chapter.dart';
import '../logic/chapter_engine.dart';
import '../logic/chapter_progress.dart';
import '../strings.dart';
import 'notices.dart';
import 'step_controller.dart';

/// Pantalla única: pasos, etapa actual con sus objetos y el viaje completo.
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noticeFor(events)),
        duration: const Duration(seconds: 4),
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
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final chapter = controller.game.chapter;
            final stage = engine.currentStage(chapter);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepsHeader(controller: controller),
                  _StatusNotice(controller: controller),
                  const SizedBox(height: 16),
                  if (stage == null)
                    const _ChapterDoneCard()
                  else ...[
                    _StageCard(engine: engine, stage: stage, progress: chapter),
                    const SizedBox(height: 12),
                    _ItemsCard(engine: engine, stage: stage, progress: chapter),
                  ],
                  const SizedBox(height: 12),
                  _JourneyCard(engine: engine, progress: chapter),
                  if (widget.showDebug) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => controller.addDebugSteps(debugStepBonus),
                      child: Text(Strings.debugAdd(debugStepBonus)),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
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
    return Column(
      children: [
        Text(Strings.todayLabel, style: text.titleMedium),
        Text(
          Strings.formatNumber(state.todaySteps),
          style: text.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(Strings.total(state.totalSteps), style: text.bodyLarge),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.stageOf(progress.stageIndex + 1, count),
              style: text.labelLarge,
            ),
            Text(stage.name, style: text.headlineSmall),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.stepsInStage / stage.steps,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 6),
            Text(Strings.stageProgress(progress.stepsInStage, stage.steps)),
            const SizedBox(height: 6),
            Text(Strings.reward(stage.reward), style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.engine,
    required this.stage,
    required this.progress,
  });

  final ChapterEngine engine;
  final Stage stage;
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final next = engine.nextItem(progress);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                Strings.itemsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final item in stage.items)
              ListTile(
                dense: true,
                leading: progress.has(item.id)
                    ? Icon(Icons.check_circle, color: colors.primary)
                    : Icon(Icons.radio_button_unchecked, color: colors.outline),
                title: Text(item.name),
                subtitle: progress.has(item.id)
                    ? null
                    : Text(
                        item == next
                            ? Strings.stepsToNext(
                                engine.stepsToNextItem(progress),
                              )
                            : Strings.itemAt(item.atSteps),
                      ),
              ),
          ],
        ),
      ),
    );
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
    return Card(
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
  const _ChapterDoneCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.sailing, size: 48),
            Text(Strings.chapterDoneTitle, style: text.headlineSmall),
            const SizedBox(height: 8),
            const Text(Strings.chapterDoneBody, textAlign: TextAlign.center),
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
      child: Card(
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
