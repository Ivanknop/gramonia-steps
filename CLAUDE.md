# Gramonia RPG

RPG de caminata para Android, ambientado en Gramonia (los Cuentos de Gramonia, de Iván y su hija Regi). Se avanza caminando en la vida real. Gratis, sin fines comerciales. Es la primera app Android de Iván: explicá los pasos en español simple.

El diseño completo del Capítulo 1 está en `docs/diseno.md`. Ante una duda de reglas del juego, ese archivo manda.

## Stack y entorno

- Flutter (Dart) + Android SDK de línea de comandos + JDK 17, dentro del devcontainer de `.devcontainer/`. Sin Android Studio.
- Solo Android por ahora. Sin servidor: todo se guarda en el celular.
- Distribución: APK compartido por link. Google Play queda para más adelante.

## Reglas

- Textos del juego en español. Código, nombres de variables y comentarios técnicos pueden ir en inglés; los textos visibles van en archivos de strings, no sueltos en los widgets.
- Las cifras del juego (pasos por etapa, objetos y sus umbrales, recompensas) van en un solo archivo de datos: `lib/data/chapter1.dart`. Nunca se repiten en la lógica. Así se ajustan cambiando un número.
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

- Sin combate ni enemigos. Cada etapa se completa juntando objetos que se consiguen caminando.
- Cada paso: +1 avance en la etapa actual. Cada objeto tiene un umbral de pasos dentro de la etapa; al cruzarlo, va al inventario con un aviso.
- El último objeto está en la meta de la etapa. Al completarla se entrega la recompensa, se destraba la siguiente y los pasos que sobran pasan a ella (un salto grande puede completar varias etapas).
- No hay que mirar el celular mientras se camina: los objetos se juntan solos.
- Capítulo 1: 7 etapas, 30.000 pasos. Termina cuando el barco zarpa.
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
- APK de release: `flutter build apk --release` (sale en `build/app/outputs/flutter-apk/`).
