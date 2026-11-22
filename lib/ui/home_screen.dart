import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart';
import '../strings.dart';
import 'step_controller.dart';

/// Pantalla única: pasos de hoy, total y botón de debug.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.showDebug = kDebugMode,
  });

  final StepController controller;

  /// El botón "+1.000 pasos" solo aparece en builds de debug.
  final bool showDebug;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final state = controller.state;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Strings.todayLabel,
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                  Text(
                    Strings.formatNumber(state.todaySteps),
                    textAlign: TextAlign.center,
                    style: text.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Strings.total(state.totalSteps),
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  _StatusNotice(controller: controller),
                  if (showDebug) ...[
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => controller.addDebugSteps(debugStepBonus),
                      child: Text(Strings.debugAdd(debugStepBonus)),
                    ),
                  ],
                ],
              );
            },
          ),
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
    return Card(
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
    );
  }
}
