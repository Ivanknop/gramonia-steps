import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import 'title_screen.dart';

/// Abre un link afuera de la app (en el navegador).
typedef LinkOpener = Future<bool> Function(Uri link);

Future<bool> _openInBrowser(Uri link) =>
    launchUrl(link, mode: LaunchMode.externalApplication);

/// Créditos: título, autores y el link al blog de los cuentos.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({
    super.key,
    required this.background,
    this.openLink = _openInBrowser,
  });

  /// El mapa de la isla.
  final String background;

  /// Para los tests: en vez de abrir el navegador.
  final LinkOpener openLink;

  /// Abre la pantalla de créditos encima de la actual.
  static void show(BuildContext context, String background) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreditsScreen(background: background),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final link = Uri.parse(t.creditosBlog);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(Strings.creditsButton),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(background, fit: BoxFit.cover),
          const ColoredBox(color: Colors.black54),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                const GameLogo(text: t.creditosTitulo),
                const SizedBox(height: 8),
                Text(
                  t.creditosSubtitulo,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                for (final (what, who) in t.creditos) ...[
                  Text(
                    what,
                    textAlign: TextAlign.center,
                    style: text.labelLarge?.copyWith(
                      color: colors.primaryContainer,
                    ),
                  ),
                  Text(
                    who,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 12),
                // El link escrito, por si no se puede abrir el navegador.
                SelectableText(
                  t.creditosBlog,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => openLink(link),
                    icon: const Icon(Icons.menu_book),
                    label: const Text(t.creditosBlogBoton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
