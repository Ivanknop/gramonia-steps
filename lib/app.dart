import 'package:material_ui/material_ui.dart';

import 'services/step_sensor.dart';
import 'services/step_storage.dart';
import 'strings.dart';
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
          storage: PrefsStepStorage(),
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
      // Pantalla provisoria para probar el sensor; la definitiva va en el paso 5.
      home: Scaffold(
        body: Center(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Strings.today(_controller.state.todaySteps)),
                Text(Strings.total(_controller.state.totalSteps)),
                Text(_statusText(_controller.status)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText(StepStatus status) => switch (status) {
    StepStatus.loading => Strings.loading,
    StepStatus.tracking => Strings.tracking,
    StepStatus.needsPermission => Strings.needsPermission,
    StepStatus.permissionBlocked => Strings.permissionBlocked,
    StepStatus.noSensor => Strings.noSensor,
  };
}
