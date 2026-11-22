import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/strings.dart';
import 'package:rpg/ui/home_screen.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late FakeSensor sensor;
  late FakeStorage storage;
  late StepController controller;

  Future<void> show(WidgetTester tester, {bool showDebug = true}) async {
    controller = StepController(
      sensor: sensor,
      storage: storage,
      clock: FakeClock(DateTime(2026, 11, 22, 10)),
    );
    await controller.start();
    // El timer del cambio de día tiene que cerrarse dentro de cada test.
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(controller: controller, showDebug: showDebug),
      ),
    );
  }

  setUp(() {
    sensor = FakeSensor();
    storage = FakeStorage(
      const StepState(
        lastReading: 100,
        totalSteps: 12345,
        todaySteps: 678,
        todayDate: '2026-11-22',
      ),
    );
  });

  testWidgets('muestra los pasos de hoy y el total', (tester) async {
    await show(tester);
    expect(find.text(Strings.todayLabel), findsOneWidget);
    expect(find.text('678'), findsOneWidget);
    expect(find.text(Strings.total(12345)), findsOneWidget);
    expect(find.text(Strings.needsPermission), findsNothing);
  });

  testWidgets('el botón de debug suma 1.000 pasos', (tester) async {
    await show(tester);
    await tester.tap(find.text(Strings.debugAdd(debugStepBonus)));
    await tester.pump();
    expect(find.text('1.678'), findsOneWidget);
    expect(find.text(Strings.total(13345)), findsOneWidget);
  });

  testWidgets('sin debug no aparece el botón', (tester) async {
    await show(tester, showDebug: false);
    expect(find.text(Strings.debugAdd(debugStepBonus)), findsNothing);
  });

  testWidgets('sin permiso aparece el aviso y el botón lo pide', (
    tester,
  ) async {
    sensor.permission = SensorPermission.denied;
    await show(tester);
    expect(find.text(Strings.needsPermission), findsOneWidget);

    sensor.answerToRequest = SensorPermission.granted;
    await tester.tap(find.text(Strings.grantPermission));
    await tester.pump();
    expect(find.text(Strings.needsPermission), findsNothing);
  });

  testWidgets('con permiso bloqueado, el botón abre los ajustes', (
    tester,
  ) async {
    sensor.permission = SensorPermission.permanentlyDenied;
    await show(tester);
    expect(find.text(Strings.permissionBlocked), findsOneWidget);
    await tester.tap(find.text(Strings.openSettings));
    await tester.pump();
    expect(sensor.settingsCount, 1);
  });

  testWidgets('sin sensor aparece el aviso', (tester) async {
    await show(tester);
    sensor.fail(const StepSensorUnavailable('no hay'));
    await tester.pump();
    await tester.pump();
    expect(find.text(Strings.noSensor), findsOneWidget);
  });
}
