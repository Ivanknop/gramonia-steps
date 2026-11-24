import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/shop.dart';
import 'package:test/test.dart';

import '../fakes/fake_random.dart';

/// Devuelve los números en orden (recortados al rango pedido).
class ScriptRandom implements Random {
  ScriptRandom(this.values);
  final List<int> values;
  var _i = 0;

  @override
  int nextInt(int max) => min(values[_i++ % values.length], max - 1);

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  const engine = ChapterEngine(chapter1);
  const shop = Shop(engine, shopPrices);

  int stageIndex(String id) => chapter1.stages.indexWhere((s) => s.id == id);

  /// En la etapa [id], ya llegados (después del tramo), con [inv].
  ChapterProgress at(String id, [Map<String, int> inv = const {}]) {
    final i = stageIndex(id);
    return ChapterProgress(
      stageIndex: i,
      stepsInStage: chapter1.stages[i].travelSteps,
      inventory: inv,
      sinceLast: const {},
    );
  }

  group('monedas al caminar', () {
    test('cada tirada al azar en la que no sale nada da de 13 a 51', () {
      // Flor lila: una tirada cada 50 pasos. Con 1, nunca sale; la moneda
      // da 13 + 1.
      final r = engine.advance(at('casa_abuelita'), 500, FixedRandom(1));
      expect(r.progress.count('flor_lila'), 0);
      expect(r.coins, 10 * 14);
    });

    test('con el máximo, 51 por tirada', () {
      final r = engine.advance(at('casa_abuelita'), 50, FixedRandom(99));
      expect(r.coins, 51);
    });

    test('si sale el objeto, esa tirada no da monedas', () {
      final r = engine.advance(at('casa_abuelita'), 500, FixedRandom(0));
      expect(r.progress.count('flor_lila'), 10);
      expect(r.coins, 0);
    });

    test('los objetos fijos y el tramo de caminata no dan monedas', () {
      expect(
        engine.advance(at('jardin_abuelita'), 1000, FixedRandom(1)).coins,
        0,
      );
      final nido = ChapterProgress(
        stageIndex: stageIndex('nido_rocanron'),
        stepsInStage: 0,
        inventory: const {},
        sinceLast: const {},
      );
      expect(engine.advance(nido, 3000, FixedRandom(1)).coins, 0);
    });

    test('con la etapa completa no da más monedas', () {
      final almost = at('barco', {
        'madera': 1,
        'clavos': 1,
        'cuerdas': 1,
        'bandera': 1,
      });
      // A los 50 pasos: moneda de oro (no sale, 13 monedas).
      // A los 100: el ancla sale (0) y completa el barco; la tirada de la
      // moneda de oro (no sale) ya no da monedas.
      final r = engine.advance(almost, 100, ScriptRandom([5, 0, 0, 5]));
      expect(r.events.whereType<StageCompleted>(), isNotEmpty);
      expect(r.coins, 13);

      // Sin el ancla, las dos tiradas a los 100 dan monedas.
      final miss = engine.advance(
        almost,
        100,
        ScriptRandom([5, 0, 5, 0, 5, 0]),
      );
      expect(miss.coins, 3 * 13);
    });

    test('después del final no hay más monedas', () {
      final done = ChapterProgress(
        stageIndex: chapter1.stages.length,
        stepsInStage: 0,
        inventory: const {},
        sinceLast: const {},
      );
      expect(engine.advance(done, 10000, FixedRandom(1)).coins, 0);
    });
  });

  group('precios', () {
    test('según cuántos pide la etapa', () {
      expect(shopPrices.priceFor(15), 300); // flores
      expect(shopPrices.priceFor(11), 300);
      expect(shopPrices.priceFor(10), 600);
      expect(shopPrices.priceFor(6), 600);
      expect(shopPrices.priceFor(5), 1200);
      expect(shopPrices.priceFor(3), 1200); // semillas de fuego
      expect(shopPrices.priceFor(1), 1200); // piezas, pista, ofrendas
    });
  });

  group('qué se vende', () {
    test('solo lo que pide la etapa actual y falta', () {
      final offers = shop.offers(
        at('laberinto_hormigas', {'pieza_hoja': 1, 'pieza_gota': 1}),
      );
      expect(offers.map((o) => o.item.id), [
        'pieza_piedra',
        'pieza_sol',
        'pieza_luna',
        'pieza_estrella',
      ]);
      expect(offers.every((o) => o.price == 1200 && o.missing == 1), isTrue);
    });

    test('flores lilas: 300 cada una, con cuántas faltan', () {
      final offer = shop.offers(at('casa_abuelita', {'flor_lila': 4})).single;
      expect(offer.item.id, 'flor_lila');
      expect(offer.price, 300);
      expect(offer.missing, 11);
    });

    test('los objetos comunes no se venden', () {
      final offers = shop.offers(at('nido_rocanron'));
      expect(offers.map((o) => o.item.id), ['semilla_fuego']);
    });

    test('en el tramo de caminata no se vende nada', () {
      final p = ChapterProgress(
        stageIndex: stageIndex('puerto'),
        stepsInStage: 100,
        inventory: const {},
        sinceLast: const {},
      );
      expect(shop.closedReason(p), ShopClosed.traveling);
      expect(shop.offers(p), isEmpty);
    });

    test('antes de entrar a la etapa no se vende nada', () {
      final p = ChapterProgress(
        stageIndex: stageIndex('puerto'),
        stepsInStage: 10000,
        inventory: const {},
        sinceLast: const {},
        entered: false,
      );
      expect(shop.closedReason(p), ShopClosed.notEntered);
      expect(shop.offers(p), isEmpty);
    });

    test('después de que zarpa el barco, cerrado', () {
      final p = ChapterProgress(
        stageIndex: chapter1.stages.length,
        stepsInStage: 0,
        inventory: const {},
        sinceLast: const {},
      );
      expect(shop.closedReason(p), ShopClosed.chapterDone);
      expect(shop.offers(p), isEmpty);
    });
  });

  group('comprar', () {
    test('suma el objeto (también a la bolsa) y dice el precio', () {
      final p = at('casa_abuelita', {'flor_lila': 4});
      final buy = shop.buy(p, 300, 'flor_lila', Random(1))!;
      expect(buy.price, 300);
      expect(buy.progress.count('flor_lila'), 5);
      expect(buy.progress.foundCount('flor_lila'), 1);
      expect(buy.progress.unseen, 0);
      expect(buy.events, isEmpty);
    });

    test('si no alcanzan las monedas, no se compra', () {
      final p = at('casa_abuelita');
      expect(shop.buy(p, 299, 'flor_lila', Random(1)), isNull);
    });

    test('lo que no se vende no se compra', () {
      expect(
        shop.buy(at('nido_rocanron'), 9999, 'semilla_agua', Random(1)),
        isNull,
      );
      expect(
        shop.buy(at('nido_rocanron'), 9999, 'pieza_sol', Random(1)),
        isNull,
      );
    });

    test('con el último que faltaba, la etapa se completa', () {
      final p = at('casa_abuelita', {'flor_lila': 14});
      final buy = shop.buy(p, 300, 'flor_lila', Random(1))!;
      expect(
        buy.events.whereType<StageCompleted>().single.stage.id,
        'casa_abuelita',
      );
      expect(engine.currentStage(buy.progress)!.id, 'nido_rocanron');
      // La etapa siguiente empieza con su tramo de caminata.
      expect(engine.isTraveling(buy.progress), isTrue);
    });

    test('se pueden comprar piezas fuera de orden', () {
      var p = at('laberinto_hormigas');
      p = shop.buy(p, 1200, 'pieza_estrella', Random(1))!.progress;
      expect(p.count('pieza_estrella'), 1);
      // La próxima pieza fija sigue siendo la primera que falta.
      final r = engine.advance(p, 1000, FixedRandom(0));
      expect(r.progress.count('pieza_hoja'), 1);
    });
  });
}
