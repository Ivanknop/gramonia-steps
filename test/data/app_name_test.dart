import 'dart:io';

import 'package:rpg/data/textos.dart';
import 'package:test/test.dart';

void main() {
  test('debajo del ícono, el nombre corto; en la app, el largo', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    // El manifest toma el nombre de build.gradle.kts: "Gramonia" en release
    // y "Gramonia DEV" en debug.
    expect(manifest, contains(r'android:label="${appLabel}"'));
    expect(
      gradle,
      contains('manifestPlaceholders["appLabel"] = "${Strings.launcherName}"'),
    );
    expect(
      gradle,
      contains(
        'manifestPlaceholders["appLabel"] = "${Strings.launcherName} DEV"',
      ),
    );
    expect(gradle, contains('applicationIdSuffix = ".debug"'));
    expect(Strings.titleLogo, Strings.appTitle);
    expect(creditosTitulo, Strings.appTitle);
  });
}
