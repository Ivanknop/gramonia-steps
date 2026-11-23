import 'package:material_ui/material_ui.dart';

import '../data/textos.dart';
import 'home_screen.dart';
import 'my_steps_screen.dart';
import 'step_controller.dart';

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
