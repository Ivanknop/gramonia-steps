import 'dart:io';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:test/test.dart';

void main() {
  test('el capítulo tiene 7 etapas', () {
    expect(chapter1.stages, hasLength(7));
  });

  test('los ids de etapas y objetos no se repiten', () {
    final stageIds = chapter1.stages.map((s) => s.id).toList();
    expect(stageIds.toSet(), hasLength(stageIds.length));
    final itemIds = chapter1.items.map((i) => i.id).toList();
    expect(itemIds.toSet(), hasLength(itemIds.length));
  });

  test('cada etapa tiene su fondo, el archivo existe y está declarado', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final backgrounds = chapter1.stages.map((s) => s.background).toList();
    expect(backgrounds.toSet(), hasLength(chapter1.stages.length));
    for (final path in backgrounds) {
      expect(File(path).existsSync(), isTrue, reason: path);
      final folder = path.substring(0, path.lastIndexOf('/') + 1);
      expect(pubspec, contains('- $folder'), reason: path);
    }
  });

  test('ningún texto está vacío', () {
    for (final item in chapter1.items) {
      expect(item.name.trim(), isNotEmpty, reason: item.id);
      expect(item.message.trim(), isNotEmpty, reason: item.id);
    }
    for (final stage in chapter1.stages) {
      expect(stage.name.trim(), isNotEmpty, reason: stage.id);
      expect(stage.intro.trim(), isNotEmpty, reason: stage.id);
      expect(stage.reward.trim(), isNotEmpty, reason: stage.id);
      expect(stage.completeMessage.trim(), isNotEmpty, reason: stage.id);
      if (stage.hasTravel) {
        expect(stage.travelText.trim(), isNotEmpty, reason: stage.id);
      }
      for (final e in stage.exchanges) {
        expect(e.message.trim(), isNotEmpty, reason: stage.id);
      }
    }
  });

  for (final stage in chapter1.stages) {
    group(stage.name, () {
      test('todos los objetos que usa existen', () {
        final ids = [
          for (final r in stage.requirements) r.item,
          for (final s in stage.spawns) ...s.items,
          for (final e in stage.exchanges) ...[...e.inputs, ...e.outputs],
        ];
        for (final id in ids) {
          expect(() => chapter1.item(id), returnsNormally, reason: id);
        }
      });

      test('todo lo que pide tiene una forma de aparecer', () {
        for (final r in stage.requirements) {
          final appears =
              stage.spawns.any((s) => s.items.contains(r.item)) ||
              stage.exchanges.any((e) => e.outputs.contains(r.item));
          expect(appears, isTrue, reason: r.item);
          expect(r.count, greaterThan(0), reason: r.item);
        }
      });

      test('cada aparición es toda de objetos pedidos o toda de comunes', () {
        for (final s in stage.spawns) {
          final required = s.items.where(stage.isRequired).length;
          expect(
            required == 0 || required == s.items.length,
            isTrue,
            reason: s.key,
          );
          expect(s.every, greaterThan(0), reason: s.key);
          if (s is RandomSpawn) expect(s.oneIn, greaterThan(0), reason: s.key);
        }
        final keys = stage.spawns.map((s) => s.key).toList();
        expect(keys.toSet(), hasLength(keys.length));
      });

      test('los canjes dan objetos que pide la etapa', () {
        for (final e in stage.exchanges) {
          expect(e.outputs.every(stage.isRequired), isTrue);
          expect(e.count, greaterThan(0));
          if (e.outputs.length > 1) expect(e.message, contains('{item}'));
        }
      });
    });
  }
}
