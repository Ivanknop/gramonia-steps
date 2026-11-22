import '../data/chapter1.dart' as data;
import 'clock.dart';
import 'step_state.dart';

/// Reglas para convertir lecturas del sensor en pasos de hoy y total.
class StepTracker {
  const StepTracker({this.maxStepsPerReading = data.maxStepsPerReading});

  final int maxStepsPerReading;

  /// Aplica una lectura de TYPE_STEP_COUNTER (pasos desde el último reinicio).
  StepState applyReading(StepState state, int reading, DateTime now) {
    final current = refreshDay(state, now);
    final last = current.lastReading;

    final int delta;
    if (last == null) {
      delta = 0; // Primera lectura: solo es la base.
    } else if (reading >= last) {
      delta = reading - last;
    } else {
      delta = reading; // El celular se reinició: el sensor volvió a cero.
    }

    if (delta > maxStepsPerReading) {
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
