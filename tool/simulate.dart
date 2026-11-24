// Simula muchas partidas del Capítulo 1 con el motor real del juego.
//
// Uso: dart run tool/simulate.dart [partidas] [semilla]
// Imprime tablas en Markdown para pegar en docs/diseno.md:
// - sin usar la tienda;
// - comprando en la Tienda del Lobo todo lo posible, apenas alcanzan las
//   monedas (con el bono del día, sin el de bienvenida).
// Es una herramienta de terminal: imprimir es lo que tiene que hacer.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';
import 'package:rpg/logic/shop.dart';

/// Pasos por día de referencia (docs/diseno.md).
const stepsPerDay = 4500;

// Todas las tiradas y tramos son múltiplos de 50: avanzar de a 50 es exacto.
const tick = 50;

const engine = ChapterEngine(chapter1);
const shop = Shop(engine, shopPrices);

class Result {
  final perStage = [for (final _ in chapter1.stages) <int>[]];
  final totals = <int>[];
  final coinsEarned = <int>[];
  final coinsSpent = <int>[];
  final bought = <int>[];
}

void play(Random random, Result out, {required bool buy}) {
  var p = const ChapterProgress.initial();
  var total = 0;
  var inStage = 0;
  var coins = 0;
  var earned = 0;
  var spent = 0;
  var bought = 0;

  void record(int before) {
    if (p.stageIndex != before) {
      out.perStage[before].add(inStage - p.stepsInStage);
      inStage = p.stepsInStage;
    }
  }

  while (!engine.isFinished(p)) {
    // Bono del día: al empezar cada día de caminata.
    if (total % stepsPerDay < tick) {
      final daily = dailyBonusCoins.roll(random);
      coins += daily;
      earned += daily;
    }
    final before = p.stageIndex;
    final advance = engine.advance(p, tick, random);
    p = advance.progress;
    coins += advance.coins;
    earned += advance.coins;
    total += tick;
    inStage += tick;
    record(before);

    // Al llegar a una etapa se entra enseguida (en el juego, al tocar
    // "Entrar").
    p = engine.enter(p);
    while (buy) {
      final offer = shop.offers(p).firstOrNull;
      if (offer == null || coins < offer.price) break;
      final stage = p.stageIndex;
      final purchase = shop.buy(p, coins, offer.item.id, random)!;
      p = engine.enter(purchase.progress);
      coins -= purchase.price;
      spent += purchase.price;
      bought++;
      record(stage);
    }
  }
  out.totals.add(total);
  out.coinsEarned.add(earned);
  out.coinsSpent.add(spent);
  out.bought.add(bought);
}

String fmt(num n) {
  final s = n.round().toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return out.toString();
}

int quantile(List<int> xs, double q) {
  final sorted = [...xs]..sort();
  return sorted[(q * (sorted.length - 1)).floor()];
}

double mean(List<int> xs) => xs.reduce((a, b) => a + b) / xs.length;

String days(num steps) => (steps / stepsPerDay).toStringAsFixed(1);

void table(Result r) {
  final stages = chapter1.stages;
  print('| # | Etapa | Promedio | Suerte (10%) | Mala suerte (90%) |');
  print('| --- | --- | --- | --- | --- |');
  for (var i = 0; i < stages.length; i++) {
    final xs = r.perStage[i];
    print(
      '| ${i + 1} | ${stages[i].name} | ${fmt(mean(xs))} | '
      '${fmt(quantile(xs, .1))} | ${fmt(quantile(xs, .9))} |',
    );
  }
  print(
    '| | **Capítulo completo** | **${fmt(mean(r.totals))}** | '
    '**${fmt(quantile(r.totals, .1))}** | '
    '**${fmt(quantile(r.totals, .9))}** |',
  );
  print(
    '\nMínimo: ${fmt(r.totals.reduce(min))} pasos. '
    'Máximo: ${fmt(r.totals.reduce(max))} pasos. '
    'Promedio: ${days(mean(r.totals))} días a ${fmt(stepsPerDay)} pasos.',
  );
}

void main(List<String> args) {
  final games = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final seed = args.length > 1 ? int.parse(args[1]) : 2026;

  final walking = Result();
  final buying = Result();
  final random = Random(seed);
  for (var game = 0; game < games; game++) {
    play(random, walking, buy: false);
  }
  final shopRandom = Random(seed);
  for (var game = 0; game < games; game++) {
    play(shopRandom, buying, buy: true);
  }

  print('Simulación: $games partidas, semilla $seed.\n');
  print('### Sin usar la tienda\n');
  table(walking);
  print(
    '\nMonedas ganadas en el capítulo (promedio): '
    '${fmt(mean(walking.coinsEarned))}.\n',
  );

  print('### Comprando todo lo posible en la Tienda del Lobo\n');
  table(buying);
  print(
    '\nMonedas ganadas: ${fmt(mean(buying.coinsEarned))}; gastadas: '
    '${fmt(mean(buying.coinsSpent))}; objetos comprados: '
    '${mean(buying.bought).toStringAsFixed(1)} (promedio).',
  );

  final saved = mean(walking.totals) - mean(buying.totals);
  print(
    '\n**Ahorro de quien compra todo:** ${fmt(saved)} pasos '
    '(${days(saved)} días, '
    '${(100 * saved / mean(walking.totals)).toStringAsFixed(0)}% del '
    'capítulo).',
  );
  for (var i = 0; i < chapter1.stages.length; i++) {
    final a = mean(walking.perStage[i]);
    final b = mean(buying.perStage[i]);
    print(
      '- ${chapter1.stages[i].name}: ${fmt(a)} → ${fmt(b)} '
      '(${(100 * (a - b) / a).toStringAsFixed(0)}% menos)',
    );
  }
}
