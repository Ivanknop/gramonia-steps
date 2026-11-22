import 'dart:math';

/// Random que siempre devuelve [value] (recortado al rango pedido).
/// Con 0 todas las tiradas al azar salen; con 1, ninguna (salvo la garantía).
class FixedRandom implements Random {
  FixedRandom(this.value);
  final int value;
  int rolls = 0;

  @override
  int nextInt(int max) {
    rolls++;
    return min(value, max - 1);
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
