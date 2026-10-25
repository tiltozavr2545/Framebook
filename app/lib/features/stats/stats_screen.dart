import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/library.dart';
import '../../data/library/stats.dart';
import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/coverage_line.dart';
import '../../shared/format.dart';
import '../../shared/kind_filter.dart';
import '../../shared/title_row.dart';

/// The kind the statistics are filtered by; `null` — all. Kept while the app
/// is open.
class StatsKindNotifier extends Notifier<WorkKind?> {
  @override
  WorkKind? build() => null;

  void select(WorkKind? kind) => state = kind;
}

final statsKindProvider = NotifierProvider<StatsKindNotifier, WorkKind?>(
  StatsKindNotifier.new,
);

/// Genre names in the content language, from TMDB through the HTTP cache.
/// Empty when TMDB can't be reached and nothing is cached: the rest of the
/// statistics doesn't need a network.
final genreNamesProvider = FutureProvider.autoDispose<Map<int, String>>((
  ref,
) async {
  final tmdb = ref.watch(tmdbProvider);
  try {
    final lists = await Future.wait([
      tmdb.genres(WorkKind.tv),
      tmdb.genres(WorkKind.movie),
    ]);
    // Film names win where the lists share an id: they are the same genre.
    return {
      for (final list in lists)
        for (final genre in list) genre.id: genre.name,
    };
  } on SourceException {
    return const {};
  }
});

/// The Stats tab: computed from the local database, so it works offline.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = ref.watch(statsKindProvider);
    final all = ref.watch(ratedTitlesProvider).value;
    final titles = all == null
        ? null
        : [
            for (final title in all)
              if (kind == null || title.work.kind == kind) title,
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabStats),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: switch (titles) {
        null => const Center(child: CircularProgressIndicator()),
        _ when all!.isEmpty => EmptyMessage(
          icon: Icons.insights_outlined,
          text: l10n.statsEmpty,
        ),
        final titles => Column(
          children: [
            KindFilter(
              selected: kind,
              onSelected: ref.read(statsKindProvider.notifier).select,
            ),
            Expanded(
              child: titles.isEmpty
                  ? EmptyMessage(
                      icon: Icons.filter_alt_off_outlined,
                      text: l10n.ratingsEmptyKind,
                    )
                  : _StatsBody(titles: titles),
            ),
          ],
        ),
      },
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.titles});

  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = computeStats(titles);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          '${l10n.statsRatingCount(stats.count)} · '
          '${l10n.statsAverage(formatScore(stats.average!))}',
          style: theme.textTheme.titleMedium,
        ),
        _Heading(l10n.statsDistribution),
        _Distribution(counts: stats.distribution),
        _Heading(l10n.statsCompared),
        Text(
          l10n.statsComparedHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final source in compareSources)
          _DeviationTile(
            source: source,
            deviation: stats.deviation[source],
            titles: titles,
          ),
        if (stats.genres.isNotEmpty) ...[
          _Heading(l10n.statsGenres),
          _Genres(groups: stats.genres),
        ],
        if (stats.decades.isNotEmpty) ...[
          _Heading(l10n.statsDecades),
          for (final group in stats.decades)
            _GroupRow(label: l10n.statsDecade('${group.key}'), group: group),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// How many times each score from 1 to 10 was given, in half-point bars.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall;
    final most = counts.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: most.toDouble(),
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
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
                reservedSize: 24,
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
                    width: 10,
                    color: scheme.primary,
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

class _DeviationTile extends StatelessWidget {
  const _DeviationTile({
    required this.source,
    required this.deviation,
    required this.titles,
  });

  final RatingSource source;
  final Deviation? deviation;
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final name = ratingSourceLabel(l10n, source);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          if (deviation case final d?) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatDivergence(d.signed),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(l10n.statsDeviationOnAverage, style: muted),
                ),
              ],
            ),
            Text(
              '${l10n.statsDeviationAbsolute(formatScore(d.absolute))} · '
              '${l10n.statsDeviationCount(d.count)}',
              style: muted,
            ),
          ] else
            Text(l10n.statsDeviationNone(name), style: muted),
          CoverageLine(source: source, titles: titles),
        ],
      ),
    );
  }
}

class _Genres extends ConsumerWidget {
  const _Genres({required this.groups});

  final List<GroupAverage> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final names = ref.watch(genreNamesProvider);
    return switch (names) {
      AsyncData(value: final names) when names.isNotEmpty => Column(
        children: [
          for (final group in groups)
            if (names[group.key] case final name?)
              _GroupRow(label: _capitalized(name), group: group),
        ],
      ),
      AsyncData() => Text(
        l10n.statsGenresOffline,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      _ => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  /// TMDB's Russian genre names are lower case ("боевик").
  static String _capitalized(String name) =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// A genre or a decade: its name, how many ratings, the average with a bar.
class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.label, required this.group});

  final String label;
  final GroupAverage group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatScore(group.average),
                style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}
