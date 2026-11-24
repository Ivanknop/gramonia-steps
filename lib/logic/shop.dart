import 'dart:math';

import 'chapter.dart';
import 'chapter_engine.dart';
import 'chapter_progress.dart';

/// Un precio según cuántos de ese objeto pide la etapa.
class PriceTier {
  const PriceTier({required this.moreThan, required this.price});

  /// Vale si la etapa pide más de esta cantidad.
  final int moreThan;
  final int price;
}

/// Precios de la tienda. Los escalones van de la cantidad más grande a la
/// más chica; vale el primero que corresponde.
class ShopPrices {
  const ShopPrices(this.tiers);

  final List<PriceTier> tiers;

  /// Precio de un objeto que la etapa pide [needed] veces.
  int priceFor(int needed) => tiers
      .firstWhere((t) => needed > t.moreThan, orElse: () => tiers.last)
      .price;
}

/// Algo que se puede comprar: un objeto que la etapa actual pide y falta.
class Offer {
  const Offer({required this.item, required this.price, required this.missing});

  final ItemType item;
  final int price;

  /// Cuántos faltan para la etapa.
  final int missing;
}

/// Por qué no hay nada para comprar.
enum ShopClosed {
  /// En el tramo de caminata: primero hay que llegar.
  traveling,

  /// Hay que entrar a la etapa (pantalla de llegada o diálogo).
  notEntered,

  /// El barco ya zarpó.
  chapterDone,
}

class Purchase {
  const Purchase(this.progress, this.price, this.events);

  /// El progreso con el objeto comprado (y la etapa terminada, si era el
  /// último que faltaba).
  final ChapterProgress progress;
  final int price;
  final List<ChapterEvent> events;
}

/// Tienda del Lobo: vende solo los objetos que pide la etapa actual y que
/// todavía faltan, uno por vez.
class Shop {
  const Shop(this.engine, this.prices);

  final ChapterEngine engine;
  final ShopPrices prices;

  ShopClosed? closedReason(ChapterProgress p) {
    if (engine.isFinished(p)) return ShopClosed.chapterDone;
    if (engine.isTraveling(p)) return ShopClosed.traveling;
    if (engine.needsEntering(p)) return ShopClosed.notEntered;
    return null;
  }

  List<Offer> offers(ChapterProgress p) {
    if (closedReason(p) != null) return const [];
    final stage = engine.currentStage(p)!;
    return [
      for (final r in stage.requirements)
        if (p.count(r.item) < r.count)
          Offer(
            item: engine.chapter.item(r.item),
            price: prices.priceFor(r.count),
            missing: r.count - p.count(r.item),
          ),
    ];
  }

  /// Compra un [itemId] con [coins] monedas. Devuelve null si no se vende o
  /// si no alcanzan las monedas.
  Purchase? buy(ChapterProgress p, int coins, String itemId, Random random) {
    final offer = offers(p).where((o) => o.item.id == itemId).firstOrNull;
    if (offer == null || coins < offer.price) return null;
    // Con 0 pasos, el motor solo cierra la etapa si ya está completa.
    final advance = engine.advance(p.withItem(itemId), 0, random);
    return Purchase(advance.progress, offer.price, advance.events);
  }
}
