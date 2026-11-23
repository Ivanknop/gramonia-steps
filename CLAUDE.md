# Gramonia RPG

RPG de caminata para Android, ambientado en Gramonia (los Cuentos de Gramonia, de Iván y su hija Regi). Se avanza caminando en la vida real. Gratis, sin fines comerciales. Es la primera app Android de Iván: explicá los pasos en español simple.

El diseño completo del Capítulo 1 está en `docs/diseno.md`. Ante una duda de reglas del juego, ese archivo manda.

## Stack y entorno

- Flutter (Dart) + Android SDK de línea de comandos + JDK 17, dentro del devcontainer de `.devcontainer/`. Sin Android Studio.
- Solo Android por ahora. Sin servidor: todo se guarda en el celular.
- Distribución: APK compartido por link. Google Play queda para más adelante.

## Reglas

- Textos del juego en español, con el estilo de los cuentos (`arte/cuentos/`): frases cortas, para primaria, y sin género para quien juega. Código, nombres de variables y comentarios técnicos pueden ir en inglés. **Todos** los textos visibles van en `lib/data/textos.dart` (pantallas e historia), nunca sueltos en los widgets ni en `chapter1.dart`.
- Las cifras del juego (pasos por etapa, objetos y sus umbrales, recompensas) y los `id` van en un solo archivo de datos: `lib/data/chapter1.dart`. Nunca se repiten en la lógica. Así se ajustan cambiando un número.
- Trabajar en partes chicas que se puedan probar en el celular. Antes de terminar una tarea: `flutter analyze` y `flutter test` sin errores.
- La lógica del juego (pasos → avance de etapa, objetos, recompensas) va en Dart puro, sin Flutter, con tests unitarios.
- Mantener siempre un botón de debug "+1.000 pasos" (solo en builds de debug) para probar sin caminar.
- Nunca subir al repo la keystore ni `key.properties`. Sin ella no se pueden publicar actualizaciones de la misma app.

## Pasos: trampas conocidas

- Pedir el permiso ACTIVITY_RECOGNITION.
- El sensor cuenta pasos desde el último reinicio del celular: guardar la última lectura y sumar la diferencia. Si la lectura nueva es menor (hubo reinicio), sumar la lectura nueva completa.
- Sin GPS en segundo plano.
- El ahorro de batería de Xiaomi y Samsung puede cortar la app en segundo plano.

## Resumen de reglas del juego

- Sin combate ni enemigos. Cada etapa se completa juntando los objetos que pide.
- Mecánicas genéricas para todos los objetos: aparición al azar (cada K pasos, 1 en N), garantía de mala suerte (sale seguro a los 3×N×K pasos), objetos fijos (uno cada M pasos), canje (X comunes → 1 objeto de la etapa) y tramo de "llegar" sin objetos al inicio de algunas etapas.
- El azar usa un `Random` con semilla inyectable para los tests.
- Al completar una etapa se entrega la recompensa y los pasos que sobran pasan a la siguiente (un salto grande puede completar varias).
- No hay que mirar el celular mientras se camina: los objetos se juntan solos.
- Capítulo 1: 8 etapas, unos 110.000 pasos en promedio (unas 3 semanas y media). Todo cambio de lugar es un tramo de caminata. Empieza en el jardín de la abuelita y termina cuando el barco zarpa. Al cambiar números, repetir la simulación de `docs/diseno.md`.
- Los `id` de objetos y etapas y el número de etapa quedan guardados en el celular: no se cambian (ni se agregan etapas antes de otras) sin migrar la partida vieja en `lib/logic/game_save.dart`.
- Monedas, tienda (mejoras para conseguir más objetos) y experiencia quedan para más adelante.

## Plan de desarrollo

1. App vacía que abre en el celular.
2. Leer los pasos y mostrarlos.
3. Las 7 etapas con su barra de progreso y sus objetos a recolectar.
4. Guardado de la partida (etapas e inventario).
5. Monedas y tienda de mejoras.
6. Textos, dibujos y sonidos.

## Comandos útiles

- Conectar el celular por WiFi (depuración inalámbrica): `adb pair IP:PUERTO` y después `adb connect IP:PUERTO`; verificar con `adb devices`.
- Correr en el celular: `flutter run`
- Simular el balance del capítulo (1.000 partidas): `dart run tool/simulate.dart`
- Convertir dibujos de `arte/` a WebP: `python3 tool/convert_art.py` (el nombre del archivo es el `id`). Los GIF de `arte/personajes/` pasan a WebP animado; los de `arte/lugares/<id de etapa>.gif`, a pantallas de llegada. Se puede pasar solo algunos `id` para no convertir todo (los animados tardan).
- Ver qué dibujos faltan o sobran: `dart run tool/check_art.dart`
- Recortar los loops de música de `arte/musica/` a `assets/music/*.ogg`: `python3 tool/make_loops.py` (dónde empieza cada loop y qué archivo usa, en `TRACKS`).
- APK de release: `flutter build apk --release` (sale en `build/app/outputs/flutter-apk/`).
