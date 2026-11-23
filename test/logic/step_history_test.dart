import 'package:rpg/logic/step_history.dart';
import 'package:test/test.dart';

void main() {
  final today = DateTime(2026, 11, 23, 18); // lunes

  test('semana: los últimos 7 días terminando hoy, con 0 si no hay datos', () {
    final h = StepHistory({
      '2026-11-23': 500,
      '2026-11-17': 100,
      '2026-11-16': 9,
    });
    final week = h.week(today);
    expect(week.length, 7);
    expect(week.first, StepBar(DateTime(2026, 11, 17), 100));
    expect(week.last, StepBar(DateTime(2026, 11, 23), 500));
    expect(week[3].steps, 0);
  });

  test('semana que cruza el cambio de mes', () {
    final h = StepHistory({'2026-10-30': 7, '2026-11-02': 8});
    final week = h.week(DateTime(2026, 11, 2));
    expect(week.first.start, DateTime(2026, 10, 27));
    expect(week.map((b) => b.steps), [0, 0, 0, 7, 0, 0, 8]);
  });

  test('mes por semanas: 1–7, 8–14, 15–21 y del 22 a fin de mes', () {
    final h = StepHistory({
      '2026-11-01': 1,
      '2026-11-07': 2,
      '2026-11-08': 10,
      '2026-11-21': 100,
      '2026-11-22': 1000,
      '2026-11-30': 2000,
      '2026-10-31': 99999, // otro mes
      '2026-12-01': 99999,
    });
    final weeks = h.monthByWeeks(today);
    expect(weeks.map((b) => b.start.day), [1, 8, 15, 22]);
    expect(weeks.map((b) => b.steps), [3, 10, 100, 3000]);
  });

  test('meses: los últimos 6, cruzando el año', () {
    final h = StepHistory({
      '2026-01-15': 5,
      '2026-01-31': 5,
      '2025-12-01': 3,
      '2025-08-31': 99, // ya quedó afuera
    });
    final months = h.months(DateTime(2026, 2, 10));
    expect(months.map((b) => b.start), [
      DateTime(2025, 9),
      DateTime(2025, 10),
      DateTime(2025, 11),
      DateTime(2025, 12),
      DateTime(2026, 1),
      DateTime(2026, 2),
    ]);
    expect(months.map((b) => b.steps), [0, 0, 0, 3, 10, 0]);
  });

  test('set reemplaza los pasos del día', () {
    final h = StepHistory()..set('2026-11-23', 10);
    h.set('2026-11-23', 40);
    expect(h.stepsOn(today), 40);
  });
}
