import 'dart:io';

import 'package:rpg/data/chapter1.dart';
import 'package:rpg/logic/chapter.dart';
import 'package:test/test.dart';

void main() {
  test('el capítulo tiene 8 etapas y empieza por el jardín', () {
    expect(chapter1.stages, hasLength(8));
    expect(chapter1.stages.first.id, 'jardin_abuelita');
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
    // El jardín y la casa de la abuelita comparten fondo; el resto, no.
    expect(backgrounds[0], backgrounds[1]);
    expect(backgrounds.skip(1).toSet(), hasLength(chapter1.stages.length - 1));
    for (final path in backgrounds) {
      expect(File(path).existsSync(), isTrue, reason: path);
      final folder = path.substring(0, path.lastIndexOf('/') + 1);
      expect(pubspec, contains('- $folder'), reason: path);
    }
  });

  test('el fondo de caminata existe y está declarado', () {
    final path = chapter1.walkingBackground;
    expect(File(path).existsSync(), isTrue);
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    expect(File('pubspec.yaml').readAsStringSync(), contains('- $folder'));
  });

  test('cada etapa tiene su lugar', () {
    expect(chapter1.stages.map((s) => s.place), [
      'Aldea de las Caperucitas',
      'Aldea de las Caperucitas',
      'Árbol Mágico',
      'Bosque Mágico',
      'Muelle',
      'Montaña Dragón',
      'Aldea de las Caperucitas',
      'Muelle',
    ]);
  });

  test('todo cambio de lugar es un tramo de caminata', () {
    final stages = chapter1.stages;
    for (var i = 1; i < stages.length; i++) {
      if (stages[i].place != stages[i - 1].place) {
        expect(stages[i].hasTravel, isTrue, reason: stages[i].id);
      }
    }
  });

  test('las animaciones de los diálogos existen', () {
    for (final c in chapter1.characters) {
      // La de caminar todavía no está (se ve el dibujo quieto).
      if (c.id == chapter1.walkingCharacter) continue;
      final path = c.animatedImage;
      if (path != null) expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('ningún texto está vacío', () {
    for (final item in chapter1.items) {
      expect(item.name.trim(), isNotEmpty, reason: item.id);
      expect(item.message.trim(), isNotEmpty, reason: item.id);
      expect(item.foundName.trim(), isNotEmpty, reason: item.id);
    }
    for (final stage in chapter1.stages) {
      expect(stage.name.trim(), isNotEmpty, reason: stage.id);
      expect(stage.intro.trim(), isNotEmpty, reason: stage.id);
      expect(stage.reward.name.trim(), isNotEmpty, reason: stage.id);
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

  test('los ids de las recompensas no se repiten', () {
    final ids = chapter1.stages.map((s) => s.reward.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('los dibujos están en las carpetas declaradas', () {
    for (final item in chapter1.items) {
      expect(item.image, startsWith('assets/items/'), reason: item.id);
    }
    for (final stage in chapter1.stages) {
      expect(stage.reward.image, startsWith('assets/items/'), reason: stage.id);
    }
    for (final c in chapter1.characters) {
      expect(c.image, startsWith('assets/characters/'), reason: c.id);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/items/'));
    expect(pubspec, contains('- assets/characters/'));
  });

  test('los personajes que usan las etapas existen', () {
    expect(
      () => chapter1.character(chapter1.walkingCharacter),
      returnsNormally,
    );
    for (final stage in chapter1.stages) {
      expect(() => chapter1.character(stage.introCharacter), returnsNormally);
      expect(
        () => chapter1.character(stage.completeCharacter),
        returnsNormally,
      );
    }
    final ids = chapter1.characters.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('todos los objetos aparecen en alguna etapa y sirven para algo', () {
    for (final item in chapter1.items) {
      expect(chapter1.stageWhereFound(item.id), isNotNull, reason: item.id);
      expect(chapter1.usesOf(item.id), isNotEmpty, reason: item.id);
    }
  });

  test('para qué sirven las semillas de agua y dónde salen', () {
    expect(chapter1.stageWhereFound('semilla_agua'), 2);
    final use = chapter1.usesOf('semilla_agua').single as TradedIn;
    expect(use.exchange.outputs, ['semilla_fuego']);
    final flor = chapter1.usesOf('flor_lila').single as NeededFor;
    expect(flor.count, 15);
    expect(flor.stage.id, 'casa_abuelita');
    // Las ofrendas salen al azar o por canje: se consiguen en la etapa 6.
    expect(chapter1.stageWhereFound('escama'), 5);
  });

  test('las flores amarillas salen una cada 100 pasos, 15 en total', () {
    final garden = chapter1.stages.first;
    expect(garden.requiredCount('flor_amarilla'), 15);
    final spawn = garden.spawns.single as FixedSpawn;
    expect(spawn.items, ['flor_amarilla']);
    expect(spawn.every, 100);
    expect(garden.introCharacter, 'caperucita_sin_caperuza');
    expect(garden.completeCharacter, 'hada_madrina');
  });
}
