import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/insights_provider.dart';
import '../../data/library/library.dart';
import '../../data/library/prepared_views.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/coverage_line.dart';
import '../../shared/format.dart';
import '../../shared/kind_filter.dart';
import '../../shared/local_data_failure.dart';
import '../../shared/title_row.dart';
import '../search/people_shelves.dart';
import 'insight_sections.dart';
import 'stats_providers.dart';
import 'stats_widgets.dart';
import 'stats_works.dart';

enum StatsSection { scores, genres, people, comparison }

class StatsDetailScreen extends ConsumerWidget {
  const StatsDetailScreen({super.key, required this.section});
  final StatsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(ratedTitlesProvider);
    final computed = ref.watch(statsViewProvider);
    final data = computed.value;
    final heading = switch (section) {
      StatsSection.scores => l10n.statsDistribution,
      StatsSection.genres => l10n.statsGenresAndDecades,
      StatsSection.people => l10n.statsActorsDirectors,
      StatsSection.comparison => l10n.statsCompared,
    };
    final titlePainter = TextPainter(
      text: TextSpan(
        text: heading,
        style:
            Theme.of(context).appBarTheme.titleTextStyle ??
            Theme.of(context).textTheme.titleLarge,
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      maxLines: 2,
    )..layout(maxWidth: MediaQuery.sizeOf(context).width - 88);
    final measuredHeight = titlePainter.height + 16;
    titlePainter.dispose();
    return Scaffold(
      appBar: AppBar(
        title: Text(heading, maxLines: 2, overflow: TextOverflow.ellipsis),
        toolbarHeight: measuredHeight > kToolbarHeight
            ? measuredHeight
            : kToolbarHeight,
      ),
      body: data == null
          ? saved.hasError || computed.hasError
                ? LocalDataFailure(
                    onRetry: () {
                      ref.invalidate(ratedTitlesProvider);
                      ref.invalidate(statsViewProvider);
                    },
                  )
                : const Center(child: CircularProgressIndicator())
          : data.titles.isEmpty
          ? EmptyMessage(
              icon: Icons.insights_outlined,
              text: l10n.ratingsEmptyKind,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${_kind(l10n, data.kind)} · ${l10n.statsRatingCount(data.stats.count)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: switch (section) {
                    StatsSection.scores => _Scores(data: data),
                    StatsSection.genres => _Genres(data: data),
                    StatsSection.people => _People(
                      key: ValueKey(data.kind),
                      data: data,
                    ),
                    StatsSection.comparison => _Comparison(data: data),
                  },
                ),
              ],
            ),
    );
  }

  String _kind(AppLocalizations l10n, WorkKind? kind) => switch (kind) {
    WorkKind.movie => l10n.kindMovies,
    WorkKind.tv => l10n.kindSeries,
    WorkKind.season => l10n.kindSeasons,
    WorkKind.episode => l10n.kindEpisodes,
    null => l10n.kindAll,
  };
}

class _Scores extends StatelessWidget {
  const _Scores({required this.data});
  final StatsView data;
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      20,
      8,
      20,
      24 + MediaQuery.paddingOf(context).bottom,
    ),
    children: [
      ScoreDistribution(
        counts: data.stats.distribution,
        onSelected: (half) => _open(context, half),
      ),
      const SizedBox(height: 20),
      for (var i = 18; i >= 0; i--)
        if (data.stats.distribution[i] > 0)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(formatMyScore(i + 2)),
            subtitle: Text(
              AppLocalizations.of(
                context,
              ).statsRatingCount(data.stats.distribution[i]),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, i + 2),
          ),
    ],
  );
  void _open(BuildContext context, int half) => showRatedWorks(
    context,
    formatMyScore(half),
    data.titles.where((t) => t.rating.scoreHalf == half).toList(),
  );
}

class _Genres extends ConsumerWidget {
  const _Genres({required this.data});
  final StatsView data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final names = ref.watch(genreNamesProvider);
    return CustomScrollView(
      slivers: [
        if (data.stats.genres.isNotEmpty) ...[
          SliverToBoxAdapter(child: StatsHeading(l10n.statsGenres)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(
              children: [
                if (names.isLoading && !names.hasValue)
                  const LinearProgressIndicator()
                else if (names.value?.isEmpty ?? true)
                  Text(l10n.statsGenresOffline),
                for (final group in data.stats.genres)
                  if (names.value?[group.key] case final name?)
                    StatsGroupRow(
                      label: capitalizedGenre(name),
                      group: group,
                      onTap: () => showRatedWorks(
                        context,
                        capitalizedGenre(name),
                        data.titles
                            .where((t) => t.genreIds.contains(group.key))
                            .toList(),
                      ),
                    ),
              ],
            ),
          ),
        ],
        if (data.stats.decades.isNotEmpty) ...[
          SliverToBoxAdapter(child: StatsHeading(l10n.statsDecades)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(
              children: [
                for (final group in data.stats.decades)
                  StatsGroupRow(
                    label: l10n.statsDecade('${group.key}'),
                    group: group,
                    onTap: () => showRatedWorks(
                      context,
                      l10n.statsDecade('${group.key}'),
                      data.titles
                          .where(
                            (t) =>
                                t.work.year != null &&
                                t.work.year! - t.work.year! % 10 == group.key,
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (data.stats.genres.isEmpty && data.stats.decades.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyMessage(
              icon: Icons.local_movies_outlined,
              text: l10n.statsNoCategories,
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }
}

class _People extends ConsumerWidget {
  const _People({super.key, required this.data});
  final StatsView data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(libraryInsightsProvider(data.kind));
    if (!insights.hasValue) {
      if (insights.hasError) {
        return LocalDataFailure(
          onRetry: () => ref.invalidate(libraryInsightsProvider(data.kind)),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: StatsPeopleSection(
            titles: data.titles,
            insights: insights.value!,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: const PeopleIndexProgress(),
          ),
        ),
      ],
    );
  }
}

class _Comparison extends StatefulWidget {
  const _Comparison({required this.data});
  final StatsView data;
  @override
  State<_Comparison> createState() => _ComparisonState();
}

class _ComparisonState extends State<_Comparison> {
  RatingSource _source = RatingSource.kp;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = ratingSourceLabel(l10n, _source);
    final deviation = widget.data.stats.deviation[_source];
    final breakdown = widget.data.sources[_source]!;
    return ListView(
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        ChipRow(
          children: [
            for (final source in compareSources)
              ChoiceChip(
                label: Text(ratingSourceLabel(l10n, source)),
                selected: _source == source,
                onSelected: (_) => setState(() => _source = source),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deviation case final d?) ...[
                Text(
                  (d.signed * 10).round() == 0
                      ? l10n.statsRatesSame
                      : d.signed > 0
                      ? l10n.statsRatesHigher(formatScore(d.signed))
                      : l10n.statsRatesLower(formatScore(-d.signed)),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.statsDeviationCount(d.count),
                  style: theme.textTheme.bodyMedium,
                ),
              ] else
                Text(
                  l10n.statsDeviationNone(name),
                  style: theme.textTheme.bodyLarge,
                ),
              CoverageLine(source: _source, titles: widget.data.titles),
              if (breakdown.count > 0) ...[
                const SizedBox(height: 20),
                StatsLink(
                  icon: Icons.list_outlined,
                  title: l10n.statsSourceWorks,
                  subtitle: l10n.statsRatingCount(breakdown.count),
                  onTap: () => showRatedWorks(
                    context,
                    name,
                    widget.data.titles
                        .where((t) => t.divergenceFrom(_source) != null)
                        .toList(),
                    compareWith: _source,
                  ),
                ),
                if (breakdown.higher.isNotEmpty ||
                    breakdown.lower.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.statsFindsHint, style: theme.textTheme.bodySmall),
                  if (breakdown.higher.isNotEmpty)
                    StatsLink(
                      icon: Icons.north_east,
                      title: l10n.statsFinds,
                      subtitle: l10n.statsRatingCount(breakdown.higher.length),
                      onTap: () => showRatedWorks(
                        context,
                        '${l10n.statsFinds} · $name',
                        breakdown.higher,
                        compareWith: _source,
                      ),
                    ),
                  if (breakdown.lower.isNotEmpty)
                    StatsLink(
                      icon: Icons.south_east,
                      title: l10n.statsDisappointments,
                      subtitle: l10n.statsRatingCount(breakdown.lower.length),
                      onTap: () => showRatedWorks(
                        context,
                        '${l10n.statsDisappointments} · $name',
                        breakdown.lower,
                        compareWith: _source,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
