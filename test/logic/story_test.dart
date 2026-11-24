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

  group('género', () {
    const texto = 'Lo damos {juntos|juntas|en equipo}, {nombre}.';

    test('chico, chica y "prefiero no decir"', () {
      expect(conGenero(texto, Genero.chico), 'Lo damos juntos, {nombre}.');
      expect(conGenero(texto, Genero.chica), 'Lo damos juntas, {nombre}.');
      expect(conGenero(texto, Genero.neutro), 'Lo damos en equipo, {nombre}.');
    });

    test('sin respuesta, la variante neutra', () {
      expect(conGenero(texto, null), 'Lo damos en equipo, {nombre}.');
    });

    test('nombre y género juntos', () {
      expect(
        paraQuienJuega(texto, 'Regi', Genero.chica),
        'Lo damos juntas, Regi.',
      );
    });

    test('un nombre con barras o llaves no se confunde', () {
      expect(
        paraQuienJuega(texto, 'a|b|c', Genero.chico),
        'Lo damos juntos, a|b|c.',
      );
    });

    test('segunGenero elige entre las tres', () {
      String g(Genero? x) =>
          segunGenero(x, chico: 'o', chica: 'a', neutro: 'e');
      expect(
        [g(Genero.chico), g(Genero.chica), g(Genero.neutro), g(null)],
        ['o', 'a', 'e', 'e'],
      );
    });
  });
}
