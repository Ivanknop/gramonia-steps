import 'package:material_ui/material_ui.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import '../logic/story.dart';
import 'dialogue.dart';
import 'step_controller.dart';

/// Presentación: Sofía se presenta, pregunta el nombre de quien juega y si
/// es chico o chica.
///
/// Si el nombre ya se sabe (partidas de antes de la 1.2.0), Sofía solo
/// saluda y hace la pregunta del género, una vez.
class PresentationScreen extends StatefulWidget {
  const PresentationScreen({
    super.key,
    required this.controller,
    required this.onDone,
  });

  final StepController controller;
  final VoidCallback onDone;

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  /// Ya tenía nombre al abrir: solo falta el género.
  late final bool _returning;
  String? _name;
  Genero? _genero;

  @override
  void initState() {
    super.initState();
    _name = widget.controller.playerName;
    _returning = _name != null;
  }

  void _submit(String name) {
    widget.controller.setPlayerName(name);
    setState(() => _name = name);
  }

  void _choose(Genero genero) {
    widget.controller.setGenero(genero);
    setState(() => _genero = genero);
  }

  /// Los globos hasta la pregunta del género.
  List<Linea> get _untilQuestion => _returning
      ? t.preguntaGeneroDeNuevo
      : const [
          ...t.presentacion,
          ...t.presentacionDespues,
          ...t.preguntaGenero,
        ];

  @override
  Widget build(BuildContext context) {
    final chapter = widget.controller.engine.chapter;
    final background = chapter.stages.first.background;
    final name = _name;
    final genero = _genero;
    final Widget view;
    if (name == null) {
      view = DialogueView(
        key: const ValueKey('ask'),
        chapter: chapter,
        lines: t.presentacion,
        playerName: '',
        background: background,
        footer: NameForm(onSubmit: _submit),
      );
    } else if (genero == null) {
      view = DialogueView(
        key: const ValueKey('gender'),
        chapter: chapter,
        lines: _untilQuestion,
        // Al volver de escribir el nombre, se ve el globo nuevo enseguida.
        initiallyShown: _returning ? 1 : t.presentacion.length + 1,
        playerName: name,
        background: background,
        footer: GenderChoice(onChoose: _choose),
      );
    } else {
      final lines = [
        ..._untilQuestion,
        ...(_returning ? t.respuestaGeneroDeNuevo : t.respuestaGenero),
      ];
      view = DialogueView(
        key: const ValueKey('answered'),
        chapter: chapter,
        lines: lines,
        initiallyShown: lines.length,
        playerName: name,
        genero: genero,
        background: background,
        onDone: widget.onDone,
      );
    }
    return Scaffold(backgroundColor: Colors.black, body: view);
  }
}

/// Tres botones: chico, chica o "prefiero no decir".
class GenderChoice extends StatelessWidget {
  const GenderChoice({super.key, required this.onChoose});

  final ValueChanged<Genero> onChoose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 52),
      textStyle: text.titleMedium,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: style,
                onPressed: () => onChoose(Genero.chico),
                child: const Text(Strings.genderBoy),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: style,
                onPressed: () => onChoose(Genero.chica),
                child: const Text(Strings.genderGirl),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          onPressed: () => onChoose(Genero.neutro),
          child: const Text(Strings.genderNone),
        ),
      ],
    );
  }
}

/// Campo para escribir el nombre y botón para seguir.
class NameForm extends StatefulWidget {
  const NameForm({super.key, required this.onSubmit});

  /// Recibe el nombre ya limpio.
  final ValueChanged<String> onSubmit;

  @override
  State<NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<NameForm> {
  final _field = TextEditingController();

  String? get _clean => limpiarNombre(_field.text);

  void _send() {
    final name = _clean;
    if (name != null) widget.onSubmit(name);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _field,
            autofocus: true,
            maxLength: maxNombre,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: Strings.nameHint,
              filled: true,
              fillColor: colors.surface,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _clean == null ? null : _send,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 56)),
          child: const Text(Strings.nameButton),
        ),
      ],
    );
  }
}
