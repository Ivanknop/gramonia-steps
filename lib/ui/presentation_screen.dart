import 'package:material_ui/material_ui.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import '../logic/story.dart';
import 'dialogue.dart';
import 'step_controller.dart';

/// Presentación: Sofía se presenta y pregunta el nombre de quien juega.
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
  String? _name;

  void _submit(String name) {
    widget.controller.setPlayerName(name);
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.controller.engine.chapter;
    final name = _name;
    return Scaffold(
      backgroundColor: Colors.black,
      body: name == null
          ? DialogueView(
              key: const ValueKey('ask'),
              chapter: chapter,
              lines: t.presentacion,
              playerName: '',
              background: chapter.stages.first.background,
              footer: NameForm(onSubmit: _submit),
            )
          : DialogueView(
              key: const ValueKey('named'),
              chapter: chapter,
              lines: const [...t.presentacion, ...t.presentacionDespues],
              initiallyShown: t.presentacion.length + 1,
              playerName: name,
              background: chapter.stages.first.background,
              onDone: widget.onDone,
            ),
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
