import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rpg/data/chapter1.dart';
import 'package:rpg/data/textos.dart' as t;
import 'package:rpg/ui/credits_screen.dart';

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
      expect(find.text(what), findsOneWidget);
      expect(find.text(who), findsOneWidget);
    }
    expect(find.text(t.creditosBlog), findsOneWidget);

    await tester.tap(find.text(t.creditosBlogBoton));
    expect(opened, [Uri.parse(t.creditosBlog)]);
  });
}
