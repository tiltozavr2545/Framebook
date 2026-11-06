import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/library.dart';
import '../../data/library/stats.dart';
import '../../data/library/insights.dart';
import '../../data/library/insights_provider.dart';
import '../../data/library/people_index.dart';
import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/coverage_line.dart';
import '../../shared/format.dart';
import '../../shared/score_color.dart';
import '../../shared/kind_filter.dart';
import '../../shared/title_row.dart';
import '../search/people_shelves.dart';
import 'insight_sections.dart';
import 'stats_works.dart';

/// The kind the statistics are filtered by; `null` — all. Kept while the app
/// is open.
class StatsKindNotifier extends Notifier<WorkKind?> {
  @override
  WorkKind? build() => WorkKind.movie;

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
              includeAll: false,
              onSelected: ref.read(statsKindProvider.notifier).select,
            ),
            Expanded(
              child: titles.isEmpty
                  ? EmptyMessage(
                      icon: Icons.filter_alt_off_outlined,
                      text: l10n.ratingsEmptyKind,
                    )
                  : _StatsBody(key: ValueKey(kind), titles: titles),
            ),
          ],
        ),
      },
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({super.key, required this.titles});

  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = computeStats(titles);
    final index = ref.watch(peopleIndexProvider);
    final insights =
        ref
            .watch(libraryInsightsProvider(ref.watch(statsKindProvider)))
            .value ??
        emptyLibraryInsights;
    final profile = ScoreProfile(titles);
    final sortedScores = titles.map((t) => t.rating.scoreHalf).toList()..sort();
    final middle = sortedScores.length ~/ 2;
    final median = sortedScores.length.isOdd
        ? sortedScores[middle] / 2
        : (sortedScores[middle - 1] + sortedScores[middle]) / 4;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              Text(l10n.statsAllTime, style: theme.textTheme.bodySmall),
              // The personal average uses the same score colours as title cards.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatScore(stats.average!),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: scoreColor(context, stats.average!),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.statsAverageOver(stats.count),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
              Text('${l10n.statsMedian}: ${formatScore(median)}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (label, subset) in [
                    (
                      l10n.statsScoreHigh,
                      titles.where((t) => t.rating.scoreHalf >= 16).toList(),
                    ),
                    (
                      l10n.statsScoreMiddle,
                      titles
                          .where(
                            (t) =>
                                t.rating.scoreHalf > 8 &&
                                t.rating.scoreHalf < 16,
                          )
                          .toList(),
                    ),
                    (
                      l10n.statsScoreLow,
                      titles.where((t) => t.rating.scoreHalf <= 8).toList(),
                    ),
                  ])
                    ActionChip(
                      label: Text(
                        '$label · ${(subset.length / profile.count * 100).round()}%',
                      ),
                      onPressed: subset.isEmpty
                          ? null
                          : () => showRatedWorks(context, label, subset),
                    ),
                ],
              ),
              _Heading(l10n.statsDistribution),
              _Distribution(
                counts: stats.distribution,
                onSelected: (half) => showRatedWorks(
                  context,
                  formatMyScore(half),
                  titles.where((t) => t.rating.scoreHalf == half).toList(),
                ),
              ),
              _Heading(l10n.statsCompared),
              Text(
                l10n.statsComparedHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.statsCorrelationHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(l10n.statsFindsHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final source in compareSources)
                _DeviationTile(
                  source: source,
                  deviation: stats.deviation[source],
                  titles: titles,
                ),
              if (stats.genres.isNotEmpty) ...[
                _Heading(l10n.statsGenres),
                _Genres(groups: stats.genres, titles: titles),
              ],
              if (stats.decades.isNotEmpty) ...[
                _Heading(l10n.statsDecades),
                for (final group in stats.decades)
                  _GroupRow(
                    label: l10n.statsDecade('${group.key}'),
                    group: group,
                    onTap: () => showRatedWorks(
                      context,
                      l10n.statsDecade('${group.key}'),
                      titles
                          .where(
                            (t) =>
                                t.work.year != null &&
                                t.work.year! - t.work.year! % 10 == group.key,
                          )
                          .toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: InsightSections(
            titles: titles,
            insights: insights,
            genreNames: ref.watch(genreNamesProvider).value ?? {},
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(child: PeopleLoadStatus(index: index)),
        ),
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
    child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
  );
}

/// How many times each score from 1 to 10 was given, in half-point bars.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.counts, required this.onSelected});

  final List<int> counts;
  final ValueChanged<int> onSelected;

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
    // Ruled like the ratings on a card, no plate.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
        ),
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
          const SizedBox(height: 8),
          SourceInsights(source: source, titles: titles),
        ],
      ),
    );
  }
}

class _Genres extends ConsumerWidget {
  const _Genres({required this.groups, required this.titles});

  final List<GroupAverage> groups;
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final names = ref.watch(genreNamesProvider);
    return switch (names) {
      AsyncData(value: final names) when names.isNotEmpty => Column(
        children: [
          for (final group in groups)
            if (names[group.key] case final name?)
              _GroupRow(
                label: _capitalized(name),
                group: group,
                onTap: () => showRatedWorks(
                  context,
                  _capitalized(name),
                  titles.where((t) => t.genreIds.contains(group.key)).toList(),
                ),
              ),
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
  const _GroupRow({required this.label, required this.group, this.onTap});

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
