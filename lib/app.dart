import 'package:material_ui/material_ui.dart';

import 'services/step_sensor.dart';
import 'services/game_storage.dart';
import 'services/step_history_storage.dart';
import 'data/textos.dart';
import 'ui/home_screen.dart';
import 'ui/my_steps_screen.dart';
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
          historyStorage: SqliteStepHistoryStorage(),
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
      home: MainScreen(controller: _controller),
    );
  }
}

/// Las dos pestañas: el juego y "Mis pasos".
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.controller});

  final StepController controller;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: el juego sigue vivo (avisos en cola) al cambiar de
      // pestaña.
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(controller: widget.controller),
          MyStepsScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: Strings.tabGame,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Strings.tabSteps,
          ),
        ],
      ),
    );
  }
}
