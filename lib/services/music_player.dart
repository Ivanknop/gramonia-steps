import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que hace falta para tocar música. En los tests se reemplaza.
abstract interface class MusicPlayer {
  /// Empieza [asset] en loop, con un fundido cruzado desde lo que sonaba.
  Future<void> play(String asset, {required Duration fade});

  /// Baja el volumen hasta 0 y para.
  Future<void> fadeOut({required Duration fade});

  /// Pausa sin perder el lugar (al pasar a segundo plano).
  Future<void> pause();

  /// Sigue desde donde estaba.
  Future<void> resume();

  Future<void> dispose();
}

/// Si el celular está en modo silencio. En modo vibración, no.
abstract interface class SilentMode {
  Future<bool> isSilent();
}

/// Dónde se guarda si la música está silenciada.
abstract interface class MusicPrefs {
  Future<bool> loadMuted();
  Future<void> saveMuted(bool muted);
}

/// Música con just_audio. Dos reproductores: uno se apaga mientras el otro
/// sube, para el fundido cruzado. Sin servicio en segundo plano: nunca suena
/// con la app cerrada.
class JustAudioMusicPlayer implements MusicPlayer {
  JustAudioMusicPlayer({required this.volume});

  /// Volumen máximo (0 a 1).
  final double volume;

  AudioPlayer? _current;
  final _fading = <AudioPlayer>{};
  bool _sessionReady = false;

  static const _step = Duration(milliseconds: 50);

  Future<void> _session() async {
    if (_sessionReady) return;
    _sessionReady = true;
    // Música: se pausa sola en una llamada o si otra app reproduce sonido.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Future<void> play(String asset, {required Duration fade}) async {
    await _session();
    final old = _current;
    final next = AudioPlayer();
    _current = next;
    await next.setLoopMode(LoopMode.one);
    await next.setAsset(asset);
    await next.setVolume(0);
    unawaited(next.play());
    if (old != null) unawaited(_rampAndStop(old, fade));
    // Sube mientras siga siendo el tema actual.
    await _ramp(next, 0, volume, fade, alive: () => _current == next);
  }

  @override
  Future<void> fadeOut({required Duration fade}) async {
    final old = _current;
    _current = null;
    if (old != null) await _rampAndStop(old, fade);
  }

  @override
  Future<void> pause() async {
    await _current?.pause();
    for (final p in [..._fading]) {
      await p.stop();
      await p.dispose();
    }
    _fading.clear();
  }

  @override
  Future<void> resume() async {
    final current = _current;
    if (current == null) return;
    await current.setVolume(volume);
    unawaited(current.play());
  }

  @override
  Future<void> dispose() async {
    await _current?.dispose();
    for (final p in _fading) {
      await p.dispose();
    }
  }

  Future<void> _rampAndStop(AudioPlayer player, Duration fade) async {
    _fading.add(player);
    await _ramp(
      player,
      player.volume,
      0,
      fade,
      alive: () => _fading.contains(player),
    );
    if (_fading.remove(player)) {
      await player.stop();
      await player.dispose();
    }
  }

  Future<void> _ramp(
    AudioPlayer player,
    double from,
    double to,
    Duration fade, {
    required bool Function() alive,
  }) async {
    final steps = (fade.inMilliseconds / _step.inMilliseconds).ceil();
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(_step);
      if (!alive()) return;
      await player.setVolume(from + (to - from) * i / steps);
    }
  }
}

/// Pregunta a Android si el celular está en silencio (MainActivity.kt).
class DeviceSilentMode implements SilentMode {
  const DeviceSilentMode();

  static const _channel = MethodChannel('gramonia/sonido');

  @override
  Future<bool> isSilent() async {
    try {
      return await _channel.invokeMethod<bool>('enSilencio') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

class PrefsMusicPrefs implements MusicPrefs {
  const PrefsMusicPrefs();

  static const key = 'music_muted';

  @override
  Future<bool> loadMuted() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<void> saveMuted(bool muted) async =>
      (await SharedPreferences.getInstance()).setBool(key, muted);
}
