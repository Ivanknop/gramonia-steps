import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/data/textos.dart' as t;
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/logic/wallet.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/data/textos.dart';
import 'package:rpg/ui/arrival.dart';
import 'package:rpg/ui/bag.dart';
import 'package:rpg/ui/credits_screen.dart';
import 'package:rpg/ui/dialogue.dart';
import 'package:rpg/ui/ending.dart';
import 'package:rpg/ui/found_item.dart';
import 'package:rpg/ui/home_screen.dart';
import 'package:rpg/ui/stage_done.dart';
import 'package:rpg/ui/step_controller.dart';
import 'package:rpg/ui/widgets.dart';

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
      // El aviso del bono del día se prueba aparte (coins_test).
      dailyBonus: CoinRange.none,
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

  /// Deja que el cartel del objeto aparezca, espere y vuele a la bolsa.
  Future<void> letItemFly(WidgetTester tester) async {
    await tester.pump(
      FoundItemOverlay.appearDuration + FoundItemOverlay.holdDuration,
    );
    // El vuelo arranca en el cuadro siguiente: un poco de margen.
    await tester.pump(FoundItemOverlay.flyDuration);
    await tester.pump(FoundItemOverlay.flyDuration);
  }

  /// Toca el diálogo hasta el último globo y después "¡Vamos!".
  Future<void> finishDialogue(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      if (find.text(Strings.stageDialogueButton).evaluate().isNotEmpty) break;
      await tester.tap(find.byType(DialogueView));
      await tester.pump();
    }
    await tester.tap(find.text(Strings.stageDialogueButton));
    await tester.pump();
  }

  /// Cierra todos los carteles y ventanas que haya, tocándolos.
  Future<void> closeEverything(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(StageBackground.fadeDuration);
      if (find.byType(FoundItemOverlay).hitTestable().evaluate().isNotEmpty) {
        await tester.tap(find.byType(FoundItemOverlay).hitTestable().first);
        await tester.pump(FoundItemOverlay.flyDuration);
      } else if (find.text(Strings.continueButton).evaluate().isNotEmpty) {
        await tester.tap(find.text(Strings.continueButton));
      } else if (find.text(Strings.enterButton).evaluate().isNotEmpty) {
        await tester.tap(find.text(Strings.enterButton));
      } else if (find.byType(DialogueView).evaluate().isNotEmpty) {
        await finishDialogue(tester);
      } else {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  Finder gameImage(String asset) =>
      find.byWidgetPredicate((w) => w is GameImage && w.asset == asset);

  /// Una imagen dibujada en pantalla con ese archivo.
  Finder assetImage(String asset) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName == asset,
  );

  bool isDimmed(WidgetTester tester, String asset) =>
      tester.widget<GameImage>(gameImage(asset).first).dimmed;

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

  GameSave saveAt(
    int stage,
    int steps,
    Map<String, int> inventory, {
    bool entered = true,
  }) => GameSave(
    steps: savedSteps,
    chapter: ChapterProgress(
      stageIndex: stage,
      stepsInStage: steps,
      inventory: inventory,
      sinceLast: const {},
      entered: entered,
    ),
  );

  testWidgets('etapa con objetos al azar y canje', (tester) async {
    storage.saved = saveAt(2, 3300, {'flor_lila': 15, 'semilla_agua': 4});
    await show(tester);
    expect(find.text(Strings.stageOf(3, 8)), findsOneWidget);
    expect(find.text('El nido del Rocanón'), findsOneWidget);
    expect(find.text(chapter1.stages[2].intro), findsOneWidget);
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
    // El viaje: etapas 1 y 2 hechas, la 3 actual y 5 bloqueadas.
    expect(find.text('2. La caperuza lila'), findsOneWidget);
    expect(find.text(Strings.reward('Caperuza de aprendiz')), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
  });

  testWidgets('etapa con objetos fijos: cuántos pasos faltan', (tester) async {
    storage.saved = saveAt(3, 3200, {'pieza_hoja': 1});
    await show(tester);
    expect(find.text('Pieza de la gota'), findsOneWidget);
    expect(find.text(Strings.stepsToNext(800)), findsOneWidget);
  });

  testWidgets('tramo de llegar: mapa, "Caminando hasta" y barra del viaje', (
    tester,
  ) async {
    storage.saved = saveAt(4, 3200, const {});
    await show(tester);
    expect(find.text(Strings.walkingTo('Muelle', 'el')), findsOneWidget);
    expect(find.text(chapter1.stages[4].travelText), findsOneWidget);
    expect(find.text(Strings.stageProgress(3200, 10000)), findsOneWidget);
    expect(background(chapter1.walkingBackground), findsOneWidget);
    expect(background(chapter1.stages[4].background), findsNothing);
    // Durante el viaje no se muestra "Para juntar".
    expect(find.text(Strings.goalsTitle), findsNothing);
  });

  testWidgets('al terminar el tramo: pantalla de llegada y "Entrar"', (
    tester,
  ) async {
    storage.saved = saveAt(4, 9500, const {}, entered: false);
    // Sin suerte: la pista no sale enseguida y la etapa sigue después de llegar.
    await show(tester, dice: 1);
    expect(background(chapter1.walkingBackground), findsOneWidget);

    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pumpAndSettle();
    expect(find.byType(ArrivalScreen), findsOneWidget);
    expect(find.text(Strings.arrivedAt('Muelle', 'el')), findsWidgets);
    expect(find.text('Llegaste al Muelle'), findsWidgets); // Borde y relleno.
    // Sin GIF del lugar, se ve el fondo de la etapa.
    expect(find.byKey(const ValueKey('arrival-background')), findsOneWidget);
    // Sin paneles: no se ve lo que hay que juntar.
    expect(find.text(Strings.goalsTitle).hitTestable(), findsNothing);

    await tester.tap(find.text(Strings.enterButton));
    await tester.pumpAndSettle();
    expect(find.byType(ArrivalScreen), findsNothing);

    // Después de "Entrar", el diálogo: Sofía y quien juega, con su nombre.
    expect(find.byType(DialogueView), findsOneWidget);
    expect(find.text(chapter1.stages[4].dialogue.first.texto), findsOneWidget);
    expect(controller.game.chapter.entered, isFalse);
    await finishDialogue(tester);
    await tester.pumpAndSettle();
    expect(find.byType(DialogueView), findsNothing);
    expect(controller.game.chapter.entered, isTrue);
    expect(background(chapter1.walkingBackground), findsNothing);
    expect(background(chapter1.stages[4].background), findsOneWidget);
    expect(find.text(Strings.goalsTitle), findsOneWidget);
  });

  testWidgets('sin entrar, los pasos siguen sumando y los carteles esperan', (
    tester,
  ) async {
    storage.saved = saveAt(4, 10000, const {}, entered: false);
    await show(tester);
    // Al abrir la app, sigue en la puerta.
    expect(find.byType(ArrivalScreen), findsOneWidget);

    // Con todo a favor, la pista sale a los 50 pasos. (El botón de debug
    // queda tapado por la pantalla de llegada.)
    await controller.addDebugSteps(debugStepBonus);
    await tester.pump();
    expect(controller.game.chapter.stageIndex, 5);
    expect(find.byType(FoundItemOverlay), findsNothing);
    expect(find.byType(ArrivalScreen), findsOneWidget);

    // Al entrar (y después del diálogo), el cartel de la pista y el fin de
    // la etapa.
    await tester.tap(find.text(Strings.enterButton));
    await tester.pump();
    await tester.pump(StageBackground.fadeDuration);
    expect(find.byType(FoundItemOverlay), findsNothing);
    await finishDialogue(tester);
    await tester.pump(StageBackground.fadeDuration);
    expect(find.byType(FoundItemOverlay), findsOneWidget);
    await closeEverything(tester);
    expect(find.byType(ArrivalScreen), findsNothing);
    expect(
      find.text(Strings.walkingTo('Montaña Dragón', 'la')),
      findsOneWidget,
    );
  });

  testWidgets('las partidas de antes ya entraron', (tester) async {
    storage.saved = saveAt(4, 10000, const {});
    await show(tester);
    expect(find.byType(ArrivalScreen), findsNothing);
  });

  testWidgets('al terminar las flores lilas: cartel, fin de etapa y caminata', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, const {}); // Las flores lilas.
    await show(tester);
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(); // Llega el evento.

    // Primero, el cartel de las 15 flores.
    expect(find.byType(FoundItemOverlay), findsOneWidget);
    expect(find.text(Strings.foundMany('Flor lila', 15)), findsOneWidget);
    await letItemFly(tester);

    // Después, la ventana de fin de etapa con el personaje y la recompensa.
    await tester.pump(StageBackground.fadeDuration);
    expect(find.byType(StageDoneOverlay), findsOneWidget);
    expect(find.text(Strings.youGot('Caperuza de aprendiz')), findsOneWidget);
    expect(find.text(chapter1.stages[1].completeMessage), findsOneWidget);
    expect(gameImage('assets/items/caperuza_aprendiz.webp'), findsWidgets);
    expect(gameImage('assets/characters/caperucita.webp'), findsOneWidget);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pump();
    await tester.pump(StageBackground.fadeDuration);

    // Y empieza el tramo de caminata hasta el Árbol Mágico, con el mapa.
    await tester.pumpAndSettle(); // Termina el fundido de salida.
    expect(find.byType(StageDoneOverlay), findsNothing);
    expect(find.text(Strings.walkingTo('Árbol Mágico', 'el')), findsOneWidget);
    expect(background(chapter1.walkingBackground), findsOneWidget);
  });

  testWidgets('los carteles se cierran antes tocándolos', (tester) async {
    storage.saved = saveAt(2, 3000, {'flor_lila': 15, 'semilla_fuego': 2});
    await show(tester);
    // Con todo a favor, la tercera semilla de fuego sale a los 200 pasos.
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump();
    expect(find.byType(FoundItemOverlay), findsOneWidget);

    await tester.tap(find.byType(FoundItemOverlay)); // Semillas de agua.
    await tester.pump(FoundItemOverlay.flyDuration);
    await tester.pump(StageBackground.fadeDuration);
    await tester.tap(find.byType(FoundItemOverlay).hitTestable().first);
    await tester.pump(FoundItemOverlay.flyDuration);
    await tester.pump(StageBackground.fadeDuration);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pump();
    await tester.pump(StageBackground.fadeDuration);
    await tester.pumpAndSettle(); // Termina el fundido de salida.
    expect(find.byType(FoundItemOverlay), findsNothing);
    expect(find.byType(StageDoneOverlay), findsNothing);
    expect(find.text(Strings.walkingTo('Bosque Mágico', 'el')), findsOneWidget);
  });

  testWidgets('al terminar el laberinto empieza el tramo hasta el Muelle', (
    tester,
  ) async {
    storage.saved = saveAt(3, 7500, {
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
    expect(engineStage(), 4);
    await closeEverything(tester);
    // La etapa 4 arranca con su tramo: se ve el mapa en el fondo.
    expect(find.text(Strings.walkingTo('Muelle', 'el')), findsOneWidget);
  });

  testWidgets('el botón de debug avanza la etapa y muestra el cartel', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, const {}); // Las flores lilas.
    await show(tester);
    expect(find.text(Strings.stageOf(2, 8)), findsOneWidget);
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(); // Llega el evento y aparece el cartel.
    expect(find.text('1.678'), findsOneWidget);
    expect(find.text(Strings.stageOf(3, 8)), findsOneWidget);
    expect(find.text(Strings.foundMany('Flor lila', 15)), findsOneWidget);
    await closeEverything(tester);
  });

  testWidgets('con el capítulo terminado se ve que el barco zarpó', (
    tester,
  ) async {
    storage.saved = saveAt(8, 0, const {});
    await show(tester);
    expect(find.text(Strings.chapterDoneTitle), findsOneWidget);
    expect(find.text(chapter1.stages.last.completeMessage), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('se ve el fondo de la etapa actual', (tester) async {
    storage.saved = saveAt(3, 2000, const {});
    await show(tester);
    expect(background(chapter1.stages[3].background), findsOneWidget);
    expect(background(chapter1.stages[2].background), findsNothing);
  });

  testWidgets('al pasar de etapa, el fondo cambia con un fundido', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, const {}); // Las flores lilas.
    await show(tester);
    final first = chapter1.stages[1].background;
    // La etapa siguiente empieza con su tramo de caminata: el mapa.
    final second = chapter1.walkingBackground;
    expect(background(first), findsOneWidget);

    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump(StageBackground.fadeDuration ~/ 2);
    // A mitad del fundido se ven los dos.
    expect(background(first), findsOneWidget);
    expect(background(second), findsOneWidget);

    await tester.pump(StageBackground.fadeDuration);
    expect(background(first), findsNothing);
    expect(background(second), findsOneWidget);
    await closeEverything(tester);
  });

  testWidgets('después del final queda el fondo de la última etapa', (
    tester,
  ) async {
    storage.saved = saveAt(8, 0, const {});
    await show(tester);
    expect(background(chapter1.stages.last.background), findsOneWidget);
  });

  testWidgets('al zarpar el barco: la Isla Negra y "Continuará..."', (
    tester,
  ) async {
    storage.saved = saveAt(7, 5000, {
      for (final id in ['madera', 'clavos', 'cuerdas', 'bandera']) id: 1,
    });
    await show(tester);
    // Con todo a favor, el ancla sale a los 100 pasos y el barco zarpa.
    await tapText(tester, Strings.debugAdd(debugStepBonus));
    await tester.pump();
    // Primero, los carteles (monedas y el ancla).
    for (var i = 0; i < 5; i++) {
      await tester.pump(StageBackground.fadeDuration);
      final found = find.byType(FoundItemOverlay).hitTestable();
      if (found.evaluate().isEmpty) break;
      await tester.tap(found.first);
      await tester.pump(FoundItemOverlay.flyDuration);
    }
    expect(find.byType(StageDoneOverlay), findsOneWidget);
    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();

    expect(find.byType(EndingScreen), findsOneWidget);
    expect(find.text(t.continuara), findsWidgets); // Borde y relleno.
    expect(find.text(t.cierre.first), findsOneWidget);
    await tester.tap(find.text(Strings.backButton));
    await tester.pumpAndSettle();
    expect(find.byType(EndingScreen), findsNothing);

    // Se puede volver a ver desde la tarjeta del final.
    await tapText(tester, Strings.seeEnding);
    await tester.pumpAndSettle();
    expect(find.byType(EndingScreen), findsOneWidget);

    // Y desde el final, los créditos.
    await tester.tap(find.text(Strings.creditsButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreditsScreen), findsOneWidget);
  });

  testWidgets('sin la imagen de la Isla Negra, un fondo oscuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EndingScreen(
          background: 'assets/backgrounds/no_existe.webp',
          onBack: () {},
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.byKey(const ValueKey('ending-fallback')), findsWidgets);
    expect(find.text(t.continuara), findsWidgets); // Borde y relleno.
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

  testWidgets('para juntar: dibujos en gris lo que falta, a color lo que hay', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, {'flor_lila': 7});
    await show(tester);
    expect(isDimmed(tester, 'assets/items/flor_lila.webp'), isFalse);
    expect(find.text(Strings.countOf(7, 15)), findsOneWidget);
    // El personaje de la intro: Caperucita, todavía sin caperuza.
    expect(
      gameImage('assets/characters/caperucita_sin_caperuza.webp'),
      findsOneWidget,
    );
  });

  testWidgets('sin ningún objeto todavía, el dibujo va en gris', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, const {}); // Las flores lilas.
    await show(tester);
    expect(isDimmed(tester, 'assets/items/flor_lila.webp'), isTrue);
  });

  testWidgets('canje: el contador va junto a los dibujos', (tester) async {
    storage.saved = saveAt(2, 3300, {'flor_lila': 15, 'semilla_agua': 4});
    await show(tester);
    expect(gameImage('assets/items/semilla_agua.webp'), findsOneWidget);
    expect(gameImage('assets/items/semilla_hielo.webp'), findsOneWidget);
    expect(find.text(Strings.countOf(4, 10)), findsOneWidget);
    expect(gameImage('assets/characters/rocanon.webp'), findsOneWidget);
  });

  testWidgets('durante la caminata se ve a Caperucita de espaldas', (
    tester,
  ) async {
    storage.saved = saveAt(4, 3200, const {});
    await show(tester);
    final walking = tester.widget<GameImage>(
      gameImage('assets/characters/caperucita_espalda.webp'),
    );
    // Caminando, la animación de Sofía caminando.
    expect(walking.animated, 'assets/characters/sofia_caminando.webp');
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(
      assetImage('assets/characters/sofia_caminando.webp'),
      findsOneWidget,
    );
    // Cargó la animación: el dibujo quieto no hizo falta.
    expect(
      assetImage('assets/characters/caperucita_espalda.webp'),
      findsNothing,
    );
  });

  testWidgets('en los diálogos, los personajes animados se mueven', (
    tester,
  ) async {
    // El nido: el Rocanón en la intro.
    storage.saved = saveAt(2, 3000, {'flor_lila': 15});
    await show(tester);
    final rocanon = tester.widget<GameImage>(
      gameImage('assets/characters/rocanon.webp'),
    );
    expect(rocanon.animated, 'assets/characters/rocanon_animado.webp');
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.byKey(const ValueKey('animated-art')), findsOneWidget);
    // Cargó la animación: el dibujo quieto no hizo falta.
    expect(assetImage('assets/characters/rocanon.webp'), findsNothing);
  });

  testWidgets('el objeto vuela a la bolsa y suma al número de nuevos', (
    tester,
  ) async {
    storage.saved = saveAt(1, 0, const {}); // Las flores lilas.
    await show(tester);
    controller.addDebugSteps(50); // Sale una flor lila.
    await tester.pump();
    await tester.pump();
    final bag = find.byType(BagButton);
    // Mientras está el cartel, todavía no cuenta.
    expect(tester.widget<BagButton>(bag).unseen, 0);
    await letItemFly(tester);
    expect(tester.widget<BagButton>(bag).unseen, 1);
    expect(find.descendant(of: bag, matching: find.text('1')), findsOneWidget);
  });

  testWidgets('la bolsa muestra lo conseguido y las recompensas', (
    tester,
  ) async {
    storage.saved = GameSave(
      steps: savedSteps,
      chapter: const ChapterProgress(
        stageIndex: 3,
        stepsInStage: 0,
        inventory: {'flor_lila': 15, 'semilla_fuego': 3, 'semilla_agua': 2},
        sinceLast: {},
        found: {'flor_lila': 15, 'semilla_fuego': 3, 'semilla_agua': 22},
        unseen: 4,
      ),
    );
    await show(tester);
    expect(tester.widget<BagButton>(find.byType(BagButton)).unseen, 4);

    await tester.tap(find.byType(BagButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.bagTitle), findsOneWidget);
    expect(controller.game.chapter.unseen, 0);
    // Lo conseguido en total, aunque se haya canjeado.
    expect(find.text('Semilla de agua'), findsOneWidget);
    expect(find.text(Strings.times(22)), findsOneWidget);
    expect(find.text('Caperuza de aprendiz'), findsOneWidget);
    expect(find.text('Pluma del Rocanón'), findsOneWidget);

    // Al tocar un objeto: para qué sirve y dónde se consigue.
    await tester.tap(find.text('Semilla de agua'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        Strings.tradedFor(10, 'una semilla de fuego', 'Semilla de hielo'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(Strings.foundIn(3, 'El nido del Rocanón')),
      findsOneWidget,
    );
    await tester.tap(find.text(Strings.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pluma del Rocanón'));
    await tester.pumpAndSettle();
    expect(
      find.text(Strings.rewardOf(3, 'El nido del Rocanón')),
      findsOneWidget,
    );
  });

  testWidgets('la bolsa vacía lo dice', (tester) async {
    await show(tester);
    await tester.tap(find.byType(BagButton));
    await tester.pumpAndSettle();
    expect(find.text(Strings.bagEmpty), findsOneWidget);
    expect(find.text(Strings.noRewardsYet), findsOneWidget);
  });

  testWidgets('si falta un dibujo, se ve un ícono genérico', (tester) async {
    // En el laberinto faltan la salida a la costa, el ramo y la pluma.
    storage.saved = saveAt(3, 2000, const {});
    await show(tester);
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.byKey(const ValueKey('missing-art')), findsNWidgets(3));
  });

  testWidgets('si falta el dibujo de un personaje, se ve una persona', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameImage.character('assets/characters/no_existe.webp', size: 80),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Durations.long2));
    await tester.pump();
    expect(find.byIcon(Icons.face), findsOneWidget);
  });

  testWidgets('el jardín: flores amarillas y después la escena del Hada', (
    tester,
  ) async {
    await show(tester);
    expect(find.text(Strings.stageOf(1, 8)), findsOneWidget);
    expect(find.text('Flor amarilla'), findsOneWidget);
    expect(find.text(Strings.stepsToNext(100)), findsOneWidget);
    expect(
      gameImage('assets/characters/caperucita_sin_caperuza.webp'),
      findsOneWidget,
    );

    controller.addDebugSteps(1500); // La flor 15 sale a los 1.500.
    await tester.pump();
    expect(find.text(Strings.foundMany('Flor amarilla', 15)), findsOneWidget);
    await letItemFly(tester);
    await tester.pump(StageBackground.fadeDuration);
    expect(find.byType(StageDoneOverlay), findsOneWidget);
    expect(gameImage('assets/characters/hada_madrina.webp'), findsOneWidget);
    expect(find.text(chapter1.stages[0].completeMessage), findsOneWidget);

    await tester.tap(find.text(Strings.continueButton));
    await tester.pumpAndSettle();
    // Mismo lugar (la Aldea): no hay tramo de caminata.
    expect(
      find.text(Strings.walkingTo('Campo de Caperucitas', 'el')),
      findsNothing,
    );
    expect(find.text(Strings.stageOf(2, 8)), findsOneWidget);
  });
}
