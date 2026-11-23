import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rpg/services/step_history_storage.dart';
import 'package:rpg/data/textos.dart';
import 'package:rpg/ui/my_steps_screen.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fakes.dart';

void main() {
  testWidgets('muestra la semana, el mes y los meses', (tester) async {
    final controller = StepController(
      sensor: FakeSensor(),
      storage: FakeStorage(),
      clock: FakeClock(DateTime(2026, 11, 23, 10)),
      historyStorage: MemoryStepHistoryStorage({
        '2026-11-22': 4321,
        '2026-11-02': 1000,
        '2026-09-10': 777,
      }),
    );
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(home: MyStepsScreen(controller: controller)),
    );

    expect(find.text(Strings.lastSevenDays), findsOneWidget);
    expect(find.text('4.321'), findsOneWidget);
    expect(find.text(Strings.periodTotal(4321)), findsOneWidget);

    await tester.tap(find.text(Strings.periodMonth));
    await tester.pump();
    expect(find.text('Noviembre 2026'), findsOneWidget);
    expect(find.text(Strings.weekOfMonth(4)), findsOneWidget);
    expect(find.text(Strings.periodTotal(5321)), findsOneWidget);

    await tester.tap(find.text(Strings.periodMonths));
    await tester.pump();
    expect(find.text(Strings.monthShort(9)), findsOneWidget);
    expect(find.text(Strings.periodTotal(6098)), findsOneWidget);

    controller.dispose();
  });
}
