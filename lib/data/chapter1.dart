/// Cifras del juego. Para ajustar el juego, cambiar los números acá.
library;

/// Pasos que suma el botón de debug.
const int debugStepBonus = 1000;

/// Si una lectura del sensor trae más pasos que esto de golpe, se considera
/// absurda: no se suma y solo se toma como base nueva.
const int maxStepsPerReading = 50000;
