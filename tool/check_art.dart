// Compara los dibujos de assets/ con los que pide lib/data/chapter1.dart.
//
//     dart run tool/check_art.dart
//
// Lista los que faltan (la app muestra un ícono genérico) y los que sobran
// (están en assets/ pero ningún dato los usa).

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

  final present = <String>{
    for (final dir in ['assets/items', 'assets/characters'])
      if (Directory(dir).existsSync())
        for (final f in Directory(dir).listSync().whereType<File>())
          f.path.replaceAll(r'\', '/'),
  };

  final missing = wanted.keys.where((path) => !present.contains(path)).toList()
    ..sort();
  final extra = present.where((path) => !wanted.containsKey(path)).toList()
    ..sort();

  print('Dibujos que usa el juego: ${wanted.length}');
  print('');
  print('Faltan (${missing.length}):');
  for (final path in missing) {
    print('  - $path  ← ${wanted[path]}');
  }
  print('');
  print('Sobran (${extra.length}):');
  for (final path in extra) {
    print('  - $path');
  }
}
