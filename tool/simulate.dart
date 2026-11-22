// Simula muchas partidas del Capítulo 1 con el motor real del juego.
//
// Uso: dart run tool/simulate.dart [partidas] [semilla]
// Imprime una tabla en Markdown para pegar en docs/diseno.md.
// Es una herramienta de terminal: imprimir es lo que tiene que hacer.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter_engine.dart';
import 'package:rpg/logic/chapter_progress.dart';

void main(List<String> args) {
  final games = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final seed = args.length > 1 ? int.parse(args[1]) : 2026;
  const engine = ChapterEngine(chapter1);
  final random = Random(seed);
  final stages = chapter1.stages;

  // Todas las tiradas y tramos son múltiplos de 50: avanzar de a 50 es exacto.
  const tick = 50;
  final perStage = [for (final _ in stages) <int>[]];
  final totals = <int>[];

  for (var game = 0; game < games; game++) {
    var p = const ChapterProgress.initial();
    var total = 0;
    var inStage = 0;
    while (!engine.isFinished(p)) {
      final before = p.stageIndex;
      p = engine.advance(p, tick, random).progress;
      total += tick;
      inStage += tick;
      if (p.stageIndex != before) {
        perStage[before].add(inStage - p.stepsInStage);
        inStage = p.stepsInStage;
      }
    }
    totals.add(total);
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

  print('Simulación: $games partidas, semilla $seed.\n');
  print('| # | Etapa | Promedio | Suerte (10%) | Mala suerte (90%) |');
  print('| --- | --- | --- | --- | --- |');
  for (var i = 0; i < stages.length; i++) {
    final xs = perStage[i];
    print(
      '| ${i + 1} | ${stages[i].name} | ${fmt(mean(xs))} | '
      '${fmt(quantile(xs, .1))} | ${fmt(quantile(xs, .9))} |',
    );
  }
  print(
    '| | **Capítulo completo** | **${fmt(mean(totals))}** | '
    '**${fmt(quantile(totals, .1))}** | **${fmt(quantile(totals, .9))}** |',
  );
  print(
    '\nMínimo: ${fmt(totals.reduce(min))} pasos. '
    'Máximo: ${fmt(totals.reduce(max))} pasos.',
  );
}
