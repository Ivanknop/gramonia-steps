import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin nada guardado devuelve el estado inicial', () async {
    expect(await PrefsStepStorage().load(), const StepState.initial());
  });

  test('lo que se guarda se vuelve a leer', () async {
    const s = StepState(
      lastReading: 42,
      totalSteps: 9000,
      todaySteps: 1200,
      todayDate: '2026-11-22',
    );
    await PrefsStepStorage().save(s);
    expect(await PrefsStepStorage().load(), s);
  });

  test('un valor guardado roto devuelve el estado inicial', () async {
    SharedPreferences.setMockInitialValues({'step_state_v1': '{roto'});
    expect(await PrefsStepStorage().load(), const StepState.initial());
  });
}
