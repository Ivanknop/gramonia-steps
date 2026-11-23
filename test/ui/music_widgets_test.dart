import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rpg/app.dart';
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/data/textos.dart';
import 'package:rpg/logic/music.dart';
import 'package:rpg/ui/home_screen.dart';
import 'package:rpg/ui/music_controller.dart';
import 'package:rpg/ui/my_steps_screen.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late FakeMusicPlayer player;
  late FakeMusicPrefs prefs;
  late StepController steps;
  late MusicController music;

  Future<void> make({bool startSteps = true}) async {
    player = FakeMusicPlayer();
    prefs = FakeMusicPrefs();
    final storage = FakeStorage();
    storage.saved = storage.saved.copyWith(playerName: 'Regi', introSeen: true);
    steps = StepController(sensor: FakeSensor(), storage: storage);
    // La app arranca los pasos por su cuenta.
    if (startSteps) await steps.start();
    music = MusicController(
      player: player,
      steps: steps,
      silentMode: FakeSilentMode(),
      prefs: prefs,
    );
    await music.start();
  }

  testWidgets('el botón de la pantalla del juego silencia y activa', (
    tester,
  ) async {
    await make();
    addTearDown(steps.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(controller: steps, music: music),
      ),
    );
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    await tester.tap(find.byType(MusicButton));
    await tester.pump();
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(prefs.muted, isTrue);
    expect(player.calls.last, 'fadeOut');
    await tester.tap(find.byType(MusicButton));
    await tester.pump();
    expect(prefs.muted, isFalse);
  });

  testWidgets('"Silenciar música" en la pestaña Mis pasos', (tester) async {
    await make();
    addTearDown(steps.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MyStepsScreen(controller: steps, music: music),
      ),
    );
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(prefs.muted, isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('de la portada al juego cambia del tema tierno al de la etapa', (
    tester,
  ) async {
    await make(startSteps: false);
    await tester.pumpWidget(GramoniaApp(controller: steps, music: music));
    await tester.pump();
    expect(music.playing, MusicTrack.intro);
    await tester.tap(find.text(Strings.resumeButton));
    await tester.pumpAndSettle();
    expect(music.playing, MusicTrack.aventura);
    expect(player.calls.last, 'play:${musicAssets[MusicTrack.aventura]}');
    await tester.pumpWidget(const SizedBox());
  });
}
