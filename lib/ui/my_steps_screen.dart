import 'package:material_ui/material_ui.dart';

import '../logic/step_history.dart';
import '../data/textos.dart';
import 'step_controller.dart';

enum StepPeriod { week, month, months }

/// Pestaña "Mis pasos": gráficos de barras de la semana, el mes y los meses.
class MyStepsScreen extends StatefulWidget {
  const MyStepsScreen({super.key, required this.controller});

  final StepController controller;

  @override
  State<MyStepsScreen> createState() => _MyStepsScreenState();
}

class _MyStepsScreenState extends State<MyStepsScreen> {
  var _period = StepPeriod.week;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.historyTitle)),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final history = widget.controller.history;
          final today = widget.controller.clock.now();
          final (title, bars, labels) = switch (_period) {
            StepPeriod.week => (
              Strings.lastSevenDays,
              history.week(today),
              (StepBar b) =>
                  '${Strings.weekdayShort(b.start.weekday)}\n'
                  '${b.start.day}',
            ),
            StepPeriod.month => (
              Strings.monthTitle(today.month, today.year),
              history.monthByWeeks(today),
              (StepBar b) => Strings.weekOfMonth((b.start.day - 1) ~/ 7 + 1),
            ),
            StepPeriod.months => (
              Strings.lastMonths(StepHistory.monthsShown),
              history.months(today),
              (StepBar b) => Strings.monthShort(b.start.month),
            ),
          };
          final total = bars.fold(0, (sum, b) => sum + b.steps);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<StepPeriod>(
                segments: const [
                  ButtonSegment(
                    value: StepPeriod.week,
                    label: Text(Strings.periodWeek),
                  ),
                  ButtonSegment(
                    value: StepPeriod.month,
                    label: Text(Strings.periodMonth),
                  ),
                  ButtonSegment(
                    value: StepPeriod.months,
                    label: Text(Strings.periodMonths),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: 24),
              Text(title, style: text.titleLarge),
              Text(Strings.periodTotal(total), style: text.bodyLarge),
              const SizedBox(height: 16),
              StepBarChart(bars: bars, label: labels),
              const SizedBox(height: 24),
              Text(Strings.historySince, style: text.bodySmall),
            ],
          );
        },
      ),
    );
  }
}

/// Gráfico de barras simple: el número arriba, la barra y la etiqueta abajo.
/// La última barra (hoy, o el período actual) va resaltada.
class StepBarChart extends StatelessWidget {
  const StepBarChart({
    super.key,
    required this.bars,
    required this.label,
    this.height = 220,
  });

  final List<StepBar> bars;
  final String Function(StepBar) label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final top = bars.fold(0, (m, b) => b.steps > m ? b.steps : m);
    return SizedBox(
      height: height + 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, bar) in bars.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      child: Text(
                        Strings.formatNumber(bar.steps),
                        style: text.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: top == 0 ? 2 : 2 + (height - 2) * bar.steps / top,
                      decoration: BoxDecoration(
                        color: i == bars.length - 1
                            ? colors.tertiary
                            : colors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: Text(
                        label(bar),
                        textAlign: TextAlign.center,
                        style: text.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
