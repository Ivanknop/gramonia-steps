import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../data/textos.dart';
import 'notices.dart';
import 'widgets.dart';

/// Cartel de objeto conseguido: aparece grande en el centro y, a los pocos
/// segundos o al tocarlo, se achica y vuela hasta la bolsa.
class FoundItemOverlay extends StatefulWidget {
  const FoundItemOverlay({
    super.key,
    required this.moment,
    required this.target,
    required this.onLanded,
  });

  final FoundMoment moment;

  /// Centro de la bolsa, en coordenadas de este widget.
  final Offset Function() target;

  /// Al llegar a la bolsa.
  final VoidCallback onLanded;

  static const appearDuration = Duration(milliseconds: 350);
  static const holdDuration = Duration(milliseconds: 1600);
  static const flyDuration = Duration(milliseconds: 650);

  /// Tamaño del dibujo en el centro.
  static const bigSize = 180.0;

  /// Tamaño al llegar a la bolsa.
  static const smallSize = 28.0;

  @override
  State<FoundItemOverlay> createState() => _FoundItemOverlayState();
}

class _FoundItemOverlayState extends State<FoundItemOverlay>
    with TickerProviderStateMixin {
  late final _appear = AnimationController(
    vsync: this,
    duration: FoundItemOverlay.appearDuration,
  )..forward();
  late final _fly = AnimationController(
    vsync: this,
    duration: FoundItemOverlay.flyDuration,
  );
  Timer? _hold;
  Offset? _target;

  @override
  void initState() {
    super.initState();
    _hold = Timer(
      FoundItemOverlay.appearDuration + FoundItemOverlay.holdDuration,
      _startFlying,
    );
  }

  void _startFlying() {
    _hold?.cancel();
    if (_fly.isAnimating || _fly.isCompleted) return;
    _target = widget.target();
    _fly.forward().whenComplete(() {
      if (mounted) widget.onLanded();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _appear.dispose();
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final moment = widget.moment;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startFlying,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screen = constraints.biggest;
          final center = Offset(screen.width / 2, screen.height * 0.4);
          return AnimatedBuilder(
            animation: Listenable.merge([_appear, _fly]),
            builder: (context, _) {
              final t = Curves.easeInCubic.transform(_fly.value);
              final grow = Curves.elasticOut.transform(_appear.value);
              final size =
                  lerpDouble(
                    FoundItemOverlay.bigSize,
                    FoundItemOverlay.smallSize,
                    t,
                  )! *
                  grow;
              final position = Offset.lerp(center, _target ?? center, t)!;
              final fade = 1 - (_fly.value * 3).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: 0.4 * _appear.value * (1 - _fly.value),
                      ),
                    ),
                  ),
                  Positioned(
                    left: position.dx - size / 2,
                    top: position.dy - size / 2,
                    child: GameImage(moment.item.image, size: size),
                  ),
                  if (fade > 0)
                    Positioned(
                      left: 24,
                      right: 24,
                      top: center.dy + FoundItemOverlay.bigSize / 2 + 12,
                      child: Opacity(
                        opacity: fade * _appear.value,
                        child: Panel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                moment.title,
                                textAlign: TextAlign.center,
                                style: text.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(moment.message, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(
                                Strings.tapToContinue,
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
