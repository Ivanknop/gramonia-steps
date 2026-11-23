import 'package:material_ui/material_ui.dart';

import '../data/textos.dart';
import '../logic/chapter.dart';
import 'theme.dart';

/// Pantalla de llegada: solo la imagen del lugar (animada, si hay), el
/// título grande "Llegaste a …" y el botón "Entrar".
class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key, required this.stage, required this.onEnter});

  final Stage stage;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // El mismo fondo de la etapa que después queda detrás del juego.
        // Se ve desde el primer momento.
        Image.asset(
          stage.background,
          key: const ValueKey('arrival-background'),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
        // Si algún día hay una imagen (o GIF) propia del lugar, va encima.
        Image.asset(
          stage.arrivalImage,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Column(
              children: [
                OutlinedText(
                  Strings.arrivedAt(stage.place, stage.placeArticle),
                  style: text.displaySmall!.copyWith(color: Colors.white),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onEnter,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 64),
                    textStyle: text.titleLarge,
                  ),
                  child: const Text(Strings.enterButton),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
