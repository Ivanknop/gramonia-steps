import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/app.dart';
import 'package:rpg/data/textos.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/ui/step_controller.dart';
import 'package:rpg/ui/title_screen.dart';

import 'fakes/fakes.dart';

void main() {
  testWidgets('abre en la portada; "Empezar" lleva al juego', (tester) async {
    final sensor = FakeSensor();
    final controller = StepController(sensor: sensor, storage: FakeStorage());
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.text(Strings.titleLogo), findsWidgets);
    expect(find.text(Strings.titleSubtitle), findsOneWidget);
    expect(find.text(Strings.startButton), findsOneWidget);

    await tester.tap(find.text(Strings.startButton));
    await tester.pumpAndSettle();
    expect(find.byType(TitleScreen), findsNothing);
    expect(find.text(Strings.todayLabel), findsOneWidget);

    sensor.emit(100);
    sensor.emit(160);
    await tester.pump(); // Llegan las lecturas.
    await tester.pump(); // Se redibuja la pantalla.
    expect(find.text('60'), findsOneWidget);
    expect(find.text(Strings.total(60)), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // Cierra la app y sus timers.
  });

  testWidgets('con una partida empezada, la portada dice "Seguir caminando"', (
    tester,
  ) async {
    final controller = StepController(
      sensor: FakeSensor(),
      storage: FakeStorage(
        const StepState(
          lastReading: 10,
          totalSteps: 5000,
          todaySteps: 0,
          todayDate: '',
        ),
      ),
    );
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    expect(find.text(Strings.resumeButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
