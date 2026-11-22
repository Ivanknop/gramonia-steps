import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late FakeSensor sensor;
  late FakeStorage storage;
  late FakeClock clock;
  late StepController c;

  StepController make() => StepController(
    sensor: sensor,
    storage: storage,
    clock: clock,
    saveDelay: Duration.zero,
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    sensor = FakeSensor();
    storage = FakeStorage();
    clock = FakeClock(DateTime(2026, 11, 22, 10));
  });

  tearDown(() => c.dispose());

  test('al arrancar carga lo guardado', () async {
    storage = FakeStorage(
      const StepState(
        lastReading: 500,
        totalSteps: 8000,
        todaySteps: 300,
        todayDate: '2026-11-22',
      ),
    );
    c = make();
    await c.start();
    expect(c.state.totalSteps, 8000);
    expect(c.state.todaySteps, 300);
    expect(c.status, StepStatus.tracking);
  });

  test('si lo guardado es de otro día, hoy arranca en 0', () async {
    storage = FakeStorage(
      const StepState(
        lastReading: 500,
        totalSteps: 8000,
        todaySteps: 300,
        todayDate: '2026-11-21',
      ),
    );
    c = make();
    await c.start();
    expect(c.state.todaySteps, 0);
    expect(c.state.totalSteps, 8000);
  });

  test('las lecturas nuevas actualizan y se guardan', () async {
    c = make();
    await c.start();
    sensor.emit(1000);
    sensor.emit(1250);
    await settle();
    await settle();
    expect(c.state.totalSteps, 250);
    expect(storage.saved.steps.totalSteps, 250);
    expect(storage.saved.steps.lastReading, 1250);
  });

  test('si se niega el permiso, el estado es "sin permiso"', () async {
    sensor.permission = SensorPermission.denied;
    c = make();
    await c.start();
    expect(c.status, StepStatus.needsPermission);

    sensor.answerToRequest = SensorPermission.granted;
    await c.askPermission();
    expect(c.status, StepStatus.tracking);
  });

  test('si se niega para siempre, el botón abre los ajustes', () async {
    sensor.permission = SensorPermission.permanentlyDenied;
    c = make();
    await c.start();
    expect(c.status, StepStatus.permissionBlocked);

    await c.askPermission();
    expect(sensor.settingsCount, 1);

    // La persona da el permiso en Ajustes y vuelve a la app.
    sensor.permission = SensorPermission.granted;
    await c.onResume();
    expect(c.status, StepStatus.tracking);
  });

  test('si no hay sensor, el estado es "sin sensor"', () async {
    c = make();
    await c.start();
    sensor.fail(const StepSensorUnavailable('no hay'));
    await settle();
    expect(c.status, StepStatus.noSensor);
  });

  test('el botón de debug suma y guarda, aun sin permiso', () async {
    sensor.permission = SensorPermission.denied;
    c = make();
    await c.start();
    await c.addDebugSteps(1000);
    expect(c.state.todaySteps, 1000);
    expect(storage.saved.steps.totalSteps, 1000);
  });

  test('al volver a la app en otro día, hoy vuelve a 0', () async {
    c = make();
    await c.start();
    await c.addDebugSteps(1000);
    clock.time = DateTime(2026, 11, 23, 8);
    await c.onResume();
    expect(c.state.todaySteps, 0);
    expect(c.state.totalSteps, 1000);
  });

  test('el botón de debug avanza el capítulo y avisa', () async {
    c = make();
    final received = <List<ChapterEvent>>[];
    c.events.listen(received.add);
    await c.start();
    await c.addDebugSteps(1000);
    await settle();
    expect(c.game.chapter.stageIndex, 1);
    expect(c.game.chapter.collected, hasLength(4));
    expect(received, hasLength(1));
    expect(received.single.whereType<StageCompleted>(), hasLength(1));
    expect(storage.saved.chapter, c.game.chapter);
  });

  test('las lecturas reales avanzan el capítulo igual que el debug', () async {
    c = make();
    final received = <ChapterEvent>[];
    c.events.listen(received.addAll);
    await c.start();
    sensor.emit(5000); // base
    sensor.emit(5260); // +260: hoja dorada (250)
    await settle();
    await settle();
    expect(c.game.chapter.stepsInStage, 260);
    expect(c.game.chapter.collected, ['hoja_dorada']);
    expect(received.single, isA<ItemCollected>());
    expect(storage.saved.chapter.collected, ['hoja_dorada']);
  });

  test('el cambio de día no avanza el capítulo', () async {
    c = make();
    await c.start();
    await c.addDebugSteps(100);
    clock.time = DateTime(2026, 11, 23, 8);
    c.refreshDay();
    expect(c.game.chapter.stepsInStage, 100);
  });
}
