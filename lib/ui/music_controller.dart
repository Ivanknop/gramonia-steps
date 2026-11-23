import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chapter1.dart' as data;
import '../logic/music.dart';
import '../services/music_player.dart';
import 'step_controller.dart';

/// Decide qué música suena y cuándo. Las pantallas le cuentan dónde está
/// quien juega; el controlador elige el tema y le pide al reproductor que
/// cambie (con fundido), pause o siga.
///
/// - Si el tema no cambia, no se reinicia.
/// - Silenciada (preferencia guardada) o con el celular en modo silencio,
///   no suena.
/// - En segundo plano (o con la pantalla apagada) se pausa, y sigue al
///   volver.
class MusicController extends ChangeNotifier {
  MusicController({
    required this.player,
    required this.steps,
    this.silentMode = const DeviceSilentMode(),
    this.prefs = const PrefsMusicPrefs(),
    this.assets = data.musicAssets,
    this.fade = data.musicFade,
  });

  final MusicPlayer player;
  final SilentMode silentMode;
  final MusicPrefs prefs;

  /// De ahí sale la etapa actual (y su tema).
  final StepController steps;

  final Map<MusicTrack, String> assets;
  final Duration fade;

  bool _muted = false;

  /// Silenciada por quien juega (se guarda).
  bool get muted => _muted;

  bool _silent = false;
  bool _background = false;
  bool _started = false;

  var _scene = MusicScene.title;
  bool _ending = false;
  int _credits = 0;

  /// Lo que está sonando (o pausado en segundo plano).
  MusicTrack? _playing;
  bool _paused = false;

  /// Lo que está sonando ahora, para los tests.
  MusicTrack? get playing => _paused ? null : _playing;

  Future<void> start() async {
    _muted = await prefs.loadMuted();
    _silent = await silentMode.isSilent();
    _started = true;
    steps.addListener(_apply);
    notifyListeners();
    await _apply();
  }

  /// La pantalla grande que se ve (portada, presentación, intro o juego).
  void setScene(MusicScene scene) {
    if (scene == _scene) return;
    _scene = scene;
    _apply();
  }

  /// Si se ve el cierre ("Continuará...").
  void setEnding(bool ending) {
    if (ending == _ending) return;
    _ending = ending;
    _apply();
  }

  /// Se abrieron los créditos (al cerrarlos, [closeCredits]).
  void openCredits() {
    _credits++;
    _apply();
  }

  void closeCredits() {
    if (_credits > 0) _credits--;
    _apply();
  }

  Future<void> setMuted(bool muted) async {
    if (muted == _muted) return;
    _muted = muted;
    notifyListeners();
    await prefs.saveMuted(muted);
    await _apply();
  }

  Future<void> toggleMuted() => setMuted(!_muted);

  /// La app pasó a segundo plano o se apagó la pantalla.
  Future<void> onPause() async {
    _background = true;
    await _apply();
  }

  /// Se volvió a abrir la app: se revisa de nuevo el modo silencio.
  Future<void> onResume() async {
    _silent = await silentMode.isSilent();
    _background = false;
    await _apply();
  }

  MusicTrack get _wanted => musicFor(
    scene: _scene,
    stageMusic: steps.engine.currentStage(steps.game.chapter)?.music,
    ending: _ending,
    credits: _credits > 0,
  );

  Future<void> _apply() async {
    if (!_started) return;
    if (_background) {
      if (_playing != null && !_paused) {
        _paused = true;
        await player.pause();
      }
      return;
    }
    if (_muted || _silent) {
      if (_playing != null) {
        _playing = null;
        _paused = false;
        await player.fadeOut(fade: fade);
      }
      return;
    }
    final wanted = _wanted;
    if (wanted == _playing) {
      if (_paused) {
        _paused = false;
        await player.resume();
      }
      return;
    }
    _playing = wanted;
    _paused = false;
    await player.play(assets[wanted]!, fade: fade);
  }

  @override
  void dispose() {
    steps.removeListener(_apply);
    unawaited(player.dispose());
    super.dispose();
  }
}
