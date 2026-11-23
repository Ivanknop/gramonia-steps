import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/app.dart';
import 'package:rpg/data/textos.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/ui/step_controller.dart';
import 'package:rpg/ui/story_screens.dart';
import 'package:rpg/data/textos.dart' as t;
import 'package:rpg/ui/dialogue.dart';
import 'package:rpg/ui/presentation_screen.dart';
import 'package:rpg/ui/title_screen.dart';

import 'fakes/fakes.dart';

void main() {
  testWidgets('portada, presentación con el nombre y después el juego', (
    tester,
  ) async {
    final sensor = FakeSensor();
    final storage = FakeStorage();
    final controller = StepController(
      sensor: sensor,
      storage: storage,
      saveDelay: Duration.zero,
    );
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.text(Strings.titleLogo), findsWidgets);
    expect(find.text(Strings.titleSubtitle), findsOneWidget);
    expect(find.text(Strings.startButton), findsOneWidget);

    await tester.tap(find.text(Strings.startButton));
    await tester.pumpAndSettle();
    expect(find.byType(TitleScreen), findsNothing);

    // Sofía se presenta: se toca para ver cada globo.
    expect(find.byType(PresentationScreen), findsOneWidget);
    expect(find.text(t.presentacion.first.texto), findsOneWidget);
    for (var i = 1; i < t.presentacion.length; i++) {
      await tester.tap(find.byType(DialogueView));
      await tester.pumpAndSettle();
    }
    expect(find.text(t.presentacion.last.texto), findsOneWidget);

    // Sin nombre no se puede seguir; con espacios de más, se limpian.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '  Regi  ');
    await tester.pump();
    await tester.tap(find.text(Strings.nameButton));
    await tester.pumpAndSettle();
    expect(controller.playerName, 'Regi');
    expect(storage.saved.playerName, 'Regi');
    expect(find.text('¡Qué lindo nombre, Regi!'), findsOneWidget);

    await tester.tap(find.text(Strings.dialogueNext));
    await tester.pumpAndSettle();
    expect(find.byType(PresentationScreen), findsNothing);

    // Introducción: Mututu despierta y Sofía pide ayuda por el nombre.
    expect(find.byType(IntroScreen), findsOneWidget);
    for (var i = 1; i < t.introduccion.length; i++) {
      await tester.tap(find.byType(DialogueView));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('Regi, ¿me ayudás? Cada paso que des, lo damos juntos.'),
      findsOneWidget,
    );
    await tester.tap(find.text(Strings.introButton));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsNothing);
    expect(controller.game.introSeen, isTrue);
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

  testWidgets('con nombre e intro vista, "Seguir caminando" va al juego', (
    tester,
  ) async {
    final storage = FakeStorage();
    storage.saved = storage.saved.copyWith(playerName: 'Regi', introSeen: true);
    final controller = StepController(sensor: FakeSensor(), storage: storage);
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text(Strings.resumeButton));
    await tester.pumpAndSettle();
    expect(find.byType(PresentationScreen), findsNothing);
    expect(find.text(Strings.todayLabel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con nombre pero sin la intro vista, se ve la intro', (
    tester,
  ) async {
    final storage = FakeStorage();
    storage.saved = storage.saved.copyWith(playerName: 'Regi');
    final controller = StepController(sensor: FakeSensor(), storage: storage);
    await tester.pumpWidget(GramoniaApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text(Strings.resumeButton));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
