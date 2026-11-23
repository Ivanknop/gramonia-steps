import 'package:material_ui/material_ui.dart';

/// Panel semitransparente con bordes redondeados, para que el texto se lea
/// bien sobre la ilustración.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero});

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

/// Dibujo de un objeto, recompensa o personaje.
///
/// - Si el archivo no existe, muestra [fallback] en vez de romperse.
/// - Con [dimmed], se ve en gris y semitransparente (lo que todavía falta).
class GameImage extends StatelessWidget {
  const GameImage(
    this.asset, {
    super.key,
    required this.size,
    this.dimmed = false,
    this.fallback = Icons.auto_awesome,
  });

  /// Para personajes: el ícono genérico es una persona.
  const GameImage.character(this.asset, {super.key, required this.size})
    : dimmed = false,
      fallback = Icons.face;

  final String asset;
  final double size;
  final bool dimmed;
  final IconData fallback;

  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => SizedBox(
        width: size,
        height: size,
        child: Icon(
          fallback,
          key: const ValueKey('missing-art'),
          size: size * 0.7,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
    if (dimmed) {
      image = Opacity(
        opacity: 0.45,
        child: ColorFiltered(colorFilter: _grey, child: image),
      );
    }
    return image;
  }
}
