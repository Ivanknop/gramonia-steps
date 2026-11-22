import 'dart:async';

import 'package:rpg/logic/clock.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/services/step_storage.dart';

class FakeClock implements Clock {
  FakeClock(this.time);
  DateTime time;

  @override
  DateTime now() => time;
}

class FakeStorage implements StepStorage {
  FakeStorage([this.saved = const StepState.initial()]);
  StepState saved;
  int saveCount = 0;

  @override
  Future<StepState> load() async => saved;

  @override
  Future<void> save(StepState state) async {
    saved = state;
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
