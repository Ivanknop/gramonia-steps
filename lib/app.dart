import 'package:material_ui/material_ui.dart';

import 'services/step_sensor.dart';
import 'services/game_storage.dart';
import 'strings.dart';
import 'ui/home_screen.dart';
import 'ui/step_controller.dart';

class GramoniaApp extends StatefulWidget {
  const GramoniaApp({super.key, this.controller});

  /// Para los tests. Si es nulo, se usan el sensor y el guardado reales.
  final StepController? controller;

  @override
  State<GramoniaApp> createState() => _GramoniaAppState();
}

class _GramoniaAppState extends State<GramoniaApp> with WidgetsBindingObserver {
  late final StepController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        StepController(
          sensor: const DeviceStepSensor(),
          storage: PrefsGameStorage(),
        );
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.onResume();
      case AppLifecycleState.paused:
        _controller.onPause();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: HomeScreen(controller: _controller),
    );
  }
}
