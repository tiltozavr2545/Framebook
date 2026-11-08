import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/library/stats.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/score_color.dart';

String capitalizedGenre(String name) =>
    name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

class StatsHeading extends StatelessWidget {
  const StatsHeading(this.text, {super.key, this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

class StatsLink extends StatelessWidget {
  const StatsLink({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Icon(
        icon,
        color: onTap == null
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.primary,
      ),
      enabled: onTap != null,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

/// How many times each score from 1 to 10 was given, in half-point bars.
class ScoreDistribution extends StatelessWidget {
  const ScoreDistribution({
    super.key,
    required this.counts,
    required this.onSelected,
  });

  final List<int> counts;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall;
    final most = counts.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180 + MediaQuery.textScalerOf(context).scale(24),
      child: BarChart(
        BarChartData(
          maxY: most.toDouble(),
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              final spot = response?.spot;
              if (event is FlTapUpEvent && spot != null) {
                onSelected(spot.touchedBarGroup.x + 2);
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${formatMyScore(group.x + 2)}: ${rod.toY.round()}',
                theme.textTheme.labelMedium!.copyWith(
                  color: scheme.onInverseSurface,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: MediaQuery.textScalerOf(context).scale(24),
                // Whole scores only: 19 labels don't fit a phone.
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    value.toInt().isEven ? '${value.toInt() ~/ 2 + 1}' : '',
                    style: label,
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < counts.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: counts[i].toDouble(),
                    width: 7,
                    color: scoreColor(context, (i + 2) / 2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
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

/// A genre or a decade: its name, how many ratings, the average with a bar.
class StatsGroupRow extends StatelessWidget {
  const StatsGroupRow({
    super.key,
    required this.label,
    required this.group,
    this.onTap,
  });

  final String label;
  final GroupAverage group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: label),
                        TextSpan(
                          text: ' · ${l10n.statsRatingCount(group.count)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  formatScore(group.average),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scoreColor(context, group.average),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: group.average / 10,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }
}
