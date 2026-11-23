import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Tipografía de títulos: logo, lugares, "Continuará...".
const titleFont = 'LuckiestGuy';

/// Tipografía de textos, diálogos, botones y números.
const textFont = 'Nunito';

/// Suma las licencias de las tipografías a la pantalla de licencias
/// (Créditos → Ver las licencias).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Nunito',
    ], await rootBundle.loadString('assets/fonts/Nunito/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Luckiest Guy',
    ], await rootBundle.loadString('assets/fonts/LuckiestGuy/LICENSE.txt'));
  });
}

/// Tema de la app: colores y tipografías (incluidas en la app, sin
/// conexión).
ThemeData gameTheme() {
  final base = ThemeData(colorSchemeSeed: Colors.teal, fontFamily: textFont);
  final t = base.textTheme;

  // Luckiest Guy tiene un solo peso: sin negrita sintética.
  TextStyle title(TextStyle? style) => style!.copyWith(
    fontFamily: titleFont,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.15,
  );
  TextStyle weight(TextStyle? style, FontWeight w) =>
      style!.copyWith(fontFamily: textFont, fontWeight: w);

  return base.copyWith(
    textTheme: t.copyWith(
      displayLarge: title(t.displayLarge),
      displayMedium: title(t.displayMedium),
      displaySmall: title(t.displaySmall),
      headlineLarge: title(t.headlineLarge),
      headlineMedium: title(t.headlineMedium),
      headlineSmall: title(t.headlineSmall),
      titleLarge: weight(t.titleLarge, FontWeight.w800),
      titleMedium: weight(t.titleMedium, FontWeight.w700),
      titleSmall: weight(t.titleSmall, FontWeight.w700),
      bodyLarge: weight(t.bodyLarge, FontWeight.w400),
      bodyMedium: weight(t.bodyMedium, FontWeight.w400),
      bodySmall: weight(t.bodySmall, FontWeight.w400),
      // Los botones usan labelLarge.
      labelLarge: weight(t.labelLarge, FontWeight.w800),
      labelMedium: weight(t.labelMedium, FontWeight.w700),
      labelSmall: weight(t.labelSmall, FontWeight.w700),
    ),
  );
}

/// Texto con contorno y sombra suave, para que los títulos se lean sobre
/// las ilustraciones.
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.strokeWidth = 6,
    this.strokeColor = const Color(0xFF3B2A14),
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final double strokeWidth;
  final Color strokeColor;
  final TextAlign textAlign;

  static const shadows = [
    Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // El contorno: el mismo texto, solo con trazo (y la sombra).
        Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(
            color: null,
            shadows: shadows,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(text, textAlign: textAlign, style: style),
      ],
    );
  }
}
