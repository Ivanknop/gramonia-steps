import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/services/step_history_storage.dart';
import 'package:rpg/services/step_sensor.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fake_random.dart';
import '../fakes/fakes.dart';

void main() {
  late FakeSensor sensor;
  late FakeStorage storage;
  late FakeClock clock;
  late MemoryStepHistoryStorage history;
  late StepController c;

  StepController make() => StepController(
    sensor: sensor,
    storage: storage,
    historyStorage: history,
    clock: clock,
    saveDelay: Duration.zero,
    random: FixedRandom(0), // todas las tiradas al azar salen
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    sensor = FakeSensor();
    storage = FakeStorage();
    history = MemoryStepHistoryStorage();
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
    // 2.000 pasos dan 15 flores amarillas (una cada 100, a los 1.500) y
    // pasan a la etapa 2 con 500 pasos.
    await c.addDebugSteps(2000);
    await settle();
    expect(c.game.chapter.count('flor_amarilla'), 15);
    expect(c.game.chapter.stageIndex, 1);
    expect(c.game.chapter.stepsInStage, 500);
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
    sensor.emit(5120); // +120: una flor amarilla (cada 100)
    await settle();
    await settle();
    expect(c.game.chapter.stepsInStage, 120);
    expect(c.game.chapter.count('flor_amarilla'), 1);
    expect(received.single, isA<ItemFound>());
    expect(storage.saved.chapter.count('flor_amarilla'), 1);
  });

  test('el cambio de día no avanza el capítulo', () async {
    c = make();
    await c.start();
    await c.addDebugSteps(100);
    clock.time = DateTime(2026, 11, 23, 8);
    c.refreshDay();
    expect(c.game.chapter.stepsInStage, 100);
  });

  test('al abrir la bolsa, lo nuevo sin ver vuelve a 0 y se guarda', () async {
    c = make();
    await c.start();
    await c.addDebugSteps(100); // Sale una flor.
    expect(c.game.chapter.unseen, 1);
    c.markBagSeen();
    expect(c.game.chapter.unseen, 0);
    await settle();
    expect(storage.saved.chapter.unseen, 0);
    expect(storage.saved.chapter.foundCount('flor_amarilla'), 1);
  });

  group('historial', () {
    test(
      'al arrancar pasa al historial los pasos ya guardados de hoy',
      () async {
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
        expect(history.days, {'2026-11-22': 300});
        expect(c.history.stepsOn(clock.time), 300);
      },
    );

    test(
      'los pasos guardados de otro día también pasan, y hoy arranca en 0',
      () async {
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
        expect(history.days, {'2026-11-21': 300, '2026-11-22': 0});
      },
    );

    test('suma los pasos al día y guarda al cambiar de día', () async {
      history = MemoryStepHistoryStorage({'2026-11-20': 4000});
      c = make();
      await c.start();
      expect(c.history.days['2026-11-20'], 4000);
      sensor.emit(100);
      sensor.emit(350);
      await settle();
      await settle();
      expect(history.days['2026-11-22'], 250);

      clock.time = DateTime(2026, 11, 23, 8);
      sensor.emit(400);
      await settle();
      await settle();
      expect(history.days['2026-11-22'], 250);
      expect(history.days['2026-11-23'], 50);
    });

    test('el botón de debug también suma al día', () async {
      c = make();
      await c.start();
      await c.addDebugSteps(1000);
      expect(history.days['2026-11-22'], 1000);
    });
  });
}
