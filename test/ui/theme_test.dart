import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rpg/ui/theme.dart';

void main() {
  test('títulos en Luckiest Guy; textos, botones y números en Nunito', () {
    final t = gameTheme().textTheme;
    for (final s in [
      t.displayLarge,
      t.displayMedium,
      t.displaySmall,
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
    ]) {
      expect(s!.fontFamily, titleFont);
    }
    for (final s in [
      t.titleLarge,
      t.titleMedium,
      t.bodyLarge,
      t.bodyMedium,
      t.labelLarge,
    ]) {
      expect(s!.fontFamily, textFont);
    }
    expect(t.labelLarge!.fontWeight, FontWeight.w800); // Botones.
  });

  test('las fuentes están en la app (sin internet) y declaradas', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('google_fonts')));
    for (final path in [
      'assets/fonts/LuckiestGuy/LuckiestGuy-Regular.ttf',
      'assets/fonts/LuckiestGuy/LICENSE.txt',
      'assets/fonts/Nunito/static/Nunito-Regular.ttf',
      'assets/fonts/Nunito/static/Nunito-Italic.ttf',
      'assets/fonts/Nunito/static/Nunito-Bold.ttf',
      'assets/fonts/Nunito/static/Nunito-ExtraBold.ttf',
      'assets/fonts/Nunito/OFL.txt',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains(path), reason: path);
    }
  });
}
