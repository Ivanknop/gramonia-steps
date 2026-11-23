import 'package:material_ui/material_ui.dart';

import 'data/chapter1.dart' show musicVolume;
import 'services/music_player.dart';
import 'services/step_sensor.dart';
import 'services/game_storage.dart';
import 'services/step_history_storage.dart';
import 'data/textos.dart';
import 'ui/game_flow.dart';
import 'ui/music_controller.dart';
import 'ui/step_controller.dart';

class GramoniaApp extends StatefulWidget {
  const GramoniaApp({super.key, this.controller, this.music});

  /// Para los tests. Si es nulo, se usan el sensor y el guardado reales.
  final StepController? controller;

  /// Para los tests. Si [controller] es nulo, se usa la música real; si no,
  /// solo hay música si se pasa una.
  final MusicController? music;

  @override
  State<GramoniaApp> createState() => _GramoniaAppState();
}

class _GramoniaAppState extends State<GramoniaApp> with WidgetsBindingObserver {
  late final StepController _controller;
  MusicController? _music;

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
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
    _music?.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.onResume();
        _music?.onResume();
      case AppLifecycleState.paused:
        _controller.onPause();
        _music?.onPause();
      // Pantalla apagada o app tapada: la música se pausa.
      case AppLifecycleState.hidden:
        _music?.onPause();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.music == null) _music?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: GameFlow(controller: _controller, music: _music),
    );
  }
}
