import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/wallet.dart';
import 'package:test/test.dart';

import '../fakes/fake_random.dart';

void main() {
  const range = CoinRange(35, 78);

  group('CoinRange', () {
    test('siempre da entre el mínimo y el máximo, los dos incluidos', () {
      final random = Random(1);
      final seen = {for (var i = 0; i < 5000; i++) range.roll(random)};
      expect(seen.reduce(min), 35);
      expect(seen.reduce(max), 78);
    });

    test('none no da nada', () {
      expect(CoinRange.none.roll(Random(1)), 0);
    });
  });

  group('bono diario', () {
    test('se cobra la primera vez del día, con su aviso', () {
      final w = Wallet.initial.claimDaily('2026-11-24', range, FixedRandom(0));
      expect(w.coins, 35);
      expect(w.dailyBonusDate, '2026-11-24');
      expect(w.notices, [const CoinNotice(CoinNoticeKind.daily, 35)]);
    });

    test('al reabrir el mismo día no se repite', () {
      final w = Wallet.initial.claimDaily('2026-11-24', range, Random(1));
      expect(identical(w.claimDaily('2026-11-24', range, Random(2)), w), true);
    });

    test('si se atrasa la fecha del celular, no se cobra', () {
      final w = Wallet.initial.claimDaily('2026-11-24', range, Random(1));
      expect(identical(w.claimDaily('2026-11-23', range, Random(2)), w), true);
      expect(identical(w.claimDaily('2025-12-31', range, Random(2)), w), true);
    });

    test('al día siguiente se cobra otra vez', () {
      final w = Wallet.initial
          .claimDaily('2026-11-24', range, FixedRandom(0))
          .claimDaily('2026-11-25', range, FixedRandom(100));
      expect(w.coins, 35 + 78);
      expect(w.dailyBonusDate, '2026-11-25');
      expect(w.notices.length, 2);
    });
  });

  group('bono de bienvenida', () {
    const bonus = WelcomeBonus(coins: 20, everySteps: 500);

    test('el del juego: 20 monedas cada 500 pasos', () {
      expect(welcomeBonus.coins, 20);
      expect(welcomeBonus.everySteps, 500);
    });

    test('20 monedas por cada 500 pasos, redondeado hacia abajo', () {
      // 12.345 pasos → 24 veces 500 → 480 monedas.
      final w = Wallet.initial.payWelcome(12345, bonus);
      expect(w.coins, 480);
      expect(w.welcomeBonusPaid, isTrue);
      expect(w.notices, [const CoinNotice(CoinNoticeKind.welcome, 480)]);
      expect(bonus.amountFor(499), 0);
      expect(bonus.amountFor(500), 20);
      expect(bonus.amountFor(999), 20);
      expect(bonus.amountFor(1000), 40);
    });

    test('no se cobra dos veces', () {
      final once = Wallet.initial.payWelcome(12345, bonus);
      expect(identical(once.payWelcome(12345, bonus), once), true);
      // Ni con más pasos caminados después.
      expect(once.payWelcome(99999, bonus).coins, 480);
    });

    test('con menos de 500 pasos queda marcado, sin monedas ni aviso', () {
      final w = Wallet.initial.payWelcome(499, bonus);
      expect(w.coins, 0);
      expect(w.welcomeBonusPaid, isTrue);
      expect(w.notices, isEmpty);
    });
  });

  test('gastar descuenta y no deja gastar de más', () {
    const w = Wallet(coins: 500);
    expect(w.spend(300).coins, 200);
    expect(() => w.spend(501), throwsStateError);
  });

  test('al ver un aviso se saca solo ese', () {
    final w = Wallet.initial
        .payWelcome(1000, const WelcomeBonus(coins: 20, everySteps: 500))
        .claimDaily('2026-11-24', range, FixedRandom(0));
    final daily = w.notices.last;
    expect(w.dismiss(daily).notices, [w.notices.first]);
    expect(w.dismiss(daily).coins, w.coins);
  });

  test('ida y vuelta en JSON', () {
    final w = Wallet.initial
        .payWelcome(5000, const WelcomeBonus(coins: 20, everySteps: 500))
        .claimDaily('2026-11-24', range, Random(3))
        .add(17);
    expect(Wallet.fromJson(w.toJson()), w);
  });
}
