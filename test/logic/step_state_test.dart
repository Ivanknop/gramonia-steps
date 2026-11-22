import 'package:rpg/logic/step_state.dart';
import 'package:test/test.dart';

void main() {
  test('ida y vuelta por JSON', () {
    const s = StepState(
      lastReading: 777,
      totalSteps: 12000,
      todaySteps: 3400,
      todayDate: '2026-11-22',
    );
    expect(StepState.decode(s.encode()), s);
  });

  test('ida y vuelta sin lectura del sensor', () {
    const s = StepState.initial();
    expect(StepState.decode(s.encode()), s);
  });

  test('nulo, vacío o roto devuelve el estado inicial', () {
    expect(StepState.decode(null), const StepState.initial());
    expect(StepState.decode(''), const StepState.initial());
    expect(StepState.decode('no es json'), const StepState.initial());
    expect(
      StepState.decode('{"totalSteps": "mil"}'),
      const StepState.initial(),
    );
  });
}
