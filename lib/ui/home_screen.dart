import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart';
import '../logic/chapter.dart';
import '../logic/chapter_engine.dart';
import '../logic/chapter_progress.dart';
import '../logic/wallet.dart';
import '../data/textos.dart';
import 'arrival.dart';
import 'bag.dart';
import 'coins.dart';
import 'credits_screen.dart';
import 'dialogue.dart';
import 'ending.dart';
import 'music_controller.dart';
import 'found_item.dart';
import 'notices.dart';
import 'shop_screen.dart';
import 'stage_done.dart';
import 'step_controller.dart';
import 'theme.dart';
import 'widgets.dart';

/// Pantalla única: pasos, etapa actual con lo que hay que juntar y el viaje.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.music,
    this.showDebug = kDebugMode,
  });

  final StepController controller;

  /// Si es nulo (tests), no hay botón de música.
  final MusicController? music;

  /// El botón "+1.000 pasos" solo aparece en builds de debug.
  final bool showDebug;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ChapterEvent>>? _events;

  /// Carteles, ventanas de fin de etapa y caminatas, uno después del otro.
  final _queue = <Moment>[];
  Moment? _current;

  final _stackKey = GlobalKey();
  final _bagKey = GlobalKey<BagButtonState>();

  @override
  void initState() {
    super.initState();
    _events = widget.controller.events.listen(_onEvents);
    widget.controller.addListener(_onLoaded);
    widget.controller.addListener(_onCoinNotices);
    _onLoaded(building: true);
  }

  /// Avisos de monedas que ya están en la cola (o en pantalla).
  final _queuedNotices = Set<CoinNotice>.identity();

  /// Avisos de monedas nuevos, en el orden en que llegaron.
  List<CoinMoment> _newCoinMoments() => [
    for (final notice in widget.controller.coinNotices)
      if (_queuedNotices.add(notice)) CoinMoment(notice),
  ];

  /// Llegó un bono (por ejemplo, el del día al volver a la app).
  void _onCoinNotices() {
    if (!_checkedDoor) return; // Los primeros los pone _onLoaded.
    final moments = _newCoinMoments();
    if (moments.isEmpty) return;
    _queue.addAll(moments);
    if (_current == null) _next();
  }

  var _checkedDoor = false;

  /// Al abrir la app: si había quedado en la pantalla de llegada o en el
  /// diálogo, se vuelve a mostrar. (Después, vienen con los eventos, en
  /// orden.)
  void _onLoaded({bool building = false}) {
    final controller = widget.controller;
    if (_checkedDoor || !controller.loaded) return;
    _checkedDoor = true;
    controller.removeListener(_onLoaded);
    final chapter = controller.game.chapter;
    // Primero los bonos de monedas, después la puerta de la etapa.
    final first = <Moment>[..._newCoinMoments()];
    if (controller.engine.needsEntering(chapter)) {
      final stage = controller.engine.currentStage(chapter)!;
      first.add(stage.hasTravel ? ArrivalMoment(stage) : DialogueMoment(stage));
    }
    if (first.isEmpty) return;
    _queue.insertAll(0, first);
    if (_current != null) return;
    if (building) {
      _current = _queue.removeAt(0); // Todavía no se dibujó nada.
    } else {
      _next();
    }
  }

  void _onEvents(List<ChapterEvent> events) {
    if (!mounted) return;
    _queue.addAll(momentsFor(widget.controller.engine.chapter, events));
    if (_current == null) _next();
    setState(() {}); // El número de la bolsa descuenta lo que está en camino.
  }

  /// Muestra el próximo momento de la cola (o nada, si está vacía).
  ///
  /// La pantalla de llegada no se cierra sola: lo que pasó después (los
  /// objetos que siguen saliendo) espera a que se toque "Entrar".
  void _next() {
    if (!mounted) return;
    final next = _queue.isEmpty ? null : _queue.removeAt(0);
    setState(() => _current = next);
  }

  /// "Entrar" en la pantalla de llegada: el diálogo, si la etapa tiene.
  void _enter(Stage stage) {
    if (stage.hasDialogue) {
      setState(() => _current = DialogueMoment(stage));
    } else {
      _entered(stage);
    }
  }

  /// Ya se entró a la etapa: los objetos empiezan a mostrarse.
  void _entered(Stage stage) {
    final controller = widget.controller;
    if (controller.engine.currentStage(controller.game.chapter) == stage) {
      controller.enterStage();
    }
    _next();
  }

  void _onLanded() {
    _bagKey.currentState?.bounce();
    _next();
  }

  /// Objetos que todavía están por volar a la bolsa: no cuentan como nuevos
  /// hasta que llegan.
  int get _inFlight => [
    ?_current,
    ..._queue,
  ].whereType<FoundMoment>().fold(0, (sum, m) => sum + m.count);

  /// Centro de la bolsa, en coordenadas de la pantalla.
  Offset _bagCenter() {
    final bag = _bagKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (bag == null || stack == null) return Offset.zero;
    return stack.globalToLocal(bag.localToGlobal(bag.size.center(Offset.zero)));
  }

  void _coinNoticeSeen(CoinNotice notice) {
    widget.controller.dismissCoinNotice(notice);
    _next();
  }

  void _openShop() => ShopScreen.open(context, widget.controller);

  void _openBag() {
    widget.controller.markBagSeen();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BagScreen(controller: widget.controller),
      ),
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    widget.controller.removeListener(_onLoaded);
    widget.controller.removeListener(_onCoinNotices);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final engine = controller.engine;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final chapter = controller.game.chapter;
          final stage = engine.currentStage(chapter);
          final traveling = engine.isTraveling(chapter);
          // Durante el tramo de "llegar", el mapa; después del final, el
          // fondo de la última etapa.
          final background = traveling
              ? engine.chapter.walkingBackground
              : (stage ?? engine.chapter.stages.last).background;
          _precacheNext(chapter.stageIndex);
          final current = _current;
          // Con el cierre ("Continuará...") suena el tema del final.
          final ending = current is EndingMoment;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.music?.setEnding(ending),
          );
          return Stack(
            key: _stackKey,
            fit: StackFit.expand,
            children: [
              StageBackground(asset: background),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StepsHeader(controller: controller),
                      _StatusNotice(controller: controller),
                      const SizedBox(height: 12),
                      if (stage == null)
                        _ChapterDoneCard(
                          engine: engine,
                          onSeeEnding: () =>
                              setState(() => _current = const EndingMoment()),
                        )
                      else ...[
                        _StageCard(
                          engine: engine,
                          stage: stage,
                          progress: chapter,
                        ),
                        // Durante el viaje no aparece nada: no hace falta.
                        if (!traveling) ...[
                          const SizedBox(height: 12),
                          _GoalsCard(
                            engine: engine,
                            stage: stage,
                            progress: chapter,
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      _ShopCard(
                        engine: engine,
                        coins: controller.coins,
                        onTap: _openShop,
                      ),
                      const SizedBox(height: 12),
                      _JourneyCard(engine: engine, progress: chapter),
                      if (widget.showDebug) ...[
                        const SizedBox(height: 12),
                        Panel(
                          padding: const EdgeInsets.all(8),
                          child: OutlinedButton(
                            onPressed: () =>
                                controller.addDebugSteps(debugStepBonus),
                            child: Text(Strings.debugAdd(debugStepBonus)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CoinChip(coins: controller.coins, onTap: _openShop),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.music case final music?) ...[
                          MusicButton(music: music),
                          const SizedBox(width: 8),
                        ],
                        BagButton(
                          key: _bagKey,
                          unseen: max(0, chapter.unseen - _inFlight),
                          onTap: _openBag,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: StageBackground.fadeDuration,
                child: switch (current) {
                  null => const SizedBox.shrink(),
                  ArrivalMoment(:final stage) => ArrivalScreen(
                    key: ObjectKey(current),
                    stage: stage,
                    onEnter: () => _enter(stage),
                  ),
                  EndingMoment() => EndingScreen(
                    key: ObjectKey(current),
                    background: engine.chapter.islandBackground,
                    onBack: _next,
                    onCredits: () => CreditsScreen.show(
                      context,
                      engine.chapter.walkingBackground,
                      music: widget.music,
                    ),
                  ),
                  DialogueMoment(:final stage) => DialogueView(
                    key: ObjectKey(current),
                    chapter: engine.chapter,
                    lines: stage.dialogue,
                    playerName: controller.playerName ?? '',
                    genero: controller.genero,
                    background: stage.background,
                    doneLabel: Strings.stageDialogueButton,
                    onDone: () => _entered(stage),
                  ),
                  CoinMoment(:final notice) => CoinNoticeOverlay(
                    key: ObjectKey(current),
                    chapter: engine.chapter,
                    notice: notice,
                    onDone: () => _coinNoticeSeen(notice),
                  ),
                  FoundMoment() => FoundItemOverlay(
                    key: ObjectKey(current),
                    moment: current,
                    target: _bagCenter,
                    onLanded: _onLanded,
                  ),
                  StageMoment(:final stage) => StageDoneOverlay(
                    key: ObjectKey(current),
                    chapter: engine.chapter,
                    stage: stage,
                    onDone: _next,
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  int? _precached;

  /// Carga de antemano los fondos que pueden venir (el de la etapa
  /// siguiente y el mapa), para que los fundidos no titilen.
  void _precacheNext(int stageIndex) {
    if (_precached == stageIndex) return;
    _precached = stageIndex;
    final chapter = widget.controller.engine.chapter;
    final upcoming = [
      AssetImage(chapter.walkingBackground),
      if (stageIndex + 1 < chapter.stages.length)
        AssetImage(chapter.stages[stageIndex + 1].background),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final image in upcoming) {
        precacheImage(image, context);
      }
    });
  }
}

/// Ilustración de la etapa a pantalla completa. Al cambiar de etapa, la
/// nueva aparece con un fundido suave sobre la anterior.
class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.asset});

  final String asset;

  static const fadeDuration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: fadeDuration,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class _StepsHeader extends StatelessWidget {
  const _StepsHeader({required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = controller.state;
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Text(Strings.todayLabel, style: text.titleMedium),
          Text(
            Strings.formatNumber(state.todaySteps),
            // Los números van en Nunito, no en la letra de títulos.
            style: text.displayMedium?.copyWith(
              fontFamily: textFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(Strings.total(state.totalSteps), style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.engine,
    required this.stage,
    required this.progress,
  });

  final ChapterEngine engine;
  final Stage stage;
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = engine.chapter.stages.length;
    final traveling = engine.isTraveling(progress);

    // Barra: durante el viaje, pasos del tramo; después, objetos juntados.
    final double value;
    if (traveling) {
      value = progress.stepsInStage / stage.travelSteps;
    } else {
      var have = 0, need = 0;
      for (final r in stage.requirements) {
        have += min(progress.count(r.item), r.count);
        need += r.count;
      }
      value = have / need;
    }

    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.stageOf(progress.stageIndex + 1, count),
              style: text.labelLarge,
            ),
            if (traveling)
              Text(
                Strings.walkingTo(stage.place, stage.placeArticle),
                style: text.headlineMedium,
              )
            else
              Text(stage.name, style: text.headlineSmall),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caminando, el personaje que camina; si no, el del diálogo.
                GameImage.of(
                  engine.chapter.character(
                    traveling
                        ? engine.chapter.walkingCharacter
                        : stage.introCharacter,
                  ),
                  size: 88,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(traveling ? stage.travelText : stage.intro),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            if (traveling) ...[
              const SizedBox(height: 6),
              Text(
                Strings.stageProgress(progress.stepsInStage, stage.travelSteps),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                GameImage(stage.reward.image, size: 32, dimmed: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Strings.reward(stage.reward.name),
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que pide la etapa, con cuánto hay, y el avance de cada canje.
class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.engine,
    required this.stage,
    required this.progress,
  });

  final ChapterEngine engine;
  final Stage stage;
  final ChapterProgress progress;

  /// Debajo de cada objeto: cómo o cuándo aparece.
  String? _hint(Requirement r, bool traveling) {
    if (progress.count(r.item) >= r.count) return null;
    for (final spawn in stage.spawns) {
      if (!spawn.items.contains(r.item)) continue;
      if (traveling) return Strings.afterArriving;
      if (spawn is RandomSpawn) return Strings.appearsRandomly;
      // Fijos: solo el próximo de la lista sabe cuántos pasos faltan.
      final next = spawn.items.firstWhere(
        (id) => progress.count(id) < stage.requiredCount(id),
      );
      if (next == r.item) {
        return Strings.stepsToNext(
          engine.stepsToNextFixed(progress, spawn as FixedSpawn),
        );
      }
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chapter = engine.chapter;
    final traveling = engine.isTraveling(progress);
    return Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                Strings.goalsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final r in stage.requirements)
              ListTile(
                leading: GameImage(
                  chapter.item(r.item).image,
                  size: 48,
                  dimmed: progress.count(r.item) == 0,
                ),
                title: Text(chapter.item(r.item).name),
                subtitle: switch (_hint(r, traveling)) {
                  final hint? => Text(hint),
                  null => null,
                },
                trailing: progress.count(r.item) >= r.count
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.count > 1)
                            Text(Strings.countOf(r.count, r.count)),
                          Icon(Icons.check_circle, color: colors.primary),
                        ],
                      )
                    : r.count > 1
                    ? Text(
                        Strings.countOf(progress.count(r.item), r.count),
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    : null,
              ),
            for (final exchange in stage.exchanges)
              if (_firstMissingOutput(exchange) case final output?)
                _ExchangeRow(
                  chapter: chapter,
                  exchange: exchange,
                  output: output,
                  have: exchange.inputs.fold(
                    0,
                    (s, id) => s + progress.count(id),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String? _firstMissingOutput(Exchange exchange) {
    for (final id in exchange.outputs) {
      if (progress.count(id) < stage.requiredCount(id)) return id;
    }
    return null;
  }
}

/// Canje: dibujos de los objetos comunes con su contador → lo que se recibe.
class _ExchangeRow extends StatelessWidget {
  const _ExchangeRow({
    required this.chapter,
    required this.exchange,
    required this.output,
    required this.have,
  });

  final Chapter chapter;
  final Exchange exchange;
  final String output;
  final int have;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final id in exchange.inputs)
                GameImage(chapter.item(id).image, size: 40, dimmed: have == 0),
              const SizedBox(width: 6),
              Text(
                Strings.countOf(have, exchange.count),
                style: text.titleMedium,
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward, color: colors.tertiary),
              const SizedBox(width: 6),
              GameImage(chapter.item(output).image, size: 40, dimmed: true),
            ],
          ),
          Text(
            Strings.exchangeProgress(
              exchange.inputs
                  .map((id) => chapter.item(id).name)
                  .join(Strings.or),
              have,
              exchange.count,
              chapter.item(output).name,
            ),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Entrada a la Tienda del Lobo, con el saldo.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.engine,
    required this.coins,
    required this.onTap,
  });

  final ChapterEngine engine;
  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const ValueKey('shop-card'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          // Quieto: el animado se ve adentro de la tienda.
          leading: GameImage.character(
            engine.chapter.character(shopkeeper).image,
            size: 56,
          ),
          title: Text(Strings.shopTitle, style: text.titleMedium),
          subtitle: Row(
            children: [
              const Icon(Icons.monetization_on, color: coinColor, size: 18),
              const SizedBox(width: 4),
              Flexible(child: Text(Strings.coinBalance(coins))),
            ],
          ),
          trailing: const Icon(Icons.storefront),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.engine, required this.progress});

  final ChapterEngine engine;
  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stages = engine.chapter.stages;
    return Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                Strings.journeyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < stages.length; i++)
              ListTile(
                dense: true,
                leading: switch (engine.statusOf(i, progress)) {
                  StageStatus.done => Icon(
                    Icons.check_circle,
                    color: colors.primary,
                  ),
                  StageStatus.current => Icon(
                    Icons.directions_walk,
                    color: colors.tertiary,
                  ),
                  StageStatus.locked => Icon(Icons.lock, color: colors.outline),
                },
                title: Text('${i + 1}. ${stages[i].name}'),
                subtitle: engine.statusOf(i, progress) == StageStatus.done
                    ? Text(Strings.reward(stages[i].reward.name))
                    : null,
                trailing: engine.statusOf(i, progress) == StageStatus.done
                    ? GameImage(stages[i].reward.image, size: 36)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChapterDoneCard extends StatelessWidget {
  const _ChapterDoneCard({required this.engine, required this.onSeeEnding});

  final ChapterEngine engine;
  final VoidCallback onSeeEnding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final last = engine.chapter.stages.last;
    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GameImage.of(
                  engine.chapter.character(last.completeCharacter),
                  size: 110,
                ),
                GameImage(last.reward.image, size: 130),
              ],
            ),
            Text(Strings.chapterDoneTitle, style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(last.completeMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSeeEnding,
              child: const Text(Strings.seeEnding),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) {
    final (message, action) = switch (controller.status) {
      StepStatus.loading => (Strings.loading, null),
      StepStatus.tracking => (null, null),
      StepStatus.needsPermission => (
        Strings.needsPermission,
        Strings.grantPermission,
      ),
      StepStatus.permissionBlocked => (
        Strings.permissionBlocked,
        Strings.openSettings,
      ),
      StepStatus.noSensor => (Strings.noSensor, null),
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Panel(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.askPermission,
                  child: Text(action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón redondo para silenciar o activar la música (se guarda).
class MusicButton extends StatelessWidget {
  const MusicButton({super.key, required this.music});

  final MusicController music;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: music,
      builder: (context, _) => Material(
        color: colors.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: IconButton(
          iconSize: 28,
          tooltip: music.muted ? Strings.musicOn : Strings.musicOff,
          icon: Icon(music.muted ? Icons.volume_off : Icons.volume_up),
          onPressed: music.toggleMuted,
        ),
      ),
    );
  }
}
