import 'dart:io';

import 'package:rpg/data/textos.dart';
import 'package:test/test.dart';

void main() {
  test('debajo del ícono, el nombre corto; en la app, el largo', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="${Strings.launcherName}"'));
    expect(Strings.titleLogo, Strings.appTitle);
    expect(creditosTitulo, Strings.appTitle);
  });
}
