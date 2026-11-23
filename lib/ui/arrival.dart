import 'package:material_ui/material_ui.dart';

import '../logic/chapter.dart';
import '../data/textos.dart';

/// Pantalla de llegada: solo la imagen del lugar (animada, si hay), el
/// título grande "Llegaste a …" y el botón "Entrar".
class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key, required this.stage, required this.onEnter});

  final Stage stage;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Sombra para que el título se lea sobre cualquier dibujo, sin panel.
    const shadows = [
      Shadow(blurRadius: 12, color: Colors.black87),
      Shadow(blurRadius: 4, color: Colors.black54),
    ];
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
                Text(
                  Strings.arrivedAt(stage.place, stage.placeArticle),
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: shadows,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onEnter,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 64),
                    textStyle: text.headlineSmall,
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
