import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const oldSteps = StepState(
    lastReading: 82018,
    totalSteps: 64,
    todaySteps: 64,
    todayDate: '2026-11-22',
  );

  test('sin nada guardado devuelve la partida inicial', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await PrefsGameStorage().load(), const GameSave.initial());
  });

  test('lo que se guarda se vuelve a leer', () async {
    SharedPreferences.setMockInitialValues({});
    final game = const GameSave.initial().copyWith(steps: oldSteps);
    await PrefsGameStorage().save(game);
    expect(await PrefsGameStorage().load(), game);
  });

  for (final oldKey in [PrefsGameStorage.legacyKey, PrefsGameStorage.v2Key]) {
    test('carga la partida vieja ($oldKey) y la borra al guardar', () async {
      final oldValue = oldKey == PrefsGameStorage.legacyKey
          ? oldSteps.encode()
          : '{"version":2,"steps":${oldSteps.encode()},'
                '"chapter":{"stageIndex":0,"stepsInStage":64,"collected":[]}}';
      SharedPreferences.setMockInitialValues({oldKey: oldValue});
      final storage = PrefsGameStorage();
      final game = await storage.load();
      expect(game.steps, oldSteps);
      expect(game.chapter.stepsInStage, 64);

      await storage.save(game);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(oldKey), isFalse);
      expect(await storage.load(), game);
    });
  }
}
