import 'package:material_ui/material_ui.dart';

import 'strings.dart';

class GramoniaApp extends StatelessWidget {
  const GramoniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const Scaffold(body: Center(child: Text(Strings.appTitle))),
    );
  }
}
