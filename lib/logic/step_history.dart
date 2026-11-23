import 'clock.dart';

/// Una barra del gráfico de "Mis pasos": desde qué día empieza y cuántos
/// pasos suma.
class StepBar {
  const StepBar(this.start, this.steps);

  /// Primer día que cuenta la barra (un día, una semana del mes o un mes).
  final DateTime start;
  final int steps;

  @override
  bool operator ==(Object other) =>
      other is StepBar && other.start == start && other.steps == steps;

  @override
  int get hashCode => Object.hash(start, steps);

  @override
  String toString() => 'StepBar(${dateKey(start)}: $steps)';
}

/// Pasos de cada día (fecha aaaa-mm-dd → pasos). Arranca en la versión
/// 1.0.0 del historial: los días anteriores no se conocen y cuentan como 0.
class StepHistory {
  StepHistory([Map<String, int> days = const {}]) : _days = {...days};

  final Map<String, int> _days;

  Map<String, int> get days => Map.unmodifiable(_days);

  int stepsOn(DateTime day) => _days[dateKey(day)] ?? 0;

  /// Guarda los pasos de un día (reemplaza lo que había).
  void set(String date, int steps) => _days[date] = steps;

  /// Los últimos 7 días, terminando hoy.
  List<StepBar> week(DateTime today) {
    final end = _day(today);
    return [
      for (var i = 6; i >= 0; i--)
        StepBar(_addDays(end, -i), stepsOn(_addDays(end, -i))),
    ];
  }

  /// El mes de [today] en 4 semanas: días 1–7, 8–14, 15–21 y del 22 al
  /// último día del mes.
  List<StepBar> monthByWeeks(DateTime today) {
    final first = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    return [
      for (var week = 0; week < weeksPerMonth; week++)
        StepBar(
          DateTime(today.year, today.month, 1 + week * 7),
          _sum(
            first,
            from: 1 + week * 7,
            to: week == weeksPerMonth - 1 ? daysInMonth : (week + 1) * 7,
          ),
        ),
    ];
  }

  /// Los últimos [count] meses, terminando en el de [today].
  List<StepBar> months(DateTime today, {int count = monthsShown}) => [
    for (var i = count - 1; i >= 0; i--)
      _month(DateTime(today.year, today.month - i)),
  ];

  static const weeksPerMonth = 4;
  static const monthsShown = 6;

  StepBar _month(DateTime first) {
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    return StepBar(first, _sum(first, from: 1, to: daysInMonth));
  }

  /// Suma de los días [from] a [to] (incluidos) del mes de [first].
  int _sum(DateTime first, {required int from, required int to}) {
    var total = 0;
    for (var d = from; d <= to; d++) {
      total += stepsOn(DateTime(first.year, first.month, d));
    }
    return total;
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  // Con el constructor (y no con Duration) para no fallar en los cambios de
  // horario de verano.
  static DateTime _addDays(DateTime day, int n) =>
      DateTime(day.year, day.month, day.day + n);
}
