import 'package:material_ui/material_ui.dart';

import 'data/chapter1.dart' show musicVolume;
import 'services/music_player.dart';
import 'services/step_sensor.dart';
import 'services/game_storage.dart';
import 'services/step_history_storage.dart';
import 'services/system_notifier.dart';
import 'data/textos.dart';
import 'ui/game_flow.dart';
import 'ui/music_controller.dart';
import 'ui/notification_controller.dart';
import 'ui/step_controller.dart';
import 'ui/theme.dart';

class GramoniaApp extends StatefulWidget {
  const GramoniaApp({
    super.key,
    this.controller,
    this.music,
    this.notifications,
  });

  /// Para los tests. Si es nulo, se usan el sensor y el guardado reales.
  final StepController? controller;

  /// Para los tests. Si [controller] es nulo, se usa la música real; si no,
  /// solo hay música si se pasa una.
  final MusicController? music;

  /// Para los tests, como [music].
  final NotificationController? notifications;

  @override
  State<GramoniaApp> createState() => _GramoniaAppState();
}

class _GramoniaAppState extends State<GramoniaApp> with WidgetsBindingObserver {
  late final StepController _controller;
  MusicController? _music;
  NotificationController? _notifications;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        StepController(
          sensor: const DeviceStepSensor(),
          storage: PrefsGameStorage(),
          historyStorage: SqliteStepHistoryStorage(),
        );
    _music =
        widget.music ??
        (widget.controller == null
            ? MusicController(
                player: JustAudioMusicPlayer(volume: musicVolume),
                steps: _controller,
              )
            : null);
    _notifications =
        widget.notifications ??
        (widget.controller == null
            ? NotificationController(
                notifier: LocalSystemNotifier(),
                steps: _controller,
              )
            : null);
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
    _music?.start();
    _notifications?.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.onResume();
        _music?.onResume();
        _notifications?.onResume();
      case AppLifecycleState.paused:
        _controller.onPause();
        _music?.onPause();
        _notifications?.onPause();
      // Pantalla apagada o app tapada: la música se pausa y los avisos van
      // al celular.
      case AppLifecycleState.hidden:
        _music?.onPause();
        _notifications?.onPause();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.music == null) _music?.dispose();
    if (widget.notifications == null) _notifications?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      theme: gameTheme(),
      home: GameFlow(
        controller: _controller,
        music: _music,
        notifications: _notifications,
      ),
    );
  }
}
