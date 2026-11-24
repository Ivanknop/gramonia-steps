import 'dart:async';

import 'package:rpg/logic/clock.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/notification_summary.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/music_player.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/services/game_storage.dart';
import 'package:rpg/services/system_notifier.dart';

class FakeClock implements Clock {
  FakeClock(this.time);
  DateTime time;

  @override
  DateTime now() => time;
}

class FakeStorage implements GameStorage {
  FakeStorage([StepState steps = const StepState.initial()])
    : saved = GameSave(steps: steps, chapter: const GameSave.initial().chapter);
  GameSave saved;
  int saveCount = 0;

  @override
  Future<GameSave> load() async => saved;

  @override
  Future<void> save(GameSave game) async {
    saved = game;
    saveCount++;
  }
}

class FakeSensor implements StepSensor {
  FakeSensor({this.permission = SensorPermission.granted});

  SensorPermission permission;

  /// Lo que devuelve el pedido de permiso; si es nulo, devuelve [permission].
  SensorPermission? answerToRequest;
  int requestCount = 0;
  int settingsCount = 0;
  final controller = StreamController<int>.broadcast();

  void emit(int reading) => controller.add(reading);
  void fail(Object error) => controller.addError(error);

  @override
  Future<SensorPermission> checkPermission() async => permission;

  @override
  Future<SensorPermission> requestPermission() async {
    requestCount++;
    if (answerToRequest != null) permission = answerToRequest!;
    return permission;
  }

  @override
  Future<void> openSettings() async => settingsCount++;

  @override
  Stream<int> readings() => controller.stream;
}

class FakeMusicPlayer implements MusicPlayer {
  /// Lo que se le pidió, en orden: `play:asset`, "fadeOut", "pause"...
  final calls = <String>[];

  @override
  Future<void> play(String asset, {required Duration fade}) async =>
      calls.add('play:$asset');

  @override
  Future<void> fadeOut({required Duration fade}) async => calls.add('fadeOut');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> dispose() async {}
}

class FakeSilentMode implements SilentMode {
  bool silent = false;

  @override
  Future<bool> isSilent() async => silent;
}

class FakeMusicPrefs implements MusicPrefs {
  bool muted = false;

  @override
  Future<bool> loadMuted() async => muted;

  @override
  Future<void> saveMuted(bool muted) async => this.muted = muted;
}

class FakeNotifier implements SystemNotifier {
  bool grant = true;
  int permissionRequests = 0;
  int cancels = 0;
  int settings = 0;
  final shown = <GameNotification>[];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> show(GameNotification notification) async =>
      shown.add(notification);

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> openSettings() async => settings++;
}

class FakeNotificationPrefs implements NotificationPrefs {
  bool enabled = false;

  @override
  Future<bool> loadEnabled() async => enabled;

  @override
  Future<void> saveEnabled(bool enabled) async => this.enabled = enabled;
}
