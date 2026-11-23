# Gramonia RPG – Capítulo 1: La pluma del Rocanrón

Diseño del 22 nov 2026 (Iván). Documento vivo: los nombres y números son una propuesta para revisar.

Cambios del 22 nov 2026:
- Se saca el combate. Cada etapa se completa juntando objetos que se consiguen caminando.
- El capítulo pasa a durar unos 100.000 pasos (unas 3 semanas a 4.500 pasos por día). Los objetos aparecen con azar, con objetos fijos, con canjes y con tramos de viaje.

Cambios del 23 nov 2026:
- Nueva etapa 1, **Un paseo por el jardín**: Caperucita, todavía sin caperuza, junta 15 flores amarillas (una fija cada 100 pasos, 1.500 en total). Al terminarla llega la mariposa con el mensaje del Hada Madrina. Las demás etapas corren un número: el capítulo pasa a tener 8.
- Las partidas guardadas antes de este cambio dan el jardín por hecho y siguen en la etapa en que estaban (partida versión 4).
- Dibujos de objetos, recompensas y personajes; cartel grande al encontrar un objeto, bolsa y ventana de fin de etapa (ver "Avisos").

## Resumen

El Capítulo 1 lleva a la jugadora de la casa de la abuelita hasta el barco, en unos 105.000 pasos reales repartidos en 8 etapas.

- **Misión:** el Hada Madrina pide llevar una pluma del Rocanrón hasta la Isla Negra para calmar la furia de Mututu.
- **Recorrido:** jardín de la abuelita → casa de la abuelita → nido del Rocanrón (bosque) → laberinto de las hormigas → puerto en la costa → montaña dragón → casa de papá Caperucita → barco (en el puerto).
- **Cómo se avanza:** cada etapa pide juntar ciertos objetos. Los objetos aparecen mientras se camina: algunos al azar, otros fijos cada tantos pasos, y otros se canjean juntando objetos comunes.
- **Final:** el capítulo termina cuando el barco zarpa. Isla Negra queda para un capítulo posterior.

## Mecánicas

Las mismas reglas sirven para todos los objetos. Solo cambian el objeto y sus números.

- **Aparición al azar (cada K pasos, 1 en N):** cada K pasos se tira un número del 1 al N; si sale 1, aparece el objeto. En promedio aparece uno cada N×K pasos.
- **Garantía de mala suerte:** si pasan 3×N×K pasos sin que el objeto aparezca, en la tirada siguiente sale seguro. El contador vuelve a 0 cada vez que el objeto aparece.
- **Objeto fijo (cada M pasos):** sale uno cada M pasos, sin azar. Si son varios objetos distintos, salen en orden.
- **Canje:** al juntar X objetos comunes, se cambian solos por 1 objeto de la etapa. Si la etapa pide varios objetos distintos, el canje da el primero que falte.
- **Llegar:** algunas etapas empiezan con un tramo de viaje. Durante ese tramo no aparece nada. Los objetos empiezan a aparecer al llegar.
- **Fin de etapa:** cuando se juntan todos los objetos que pide la etapa, se entrega la recompensa y empieza la siguiente.
  - Los pasos que sobran pasan a la etapa siguiente. Un salto grande de pasos puede completar varias etapas de golpe.
  - Un objeto de etapa que ya no hace falta deja de aparecer.
  - Los objetos comunes que sobran quedan en el inventario.
- Después de que el barco zarpa, los pasos se siguen contando en el total, pero ya no hay etapas.
- No hace falta mirar el celular mientras se camina: todo se junta solo y los avisos se ven al abrir la app.

## Etapas del capítulo

| # | Etapa | Llegar | Qué hay que juntar | Cómo aparecen | Recompensa |
| --- | --- | --- | --- | --- | --- |
| 1 | Un paseo por el jardín | — | 15 flores amarillas | Fijas: una cada 100 pasos | Ramo de flores amarillas |
| 2 | Salir de la casa de la abuelita | — | 15 flores lilas | Flor lila: 1 en 10 cada 50 pasos | Caperuza de aprendiz |
| 3 | El nido del Rocanrón | — | 3 semillas de fuego | Semilla de fuego: 1 en 100 cada 200 pasos. Semilla de agua o de hielo: 1 en 10 cada 50 pasos (mitad y mitad). **Canje:** 10 de agua o hielo → 1 de fuego | Pluma del Rocanrón |
| 4 | El laberinto de las hormigas | — | 6 piezas del acertijo | Fijas: una cada 1.000 pasos | Salida a la costa |
| 5 | El puerto | 10.000 | 1 pista | Pista: 1 en 100 cada 50 pasos | Pista: "los dragones pueden calmarla" |
| 6 | La montaña dragón | 15.000 | 4 ofrendas | Ofrenda: 1 en 200 cada 100 pasos. Gema preciosa: fija, una cada 50 pasos. **Canje:** 100 gemas → 1 ofrenda | Los dragones calman la tormenta |
| 7 | La casa de papá Caperucita | 5.000 | 4 objetos para la mochila | Fijos: uno cada 2.000 pasos | Mochila con insumos |
| 8 | El barco (en el puerto) | 5.000 | 5 bienes: madera, clavos, cuerdas, bandera pirata y ancla | Cada bien: 1 en **100** cada 100 pasos. Moneda de oro: 1 en 10 cada 50 pasos. **Canje:** **20** monedas → el bien que falte | El barco zarpa: fin del capítulo |

**Ajuste aprobado en la etapa del barco** (hoy la 8). El pedido original era "cada bien 1 en 1.000" y "200 monedas". Con esos números, el barco solo tarda unos 149.000 pasos en promedio y el capítulo llega a unos 234.000 (ver la simulación). Con "1 en 100" y "20 monedas", el capítulo queda en unos 100.000.

## Pasos por etapa: simulación de 1.000 partidas

Cada número es el total de pasos de la etapa, incluido el tramo de "llegar".
- **Suerte (10%):** solo 1 de cada 10 partidas termina más rápido que esto.
- **Mala suerte (90%):** 9 de cada 10 partidas terminan antes que esto.

**Reglas actuales (bienes 1 en 100, 20 monedas), con el motor real del juego:**

| # | Etapa | Promedio | Suerte (10%) | Mala suerte (90%) |
| --- | --- | --- | --- | --- |
| 1 | Un paseo por el jardín | 1.500 | 1.500 | 1.500 |
| 2 | Salir de la casa de la abuelita | 7.194 | 5.250 | 9.200 |
| 3 | El nido del Rocanrón | 11.931 | 7.800 | 15.700 |
| 4 | El laberinto de las hormigas | 6.000 | 6.000 | 6.000 |
| 5 | El puerto | 14.906 | 10.550 | 22.050 |
| 6 | La montaña dragón | 31.378 | 25.400 | 35.000 |
| 7 | La casa de papá Caperucita | 13.000 | 13.000 | 13.000 |
| 8 | El barco | 19.166 | 13.200 | 26.100 |
| | **Capítulo completo** | **105.076** | **95.050** | **115.450** |

A 4.500 pasos por día, son unos 23 días en promedio: entre 21 y 26 días en 8 de cada 10 partidas. La partida más corta de la simulación fue de 84.300 pasos y la más larga de 137.150.

**Con los números originales (bienes 1 en 1.000, 200 monedas), simulación preliminar** (antes de sumar el jardín; las etapas tienen la numeración vieja):

| # | Etapa | Promedio | Suerte (10%) | Mala suerte (90%) |
| --- | --- | --- | --- | --- |
| 1 | Casa de la abuelita | 7.161 | 5.250 | 9.200 |
| 2 | Nido del Rocanrón | 12.086 | 7.800 | 16.100 |
| 3 | Laberinto de las hormigas | 6.000 | 6.000 | 6.000 |
| 4 | El puerto | 14.875 | 10.600 | 22.000 |
| 5 | Montaña dragón | 31.409 | 25.700 | 35.000 |
| 6 | Casa de papá Caperucita | 13.000 | 13.000 | 13.000 |
| 7 | El barco | 149.286 | 93.600 | 205.250 |
| | **Capítulo completo** | **233.817** | **176.000** | **291.700** |

**Por qué el barco tardaba tanto:** con 1 en 1.000 cada 100 pasos, cada bien sale en promedio cada 100.000 pasos. Una compra con 200 monedas también cuesta unos 100.000 pasos (una moneda cada 500). Los primeros bienes salen rápido, pero los últimos tardan cada vez más.

**Notas de la simulación**
- La tabla de las reglas actuales sale del motor real del juego: `dart run tool/simulate.dart` (1.000 partidas, semilla 2026). Hay que repetirla cada vez que se cambien números en `lib/data/chapter1.dart`.
- La tabla de los números originales salió de un script preliminar en Python, antes de programar el juego. Con el ajuste, ese script daba casi lo mismo que el motor real (103.509 contra 103.576).
- Un test (`test/logic/chapter_engine_test.dart`) verifica que 300 partidas promedien entre 90.000 y 120.000 pasos. Si un cambio de números rompe el balance, el test avisa.
- En la montaña dragón, la mala suerte (90%) da justo 35.000: es el tope que ponen las gemas. Con una gema cada 50 pasos, 100 gemas son 5.000 pasos por ofrenda. Por eso las 4 ofrendas nunca tardan más de 20.000 pasos después de llegar.

## Avisos

- **Al conseguir un objeto** (o recibirlo por un canje): aparece grande en el centro con "¡Encontraste …!". A los 1,6 segundos, o al tocarlo, vuela hasta la bolsa, que rebota y suma al número de nuevos.
- **Muchos objetos de golpe** (por ejemplo, al abrir la app después de caminar mucho): un cartel por tipo de objeto ("×15"), como mucho 3. Primero van los que pide la etapa; el resto va directo a la bolsa.
- **Gemas preciosas:** salen cada 50 pasos, así que no tienen cartel ni suman al número de la bolsa.
- **Fin de etapa:** una ventana con el personaje, la recompensa en grande y el texto final. Si la etapa siguiente es en otro lugar y no tiene tramo de "llegar", después viene la pantalla "Caminando hasta …".
- **Llegada** al final de un tramo de viaje: aviso chico abajo.

## Bolsa

Todo lo conseguido en el capítulo, con la cantidad total (aunque se haya canjeado), y las recompensas aparte. Al tocar un objeto se ve grande, con para qué sirve y en qué etapa se consigue.

## Más adelante

- **Monedas y tienda:** vuelven en una etapa posterior. Las monedas se ganan caminando y en la tienda se compran mejoras que ayudan a conseguir más objetos. Las monedas de oro de la etapa del barco son parte de esa etapa.
- **Experiencia y niveles:** quedan para más adelante, si suman al juego.
- **Laberinto con caminos:** la idea original de elegir un camino y resolver el acertijo de las hormigas (si se falla, el camino suma pasos) puede volver como mejora de la etapa del laberinto.

## Personajes y objetos clave

Personajes:

- **La jugadora (Caperucita):** aprendiz de Caperucita Pirata. Empieza sin caperuza.
- **La abuelita:** teje la caperuza de aprendiz antes del viaje.
- **Hada Madrina:** vive en el árbol mágico, en el centro del mapa. Manda la misión.
- **Rocanrón:** dueño de la pluma que puede calmar a Mututu. Come semillas de fuego.
- **Hormigas guardianas:** custodian el laberinto del bosque mágico.
- **Dragones:** viven en la montaña dragón; con sus alas enormes pueden calmar la tormenta. Aman las gemas preciosas.
- **Papá Caperucita:** ayuda a preparar la mochila antes del viaje.
- **Mututu:** está furioso en la Isla Negra y su furia causa la gran tormenta. No aparece en este capítulo.

Objetos de misión:

- **Pluma del Rocanrón:** el objetivo de todo el viaje.
- **Mochila con insumos:** lo necesario para el viaje en barco.
- **El barco:** destraba el mar y el próximo capítulo.

La caperuza de Caperucita Pirata no se consigue en este capítulo: se gana al final de la saga ("una caperucita no nace, se hace").
