import 'package:material_ui/material_ui.dart';

import 'main_screen.dart';
import 'presentation_screen.dart';
import 'step_controller.dart';
import 'title_screen.dart';

/// Qué pantalla grande se ve.
enum FlowScreen { title, presentation, game }

/// Ordena las pantallas grandes: portada → presentación (si todavía no se
/// sabe el nombre de quien juega) → juego.
class GameFlow extends StatefulWidget {
  const GameFlow({super.key, required this.controller});

  final StepController controller;

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  var _screen = FlowScreen.title;

  void _go(FlowScreen next) => setState(() => _screen = next);

  /// Después de la portada: lo que todavía no se vio.
  void _start() {
    final controller = widget.controller;
    _go(
      controller.playerName == null ? FlowScreen.presentation : FlowScreen.game,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: switch (_screen) {
          FlowScreen.title => TitleScreen(
            key: const ValueKey(FlowScreen.title),
            background: controller.engine.chapter.walkingBackground,
            started: controller.hasStarted,
            onStart: _start,
          ),
          FlowScreen.presentation => PresentationScreen(
            key: const ValueKey(FlowScreen.presentation),
            controller: controller,
            onDone: () => _go(FlowScreen.game),
          ),
          FlowScreen.game => MainScreen(
            key: const ValueKey(FlowScreen.game),
            controller: controller,
          ),
        },
      ),
    );
  }
}
