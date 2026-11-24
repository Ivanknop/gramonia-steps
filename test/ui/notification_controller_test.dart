import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:rpg/data/textos.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/notification_summary.dart';
import 'package:rpg/logic/wallet.dart';
import 'package:rpg/services/system_notifier.dart';
import 'package:rpg/ui/my_steps_screen.dart';
import 'package:rpg/ui/notification_controller.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fake_random.dart';
import '../fakes/fakes.dart';

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

void main() {
  late FakeNotifier notifier;
  late FakeNotificationPrefs prefs;
  late StepController steps;
  late NotificationController n;

  const delay = Duration(seconds: 15);

  Future<void> make({bool enabled = true}) async {
    notifier = FakeNotifier();
    prefs = FakeNotificationPrefs()..enabled = enabled;
    final storage = FakeStorage();
    // En la casa de la abuelita: con FixedRandom(0), una flor cada 50 pasos.
    storage.saved = storage.saved.copyWith(
      chapter: const ChapterProgress(
        stageIndex: 1,
        stepsInStage: 0,
        inventory: {},
        sinceLast: {},
      ),
    );
    steps = StepController(
      sensor: FakeSensor(),
      storage: storage,
      random: FixedRandom(0),
      saveDelay: Duration.zero,
      dailyBonus: CoinRange.none,
    );
    await steps.start();
    n = NotificationController(
      notifier: notifier,
      prefs: prefs,
      steps: steps,
      delay: delay,
    );
    await n.start();
  }

  tearDown(() {
    n.dispose();
    steps.dispose();
  });

  test('empiezan apagadas y sin pedir permiso al abrir', () async {
    await make(enabled: false);
    expect(n.enabled, isFalse);
    expect(notifier.permissionRequests, 0);
  });

  test('al activarlas se pide el permiso y se guarda', () async {
    await make(enabled: false);
    expect(await n.setEnabled(true), isTrue);
    expect(notifier.permissionRequests, 1);
    expect(n.enabled, isTrue);
    expect(prefs.enabled, isTrue);
  });

  test('si se niega el permiso, quedan apagadas', () async {
    await make(enabled: false);
    notifier.grant = false;
    expect(await n.setEnabled(true), isFalse);
    expect(n.enabled, isFalse);
    expect(prefs.enabled, isFalse);
  });

  test('con el juego a la vista no hay notificaciones', () {
    fakeAsync((async) {
      make();
      async.flushMicrotasks();
      steps.addDebugSteps(500);
      async.elapse(delay * 2);
      expect(notifier.shown, isEmpty);
    });
  });

  test('en segundo plano: una sola notificación para muchos objetos', () {
    fakeAsync((async) {
      make();
      async.flushMicrotasks();
      n.onPause();
      // Diez flores, en cinco lecturas seguidas.
      for (var i = 0; i < 5; i++) {
        steps.addDebugSteps(100);
        async.elapse(const Duration(seconds: 1));
      }
      expect(notifier.shown, isEmpty); // Espera para juntarlas.
      async.elapse(delay);
      expect(notifier.shown.length, 1);
      expect(notifier.shown.single.title, '¡Encontraste 10 objetos!');
      expect(notifier.shown.single.alert, isTrue);

      // Más objetos: se actualiza la misma, en silencio.
      steps.addDebugSteps(100);
      async.elapse(delay);
      expect(notifier.shown.length, 2);
      expect(notifier.shown.last.lines, ['Flor lila ×12']);
      expect(notifier.shown.last.alert, isFalse);
    });
  });

  test('al pasar de etapa, suena', () {
    fakeAsync((async) {
      make();
      async.flushMicrotasks();
      n.onPause();
      steps.addDebugSteps(750); // 15 flores: termina la etapa.
      async.elapse(delay);
      expect(notifier.shown.last.title, startsWith('¡Etapa completada'));
      expect(notifier.shown.last.alert, isTrue);
    });
  });

  test('al volver al juego se saca la notificación', () {
    fakeAsync((async) {
      make();
      async.flushMicrotasks();
      n.onPause();
      steps.addDebugSteps(100);
      async.elapse(delay);
      n.onResume();
      async.flushMicrotasks();
      expect(notifier.cancels, 1);
    });
  });

  test('apagadas, no se manda nada', () {
    fakeAsync((async) {
      make(enabled: false);
      async.flushMicrotasks();
      n.onPause();
      steps.addDebugSteps(500);
      async.elapse(delay * 2);
      expect(notifier.shown, isEmpty);
    });
  });

  testWidgets('el interruptor de "Mis pasos"', (tester) async {
    await tester.runAsync(() => make(enabled: false));
    await tester.pumpWidget(
      MaterialApp(
        home: MyStepsScreen(controller: steps, notifications: n),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notifications-switch')),
      200,
    );
    expect(find.text(Strings.notificationsSwitch), findsOneWidget);

    // Permiso negado: queda apagado y avisa, con el botón a los ajustes.
    notifier.grant = false;
    await tester.tap(find.byKey(const ValueKey('notifications-switch')));
    await tester.pumpAndSettle();
    expect(n.enabled, isFalse);
    expect(find.text(Strings.notificationsDenied), findsOneWidget);
    await tester.tap(find.text(Strings.openSettings));
    await tester.pumpAndSettle(); // Se va el aviso.
    expect(notifier.settings, 1);

    notifier.grant = true;
    await tester.tap(find.byKey(const ValueKey('notifications-switch')));
    await tester.pumpAndSettle();
    expect(n.enabled, isTrue);
    expect(prefs.enabled, isTrue);
  });
}
