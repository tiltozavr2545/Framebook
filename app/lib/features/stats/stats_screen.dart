import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/library/library.dart';
import '../../data/library/prepared_views.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/horizontal_shelf.dart';
import '../../shared/local_data_failure.dart';
import '../../shared/poster.dart';
import '../../shared/score_color.dart';
import '../../shared/title_row.dart';
import '../../shared/title_text.dart';
import '../title/my_rating.dart';
import '../title/title_routes.dart';
import 'pair_calibration_screen.dart';
import 'stats_kind_switcher.dart';
import 'stats_providers.dart';
import 'stats_widgets.dart';
import 'stats_works.dart';

export 'stats_providers.dart';

/// A small local overview; deeper statistics have their own routes.
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
    final names = ref.watch(genreNamesProvider).value ?? {};
    final genres = prepared.favoriteGenres
        .where((g) => names.containsKey(g.key))
        .take(3)
        .toList();
    // These bounded sections need exact extents from the first layout. Lazy
    // lists estimate unequal row heights and revise the scroll range mid-drag.
    return CustomScrollView(
      key: PageStorageKey('stats-overview-${prepared.kind}'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.statsAllTime, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                _Summary(prepared: prepared),
                if (prepared.kind == WorkKind.movie)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: PairCalibrationEntry(
                      filmCount: prepared.titles.length,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (prepared.topRated.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: StatsHeading(
              l10n.statsTopRated,
              action: TextButton(
                onPressed: () => showRatedWorks(
                  context,
                  l10n.statsTopRated,
                  prepared.topRated,
                ),
                child: Text(l10n.statsSeeAll),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _TopShelf(titles: prepared.topRated.take(6).toList()),
          ),
        ],
        if (genres.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: StatsHeading(
              l10n.statsFavoriteGenres,
              action: TextButton(
                onPressed: () => context.push(Routes.statsGenres),
                child: Text(l10n.statsSeeAll),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  for (final genre in genres)
                    StatsGroupRow(
                      label: capitalizedGenre(names[genre.key]!),
                      group: genre,
                      onTap: () => showRatedWorks(
                        context,
                        capitalizedGenre(names[genre.key]!),
                        prepared.titles
                            .where((t) => t.genreIds.contains(genre.key))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                StatsLink(
                  icon: Icons.bar_chart_outlined,
                  title: l10n.statsDistribution,
                  subtitle: l10n.statsScoresLinkHint,
                  onTap: () => context.push(Routes.statsScores),
                ),
                StatsLink(
                  icon: Icons.local_movies_outlined,
                  title: l10n.statsGenresAndDecades,
                  subtitle: l10n.statsGenresLinkHint,
                  onTap: () => context.push(Routes.statsGenres),
                ),
                StatsLink(
                  icon: Icons.people_outline,
                  title: l10n.statsActorsDirectors,
                  subtitle: l10n.statsPeopleLinkHint,
                  onTap: () => context.push(Routes.statsPeople),
                ),
                StatsLink(
                  icon: Icons.compare_arrows_outlined,
                  title: l10n.statsCompared,
                  subtitle: l10n.statsCompareLinkHint,
                  onTap: () => context.push(Routes.statsComparison),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.prepared});
  final StatsView prepared;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget figure(
      String value,
      String label, {
      Color? color,
      VoidCallback? onTap,
    }) => InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
    final count = figure(
      '${prepared.stats.count}',
      l10n.statsRated,
      onTap: () => showRatedWorks(context, l10n.tabRatings, prepared.titles),
    );
    final average = figure(
      formatScore(prepared.stats.average!),
      l10n.statsAverage,
      color: scoreColor(context, prepared.stats.average!),
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < MediaQuery.textScalerOf(context).scale(180)
          ? Column(children: [count, const SizedBox(height: 12), average])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: count),
                const SizedBox(width: 24),
                Expanded(child: average),
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
