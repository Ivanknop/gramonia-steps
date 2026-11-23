import 'package:material_ui/material_ui.dart';

import '../logic/chapter.dart';
import '../strings.dart';
import 'widgets.dart';

/// Ventana de fin de etapa: el personaje, la recompensa en grande y el texto
/// final. Se cierra con el botón o tocando afuera.
class StageDoneOverlay extends StatelessWidget {
  const StageDoneOverlay({
    super.key,
    required this.chapter,
    required this.stage,
    required this.onDone,
  });

  final Chapter chapter;
  final Stage stage;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final character = chapter.character(stage.completeCharacter);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDone,
      child: ColoredBox(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Panel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Strings.stageDoneTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GameImage.of(character, size: 110),
                        const SizedBox(width: 8),
                        GameImage(stage.reward.image, size: 150),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Strings.youGot(stage.reward.name),
                      textAlign: TextAlign.center,
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(stage.completeMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onDone,
                      child: const Text(Strings.continueButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
