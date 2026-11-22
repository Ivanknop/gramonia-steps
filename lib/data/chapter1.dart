/// Cifras y textos del Capítulo 1. Para ajustar el juego, cambiar acá.
///
/// - Las reglas están en docs/diseno.md. Si se cambian números, repetir la
///   simulación: `dart run tool/simulate.dart`.
/// - Los `id` se guardan en el celular: no cambiarlos sin migrar la partida.
/// - test/data/chapter1_test.dart verifica que todo lo que pide cada etapa
///   tenga una forma de aparecer y que no falte ningún texto.
library;

import '../logic/chapter.dart';

/// Pasos que suma el botón de debug.
const int debugStepBonus = 1000;

/// Si una lectura del sensor trae más pasos que esto de golpe, se considera
/// absurda: no se suma y solo se toma como base nueva.
const int maxStepsPerReading = 50000;

const _ofrendas = ['piedra_fuego', 'agua_cascada', 'escama', 'flor_nubes'];
const _bienes = ['madera', 'clavos', 'cuerdas', 'bandera', 'ancla'];

const chapter1 = Chapter(
  name: 'Capítulo 1: La pluma del Rocanrón',
  items: [
    // Etapa 1.
    ItemType(
      id: 'flor_lila',
      name: 'Flor lila',
      message: '¡Encontraste una flor lila! Huele a lavanda y a aventura.',
    ),
    // Etapa 2.
    ItemType(
      id: 'semilla_fuego',
      name: 'Semilla de fuego',
      message: '¡Una semilla de fuego! Está tibia y brilla como una brasa.',
    ),
    ItemType(
      id: 'semilla_agua',
      name: 'Semilla de agua',
      message:
          'Encontraste una semilla de agua. Hace glu glu cuando la sacudís.',
    ),
    ItemType(
      id: 'semilla_hielo',
      name: 'Semilla de hielo',
      message: 'Encontraste una semilla de hielo. ¡Está fresquita!',
    ),
    // Etapa 3.
    ItemType(
      id: 'pieza_hoja',
      name: 'Pieza de la hoja',
      message: 'Debajo de una hoja gigante aparece una pieza del acertijo.',
    ),
    ItemType(
      id: 'pieza_gota',
      name: 'Pieza de la gota',
      message: 'Una gota de rocío guardaba otra pieza del acertijo.',
    ),
    ItemType(
      id: 'pieza_piedra',
      name: 'Pieza de la piedra',
      message: 'Detrás de una piedra con musgo, una pieza te guiña un ojo.',
    ),
    ItemType(
      id: 'pieza_sol',
      name: 'Pieza del sol',
      message: 'Un rayo de sol ilumina una pieza dorada entre los yuyos.',
    ),
    ItemType(
      id: 'pieza_luna',
      name: 'Pieza de la luna',
      message: 'Una hormiga trae en la espalda una pieza con forma de luna.',
    ),
    ItemType(
      id: 'pieza_estrella',
      name: 'Pieza de la estrella',
      message: '¡Una pieza con forma de estrella! Brilla en tu mano.',
    ),
    // Etapa 4.
    ItemType(
      id: 'pista',
      name: 'Pista del viejo marinero',
      message:
          'Un viejo marinero te cuenta un secreto al oído: «Solo los dragones '
          'de la montaña pueden calmar esta tormenta».',
    ),
    // Etapa 5.
    ItemType(
      id: 'gema',
      name: 'Gema preciosa',
      message: 'Una gema preciosa: brilla de todos los colores.',
      notify: false,
    ),
    ItemType(
      id: 'piedra_fuego',
      name: 'Piedra de fuego',
      message: 'Encontraste una piedra de fuego, calentita como un abrazo de dragón.',
    ),
    ItemType(
      id: 'agua_cascada',
      name: 'Agua de la cascada',
      message: 'Llenaste un frasco con agua de la cascada que canta.',
    ),
    ItemType(
      id: 'escama',
      name: 'Escama brillante',
      message: 'Una escama brillante cae del cielo. ¿Será de un dragón bebé?',
    ),
    ItemType(
      id: 'flor_nubes',
      name: 'Flor de las nubes',
      message: 'Entre las nubes crece una flor blanca y suave: ¡la flor de las nubes!',
    ),
    // Etapa 6.
    ItemType(
      id: 'farol_luciernagas',
      name: 'Farol de luciérnagas',
      message: 'Papá te presta su farol de luciérnagas, para las noches en alta mar.',
    ),
    ItemType(
      id: 'manta',
      name: 'Manta tejida',
      message: 'Una manta tejida, abrigada y con olor a casa.',
    ),
    ItemType(
      id: 'pan',
      name: 'Pan casero',
      message: 'Pan casero recién horneado, ¡crujiente!',
    ),
    ItemType(
      id: 'mermelada',
      name: 'Frasco de mermelada',
      message: 'Un frasco de mermelada de frutillas, la favorita de papá.',
    ),
    // Etapa 7.
    ItemType(
      id: 'madera',
      name: 'Madera',
      message: 'Encontraste tablas de madera para arreglar el casco.',
    ),
    ItemType(
      id: 'clavos',
      name: 'Clavos',
      message: 'Un puñado de clavos brillantes. ¡Toc, toc, toc!',
    ),
    ItemType(
      id: 'cuerdas',
      name: 'Cuerdas',
      message: 'Cuerdas de marinero, fuertes como trenzas de gigante.',
    ),
    ItemType(
      id: 'bandera',
      name: 'Bandera pirata',
      message: '¡Una bandera pirata! Flamea con el viento.',
    ),
    ItemType(
      id: 'ancla',
      name: 'Ancla',
      message: 'Un ancla pesada, para que el barco no se escape.',
    ),
    ItemType(
      id: 'moneda_oro',
      name: 'Moneda de oro',
      message: '¡Una moneda de oro! Suena tilín al caer en el bolsillo.',
    ),
  ],
  stages: [
    Stage(
      id: 'casa_abuelita',
      background: 'assets/backgrounds/stage_1.webp',
      name: 'Salir de la casa de la abuelita',
      intro:
          'Una mañana, una mariposa trae un mensaje del Hada Madrina: hay que '
          'llevar una pluma del Rocanrón hasta la Isla Negra para calmar la '
          'furia de Mututu. Pero antes de salir, la abuelita quiere tejerte una '
          'caperuza de aprendiz. Para teñirla de lila necesita 15 flores lilas '
          'del jardín.',
      requirements: [Requirement('flor_lila', 15)],
      spawns: [
        RandomSpawn(items: ['flor_lila'], every: 50, oneIn: 10),
      ],
      reward: 'Caperuza de aprendiz',
      completeMessage:
          'La abuelita tiñe la lana con las flores y teje toda la noche. ¡Ya '
          'tenés tu Caperuza de aprendiz! Es hora de salir al bosque.',
    ),
    Stage(
      id: 'nido_rocanron',
      background: 'assets/backgrounds/stage_2.webp',
      name: 'El nido del Rocanrón',
      intro:
          'En lo más alto del bosque vive el Rocanrón, un pájaro enorme que '
          'canta como una guitarra eléctrica. Te va a regalar una pluma si le '
          'llevás 3 semillas de fuego, su comida favorita. Son muy difíciles de '
          'encontrar… pero dicen que 10 semillas de agua o de hielo, juntas, se '
          'pueden convertir en una de fuego.',
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
          message:
              '¡Las 10 semillas de agua y de hielo giran en un remolino… y se '
              'encienden! Ahora tenés una semilla de fuego.',
        ),
      ],
      reward: 'Pluma del Rocanrón',
      completeMessage:
          'El Rocanrón se come las semillas, canta un solo de rock que hace '
          'temblar las hojas y te regala una de sus plumas. ¡Tenés la Pluma del '
          'Rocanrón!',
    ),
    Stage(
      id: 'laberinto_hormigas',
      background: 'assets/backgrounds/stage_3.webp',
      name: 'El laberinto de las hormigas',
      intro:
          'Para salir del bosque hay que cruzar el laberinto de las hormigas '
          'guardianas. Solo dejan pasar a quien arme su acertijo: 6 piezas '
          'escondidas entre los caminos.',
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
      reward: 'Salida a la costa',
      completeMessage:
          'Las hormigas arman el acertijo, aplauden con sus seis patitas y te '
          'muestran la salida. A lo lejos se escucha el mar.',
    ),
    Stage(
      id: 'puerto',
      background: 'assets/backgrounds/stage_4.webp',
      name: 'El puerto',
      travelSteps: 10000,
      travelText:
          'El camino hasta la costa es largo: hay que bajar colinas, cruzar '
          'arroyos y seguir el olor a sal. ¡A caminar!',
      intro:
          'En el puerto hay un problema: una gran tormenta no deja zarpar a '
          'ningún barco. Los marineros dicen que alguien sabe cómo calmarla. '
          'Buscá la pista entre redes, cajones y gaviotas.',
      requirements: [Requirement('pista')],
      spawns: [
        RandomSpawn(items: ['pista'], every: 50, oneIn: 100),
      ],
      reward: 'Pista: "los dragones pueden calmarla"',
      completeMessage:
          'Ya sabés qué hacer: ¡hay que subir a la montaña dragón!',
    ),
    Stage(
      id: 'montana_dragon',
      background: 'assets/backgrounds/stage_5.webp',
      name: 'La montaña dragón',
      travelSteps: 15000,
      travelText:
          'La montaña dragón es altísima. El sendero sube y sube entre piedras '
          'y nubes. Respirá hondo y seguí, paso a paso.',
      intro:
          'En la cima viven los dragones. Van a ayudar a quien les traiga 4 '
          'ofrendas. Por el camino brillan gemas preciosas: los dragones las '
          'aman, y por 100 gemas te dan una ofrenda.',
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
          message:
              'Los dragones cuentan tus 100 gemas, sonríen con todos sus '
              'dientes y te dan a cambio: {item}.',
        ),
      ],
      reward: 'Los dragones calman la tormenta',
      completeMessage:
          'Los dragones reciben las ofrendas, abren sus alas enormes y vuelan '
          'hacia el mar. Con un gran soplido… ¡la tormenta se calma!',
    ),
    Stage(
      id: 'casa_papa',
      background: 'assets/backgrounds/stage_6.webp',
      name: 'La casa de papá Caperucita',
      travelSteps: 5000,
      travelText:
          'Antes de embarcar, vale la pena visitar a papá Caperucita. Su casa '
          'queda del otro lado del valle.',
      intro:
          'Papá Caperucita te recibe con un abrazo de oso. Juntos preparan la '
          'mochila para el viaje: hay que conseguir 4 cosas.',
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
      reward: 'Mochila con insumos',
      completeMessage:
          'La mochila está lista. Papá te da un beso en la frente y te dice: '
          '«Una caperucita no nace, se hace». ¡A buscar el barco!',
    ),
    Stage(
      id: 'barco',
      background: 'assets/backgrounds/stage_7.webp',
      name: 'El barco',
      travelSteps: 5000,
      travelText:
          'De vuelta al puerto. Ahora que la tormenta se calmó, el mar está '
          'tranquilo y brillante.',
      intro:
          'En el muelle espera un barco viejito que necesita arreglos: madera, '
          'clavos, cuerdas, una bandera pirata y un ancla. Si juntás monedas de '
          'oro, el vendedor del puerto te vende lo que falte.',
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
          message:
              'Con 20 monedas de oro, el vendedor del puerto te da: {item}.',
        ),
      ],
      reward: 'El barco zarpa',
      completeMessage:
          'El barco está listo. Suben las velas, flamea la bandera pirata… ¡y '
          'el barco zarpa hacia la Isla Negra! Fin del Capítulo 1.',
    ),
  ],
);
