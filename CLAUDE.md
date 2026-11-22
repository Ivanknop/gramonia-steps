# Gramonia RPG

RPG de caminata para Android, ambientado en Gramonia (los Cuentos de Gramonia, de Iván y su hija Regi). Se avanza caminando en la vida real. Gratis, sin fines comerciales. Es la primera app Android de Iván: explicá los pasos en español simple.

El diseño completo del Capítulo 1 está en `docs/diseno.md`. Ante una duda de reglas del juego, ese archivo manda.

## Stack y entorno

- Flutter (Dart) + Android SDK de línea de comandos + JDK 17, dentro del devcontainer de `.devcontainer/`. Sin Android Studio.
- Solo Android por ahora. Sin servidor: todo se guarda en el celular.
- Distribución: APK compartido por link. Google Play queda para más adelante.

## Reglas

- Textos del juego en español. Código, nombres de variables y comentarios técnicos pueden ir en inglés; los textos visibles van en archivos de strings, no sueltos en los widgets.
- Las cifras del juego (pasos por etapa, enemigos, precios, niveles) van en un solo archivo de datos (por ejemplo `lib/data/chapter1.dart`), nunca repetidas en la lógica. Así se ajustan cambiando un número.
- Trabajar en partes chicas que se puedan probar en el celular. Antes de terminar una tarea: `flutter analyze` y `flutter test` sin errores.
- La lógica del juego (pasos → avance, XP, monedas, encuentros, combate) va en Dart puro, sin Flutter, con tests unitarios.
- Mantener siempre un botón de debug "+1.000 pasos" (solo en builds de debug) para probar sin caminar.
- Nunca subir al repo la keystore ni `key.properties`. Sin ella no se pueden publicar actualizaciones de la misma app.

## Pasos: trampas conocidas

- Pedir el permiso ACTIVITY_RECOGNITION.
- El sensor cuenta pasos desde el último reinicio del celular: guardar la última lectura y sumar la diferencia. Si la lectura nueva es menor (hubo reinicio), sumar la lectura nueva completa.
- Sin GPS en segundo plano.
- El ahorro de batería de Xiaomi y Samsung puede cortar la app en segundo plano.

## Resumen de reglas del juego

- Cada paso: +1 avance de etapa, +1 XP; 1 moneda cada 10 pasos; 1 encuentro cada ~500 pasos.
- Los encuentros se guardan y se pelean cuando la jugadora quiera (no hay que mirar el celular mientras camina).
- Combate por turnos: Atacar, Defender (mitad de daño ese turno), Usar objeto. Si la Vida llega a 0, vuelve al último lugar seguro sin perder pasos ni monedas.
- Niveles: nivel 2 a 1.000 XP, nivel 3 a 2.500, nivel 4 a 4.500, nivel 5 a 7.000, sumando 500 más cada vez. Cada nivel: +5 Vida, +1 Fuerza.
- Capítulo 1: 7 etapas, 30.000 pasos. Termina cuando el barco zarpa.

## Plan de desarrollo

1. App vacía que abre en el celular.
2. Leer los pasos y mostrarlos.
3. Barras de progreso de las 7 etapas.
4. Guardado de la partida.
5. Combate por turnos.
6. Tienda y equipo.
7. Textos, dibujos y sonidos.

## Comandos útiles

- Conectar el celular por WiFi (depuración inalámbrica): `adb pair IP:PUERTO` y después `adb connect IP:PUERTO`; verificar con `adb devices`.
- Correr en el celular: `flutter run`
- APK de release: `flutter build apk --release` (sale en `build/app/outputs/flutter-apk/`).
