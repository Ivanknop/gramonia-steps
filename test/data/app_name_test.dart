import 'dart:io';

import 'package:rpg/data/textos.dart';
import 'package:test/test.dart';

void main() {
  test('el nombre en el celular es el mismo que el de la app y el logo', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="${Strings.appTitle}"'));
    expect(Strings.titleLogo, Strings.appTitle);
    expect(creditosTitulo, Strings.appTitle);
  });
}
