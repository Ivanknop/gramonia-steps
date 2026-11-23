import 'dart:math';

import '../data/chapter1.dart' as data;
import 'clock.dart';
import 'step_state.dart';

/// Reglas para convertir lecturas del sensor en pasos de hoy y total.
class StepTracker {
  const StepTracker({this.maxStepsPerDay = data.maxStepsPerDay});

  /// Tope de pasos por día transcurrido desde la última lectura.
  final int maxStepsPerDay;

  /// Cuántos pasos puede traer de golpe una lectura que llega en [now]:
  /// [maxStepsPerDay] por cada día desde la lectura anterior (como mínimo,
  /// un día). En las partidas de antes no se sabe la hora de la última
  /// lectura: se cuenta desde el comienzo del día de los pasos guardados.
  int maxStepsFor(StepState state, DateTime now) {
    final since = state.lastReadingAt ?? _dayStart(state.todayDate);
    if (since == null) return maxStepsPerDay;
    final days = now.difference(since).inMinutes / Duration.minutesPerDay;
    return (maxStepsPerDay * max(1.0, days)).ceil();
  }

  static DateTime? _dayStart(String date) => DateTime.tryParse(date);

  /// Aplica una lectura de TYPE_STEP_COUNTER (pasos desde el último reinicio).
  StepState applyReading(StepState state, int reading, DateTime now) {
    // El tope se calcula con el estado de antes de cambiar de día.
    final limit = maxStepsFor(state, now);
    final current = refreshDay(state, now).copyWith(lastReadingAt: now);
    final last = current.lastReading;

    final int delta;
    if (last == null) {
      delta = 0; // Primera lectura: solo es la base.
    } else if (reading >= last) {
      delta = reading - last;
    } else {
      delta = reading; // El celular se reinició: el sensor volvió a cero.
    }

    if (delta > limit) {
      // Lectura absurda: no se suma, solo se toma como base nueva.
      return current.copyWith(lastReading: reading);
    }

    return current.copyWith(
      lastReading: reading,
      totalSteps: current.totalSteps + delta,
      todaySteps: current.todaySteps + delta,
    );
  }

  /// Suma pasos a mano (botón de debug). No toca la lectura del sensor.
  StepState addDebugSteps(StepState state, int steps, DateTime now) {
    final current = refreshDay(state, now);
    return current.copyWith(
      totalSteps: current.totalSteps + steps,
      todaySteps: current.todaySteps + steps,
    );
  }

  /// Si cambió el día, pone en cero los pasos de hoy. El total no cambia.
  StepState refreshDay(StepState state, DateTime now) {
    final today = dateKey(now);
    if (state.todayDate == today) return state;
    return state.copyWith(todaySteps: 0, todayDate: today);
  }
}
