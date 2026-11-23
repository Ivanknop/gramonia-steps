// Compara los dibujos de assets/ con los que pide lib/data/chapter1.dart.
//
//     dart run tool/check_art.dart
//
// Lista los que faltan (la app muestra un ícono genérico) y los que sobran
// (están en assets/ pero ningún dato los usa). Aparte, las animaciones y las
// pantallas de llegada que todavía no están (son opcionales: sin ellas se ve
// el dibujo quieto o el fondo de la etapa).

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:rpg/data/chapter1.dart';

void main() {
  final wanted = <String, String>{
    for (final item in chapter1.items) item.image: 'objeto ${item.id}',
    for (final (i, stage) in chapter1.stages.indexed)
      stage.reward.image:
          'recompensa de la etapa ${i + 1} (${stage.reward.id})',
    for (final c in chapter1.characters) c.image: 'personaje ${c.id}',
  };

  final optional = <String, String>{
    for (final c in chapter1.characters)
      ?c.animatedImage:
          'animación de ${c.id} (arte/personajes/${c.animation}.gif)',
    for (final stage in chapter1.stages)
      if (stage.hasTravel)
        stage.arrivalImage:
            'llegada a ${stage.place} (arte/lugares/${stage.id}.gif)',
  };

  final present = <String>{
    for (final dir in ['assets/items', 'assets/characters', 'assets/places'])
      if (Directory(dir).existsSync())
        for (final f in Directory(dir).listSync().whereType<File>())
          f.path.replaceAll(r'\', '/'),
  };

  final missing = wanted.keys.where((path) => !present.contains(path)).toList()
    ..sort();
  final extra =
      present
          .where((p) => !wanted.containsKey(p) && !optional.containsKey(p))
          .where((p) => !p.split('/').last.startsWith('.'))
          .toList()
        ..sort();
  final optionalMissing =
      optional.keys.where((path) => !present.contains(path)).toList()..sort();

  print('Dibujos que usa el juego: ${wanted.length}');
  print('');
  print('Faltan (${missing.length}):');
  for (final path in missing) {
    print('  - $path  ← ${wanted[path]}');
  }
  print('');
  print('Opcionales que todavía no están (${optionalMissing.length}):');
  for (final path in optionalMissing) {
    print('  - $path  ← ${optional[path]}');
  }
  print('');
  print('Sobran (${extra.length}):');
  for (final path in extra) {
    print('  - $path');
  }
}
