import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/logic/step_tracker.dart';
import 'package:test/test.dart';

void main() {
  const tracker = StepTracker();
  final day1 = DateTime(2026, 11, 22, 10);
  final day1Later = DateTime(2026, 11, 22, 23, 59);
  final day2 = DateTime(2026, 11, 23, 0, 1);

  StepState started(int reading) =>
      tracker.applyReading(const StepState.initial(), reading, day1);

  test('la primera lectura da 0 pasos y queda como base', () {
    final s = started(12345);
    expect(s.lastReading, 12345);
    expect(s.totalSteps, 0);
    expect(s.todaySteps, 0);
    expect(s.todayDate, '2026-11-22');
  });

  test('las lecturas que suben suman la diferencia', () {
    var s = started(100);
    s = tracker.applyReading(s, 150, day1);
    s = tracker.applyReading(s, 400, day1Later);
    expect(s.totalSteps, 300);
    expect(s.todaySteps, 300);
    expect(s.lastReading, 400);
  });

  test('una lectura igual a la anterior no cambia nada', () {
    final s = tracker.applyReading(started(100), 150, day1);
    expect(tracker.applyReading(s, 150, day1), s);
  });

  test('una lectura menor (reinicio) suma la lectura completa', () {
    var s = tracker.applyReading(started(5000), 5200, day1);
    s = tracker.applyReading(s, 30, day1);
    expect(s.totalSteps, 230);
    expect(s.todaySteps, 230);
    expect(s.lastReading, 30);
  });

  test('el cambio de día pone hoy en 0 y no toca el total', () {
    var s = tracker.applyReading(started(100), 600, day1);
    s = tracker.applyReading(s, 650, day2);
    expect(s.todayDate, '2026-11-23');
    expect(s.todaySteps, 50);
    expect(s.totalSteps, 550);
  });

  test('cambio de día y reinicio a la vez', () {
    var s = tracker.applyReading(started(1000), 1800, day1);
    s = tracker.applyReading(s, 70, day2);
    expect(s.todaySteps, 70);
    expect(s.totalSteps, 870);
    expect(s.lastReading, 70);
  });

  test('una lectura absurda no suma pasos y queda como base nueva', () {
    var s = tracker.applyReading(started(100), 200, day1);
    s = tracker.applyReading(s, 200 + maxStepsPerReading + 1, day1);
    expect(s.totalSteps, 100);
    expect(s.todaySteps, 100);
    expect(s.lastReading, 200 + maxStepsPerReading + 1);
    // La siguiente lectura normal se cuenta desde la base nueva.
    s = tracker.applyReading(s, 200 + maxStepsPerReading + 11, day1);
    expect(s.totalSteps, 110);
  });

  test('justo en el máximo, la lectura sí se suma', () {
    final s = tracker.applyReading(started(0), maxStepsPerReading, day1);
    expect(s.totalSteps, maxStepsPerReading);
  });

  test('un reinicio con lectura absurda tampoco suma', () {
    var s = started(900000);
    s = tracker.applyReading(s, maxStepsPerReading + 1, day1);
    expect(s.totalSteps, 0);
    expect(s.lastReading, maxStepsPerReading + 1);
  });

  test('debug suma a hoy y al total sin tocar la lectura del sensor', () {
    var s = started(100);
    s = tracker.addDebugSteps(s, debugStepBonus, day1);
    expect(s.todaySteps, debugStepBonus);
    expect(s.totalSteps, debugStepBonus);
    expect(s.lastReading, 100);
    s = tracker.applyReading(s, 130, day1);
    expect(s.totalSteps, debugStepBonus + 30);
  });

  test('debug en un día nuevo reinicia hoy primero', () {
    var s = tracker.addDebugSteps(started(0), 500, day1);
    s = tracker.addDebugSteps(s, 1000, day2);
    expect(s.todaySteps, 1000);
    expect(s.totalSteps, 1500);
  });

  test('refreshDay el mismo día no cambia nada', () {
    final s = tracker.applyReading(started(0), 40, day1);
    expect(tracker.refreshDay(s, day1Later), s);
  });

  test('refreshDay al día siguiente pone hoy en 0', () {
    final s = tracker.applyReading(started(0), 40, day1);
    final r = tracker.refreshDay(s, day2);
    expect(r.todaySteps, 0);
    expect(r.totalSteps, 40);
    expect(r.lastReading, 40);
  });
}
