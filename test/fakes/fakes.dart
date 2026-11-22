import 'dart:async';

import 'package:rpg/logic/clock.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/services/game_storage.dart';

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
