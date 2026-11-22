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

Finder background(String asset) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == asset,
);

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

  /// [dice] 0: todas las tiradas al azar salen; 1: ninguna (salvo garantía).
  Future<void> show(
    WidgetTester tester, {
    bool showDebug = true,
    int dice = 0,
  }) async {
    controller = StepController(
      sensor: sensor,
      storage: storage,
      clock: FakeClock(DateTime(2026, 11, 22, 10)),
      random: FixedRandom(dice),
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

  int engineStage() => controller.game.chapter.stageIndex;

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

  testWidgets('tramo de llegar: mapa, "Caminando hasta" y barra del viaje', (
    tester,
  ) async {
    storage.saved = saveAt(3, 3200, const {});
    await show(tester);
    expect(find.text(Strings.walkingTo('Muelle')), findsOneWidget);
    expect(find.text(chapter1.stages[3].travelText), findsOneWidget);
    expect(find.text(Strings.stageProgress(3200, 10000)), findsOneWidget);
    expect(background(chapter1.walkingBackground), findsOneWidget);
    expect(background(chapter1.stages[3].background), findsNothing);
    // Durante el viaje no se muestra "Para juntar".
    expect(find.text(Strings.goalsTitle), findsNothing);
  });

  testWidgets('al terminar el tramo, fundido del mapa al fondo de la etapa', (
    tester,
  ) async {
    storage.saved = saveAt(3, 9500, const {});
    // Sin suerte: la pista no sale enseguida y la etapa sigue después de llegar.
    await show(tester, dice: 1);
    expect(background(chapter1.walkingBackground), findsOneWidget);

    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(StageBackground.fadeDuration ~/ 2);
    expect(background(chapter1.walkingBackground), findsOneWidget);
    expect(background(chapter1.stages[3].background), findsOneWidget);

    await tester.pump(StageBackground.fadeDuration);
    expect(background(chapter1.walkingBackground), findsNothing);
    expect(background(chapter1.stages[3].background), findsOneWidget);
    expect(find.text(Strings.goalsTitle), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // Se va el aviso.
  });

  testWidgets('al terminar la etapa 1, transición hasta el Árbol Mágico', (
    tester,
  ) async {
    await show(tester);
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(); // Llega el evento.
    await tester.pump(StageBackground.fadeDuration);
    expect(find.byType(WalkingTransition), findsOneWidget);
    expect(find.text(Strings.walkingTo('Árbol Mágico')), findsOneWidget);

    // Se cierra sola a los pocos segundos.
    await tester.pump(WalkingTransition.duration);
    await tester.pumpAndSettle(); // Termina el fundido de salida.
    expect(find.byType(WalkingTransition), findsNothing);
    expect(background(chapter1.stages[1].background), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // Se va el aviso.
  });

  testWidgets('la transición se cierra antes tocándola', (tester) async {
    storage.saved = saveAt(1, 0, {'flor_lila': 15, 'semilla_fuego': 2});
    await show(tester);
    // Con todo a favor, la tercera semilla de fuego sale a los 200 pasos.
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump();
    await tester.pump(StageBackground.fadeDuration);
    expect(find.text(Strings.walkingTo('Bosque Mágico')), findsOneWidget);

    await tester.tap(find.byType(WalkingTransition));
    await tester.pumpAndSettle(); // Termina el fundido de salida.
    expect(find.byType(WalkingTransition), findsNothing);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('sin transición si la etapa nueva tiene su tramo de llegar', (
    tester,
  ) async {
    storage.saved = saveAt(2, 5500, {
      'flor_lila': 15,
      'semilla_fuego': 3,
      'pieza_hoja': 1,
      'pieza_gota': 1,
      'pieza_piedra': 1,
      'pieza_sol': 1,
      'pieza_luna': 1,
    });
    await show(tester);
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump();
    await tester.pump(StageBackground.fadeDuration);
    expect(engineStage(), 3);
    expect(find.byType(WalkingTransition), findsNothing);
    // La etapa 4 arranca con su tramo: se ve el mapa en el fondo.
    expect(find.text(Strings.walkingTo('Muelle')), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
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

  testWidgets('se ve el fondo de la etapa actual', (tester) async {
    storage.saved = saveAt(2, 0, const {});
    await show(tester);
    expect(background(chapter1.stages[2].background), findsOneWidget);
    expect(background(chapter1.stages[1].background), findsNothing);
  });

  testWidgets('al pasar de etapa, el fondo cambia con un fundido', (
    tester,
  ) async {
    await show(tester);
    final first = chapter1.stages[0].background;
    final second = chapter1.stages[1].background;
    expect(background(first), findsOneWidget);

    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(StageBackground.fadeDuration ~/ 2);
    // A mitad del fundido se ven los dos.
    expect(background(first), findsOneWidget);
    expect(background(second), findsOneWidget);

    await tester.pump(StageBackground.fadeDuration);
    expect(background(first), findsNothing);
    expect(background(second), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // Se va el aviso.
  });

  testWidgets('después del final queda el fondo de la etapa 7', (tester) async {
    storage.saved = saveAt(7, 0, const {});
    await show(tester);
    expect(background(chapter1.stages.last.background), findsOneWidget);
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
