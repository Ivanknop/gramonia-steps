import 'package:material_ui/material_ui.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;

/// Cierre del capítulo: la Isla Negra y "Continuará...". Si falta la
/// imagen, un fondo oscuro de reemplazo.
class EndingScreen extends StatelessWidget {
  const EndingScreen({
    super.key,
    required this.background,
    required this.onBack,
    this.onCredits,
  });

  final String background;
  final VoidCallback onBack;

  /// Si no es nulo, se ve el botón "Créditos".
  final VoidCallback? onCredits;

  static const _shadows = [
    Shadow(blurRadius: 12, color: Colors.black),
    Shadow(blurRadius: 4, color: Colors.black87),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        const _DarkFallback(),
        Image.asset(
          background,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _DarkFallback(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black87],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Column(
              children: [
                for (final line in t.cierre)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: _shadows,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  t.continuara,
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    shadows: _shadows,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (onCredits != null)
                      OutlinedButton(
                        onPressed: onCredits,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(140, 52),
                        ),
                        child: const Text(Strings.creditsButton),
                      ),
                    FilledButton(
                      onPressed: onBack,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 52),
                      ),
                      child: const Text(Strings.backButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fondo oscuro de reemplazo, si no está la imagen de la Isla Negra.
class _DarkFallback extends StatelessWidget {
  const _DarkFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      key: ValueKey('ending-fallback'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1530), Color(0xFF05040A)],
        ),
      ),
    );
  }
}
