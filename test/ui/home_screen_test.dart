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

import '../fakes/fake_random.dart';
import '../fakes/fakes.dart';

void main() {
  late FakeSensor sensor;
  late FakeStorage storage;
  late StepController controller;

  const savedSteps = StepState(
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
      random: FixedRandom(0), // todas las tiradas al azar salen
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
    storage = FakeStorage(savedSteps);
  });

  testWidgets('muestra los pasos de hoy y el total', (tester) async {
    await show(tester);
    expect(find.text(Strings.todayLabel), findsOneWidget);
    expect(find.text('678'), findsOneWidget);
    expect(find.text(Strings.total(12345)), findsOneWidget);
    expect(find.text(Strings.needsPermission), findsNothing);
  });

  GameSave saveAt(int stage, int steps, Map<String, int> inventory) => GameSave(
    steps: savedSteps,
    chapter: ChapterProgress(
      stageIndex: stage,
      stepsInStage: steps,
      inventory: inventory,
      sinceLast: const {},
    ),
  );

  testWidgets('etapa con objetos al azar y canje', (tester) async {
    storage.saved = saveAt(1, 300, {'flor_lila': 15, 'semilla_agua': 4});
    await show(tester);
    expect(find.text(Strings.stageOf(2, 7)), findsOneWidget);
    expect(find.text('El nido del Rocanrón'), findsOneWidget);
    expect(find.text(chapter1.stages[1].intro), findsOneWidget);
    expect(find.text('Semilla de fuego'), findsOneWidget);
    expect(find.text(Strings.countOf(0, 3)), findsOneWidget);
    expect(find.text(Strings.appearsRandomly), findsOneWidget);
    expect(
      find.text(
        Strings.exchangeProgress(
          'Semilla de agua o Semilla de hielo',
          4,
          10,
          'Semilla de fuego',
        ),
      ),
      findsOneWidget,
    );
    // El viaje: etapa 1 hecha, la 2 actual y 5 bloqueadas.
    expect(find.text('1. Salir de la casa de la abuelita'), findsOneWidget);
    expect(find.text(Strings.reward('Caperuza de aprendiz')), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
  });

  testWidgets('etapa con objetos fijos: cuántos pasos faltan', (tester) async {
    storage.saved = saveAt(2, 1200, {'pieza_hoja': 1});
    await show(tester);
    expect(find.text('Pieza de la gota'), findsOneWidget);
    expect(find.text(Strings.stepsToNext(800)), findsOneWidget);
  });

  testWidgets('tramo de llegar: barra del viaje y su texto', (tester) async {
    storage.saved = saveAt(3, 3200, const {});
    await show(tester);
    expect(find.text(Strings.travelingTo('El puerto')), findsOneWidget);
    expect(find.text(chapter1.stages[3].travelText), findsOneWidget);
    expect(find.text(Strings.stageProgress(3200, 10000)), findsOneWidget);
    expect(find.text(Strings.afterArriving), findsOneWidget);
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
    expect(find.textContaining('¡Conseguiste'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // Se va el aviso.
  });

  testWidgets('con el capítulo terminado se ve que el barco zarpó', (
    tester,
  ) async {
    storage.saved = saveAt(7, 0, const {});
    await show(tester);
    expect(find.text(Strings.chapterDoneTitle), findsOneWidget);
    expect(find.text(chapter1.stages.last.completeMessage), findsOneWidget);
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
