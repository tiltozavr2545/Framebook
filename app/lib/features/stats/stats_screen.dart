import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/library.dart';
import '../../data/library/prepared_views.dart';
import '../../data/library/stats.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/coverage_line.dart';
import '../../shared/format.dart';
import '../../shared/local_data_failure.dart';
import '../../shared/score_color.dart';
import '../../shared/title_row.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../shared/horizontal_shelf.dart';
import '../../shared/poster.dart';
import '../../shared/title_text.dart';
import '../title/my_rating.dart';
import '../title/title_routes.dart';
import 'stats_widgets.dart';
import 'stats_works.dart';
import 'stats_kind_switcher.dart';
import 'stats_providers.dart';

export 'stats_providers.dart';

/// All-time local statistics with the original single-page presentation.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(ratedTitlesProvider);
    final computed = ref.watch(statsViewProvider);
    final prepared = computed.value;
    final requestedKind = ref.watch(statsKindProvider);
    final kind = prepared != null ? prepared.kind : requestedKind;
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
      body: prepared == null
          ? saved.hasError || computed.hasError
                ? LocalDataFailure(
                    onRetry: () {
                      ref.invalidate(ratedTitlesProvider);
                      ref.invalidate(statsViewProvider);
                    },
                  )
                : const Center(child: CircularProgressIndicator())
          : saved.value?.isEmpty == true
          ? EmptyMessage(icon: Icons.insights_outlined, text: l10n.statsEmpty)
          : Column(
              children: [
                StatsKindSwitcher(
                  selected: kind,
                  onSelected: ref.read(statsKindProvider.notifier).select,
                ),
                Expanded(
                  child: prepared.titles.isEmpty
                      ? EmptyMessage(
                          icon: Icons.filter_alt_off_outlined,
                          text: l10n.ratingsEmptyKind,
                        )
                      : _Overview(
                          key: ValueKey(prepared.kind),
                          prepared: prepared,
                        ),
                ),
              ],
            ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({super.key, required this.prepared});

  final StatsView prepared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final names = ref.watch(genreNamesProvider);
    final stats = prepared.stats;
    final titles = prepared.titles;
    return SingleChildScrollView(
      key: PageStorageKey('stats-overview-${prepared.kind}'),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The personal average uses the same score colours as title cards.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width - 46) * .48,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatScore(stats.average!),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: scoreColor(context, stats.average!),
                    ),
                  ),
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
          _Heading(l10n.statsDistribution),
          _Distribution(counts: stats.distribution),
          if (prepared.topRated.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _Heading(l10n.statsTopRated)),
                TextButton(
                  onPressed: () => showRatedWorks(
                    context,
                    l10n.statsTopRated,
                    prepared.topRated,
                  ),
                  child: Text(l10n.statsSeeAll),
                ),
              ],
            ),
            _TopShelf(titles: prepared.topRated.take(6).toList()),
          ],
          if (stats.decades.isNotEmpty) ...[
            _Heading(l10n.statsDecades),
            for (final decade in stats.decades)
              StatsGroupRow(
                label: l10n.statsDecade('${decade.key}'),
                group: decade,
                onTap: () => showRatedWorks(
                  context,
                  l10n.statsDecade('${decade.key}'),
                  titles
                      .where(
                        (t) =>
                            t.work.year != null &&
                            t.work.year! - t.work.year! % 10 == decade.key,
                      )
                      .toList(),
                ),
              ),
          ],
          if (stats.genres.isNotEmpty) ...[
            _Heading(l10n.statsGenres),
            if (names.isLoading && !names.hasValue)
              const LinearProgressIndicator()
            else if (names.value?.isEmpty ?? true)
              Text(l10n.statsGenresOffline),
            for (final genre in stats.genres)
              if (names.value?[genre.key] case final name?)
                StatsGroupRow(
                  label: capitalizedGenre(name),
                  group: genre,
                  onTap: () => showRatedWorks(
                    context,
                    capitalizedGenre(name),
                    titles
                        .where((t) => t.genreIds.contains(genre.key))
                        .toList(),
                  ),
                ),
          ],
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
        ],
      ),
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
  const _Distribution({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall;
    final most = counts.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 136 + MediaQuery.textScalerOf(context).scale(24),
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
        ],
      ),
    );
  }
}

class _TopShelf extends StatelessWidget {
  const _TopShelf({required this.titles});
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double textHeight(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 2,
      )..layout(maxWidth: 112);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    var textExtent = 0.0;
    for (final title in titles) {
      final lines = describeRated(AppLocalizations.of(context), title);
      final height =
          textHeight(lines.title, theme.textTheme.titleSmall) +
          textHeight(lines.subtitle, theme.textTheme.labelSmall);
      if (height > textExtent) textExtent = height;
    }
    return SizedBox(
      height: 168 + 6 + textExtent,
      child: HorizontalShelf(
        itemKeys: [for (final title in titles) title.key],
        itemWidth: 112,
        itemBuilder: (context, i) {
          final title = titles[i];
          final lines = describeRated(AppLocalizations.of(context), title);
          return InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () =>
                context.push('${Routes.stats}/${TitleRoutes.path(title.key)}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Poster(title.posterPath, size: ImageSize.w185, width: 112),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: MyScoreBadge(title.key, onPoster: true),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lines.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  lines.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
