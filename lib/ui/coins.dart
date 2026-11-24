import 'package:material_ui/material_ui.dart';

import '../data/chapter1.dart' show shopkeeper;
import '../data/textos.dart';
import '../logic/chapter.dart';
import '../logic/wallet.dart';
import 'theme.dart';
import 'widgets.dart';

/// Color de las monedas.
const coinColor = Color(0xFFF2B705);

/// Saldo de monedas, en una pastilla. Si tiene [onTap], es un botón.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.onTap});

  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.9),
      shape: const StadiumBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Tooltip(
          message: onTap == null ? Strings.bagCoins : Strings.coinsTooltip,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: coinColor, size: 30),
                const SizedBox(width: 6),
                Text(
                  Strings.formatNumber(coins),
                  key: const ValueKey('coin-balance'),
                  style: text.titleLarge?.copyWith(
                    fontFamily: textFont,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de monedas recibidas (bono del día o de bienvenida). Se cierra con
/// el botón o tocando afuera.
class CoinNoticeOverlay extends StatelessWidget {
  const CoinNoticeOverlay({
    super.key,
    required this.chapter,
    required this.notice,
    required this.onDone,
  });

  final Chapter chapter;
  final CoinNotice notice;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final welcome = notice.kind == CoinNoticeKind.welcome;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDone,
      child: ColoredBox(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Panel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (welcome)
                      GameImage.of(chapter.character(shopkeeper), size: 140)
                    else
                      const Icon(
                        Icons.monetization_on,
                        color: coinColor,
                        size: 96,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      welcome
                          ? Strings.welcomeBonus(notice.amount)
                          : Strings.dailyBonus(notice.amount),
                      textAlign: TextAlign.center,
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onDone,
                      child: const Text(Strings.coinNoticeButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
