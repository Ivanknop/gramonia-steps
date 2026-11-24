import 'package:material_ui/material_ui.dart';

import 'credits_screen.dart';
import '../logic/music.dart';
import 'main_screen.dart';
import 'notification_controller.dart';
import 'music_controller.dart';
import 'presentation_screen.dart';
import 'story_screens.dart';
import 'step_controller.dart';
import 'title_screen.dart';

/// Qué pantalla grande se ve.
enum FlowScreen { title, presentation, intro, game }

/// Ordena las pantallas grandes: portada → presentación (si todavía no se
/// sabe el nombre de quien juega) → introducción (una sola vez) → juego.
class GameFlow extends StatefulWidget {
  const GameFlow({
    super.key,
    required this.controller,
    this.music,
    this.notifications,
  });

  final StepController controller;
  final MusicController? music;
  final NotificationController? notifications;

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  var _screen = FlowScreen.title;

  void _go(FlowScreen next) {
    setState(() => _screen = next);
    widget.music?.setScene(switch (next) {
      FlowScreen.title => MusicScene.title,
      FlowScreen.presentation => MusicScene.presentation,
      FlowScreen.intro => MusicScene.intro,
      FlowScreen.game => MusicScene.game,
    });
  }

  /// Después de la portada: lo que todavía no se vio. Si falta el nombre,
  /// el género o la pregunta de los avisos (partidas de antes), la
  /// presentación.
  void _start() {
    final controller = widget.controller;
    // Si ya activó los avisos en "Mis pasos", no hace falta preguntar.
    if (widget.notifications?.enabled ?? false) {
      controller.markNotificationsAsked();
    }
    final ask =
        controller.playerName == null ||
        controller.genero == null ||
        !controller.notificationsAsked;
    _go(ask ? FlowScreen.presentation : _afterName());
  }

  FlowScreen _afterName() =>
      widget.controller.game.introSeen ? FlowScreen.game : FlowScreen.intro;

  void _introDone() {
    widget.controller.markIntroSeen();
    _go(FlowScreen.game);
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
            onCredits: () => CreditsScreen.show(
              context,
              controller.engine.chapter.walkingBackground,
              music: widget.music,
            ),
          ),
          FlowScreen.presentation => PresentationScreen(
            key: const ValueKey(FlowScreen.presentation),
            controller: controller,
            enableNotifications: switch (widget.notifications) {
              final n? => () => n.setEnabled(true),
              null => null,
            },
            onDone: () => _go(_afterName()),
          ),
          FlowScreen.intro => IntroScreen(
            key: const ValueKey(FlowScreen.intro),
            controller: controller,
            onDone: _introDone,
          ),
          FlowScreen.game => MainScreen(
            key: const ValueKey(FlowScreen.game),
            controller: controller,
            music: widget.music,
            notifications: widget.notifications,
          ),
        },
      ),
    );
  }
}
