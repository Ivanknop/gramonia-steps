import 'package:material_ui/material_ui.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import 'dialogue.dart';
import 'step_controller.dart';

/// Introducción: Mututu despierta y Sofía pide ayuda. Se ve una sola vez.
class IntroScreen extends StatelessWidget {
  const IntroScreen({
    super.key,
    required this.controller,
    required this.onDone,
  });

  final StepController controller;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final chapter = controller.engine.chapter;
    return Scaffold(
      backgroundColor: Colors.black,
      body: DialogueView(
        chapter: chapter,
        lines: t.introduccion,
        playerName: controller.playerName ?? '',
        background: chapter.islandBackground,
        doneLabel: Strings.introButton,
        onDone: onDone,
      ),
    );
  }
}
