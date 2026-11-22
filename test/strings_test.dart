import 'package:rpg/strings.dart';
import 'package:test/test.dart';

void main() {
  test('formatea números con punto de miles', () {
    expect(Strings.formatNumber(0), '0');
    expect(Strings.formatNumber(999), '999');
    expect(Strings.formatNumber(1000), '1.000');
    expect(Strings.formatNumber(30000), '30.000');
    expect(Strings.formatNumber(1234567), '1.234.567');
  });
}
