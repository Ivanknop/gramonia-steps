import 'package:material_ui/material_ui.dart';

import '../data/textos.dart';

/// Portada: el mapa de la isla, el título y el botón para empezar.
class TitleScreen extends StatelessWidget {
  const TitleScreen({
    super.key,
    required this.background,
    required this.started,
    required this.onStart,
    this.onCredits,
  });

  /// El mapa de la isla.
  final String background;

  /// Si ya se empezó a jugar ("Seguir caminando" en vez de "Empezar").
  final bool started;
  final VoidCallback onStart;
  final VoidCallback? onCredits;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(background, fit: BoxFit.cover),
          // Oscurece arriba y abajo para que se lean el título y el botón.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
              child: Column(
                children: [
                  const GameLogo(text: Strings.titleLogo),
                  const SizedBox(height: 12),
                  Text(
                    Strings.titleSubtitle,
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      shadows: GameLogo.shadows,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(240, 64),
                      textStyle: text.headlineSmall,
                    ),
                    child: Text(
                      started ? Strings.resumeButton : Strings.startButton,
                    ),
                  ),
                  if (onCredits != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onCredits,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(Strings.creditsButton),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El título "Caminando por Gramonia" como logo: letras grandes con borde
/// y sombra.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, required this.text});

  final String text;

  static const shadows = [
    Shadow(blurRadius: 12, color: Colors.black87),
    Shadow(blurRadius: 4, color: Colors.black54),
  ];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.displayMedium!
        .copyWith(fontWeight: FontWeight.w900, height: 1.05, letterSpacing: 1);
    const border = Color(0xFF3B2A14);
    return Stack(
      children: [
        // Borde: el mismo texto, solo con trazo.
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            shadows: shadows,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8
              ..strokeJoin = StrokeJoin.round
              ..color = border,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(color: const Color(0xFFFFE08A)),
        ),
      ],
    );
  }
}
