import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logic/chapter_engine.dart';
import '../logic/notification_summary.dart';
import '../services/system_notifier.dart';
import 'step_controller.dart';

/// Notificaciones del celular al conseguir objetos y al pasar de etapa,
/// mientras el juego no está a la vista (en segundo plano o con la pantalla
/// apagada). Con el juego abierto ya están los avisos de adentro.
///
/// Solo llegan si Android sigue entregando los pasos: si cierra la app (por
/// ejemplo, por ahorro de batería), no hay pasos ni notificaciones hasta
/// que se vuelve a abrir.
class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.notifier,
    required this.steps,
    this.prefs = const PrefsNotificationPrefs(),
    this.delay = const Duration(seconds: 15),
  });

  final SystemNotifier notifier;
  final NotificationPrefs prefs;
  final StepController steps;

  /// Se espera esto después del primer evento para juntar los que vienen
  /// de golpe en una sola notificación.
  final Duration delay;

  bool _enabled = false;
  bool get enabled => _enabled;

  var _foreground = true;
  final _summary = NotificationSummary();
  StreamSubscription<List<ChapterEvent>>? _events;
  Timer? _timer;
  bool _disposed = false;

  Future<void> start() async {
    _events = steps.events.listen(_onEvents);
    final enabled = await prefs.loadEnabled();
    if (_disposed) return;
    _enabled = enabled;
    notifyListeners();
  }

  /// Interruptor de "Mis pasos". Al activar se pide el permiso; si se niega,
  /// queda apagado y devuelve false.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await notifier.requestPermission()) return false;
    if (_disposed) return false;
    _enabled = enabled;
    notifyListeners();
    await prefs.saveEnabled(enabled);
    if (!enabled) await _reset();
    return true;
  }

  /// La app pasa a segundo plano (o se apaga la pantalla).
  void onPause() => _foreground = false;

  /// Se volvió al juego: ya se ve todo adentro.
  Future<void> onResume() async {
    _foreground = true;
    await _reset();
  }

  Future<void> _reset() async {
    _timer?.cancel();
    _timer = null;
    final had = !_summary.isEmpty;
    _summary.clear();
    if (had && _enabled) await notifier.cancel();
  }

  void _onEvents(List<ChapterEvent> events) {
    if (!_enabled || _foreground) return;
    _summary.add(events);
    if (_summary.isEmpty) return; // Solo gemas.
    _timer ??= Timer(delay, _post);
  }

  void _post() {
    _timer = null;
    if (!_enabled || _foreground || _summary.isEmpty) return;
    notifier.show(_summary.build());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _events?.cancel();
    super.dispose();
  }
}
