import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide StepState;
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/data/textos.dart' as t;
import 'package:rpg/data/textos.dart' show Strings;
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/game_save.dart';
import 'package:rpg/logic/step_state.dart';
import 'package:rpg/logic/story.dart';
import 'package:rpg/logic/wallet.dart';
import 'package:rpg/ui/bag.dart';
import 'package:rpg/ui/coins.dart';
import 'package:rpg/ui/home_screen.dart';
import 'package:rpg/ui/shop_screen.dart';
import 'package:rpg/ui/stage_done.dart';
import 'package:rpg/ui/step_controller.dart';

import '../fakes/fake_random.dart';
import '../fakes/fakes.dart';

void main() {
  late FakeSensor sensor;
  late FakeStorage storage;
  late FakeClock clock;

  const savedSteps = StepState(
    lastReading: 100,
    totalSteps: 12345,
    todaySteps: 678,
    todayDate: '2026-11-24',
  );

  setUp(() {
    sensor = FakeSensor();
    storage = FakeStorage(savedSteps);
    storage.saved = storage.saved.copyWith(
      playerName: 'Regi',
      introSeen: true,
      genero: Genero.neutro,
    );
    clock = FakeClock(DateTime(2026, 11, 24, 9));
  });

  /// [dice] 0: todas las tiradas al azar salen (y las monedas dan el
  /// mínimo); 1: ninguna sale.
  StepController make({int dice = 0, CoinRange daily = dailyBonusCoins}) =>
      StepController(
        sensor: sensor,
        storage: storage,
        clock: clock,
        random: FixedRandom(dice),
        saveDelay: Duration.zero,
        dailyBonus: daily,
      );

  /// En la etapa [id], ya llegados, con [coins] monedas.
  void saveAt(String id, int coins, [Map<String, int> inv = const {}]) {
    final i = chapter1.stages.indexWhere((s) => s.id == id);
    storage.saved = storage.saved.copyWith(
      chapter: ChapterProgress(
        stageIndex: i,
        stepsInStage: chapter1.stages[i].travelSteps,
        inventory: inv,
        sinceLast: const {},
      ),
      wallet: Wallet(
        coins: coins,
        // El bono de hoy ya se cobró.
        dailyBonusDate: '2026-11-24',
        welcomeBonusPaid: true,
      ),
    );
  }

  group('controlador', () {
    test('al abrir por primera vez en el día, cobra el bono', () async {
      final c = make();
      await c.start();
      addTearDown(c.dispose);
      expect(c.coins, 35); // FixedRandom(0): el mínimo.
      expect(c.coinNotices, [const CoinNotice(CoinNoticeKind.daily, 35)]);
      expect(storage.saved.wallet.dailyBonusDate, '2026-11-24');
      expect(storage.saved.wallet.coins, 35);
    });

    test('al reabrir el mismo día no se repite', () async {
      final first = make();
      await first.start();
      first.dispose();
      final again = make();
      await again.start();
      addTearDown(again.dispose);
      expect(again.coins, 35);
    });

    test('si se atrasa la hora del celular, no se repite', () async {
      final first = make();
      await first.start();
      first.dispose();
      clock.time = DateTime(2026, 11, 23, 22);
      final again = make();
      await again.start();
      addTearDown(again.dispose);
      expect(again.coins, 35);
      // Ni al volver al día de verdad.
      clock.time = DateTime(2026, 11, 24, 23);
      again.refreshDay();
      expect(again.coins, 35);
    });

    test('al pasar al día siguiente con la app abierta, otro bono', () async {
      final c = make();
      await c.start();
      addTearDown(c.dispose);
      clock.time = DateTime(2026, 11, 25, 0, 1);
      c.refreshDay();
      expect(c.coins, 70);
      expect(c.coinNotices.length, 2);
    });

    test('caminar sin que salga nada da monedas', () async {
      saveAt('casa_abuelita', 0);
      final c = make(dice: 1);
      await c.start();
      addTearDown(c.dispose);
      await c.addDebugSteps(1000);
      // 20 tiradas de flor lila; FixedRandom(1) da el mínimo + 1.
      expect(c.coins, 20 * (missCoins.min + 1));
      expect(storage.saved.wallet.coins, 20 * (missCoins.min + 1));
    });

    test('comprar descuenta, suma el objeto y guarda', () async {
      saveAt('casa_abuelita', 1000, {'flor_lila': 3});
      final c = make();
      await c.start();
      addTearDown(c.dispose);
      final purchase = await c.buy('flor_lila');
      expect(purchase, isNotNull);
      expect(c.coins, 700);
      expect(c.game.chapter.count('flor_lila'), 4);
      expect(storage.saved.wallet.coins, 700);
      expect(storage.saved.chapter.count('flor_lila'), 4);
    });

    test('sin monedas suficientes no compra', () async {
      saveAt('casa_abuelita', 299);
      final c = make();
      await c.start();
      addTearDown(c.dispose);
      expect(await c.buy('flor_lila'), isNull);
      expect(c.coins, 299);
    });

    test('al ver el aviso, no vuelve a aparecer', () async {
      final c = make();
      await c.start();
      addTearDown(c.dispose);
      c.dismissCoinNotice(c.coinNotices.single);
      expect(c.coinNotices, isEmpty);
      await c.onPause();
      expect(storage.saved.wallet.notices, isEmpty);
      expect(storage.saved.wallet.coins, 35);
    });
  });

  group('pantallas', () {
    Future<StepController> showHome(
      WidgetTester tester, {
      CoinRange daily = dailyBonusCoins,
    }) async {
      final c = make(daily: daily);
      await c.start();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(controller: c, showDebug: false)),
      );
      return c;
    }

    String balance(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('coin-balance')).first)
        .data!;

    testWidgets('aviso del bono del día y saldo en la pantalla principal', (
      tester,
    ) async {
      final c = await showHome(tester);
      expect(find.text('¡Bono del día: 35 monedas!'), findsOneWidget);
      await tester.tap(find.text(Strings.coinNoticeButton));
      await tester.pumpAndSettle();
      expect(find.byType(CoinNoticeOverlay), findsNothing);
      expect(c.coinNotices, isEmpty);
      expect(balance(tester), '35');
      expect(find.text(Strings.coinBalance(35)), findsOneWidget);
    });

    testWidgets('el aviso de monedas se cierra solo a los 6 segundos', (
      tester,
    ) async {
      final c = await showHome(tester);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(CoinNoticeOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(CoinNoticeOverlay), findsNothing);
      expect(c.coinNotices, isEmpty);
    });

    testWidgets('con la x se cierra antes', (tester) async {
      final c = await showHome(tester);
      await tester.tap(find.byKey(const ValueKey('notice-close')));
      await tester.pumpAndSettle();
      expect(find.byType(CoinNoticeOverlay), findsNothing);
      expect(c.coinNotices, isEmpty);
    });

    testWidgets('bono de bienvenida de la 1.2.0, antes que el del día', (
      tester,
    ) async {
      // Una partida de la 1.1.0, como la lee el celular al actualizar.
      final old = const GameSave(
        steps: savedSteps,
        chapter: ChapterProgress.initial(),
      ).encode().replaceFirst('"version":6', '"version":5');
      storage.saved = GameSave.decode(
        old,
        engine: const ChapterEngine(chapter1),
        welcomeCoinsPer100Steps: welcomeCoinsPer100Steps,
      );
      final c = await showHome(tester);
      expect(
        find.text(
          '¡Gracias por jugar desde el principio! Recibiste 1.230 monedas '
          'para la Tienda del Lobo',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(Strings.coinNoticeButton));
      await tester.pumpAndSettle();
      expect(find.text('¡Bono del día: 35 monedas!'), findsOneWidget);
      await tester.tap(find.text(Strings.coinNoticeButton));
      await tester.pumpAndSettle();
      expect(c.coins, 1230 + 35);
      expect(balance(tester), '1.265');
    });

    testWidgets('el saldo también se ve en la bolsa', (tester) async {
      saveAt('casa_abuelita', 4321);
      await showHome(tester, daily: CoinRange.none);
      await tester.tap(find.byType(BagButton));
      await tester.pumpAndSettle();
      expect(find.byType(BagScreen), findsOneWidget);
      expect(find.text(Strings.bagCoins), findsOneWidget);
      expect(balance(tester), '4.321');
    });

    testWidgets('a la tienda se entra desde la pantalla principal', (
      tester,
    ) async {
      saveAt('casa_abuelita', 500);
      await showHome(tester, daily: CoinRange.none);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('shop-card')),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('shop-card')));
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget);
      expect(find.text(Strings.shopTitle), findsOneWidget);
    });

    Future<StepController> showShop(WidgetTester tester) async {
      final c = make(daily: CoinRange.none);
      await c.start();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ShopScreen(controller: c, random: FixedRandom(0)),
        ),
      );
      return c;
    }

    testWidgets('el Lobo saluda y vende lo que falta de la etapa', (
      tester,
    ) async {
      saveAt('casa_abuelita', 700, {'flor_lila': 12});
      final c = await showShop(tester);
      expect(
        find.text('Pasen. Soy el Lobo. Guardo cosas para quien camina.'),
        findsOneWidget,
      );
      expect(find.text(t.florLila.nombre), findsOneWidget);
      expect(find.text(Strings.shopMissing(3)), findsOneWidget);
      expect(find.text('300'), findsOneWidget);

      await tester.tap(find.text('300'));
      await tester.pumpAndSettle();
      expect(c.coins, 400);
      expect(c.game.chapter.count('flor_lila'), 13);
      expect(find.text('Buena elección: una flor lila.'), findsOneWidget);
      expect(find.text(Strings.shopMissing(2)), findsOneWidget);
    });

    testWidgets('sin monedas, el Lobo avisa cuántas faltan', (tester) async {
      saveAt('laberinto_hormigas', 1000);
      final c = await showShop(tester);
      await tester.tap(find.text('1.200').first);
      await tester.pumpAndSettle();
      expect(c.coins, 1000);
      expect(
        find.text(t.loboSinMonedas.replaceAll('{faltan}', '200')),
        findsOneWidget,
      );
    });

    testWidgets('al tocar al Lobo, charla', (tester) async {
      saveAt('casa_abuelita', 0);
      await showShop(tester);
      await tester.tap(find.text(Strings.shopTapLobo));
      await tester.pumpAndSettle();
      expect(find.text(t.loboDichos.first), findsOneWidget);
    });

    testWidgets('en el tramo de caminata no hay nada para comprar', (
      tester,
    ) async {
      storage.saved = storage.saved.copyWith(
        chapter: const ChapterProgress(
          stageIndex: 4, // El puerto, caminando.
          stepsInStage: 100,
          inventory: {},
          sinceLast: {},
        ),
      );
      await showShop(tester);
      expect(find.text(t.loboViajando), findsOneWidget);
      expect(find.text(chapter1.item('pista').name), findsNothing);
    });

    testWidgets('si la compra completa la etapa, se festeja al volver', (
      tester,
    ) async {
      saveAt('casa_abuelita', 300, {'flor_lila': 14});
      final c = await showHome(tester, daily: CoinRange.none);
      await tester.tap(find.byType(CoinChip));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('offer-flor_lila')),
          matching: find.text('300'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.loboEtapaCompleta), findsOneWidget);
      expect(c.coins, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(StageDoneOverlay), findsOneWidget);
    });
  });
}
