import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/app.dart';
import 'package:rpg/strings.dart';

void main() {
  testWidgets('la app abre y muestra el título', (tester) async {
    await tester.pumpWidget(const GramoniaApp());
    expect(find.text(Strings.appTitle), findsOneWidget);
  });
}
