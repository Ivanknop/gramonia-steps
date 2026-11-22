import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
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

  const steps = StepState(
    lastReading: 100,
    totalSteps: 12345,
    todaySteps: 678,
    todayDate: '2026-11-22',
  );

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

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  setUp(() {
    sensor = FakeSensor();
    storage = FakeStorage(steps);
  });

  testWidgets('muestra los pasos de hoy y el total', (tester) async {
    await show(tester);
    expect(find.text(Strings.todayLabel), findsOneWidget);
    expect(find.text('678'), findsOneWidget);
    expect(find.text(Strings.total(12345)), findsOneWidget);
    expect(find.text(Strings.needsPermission), findsNothing);
  });

  testWidgets('muestra la etapa actual, sus objetos y el viaje', (
    tester,
  ) async {
    storage.saved = const GameSave(
      steps: steps,
      chapter: ChapterProgress(
        stageIndex: 1,
        stepsInStage: 1200,
        collected: [
          'hoja_dorada',
          'mapa_gramonia',
          'farol_luciernagas',
          'carta_mision',
          'frutillas',
          'nueces',
        ],
      ),
    );
    await show(tester);
    expect(find.text(Strings.stageOf(2, 7)), findsOneWidget);
    expect(find.text(Strings.stageProgress(1200, 4000)), findsOneWidget);
    expect(find.text(Strings.reward('Pluma del Rocanrón')), findsOneWidget);
    // Conseguidos sin subtítulo, el próximo con lo que falta.
    expect(find.text('Nueces del bosque'), findsOneWidget);
    expect(find.text(Strings.stepsToNext(300)), findsOneWidget);
    expect(find.text(Strings.itemAt(2000)), findsOneWidget);
    // El viaje: etapa 1 hecha, la 2 actual y la 3 bloqueada.
    expect(find.text('1. El árbol mágico'), findsOneWidget);
    expect(find.text(Strings.reward('Caperuza de aprendiz')), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
  });

  testWidgets('el botón de debug avanza la etapa y muestra un aviso', (
    tester,
  ) async {
    await show(tester);
    expect(find.text(Strings.stageOf(1, 7)), findsOneWidget);
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(); // Llega el evento y aparece el aviso.
    expect(find.text('1.678'), findsOneWidget);
    expect(find.text(Strings.stageOf(2, 7)), findsOneWidget);
    expect(
      find.text(Strings.collectedSummary(4, 1)),
      findsOneWidget,
      reason: 'el aviso resume los 4 objetos y la etapa',
    );
    await tester.pump(const Duration(seconds: 5)); // Se va el aviso.
  });

  testWidgets('con el capítulo terminado se ve que el barco zarpó', (
    tester,
  ) async {
    storage.saved = const GameSave(
      steps: steps,
      chapter: ChapterProgress(stageIndex: 7, stepsInStage: 0, collected: []),
    );
    await show(tester);
    expect(find.text(Strings.chapterDoneTitle), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
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
    await tapText(tester, Strings.grantPermission);
    expect(find.text(Strings.needsPermission), findsNothing);
  });

  testWidgets('con permiso bloqueado, el botón abre los ajustes', (
    tester,
  ) async {
    sensor.permission = SensorPermission.permanentlyDenied;
    await show(tester);
    expect(find.text(Strings.permissionBlocked), findsOneWidget);
    await tapText(tester, Strings.openSettings);
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
