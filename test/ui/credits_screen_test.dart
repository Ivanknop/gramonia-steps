import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/data/textos.dart' as t;
import 'package:rpg/ui/credits_screen.dart';
import 'package:rpg/ui/theme.dart';

void main() {
  testWidgets('título, autores y el botón que abre el blog', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CreditsScreen(
          background: chapter1.walkingBackground,
          openLink: (link) async {
            opened.add(link);
            return true;
          },
        ),
      ),
    );
    expect(find.text(t.creditosTitulo), findsWidgets);
    expect(find.text(t.creditosSubtitulo), findsOneWidget);
    for (final (what, who) in t.creditos) {
      await tester.scrollUntilVisible(find.text(who), 100);
      expect(find.text(what), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text(t.creditosLicencias), 100);
    expect(find.text(t.creditosBlog), findsOneWidget);

    await tester.tap(find.text(t.creditosBlogBoton));
    expect(opened, [Uri.parse(t.creditosBlog)]);
  });

  testWidgets('las licencias de las tipografías están en la pantalla de '
      'licencias', (tester) async {
    registerFontLicenses();
    final names = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      names.addAll(entry.packages);
    }
    expect(names, containsAll(['Nunito', 'Luckiest Guy']));
  });
}
