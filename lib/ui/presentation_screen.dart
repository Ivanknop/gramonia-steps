import 'package:material_ui/material_ui.dart';

import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import '../logic/story.dart';
import 'dialogue.dart';
import 'step_controller.dart';

/// Presentación: Sofía se presenta y pregunta lo que todavía no sabe, en
/// orden: el nombre, si quien juega es chico o chica, y si quiere avisos en
/// el celular.
///
/// Si el nombre ya se sabe (partidas de antes), Sofía saluda y pregunta solo
/// lo que falta, una vez.
class PresentationScreen extends StatefulWidget {
  const PresentationScreen({
    super.key,
    required this.controller,
    required this.onDone,
    this.enableNotifications,
  });

  final StepController controller;
  final VoidCallback onDone;

  /// Con "¡Sí!": pide el permiso y activa los avisos. Devuelve si quedaron
  /// activados. Si es nulo (tests), solo se guarda que se preguntó.
  final Future<bool> Function()? enableNotifications;

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

/// Qué respondió a lo de los avisos.
enum _Avisos { si, no, sinPermiso }

class _PresentationScreenState extends State<PresentationScreen> {
  late final bool _returning;
  late final bool _askGender;
  late final bool _askNotifications;
  String? _name;
  Genero? _genero;
  _Avisos? _avisos;

  /// Cuántos globos se ven al abrir cada paso: hasta el primero nuevo.
  var _shownAtStart = 1;

  StepController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _name = _controller.playerName;
    _returning = _name != null;
    _askGender = _controller.genero == null;
    _askNotifications = !_controller.notificationsAsked;
    _genero = _controller.genero;
  }

  void _submitName(String name) {
    _controller.setPlayerName(name);
    setState(() {
      _shownAtStart = t.presentacion.length + 1;
      _name = name;
    });
  }

  void _chooseGender(Genero genero) {
    _controller.setGenero(genero);
    setState(() {
      _shownAtStart = _lines().length + 1; // La respuesta de Sofía.
      _genero = genero;
    });
  }

  Future<void> _answerNotifications(bool yes) async {
    var answer = _Avisos.no;
    if (yes) {
      final enable = widget.enableNotifications;
      final enabled = enable == null || await enable();
      answer = enabled ? _Avisos.si : _Avisos.sinPermiso;
    }
    _controller.markNotificationsAsked();
    if (!mounted) return;
    setState(() {
      _shownAtStart = _lines().length + 1;
      _avisos = answer;
    });
  }

  /// Los globos hasta donde se llegó.
  List<Linea> _lines() {
    final name = _name;
    final genero = _genero;
    final avisos = _avisos;
    return [
      if (!_returning) ...t.presentacion,
      if (name != null) ...[
        if (!_returning) ...t.presentacionDespues,
        if (_askGender) ...[
          ...(_returning ? t.preguntaGeneroDeNuevo : t.preguntaGenero),
          if (genero != null)
            ...(_returning ? t.respuestaGeneroDeNuevo : t.respuestaGenero),
        ] else if (_returning)
          ...t.saludoAvisos,
        if (_askNotifications && genero != null) ...[
          ...t.preguntaAvisos,
          ...switch (avisos) {
            null => const <Linea>[],
            _Avisos.si => t.respuestaAvisosSi,
            _Avisos.no => t.respuestaAvisosNo,
            _Avisos.sinPermiso => t.respuestaAvisosSinPermiso,
          },
        ],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _controller.engine.chapter;
    final name = _name;
    final genero = _genero;
    final Widget? footer;
    final String step;
    if (name == null) {
      step = 'name';
      footer = NameForm(onSubmit: _submitName);
    } else if (genero == null) {
      step = 'gender';
      footer = GenderChoice(onChoose: _chooseGender);
    } else if (_askNotifications && _avisos == null) {
      step = 'notifications';
      footer = NotificationsChoice(onAnswer: _answerNotifications);
    } else {
      step = 'done';
      footer = null;
    }
    final lines = _lines();
    return Scaffold(
      backgroundColor: Colors.black,
      body: DialogueView(
        key: ValueKey(step),
        chapter: chapter,
        lines: lines,
        initiallyShown: _shownAtStart,
        playerName: name ?? '',
        genero: genero,
        background: chapter.stages.first.background,
        footer: footer,
        onDone: widget.onDone,
      ),
    );
  }
}

/// "¡Sí!" y "Ahora no", para los avisos en el celular.
class NotificationsChoice extends StatefulWidget {
  const NotificationsChoice({super.key, required this.onAnswer});

  final Future<void> Function(bool yes) onAnswer;

  @override
  State<NotificationsChoice> createState() => _NotificationsChoiceState();
}

class _NotificationsChoiceState extends State<NotificationsChoice> {
  /// Mientras el celular muestra el pedido de permiso.
  var _waiting = false;

  Future<void> _answer(bool yes) async {
    if (_waiting) return;
    setState(() => _waiting = true);
    await widget.onAnswer(yes);
    if (mounted) setState(() => _waiting = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              textStyle: text.titleMedium,
            ),
            onPressed: _waiting ? null : () => _answer(true),
            child: const Text(Strings.notificationsYes),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            onPressed: _waiting ? null : () => _answer(false),
            child: const Text(Strings.notificationsNo),
          ),
        ),
      ],
    );
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
