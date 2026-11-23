import 'package:rpg/logic/story.dart';
import 'package:test/test.dart';

void main() {
  test('{nombre} se reemplaza por el nombre', () {
    expect(
      conNombre('¡Hola, {nombre}! ¿{nombre}?', 'Regi'),
      '¡Hola, Regi! ¿Regi?',
    );
  });

  test('el nombre se limpia: espacios de más y largo máximo', () {
    expect(limpiarNombre('  Regi  '), 'Regi');
    expect(limpiarNombre('Ana   María'), 'Ana María');
    expect(limpiarNombre('   '), isNull);
    expect(limpiarNombre('x' * 50), hasLength(maxNombre));
  });
}
