/// Cifras del juego. Para ajustar el juego, cambiar los números acá.
/// Los objetos son una propuesta (ver docs/diseno.md): se pueden cambiar
/// nombres y pasos libremente, siempre que el último objeto de cada etapa
/// quede en la meta de la etapa (lo verifica test/data/chapter1_test.dart).
///
/// Ojo: los `id` se guardan en el celular. Si se cambia un id, los objetos
/// ya conseguidos con el id viejo dejan de reconocerse.
library;

import '../logic/chapter.dart';

/// Pasos que suma el botón de debug.
const int debugStepBonus = 1000;

/// Si una lectura del sensor trae más pasos que esto de golpe, se considera
/// absurda: no se suma y solo se toma como base nueva.
const int maxStepsPerReading = 50000;

const chapter1 = Chapter(
  name: 'Capítulo 1: La pluma del Rocanrón',
  stages: [
    Stage(
      id: 'arbol_magico',
      name: 'El árbol mágico',
      steps: 1000,
      reward: 'Caperuza de aprendiz',
      items: [
        StageItem(
          id: 'hoja_dorada',
          name: 'Hoja dorada del árbol mágico',
          atSteps: 250,
        ),
        StageItem(id: 'mapa_gramonia', name: 'Mapa de Gramonia', atSteps: 500),
        StageItem(
          id: 'farol_luciernagas',
          name: 'Farol de luciérnagas',
          atSteps: 750,
        ),
        StageItem(
          id: 'carta_mision',
          name: 'Carta de la misión del Hada Madrina',
          atSteps: 1000,
        ),
      ],
    ),
    Stage(
      id: 'nido_rocanron',
      name: 'El nido del Rocanrón',
      steps: 4000,
      reward: 'Pluma del Rocanrón',
      items: [
        StageItem(id: 'frutillas', name: 'Frutillas silvestres', atSteps: 500),
        StageItem(id: 'nueces', name: 'Nueces del bosque', atSteps: 1000),
        StageItem(id: 'miel', name: 'Miel de abejas mágicas', atSteps: 1500),
        StageItem(
          id: 'semillas_girasol',
          name: 'Semillas de girasol',
          atSteps: 2000,
        ),
        StageItem(id: 'moras', name: 'Moras azules', atSteps: 2500),
        StageItem(id: 'lombrices', name: 'Lombrices gorditas', atSteps: 3000),
        StageItem(id: 'manzana', name: 'Manzana roja', atSteps: 3500),
        StageItem(
          id: 'pastel_bellotas',
          name: 'Pastel de bellotas',
          atSteps: 4000,
        ),
      ],
    ),
    Stage(
      id: 'laberinto_hormigas',
      name: 'El laberinto de las hormigas',
      steps: 6000,
      reward: 'Salida a la costa',
      items: [
        StageItem(id: 'pieza_hoja', name: 'Pieza de la hoja', atSteps: 1000),
        StageItem(id: 'pieza_gota', name: 'Pieza de la gota', atSteps: 2000),
        StageItem(
          id: 'pieza_piedra',
          name: 'Pieza de la piedra',
          atSteps: 3000,
        ),
        StageItem(id: 'pieza_sol', name: 'Pieza del sol', atSteps: 4000),
        StageItem(id: 'pieza_luna', name: 'Pieza de la luna', atSteps: 5000),
        StageItem(
          id: 'pieza_estrella',
          name: 'Pieza de la estrella',
          atSteps: 6000,
        ),
      ],
    ),
    Stage(
      id: 'puerto',
      name: 'El puerto',
      steps: 3000,
      reward: 'Pista: "los dragones pueden calmarla"',
      items: [
        StageItem(id: 'catalejo', name: 'Catalejo', atSteps: 750),
        StageItem(
          id: 'mapa_corrientes',
          name: 'Mapa de las corrientes',
          atSteps: 1500,
        ),
        StageItem(id: 'bitacora', name: 'Bitácora del capitán', atSteps: 2250),
        StageItem(
          id: 'caracola',
          name: 'Caracola que cuenta secretos',
          atSteps: 3000,
        ),
      ],
    ),
    Stage(
      id: 'montana_dragon',
      name: 'La montaña dragón',
      steps: 10000,
      reward: 'Los dragones calman la tormenta',
      items: [
        StageItem(id: 'baston', name: 'Bastón de caminante', atSteps: 1250),
        StageItem(id: 'bufanda', name: 'Bufanda abrigada', atSteps: 2500),
        StageItem(id: 'piedra_fuego', name: 'Piedra de fuego', atSteps: 3750),
        StageItem(
          id: 'agua_cascada',
          name: 'Agua de la cascada',
          atSteps: 5000,
        ),
        StageItem(id: 'escama', name: 'Escama brillante', atSteps: 6250),
        StageItem(id: 'flor_nubes', name: 'Flor de las nubes', atSteps: 7500),
        StageItem(
          id: 'campana_viento',
          name: 'Campana de viento',
          atSteps: 8750,
        ),
        StageItem(
          id: 'cuerno_dragones',
          name: 'Cuerno de los dragones',
          atSteps: 10000,
        ),
      ],
    ),
    Stage(
      id: 'casa_papa',
      name: 'La casa de papá Caperucita',
      steps: 2000,
      reward: 'Mochila con insumos',
      items: [
        StageItem(id: 'lena', name: 'Leña para la chimenea', atSteps: 500),
        StageItem(id: 'pan', name: 'Pan casero', atSteps: 1000),
        StageItem(id: 'mermelada', name: 'Frasco de mermelada', atSteps: 1500),
        StageItem(
          id: 'foto_familia',
          name: 'Foto de la familia',
          atSteps: 2000,
        ),
      ],
    ),
    Stage(
      id: 'barco',
      name: 'El barco',
      steps: 4000,
      reward: 'El barco zarpa',
      items: [
        StageItem(id: 'vela', name: 'Vela remendada', atSteps: 500),
        StageItem(id: 'cuerdas', name: 'Cuerdas de marinero', atSteps: 1000),
        StageItem(id: 'timon', name: 'Timón', atSteps: 1500),
        StageItem(
          id: 'barril_agua',
          name: 'Barril de agua dulce',
          atSteps: 2000,
        ),
        StageItem(id: 'galletas', name: 'Galletas marineras', atSteps: 2500),
        StageItem(id: 'ancla', name: 'Ancla', atSteps: 3000),
        StageItem(id: 'brujula', name: 'Brújula', atSteps: 3500),
        StageItem(id: 'bandera', name: 'Bandera pirata', atSteps: 4000),
      ],
    ),
  ],
);
