import 'package:material_ui/material_ui.dart';

import '../data/textos.dart';
import '../logic/chapter.dart';
import '../logic/story.dart';
import 'widgets.dart';

/// Diálogo tipo historieta: un globo por vez, con el dibujo de quien habla al
/// lado. Se toca para ver el globo siguiente; al final aparece el botón (o
/// [footer], por ejemplo para escribir el nombre).
///
/// Sofía habla desde la izquierda; los demás personajes y quien juega, desde
/// la derecha. La narración va en un cuadro, sin dibujo.
class DialogueView extends StatefulWidget {
  const DialogueView({
    super.key,
    required this.chapter,
    required this.lines,
    required this.playerName,
    this.genero,
    required this.background,
    this.doneLabel = Strings.dialogueNext,
    this.onDone,
    this.footer,
    this.initiallyShown = 1,
  });

  final Chapter chapter;
  final List<Linea> lines;

  /// Para `{nombre}` y para el globo de quien juega.
  final String playerName;

  /// Para las variantes `{chico|chica|neutro}`.
  final Genero? genero;

  /// Ilustración de fondo.
  final String background;

  final String doneLabel;
  final VoidCallback? onDone;

  /// Si no es nulo, reemplaza al botón del final.
  final Widget? footer;

  /// Cuántos globos se ven al abrir.
  final int initiallyShown;

  @override
  State<DialogueView> createState() => _DialogueViewState();
}

class _DialogueViewState extends State<DialogueView> {
  late int _shown = widget.initiallyShown.clamp(1, widget.lines.length);
  final _scroll = ScrollController();

  bool get _allShown => _shown >= widget.lines.length;

  @override
  void initState() {
    super.initState();
    // Si abre con varios globos, se ve el último.
    if (_shown > 1) _scrollToEnd(jump: true);
  }

  void _more() {
    if (_allShown) return;
    setState(() => _shown++);
    _scrollToEnd();
  }

  /// Baja hasta el último globo cuando ya está dibujado.
  void _scrollToEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _more,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          Image.asset(
            widget.background,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const ColoredBox(color: Colors.black26),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    children: [
                      for (final line in widget.lines.take(_shown))
                        _Bubble(
                          key: ObjectKey(line),
                          line: line,
                          chapter: widget.chapter,
                          playerName: widget.playerName,
                          genero: widget.genero,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: !_allShown
                      ? Text(
                          Strings.tapForMore,
                          style: text.labelLarge?.copyWith(
                            color: Colors.white,
                            shadows: const [
                              Shadow(blurRadius: 6, color: Colors.black),
                            ],
                          ),
                        )
                      : widget.footer ??
                            FilledButton(
                              onPressed: widget.onDone,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 56),
                                textStyle: text.titleLarge,
                              ),
                              child: Text(widget.doneLabel),
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

/// Un globo de diálogo con el dibujo de quien habla.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.line,
    required this.chapter,
    required this.playerName,
    required this.genero,
  });

  final Linea line;
  final Chapter chapter;
  final String playerName;
  final Genero? genero;

  static const portrait = 72.0;

  /// Sofía (con o sin caperuza) habla desde la izquierda.
  bool get _isSofia => line.quien.startsWith('caperucita');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final message = paraQuienJuega(line.texto, playerName, genero);

    if (line.esNarracion) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final String name;
    final Widget face;
    if (line.esJugador) {
      name = playerName;
      face = CircleAvatar(
        key: const ValueKey('player-avatar'),
        radius: portrait / 2,
        backgroundColor: colors.tertiaryContainer,
        child: Text(
          playerName.isEmpty ? '?' : playerName.characters.first.toUpperCase(),
          style: text.headlineMedium?.copyWith(
            color: colors.onTertiaryContainer,
          ),
        ),
      );
    } else {
      final character = chapter.character(line.quien);
      name = character.name;
      face = GameImage.of(character, size: portrait);
    }

    final bubble = Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: line.esJugador
              ? colors.tertiaryContainer
              : colors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(_isSofia ? 4 : 18),
            bottomRight: Radius.circular(_isSofia ? 18 : 4),
          ),
          border: Border.all(color: colors.outline, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: text.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(message, style: text.titleMedium),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: _isSofia
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: _isSofia
            ? [face, const SizedBox(width: 8), bubble]
            : [bubble, const SizedBox(width: 8), face],
      ),
    );
  }
}
