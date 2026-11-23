import 'package:material_ui/material_ui.dart';

import '../logic/chapter.dart';
import '../data/textos.dart';
import 'step_controller.dart';
import 'widgets.dart';

/// Ícono de la bolsa, con el número de objetos nuevos sin ver. Rebota con
/// [BagButtonState.bounce] cuando le llega un objeto.
class BagButton extends StatefulWidget {
  const BagButton({super.key, required this.unseen, required this.onTap});

  final int unseen;
  final VoidCallback onTap;

  static const bounceDuration = Duration(milliseconds: 450);

  @override
  State<BagButton> createState() => BagButtonState();
}

class BagButtonState extends State<BagButton>
    with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(
    vsync: this,
    duration: BagButton.bounceDuration,
  );

  void bounce() => _bounce.forward(from: 0);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        // Crece y vuelve, con un pequeño rebote.
        final t = _bounce.value;
        final scale =
            1 + 0.35 * Curves.easeOut.transform(1 - (2 * t - 1).abs());
        return Transform.scale(
          scale: _bounce.isAnimating ? scale : 1,
          child: child,
        );
      },
      child: Material(
        color: colors.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Badge(
              isLabelVisible: widget.unseen > 0,
              label: Text('${widget.unseen}'),
              child: Icon(
                Icons.backpack,
                size: 32,
                color: colors.primary,
                semanticLabel: Strings.bagButton,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Todo lo conseguido en el capítulo, con su cantidad, y las recompensas.
class BagScreen extends StatelessWidget {
  const BagScreen({super.key, required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) {
    final engine = controller.engine;
    final chapter = engine.chapter;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.bagTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final progress = controller.game.chapter;
          final items = [
            for (final item in chapter.items)
              if (progress.foundCount(item.id) > 0) item,
          ];
          final rewards = engine.rewardsEarned(progress);
          return CustomScrollView(
            slivers: [
              _title(Strings.bagItems, text),
              if (items.isEmpty)
                _note(Strings.bagEmpty)
              else
                _grid([
                  for (final item in items)
                    _BagTile(
                      image: item.image,
                      label: item.name,
                      badge: Strings.times(progress.foundCount(item.id)),
                      onTap: () => _showItem(context, chapter, item),
                    ),
                ]),
              _title(Strings.bagRewards, text),
              if (rewards.isEmpty)
                _note(Strings.noRewardsYet)
              else
                _grid([
                  for (final (i, reward) in rewards.indexed)
                    _BagTile(
                      image: reward.image,
                      label: reward.name,
                      onTap: () => _showReward(context, chapter, i),
                    ),
                ]),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _title(String title, TextTheme text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    sliver: SliverToBoxAdapter(child: Text(title, style: text.titleLarge)),
  );

  Widget _note(String note) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverToBoxAdapter(child: Text(note)),
  );

  Widget _grid(List<Widget> tiles) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    sliver: SliverGrid.extent(
      maxCrossAxisExtent: 120,
      childAspectRatio: 0.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    ),
  );

  void _showItem(BuildContext context, Chapter chapter, ItemType item) {
    final where = chapter.stageWhereFound(item.id);
    _showDetail(
      context,
      image: item.image,
      title: item.name,
      lines: [
        for (final use in chapter.usesOf(item.id)) _useText(chapter, item, use),
        if (where != null)
          Strings.foundIn(where + 1, chapter.stages[where].name),
      ],
    );
  }

  void _showReward(BuildContext context, Chapter chapter, int stageIndex) {
    final stage = chapter.stages[stageIndex];
    _showDetail(
      context,
      image: stage.reward.image,
      title: stage.reward.name,
      lines: [Strings.rewardOf(stageIndex + 1, stage.name)],
    );
  }

  void _showDetail(
    BuildContext context, {
    required String image,
    required String title,
    required List<String> lines,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: GameImage(image, size: 160),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line, textAlign: TextAlign.center),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.close),
          ),
        ],
      ),
    );
  }
}

/// Texto de "para qué sirve" un objeto.
String _useText(Chapter chapter, ItemType item, ItemUse use) => switch (use) {
  NeededFor(:final stage, :final count) => Strings.neededFor(count, stage.name),
  TradedIn(:final stage, :final exchange) => Strings.tradedFor(
    exchange.count,
    exchange.outputs.length == 1
        ? chapter.item(exchange.outputs.single).foundName
        : Strings.whatIsMissing(stage.name),
    switch ([
      for (final id in exchange.inputs)
        if (id != item.id) chapter.item(id).name,
    ]) {
      [] => null,
      final others => others.join(Strings.or),
    },
  ),
};

class _BagTile extends StatelessWidget {
  const _BagTile({
    required this.image,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final String image;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(child: GameImage(image, size: 72)),
                    if (badge != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Text(
                          badge!,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
