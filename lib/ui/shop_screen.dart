import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart' show shopBackground, shopkeeper;
import '../data/textos.dart' as t;
import '../data/textos.dart' show Strings;
import '../logic/chapter_engine.dart';
import '../logic/shop.dart';
import '../logic/story.dart';
import 'coins.dart';
import 'step_controller.dart';
import 'widgets.dart';

/// Tienda del Lobo: se compran los objetos que faltan en la etapa actual.
/// El Lobo comenta cada cosa que pasa.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.controller, this.random});

  final StepController controller;

  /// Para elegir qué dice el Lobo (en los tests, con semilla fija).
  final Random? random;

  static Future<void> open(BuildContext context, StepController controller) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShopScreen(controller: controller),
        ),
      );

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final Random _random = widget.random ?? Random();
  late String _line = _greeting();
  var _saying = 0;
  var _buying = false;

  StepController get _controller => widget.controller;

  String _pick(List<String> lines) => lines[_random.nextInt(lines.length)];

  /// Lo primero que dice: por qué está cerrada, o un saludo.
  String _greeting() =>
      _closedLine(_controller.shop.closedReason(_controller.game.chapter)) ??
      _pick(t.loboSaludos);

  String? _closedLine(ShopClosed? reason) => switch (reason) {
    null => null,
    ShopClosed.traveling => t.loboViajando,
    ShopClosed.notEntered => t.loboSinEntrar,
    ShopClosed.chapterDone => t.loboFinal,
  };

  /// Tocar al Lobo: dice otra cosa.
  void _chat() => setState(() {
    _line = t.loboDichos[_saying % t.loboDichos.length];
    _saying++;
  });

  Future<void> _buy(Offer offer) async {
    if (_buying) return;
    final coins = _controller.coins;
    if (coins < offer.price) {
      setState(
        () => _line = t.loboSinMonedas.replaceAll(
          '{faltan}',
          Strings.formatNumber(offer.price - coins),
        ),
      );
      return;
    }
    _buying = true;
    final purchase = await _controller.buy(offer.item.id);
    _buying = false;
    if (!mounted || purchase == null) return;
    final completed = purchase.events.any((e) => e is StageCompleted);
    setState(
      () => _line = completed
          ? t.loboEtapaCompleta
          : _pick(t.loboCompra).replaceAll('{objeto}', offer.item.foundName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(Strings.shopTitle),
        backgroundColor: Theme.of(context).colorScheme.surface
            .withValues(alpha: 0.85),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinChip(coins: _controller.coins),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            shopBackground,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final chapter = _controller.game.chapter;
                final engine = _controller.engine;
                final stage = engine.currentStage(chapter);
                final offers = _controller.shop.offers(chapter);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _LoboSays(
                      line: paraQuienJuega(
                        _line,
                        _controller.playerName ?? '',
                        _controller.genero,
                      ),
                      onTap: _chat,
                      lobo: GameImage.of(
                        engine.chapter.character(shopkeeper),
                        size: 170,
                      ),
                    ),
                    if (offers.isNotEmpty && stage != null) ...[
                      const SizedBox(height: 12),
                      Panel(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                '${Strings.shopForSale}: ${stage.name}',
                                style: text.titleMedium,
                              ),
                            ),
                            for (final offer in offers)
                              ListTile(
                                key: ValueKey('offer-${offer.item.id}'),
                                leading: GameImage(offer.item.image, size: 48),
                                title: Text(offer.item.name),
                                subtitle: Text(
                                  Strings.shopMissing(offer.missing),
                                ),
                                trailing: FilledButton.icon(
                                  onPressed: () => _buy(offer),
                                  style: _controller.coins < offer.price
                                      ? FilledButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                        )
                                      : null,
                                  icon: const Icon(
                                    Icons.monetization_on,
                                    color: coinColor,
                                  ),
                                  label: Text(Strings.shopPrice(offer.price)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Panel(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        Strings.coinsHowTo,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// El Lobo con su globo de diálogo. Se lo toca para charlar.
class _LoboSays extends StatelessWidget {
  const _LoboSays({
    required this.line,
    required this.onTap,
    required this.lobo,
  });

  final String line;
  final VoidCallback onTap;
  final Widget lobo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.lobo,
                    style: text.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      line,
                      key: ValueKey(line),
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          lobo,
          Text(
            Strings.shopTapLobo,
            style: text.labelMedium?.copyWith(
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
