import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/app.dart';
import 'package:rpg/strings.dart';
import 'package:rpg/ui/step_controller.dart';

import 'fakes/fakes.dart';

void main() {
  testWidgets('la app abre y muestra los pasos', (tester) async {
    final sensor = FakeSensor();
    final controller = StepController(sensor: sensor, storage: FakeStorage());
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    expect(find.text(Strings.today(0)), findsOneWidget);
    expect(find.text(Strings.tracking), findsOneWidget);

    sensor.emit(100);
    sensor.emit(160);
    await tester.pump(); // Llegan las lecturas.
    await tester.pump(); // Se redibuja la pantalla.
    expect(find.text(Strings.today(60)), findsOneWidget);
    expect(find.text(Strings.total(60)), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // Cierra la app y sus timers.
  });
}
