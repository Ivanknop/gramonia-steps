import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/clock.dart';
import '../logic/step_state.dart';
import '../logic/step_tracker.dart';
import '../services/step_sensor.dart';
import '../services/step_storage.dart';

enum StepStatus {
  loading,
  needsPermission,
  permissionBlocked,
  noSensor,
  tracking,
}

/// Une el sensor, la lógica de pasos y el guardado. La pantalla lo escucha.
class StepController extends ChangeNotifier {
  StepController({
    required this.sensor,
    required this.storage,
    this.clock = const SystemClock(),
    this.tracker = const StepTracker(),
    this.saveDelay = const Duration(seconds: 1),
    this.dayCheckInterval = const Duration(minutes: 1),
  });

  final StepSensor sensor;
  final StepStorage storage;
  final Clock clock;
  final StepTracker tracker;

  /// Como mucho se guarda una vez por [saveDelay], para no escribir en cada paso.
  final Duration saveDelay;
  final Duration dayCheckInterval;

  StepState _state = const StepState.initial();
  StepState get state => _state;

  StepStatus _status = StepStatus.loading;
  StepStatus get status => _status;

  StreamSubscription<int>? _subscription;
  Timer? _saveTimer;
  Timer? _dayTimer;
  bool _disposed = false;

  Future<void> start() async {
    final loaded = await storage.load();
    if (_disposed) return;
    _update(tracker.refreshDay(loaded, clock.now()));
    await _flush();
    _dayTimer = Timer.periodic(dayCheckInterval, (_) => refreshDay());
    await _applyPermission(await sensor.requestPermission());
  }

  /// Botón "Dar permiso" / "Abrir ajustes".
  Future<void> askPermission() async {
    if (_status == StepStatus.permissionBlocked) {
      await sensor.openSettings();
      return; // Se vuelve a revisar al volver a la app (onResume).
    }
    await _applyPermission(await sensor.requestPermission());
  }

  /// Al volver a la app: revisar el permiso y el día.
  Future<void> onResume() async {
    refreshDay();
    if (_status == StepStatus.tracking || _status == StepStatus.noSensor) {
      return;
    }
    await _applyPermission(await sensor.checkPermission());
  }

  /// Al salir de la app: guardar lo pendiente.
  Future<void> onPause() => _flush();

  void refreshDay() {
    final next = tracker.refreshDay(_state, clock.now());
    if (next != _state) {
      _update(next);
      _scheduleSave();
    }
  }

  Future<void> addDebugSteps(int steps) async {
    _update(tracker.addDebugSteps(_state, steps, clock.now()));
    await _flush();
  }

  Future<void> _applyPermission(SensorPermission permission) async {
    if (_disposed) return;
    switch (permission) {
      case SensorPermission.granted:
        _listen();
      case SensorPermission.denied:
        _setStatus(StepStatus.needsPermission);
      case SensorPermission.permanentlyDenied:
        _setStatus(StepStatus.permissionBlocked);
    }
  }

  void _listen() {
    if (_subscription != null) return;
    _setStatus(StepStatus.tracking);
    _subscription = sensor.readings().listen(
      _onReading,
      onError: (Object error) {
        _log('error del sensor: $error');
        _subscription?.cancel();
        _subscription = null;
        _setStatus(StepStatus.noSensor);
      },
    );
  }

  void _onReading(int reading) {
    final next = tracker.applyReading(_state, reading, clock.now());
    _log(
      'lectura=$reading total=${next.totalSteps} hoy=${next.todaySteps} '
      '(antes: lectura=${_state.lastReading})',
    );
    _update(next);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer ??= Timer(saveDelay, _flush);
  }

  Future<void> _flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await storage.save(_state);
  }

  void _update(StepState next) {
    if (_disposed || next == _state) return;
    _state = next;
    notifyListeners();
  }

  void _setStatus(StepStatus next) {
    if (_disposed || next == _status) return;
    _status = next;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[pasos] $message');
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _dayTimer?.cancel();
    if (_saveTimer != null) {
      _saveTimer!.cancel();
      storage.save(_state);
    }
    super.dispose();
  }
}
