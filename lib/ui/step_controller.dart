import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/chapter1.dart';
import '../logic/chapter_engine.dart';
import '../logic/clock.dart';
import '../logic/game_save.dart';
import '../logic/shop.dart';
import '../logic/story.dart';
import '../logic/wallet.dart';
import '../logic/step_history.dart';
import '../logic/step_state.dart';
import '../logic/step_tracker.dart';
import '../services/step_sensor.dart';
import '../services/game_storage.dart';
import '../services/step_history_storage.dart';

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
    StepHistoryStorage? historyStorage,
    this.clock = const SystemClock(),
    this.tracker = const StepTracker(),
    this.engine = const ChapterEngine(chapter1),
    Random? random,
    this.saveDelay = const Duration(seconds: 1),
    this.dayCheckInterval = const Duration(minutes: 1),
    this.dailyBonus = dailyBonusCoins,
    ShopPrices prices = shopPrices,
  }) : random = random ?? Random(),
       historyStorage = historyStorage ?? MemoryStepHistoryStorage(),
       shop = Shop(engine, prices);

  final StepSensor sensor;
  final GameStorage storage;

  /// Pasos de cada día, para "Mis pasos".
  final StepHistoryStorage historyStorage;
  final Clock clock;
  final StepTracker tracker;
  final ChapterEngine engine;

  /// Azar para la aparición de objetos (en los tests, con semilla fija).
  final Random random;

  /// Monedas del bono del día.
  final CoinRange dailyBonus;

  /// Tienda del Lobo.
  final Shop shop;

  /// Como mucho se guarda una vez por [saveDelay], para no escribir en cada paso.
  final Duration saveDelay;
  final Duration dayCheckInterval;

  GameSave _game = const GameSave.initial();
  GameSave get game => _game;
  StepState get state => _game.steps;

  /// Monedas que hay para gastar.
  int get coins => _game.wallet.coins;

  /// Avisos de monedas que todavía no se mostraron.
  List<CoinNotice> get coinNotices => _game.wallet.notices;

  StepHistory _history = StepHistory();

  /// Pasos de cada día (incluido hoy).
  StepHistory get history => _history;

  /// Días del historial que cambiaron y todavía no se guardaron.
  final _unsavedDays = <String>{};

  final _events = StreamController<List<ChapterEvent>>.broadcast();

  /// Objetos conseguidos y etapas terminadas, agrupados por cada avance.
  Stream<List<ChapterEvent>> get events => _events.stream;

  bool _loaded = false;

  /// Ya se leyó la partida guardada.
  bool get loaded => _loaded;

  /// Ya se empezó a jugar (para "Seguir caminando" en la portada).
  bool get hasStarted => _game.playerName != null || _game.steps.totalSteps > 0;

  /// Nombre de quien juega, o null si todavía no lo escribió.
  String? get playerName => _game.playerName;

  /// Guarda el nombre que se escribió en la presentación.
  void setPlayerName(String name) {
    if (_disposed) return;
    _game = _game.copyWith(playerName: name);
    notifyListeners();
    _scheduleSave();
  }

  /// Chico, chica o "prefiero no decir"; null si todavía no se preguntó.
  Genero? get genero => _game.genero;

  void setGenero(Genero genero) {
    if (_disposed) return;
    _game = _game.copyWith(genero: genero);
    notifyListeners();
    _scheduleSave();
  }

  /// Ya se vio la introducción: no se vuelve a mostrar.
  void markIntroSeen() {
    if (_disposed || _game.introSeen) return;
    _game = _game.copyWith(introSeen: true);
    notifyListeners();
    _scheduleSave();
  }

  StepStatus _status = StepStatus.loading;
  StepStatus get status => _status;

  StreamSubscription<int>? _subscription;
  Timer? _saveTimer;
  Timer? _dayTimer;
  bool _disposed = false;

  Future<void> start() async {
    final loaded = await storage.load();
    final days = await _loadHistory();
    if (_disposed) return;
    _game = loaded;
    _loaded = true;
    _history = StepHistory(days);
    // Lo que ya estaba guardado del día (por ejemplo, de antes de que
    // existiera el historial) pasa al historial.
    _record(loaded.steps);
    _update(tracker.refreshDay(loaded.steps, clock.now()));
    _claimDailyBonus();
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
    if (_claimDailyBonus()) {
      notifyListeners();
      _scheduleSave();
    }
  }

  /// La primera vez que se abre la app en el día (fecha local), el bono.
  /// Devuelve si se cobró.
  bool _claimDailyBonus() {
    if (_disposed) return false;
    final wallet = _game.wallet.claimDaily(
      dateKey(clock.now()),
      dailyBonus,
      random,
    );
    if (identical(wallet, _game.wallet)) return false;
    _game = _game.copyWith(wallet: wallet);
    return true;
  }

  /// Ya se mostró el aviso de monedas.
  void dismissCoinNotice(CoinNotice notice) {
    if (_disposed) return;
    final wallet = _game.wallet.dismiss(notice);
    if (identical(wallet, _game.wallet)) return;
    _game = _game.copyWith(wallet: wallet);
    notifyListeners();
    _scheduleSave();
  }

  /// Compra un objeto en la Tienda del Lobo. Devuelve lo que pasó, o null si
  /// no se pudo (no se vende o no alcanzan las monedas). Si con la compra se
  /// completa la etapa, los eventos llegan como al caminar.
  Future<Purchase?> buy(String itemId) async {
    if (_disposed) return null;
    final purchase = shop.buy(_game.chapter, coins, itemId, random);
    if (purchase == null) return null;
    _game = _game.copyWith(
      chapter: purchase.progress,
      wallet: _game.wallet.spend(purchase.price),
    );
    if (purchase.events.isNotEmpty) _events.add(purchase.events);
    notifyListeners();
    await _flush(); // Las monedas se guardan enseguida.
    return purchase;
  }

  /// Al abrir la bolsa, el número de objetos nuevos vuelve a 0.
  void markBagSeen() {
    if (_disposed || _game.chapter.unseen == 0) return;
    _game = _game.copyWith(chapter: engine.markSeen(_game.chapter));
    notifyListeners();
    _scheduleSave();
  }

  /// Botón "Entrar" de la pantalla de llegada.
  void enterStage() {
    if (_disposed || !engine.needsEntering(_game.chapter)) return;
    _game = _game.copyWith(chapter: engine.enter(_game.chapter));
    notifyListeners();
    _scheduleSave();
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
    await _saveHistory();
  }

  Future<Map<String, int>> _loadHistory() async {
    try {
      return await historyStorage.load();
    } catch (error) {
      // Sin historial el juego sigue andando.
      _log('no se pudo leer el historial: $error');
      return const {};
    }
  }

  Future<void> _saveHistory() async {
    if (_unsavedDays.isEmpty) return;
    final days = {for (final d in _unsavedDays) d: _history.days[d]!};
    _unsavedDays.clear();
    try {
      await historyStorage.save(days);
    } catch (error) {
      _log('no se pudo guardar el historial: $error');
      _unsavedDays.addAll(days.keys); // Se reintenta en el próximo guardado.
    }
  }

  /// Anota en el historial los pasos del día de [steps].
  void _record(StepState steps) {
    if (steps.todayDate.isEmpty) return;
    if (_history.days[steps.todayDate] == steps.todaySteps) return;
    _history.set(steps.todayDate, steps.todaySteps);
    _unsavedDays.add(steps.todayDate);
  }

  void _update(StepState next) {
    if (_disposed || next == state) return;
    // Los pasos nuevos (reales o de debug) avanzan el capítulo.
    final delta = next.totalSteps - state.totalSteps;
    final advance = engine.advance(_game.chapter, delta, random);
    _game = _game.copyWith(
      steps: next,
      chapter: advance.progress,
      wallet: _game.wallet.add(advance.coins),
    );
    _record(next);
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
    _saveHistory();
    super.dispose();
  }
}
