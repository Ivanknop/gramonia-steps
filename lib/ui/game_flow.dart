import 'package:material_ui/material_ui.dart';

import 'main_screen.dart';
import 'step_controller.dart';
import 'title_screen.dart';

/// Qué pantalla grande se ve: la portada o el juego.
enum FlowScreen { title, game }

/// Ordena las pantallas grandes: portada → juego.
class GameFlow extends StatefulWidget {
  const GameFlow({super.key, required this.controller});

  final StepController controller;

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  var _screen = FlowScreen.title;

  void _go(FlowScreen next) => setState(() => _screen = next);

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
            onStart: () => _go(FlowScreen.game),
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
