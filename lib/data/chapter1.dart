/// Cifras del Capítulo 1. Para ajustar el juego, cambiar acá.
///
/// - Los textos están en lib/data/textos.dart.
/// - Las reglas están en docs/diseno.md. Si se cambian números, repetir la
///   simulación: `dart run tool/simulate.dart`.
/// - Los `id` se guardan en el celular: no cambiarlos sin migrar la partida.
/// - test/data/chapter1_test.dart verifica que todo lo que pide cada etapa
///   tenga una forma de aparecer y que no falte ningún texto.
library;

import '../logic/chapter.dart';
import 'textos.dart' as t;

/// Pasos que suma el botón de debug.
const int debugStepBonus = 1000;

/// Si una lectura del sensor trae más pasos que esto de golpe, se considera
/// absurda: no se suma y solo se toma como base nueva.
const int maxStepsPerReading = 50000;

const _ofrendas = ['piedra_fuego', 'agua_cascada', 'escama', 'flor_nubes'];
const _bienes = ['madera', 'clavos', 'cuerdas', 'bandera', 'ancla'];

const chapter1 = Chapter(
  name: t.capitulo1,
  walkingBackground: 'assets/backgrounds/walking.webp',
  walkingCharacter: 'caperucita_espalda',
  characters: [
    Character(id: 'caperucita_sin_caperuza', name: t.sofia),
    // Sofía saluda en los diálogos.
    Character(id: 'caperucita', name: t.sofia, animation: 'caperucita_animada'),
    // Sofía caminando, en los tramos de caminata.
    Character(
      id: 'caperucita_espalda',
      name: t.sofia,
      animation: 'sofia_caminando',
    ),
    Character(
      id: 'hada_madrina',
      name: t.hadaMadrina,
      animation: 'hada_madrina_animada',
    ),
    Character(id: 'rocanon', name: t.rocanon, animation: 'rocanon_animado'),
    Character(id: 'hormigas', name: t.hormigas),
    Character(id: 'dragones', name: t.dragones),
    Character(id: 'papa_caperucita', name: t.papa),
  ],
  items: [
    // Etapa 1.
    ItemType(id: 'flor_amarilla', texto: t.florAmarilla),
    // Etapa 2.
    ItemType(id: 'flor_lila', texto: t.florLila),
    // Etapa 3.
    ItemType(id: 'semilla_fuego', texto: t.semillaFuego),
    ItemType(id: 'semilla_agua', texto: t.semillaAgua),
    ItemType(id: 'semilla_hielo', texto: t.semillaHielo),
    // Etapa 4.
    ItemType(id: 'pieza_hoja', texto: t.piezaHoja),
    ItemType(id: 'pieza_gota', texto: t.piezaGota),
    ItemType(id: 'pieza_piedra', texto: t.piezaPiedra),
    ItemType(id: 'pieza_sol', texto: t.piezaSol),
    ItemType(id: 'pieza_luna', texto: t.piezaLuna),
    ItemType(id: 'pieza_estrella', texto: t.piezaEstrella),
    // Etapa 5.
    ItemType(id: 'pista', texto: t.pista),
    // Etapa 6.
    ItemType(id: 'gema', texto: t.gema, notify: false),
    ItemType(id: 'piedra_fuego', texto: t.piedraFuego),
    ItemType(id: 'agua_cascada', texto: t.aguaCascada),
    ItemType(id: 'escama', texto: t.escama),
    ItemType(id: 'flor_nubes', texto: t.florNubes),
    // Etapa 7.
    ItemType(id: 'farol_luciernagas', texto: t.farol),
    ItemType(id: 'manta', texto: t.manta),
    ItemType(id: 'pan', texto: t.pan),
    ItemType(id: 'mermelada', texto: t.mermelada),
    // Etapa 8.
    ItemType(id: 'madera', texto: t.madera),
    ItemType(id: 'clavos', texto: t.clavos),
    ItemType(id: 'cuerdas', texto: t.cuerdas),
    ItemType(id: 'bandera', texto: t.bandera),
    ItemType(id: 'ancla', texto: t.ancla),
    ItemType(id: 'moneda_oro', texto: t.monedaOro),
  ],
  stages: [
    Stage(
      id: 'jardin_abuelita',
      texto: t.jardin,
      introCharacter: 'caperucita_sin_caperuza',
      completeCharacter: 'hada_madrina',
      background: 'assets/backgrounds/stage_1.webp',
      requirements: [Requirement('flor_amarilla', 15)],
      spawns: [
        FixedSpawn(items: ['flor_amarilla'], every: 100),
      ],
      reward: Reward(id: 'ramo_flores', name: t.recompensaJardin),
    ),
    Stage(
      id: 'casa_abuelita',
      texto: t.caperuza,
      introCharacter: 'caperucita_sin_caperuza',
      completeCharacter: 'caperucita',
      background: 'assets/backgrounds/stage_1.webp',
      requirements: [Requirement('flor_lila', 15)],
      spawns: [
        RandomSpawn(items: ['flor_lila'], every: 50, oneIn: 10),
      ],
      reward: Reward(id: 'caperuza_aprendiz', name: t.recompensaCaperuza),
    ),
    Stage(
      // El id conserva la grafía vieja: se guarda en el celular.
      id: 'nido_rocanron',
      texto: t.nido,
      introCharacter: 'rocanon',
      completeCharacter: 'rocanon',
      background: 'assets/backgrounds/stage_2.webp',
      travelSteps: 3000,
      requirements: [Requirement('semilla_fuego', 3)],
      spawns: [
        RandomSpawn(items: ['semilla_fuego'], every: 200, oneIn: 100),
        RandomSpawn(
          items: ['semilla_agua', 'semilla_hielo'],
          every: 50,
          oneIn: 10,
        ),
      ],
      exchanges: [
        Exchange(
          inputs: ['semilla_agua', 'semilla_hielo'],
          count: 10,
          outputs: ['semilla_fuego'],
          message: t.canjeSemillas,
        ),
      ],
      reward: Reward(id: 'pluma_rocanon', name: t.recompensaNido),
    ),
    Stage(
      id: 'laberinto_hormigas',
      texto: t.laberinto,
      introCharacter: 'hormigas',
      completeCharacter: 'hormigas',
      background: 'assets/backgrounds/stage_3.webp',
      travelSteps: 2000,
      requirements: [
        Requirement('pieza_hoja'),
        Requirement('pieza_gota'),
        Requirement('pieza_piedra'),
        Requirement('pieza_sol'),
        Requirement('pieza_luna'),
        Requirement('pieza_estrella'),
      ],
      spawns: [
        FixedSpawn(
          items: [
            'pieza_hoja',
            'pieza_gota',
            'pieza_piedra',
            'pieza_sol',
            'pieza_luna',
            'pieza_estrella',
          ],
          every: 1000,
        ),
      ],
      reward: Reward(id: 'salida_costa', name: t.recompensaLaberinto),
    ),
    Stage(
      id: 'puerto',
      texto: t.puerto,
      introCharacter: 'caperucita',
      completeCharacter: 'caperucita',
      background: 'assets/backgrounds/stage_4.webp',
      travelSteps: 10000,
      requirements: [Requirement('pista')],
      spawns: [
        RandomSpawn(items: ['pista'], every: 50, oneIn: 100),
      ],
      reward: Reward(
        id: 'pista_dragones',
        name: t.recompensaPuerto,
        // Mismo dibujo que la pista del marinero.
        image: 'assets/items/pista.webp',
      ),
    ),
    Stage(
      id: 'montana_dragon',
      texto: t.montana,
      introCharacter: 'dragones',
      completeCharacter: 'dragones',
      background: 'assets/backgrounds/stage_5.webp',
      travelSteps: 15000,
      requirements: [
        Requirement('piedra_fuego'),
        Requirement('agua_cascada'),
        Requirement('escama'),
        Requirement('flor_nubes'),
      ],
      spawns: [
        RandomSpawn(items: _ofrendas, every: 100, oneIn: 200),
        FixedSpawn(items: ['gema'], every: 50),
      ],
      exchanges: [
        Exchange(
          inputs: ['gema'],
          count: 100,
          outputs: _ofrendas,
          message: t.canjeGemas,
        ),
      ],
      reward: Reward(id: 'tormenta_calmada', name: t.recompensaMontana),
    ),
    Stage(
      id: 'casa_papa',
      texto: t.casaPapa,
      introCharacter: 'papa_caperucita',
      completeCharacter: 'papa_caperucita',
      background: 'assets/backgrounds/stage_6.webp',
      travelSteps: 5000,
      requirements: [
        Requirement('farol_luciernagas'),
        Requirement('manta'),
        Requirement('pan'),
        Requirement('mermelada'),
      ],
      spawns: [
        FixedSpawn(
          items: ['farol_luciernagas', 'manta', 'pan', 'mermelada'],
          every: 2000,
        ),
      ],
      reward: Reward(id: 'mochila', name: t.recompensaCasaPapa),
    ),
    Stage(
      id: 'barco',
      texto: t.barco,
      introCharacter: 'caperucita',
      completeCharacter: 'hada_madrina',
      background: 'assets/backgrounds/stage_7.webp',
      travelSteps: 5000,
      requirements: [
        Requirement('madera'),
        Requirement('clavos'),
        Requirement('cuerdas'),
        Requirement('bandera'),
        Requirement('ancla'),
      ],
      spawns: [
        RandomSpawn(items: ['madera'], every: 100, oneIn: 100),
        RandomSpawn(items: ['clavos'], every: 100, oneIn: 100),
        RandomSpawn(items: ['cuerdas'], every: 100, oneIn: 100),
        RandomSpawn(items: ['bandera'], every: 100, oneIn: 100),
        RandomSpawn(items: ['ancla'], every: 100, oneIn: 100),
        RandomSpawn(items: ['moneda_oro'], every: 50, oneIn: 10),
      ],
      exchanges: [
        Exchange(
          inputs: ['moneda_oro'],
          count: 20,
          outputs: _bienes,
          message: t.canjeMonedas,
        ),
      ],
      reward: Reward(id: 'barco_zarpa', name: t.recompensaBarco),
    ),
  ],
);
