import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/chapter1.dart';
import '../logic/chapter_engine.dart';
import '../logic/clock.dart';
import '../logic/game_save.dart';
import '../logic/step_state.dart';
import '../logic/step_tracker.dart';
import '../services/step_sensor.dart';
import '../services/game_storage.dart';

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
    this.engine = const ChapterEngine(chapter1),
    Random? random,
    this.saveDelay = const Duration(seconds: 1),
    this.dayCheckInterval = const Duration(minutes: 1),
  }) : random = random ?? Random();

  final StepSensor sensor;
  final GameStorage storage;
  final Clock clock;
  final StepTracker tracker;
  final ChapterEngine engine;

  /// Azar para la aparición de objetos (en los tests, con semilla fija).
  final Random random;

  /// Como mucho se guarda una vez por [saveDelay], para no escribir en cada paso.
  final Duration saveDelay;
  final Duration dayCheckInterval;

  GameSave _game = const GameSave.initial();
  GameSave get game => _game;
  StepState get state => _game.steps;

  final _events = StreamController<List<ChapterEvent>>.broadcast();

  /// Objetos conseguidos y etapas terminadas, agrupados por cada avance.
  Stream<List<ChapterEvent>> get events => _events.stream;

  StepStatus _status = StepStatus.loading;
  StepStatus get status => _status;

  StreamSubscription<int>? _subscription;
  Timer? _saveTimer;
  Timer? _dayTimer;
  bool _disposed = false;

  Future<void> start() async {
    final loaded = await storage.load();
    if (_disposed) return;
    _game = loaded;
    _update(tracker.refreshDay(loaded.steps, clock.now()));
    notifyListeners();
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
    final next = tracker.refreshDay(state, clock.now());
    if (next != state) {
      _update(next);
      _scheduleSave();
    }
  }

  Future<void> addDebugSteps(int steps) async {
    _update(tracker.addDebugSteps(state, steps, clock.now()));
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
    final next = tracker.applyReading(state, reading, clock.now());
    _log(
      'lectura=$reading total=${next.totalSteps} hoy=${next.todaySteps} '
      '(antes: lectura=${state.lastReading})',
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
    await storage.save(_game);
  }

  void _update(StepState next) {
    if (_disposed || next == state) return;
    // Los pasos nuevos (reales o de debug) avanzan el capítulo.
    final delta = next.totalSteps - state.totalSteps;
    final advance = engine.advance(_game.chapter, delta, random);
    _game = GameSave(steps: next, chapter: advance.progress);
    if (advance.events.isNotEmpty) {
      _log('eventos: ${advance.events.length}');
      _events.add(advance.events);
    }
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
    _events.close();
    if (_saveTimer != null) {
      _saveTimer!.cancel();
      storage.save(_game);
    }
    super.dispose();
  }
}
