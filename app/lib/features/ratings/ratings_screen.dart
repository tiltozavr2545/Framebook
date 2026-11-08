import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/ratings_preferences.dart';
export '../../app/ratings_preferences.dart';
import '../../app/router.dart';
import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/library.dart';
import '../../data/library/rating_days.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/coverage_line.dart';
import '../../shared/format.dart';
import '../../shared/score_color.dart';
import '../../shared/kind_filter.dart';
import '../../shared/title_row.dart';
import '../../shared/title_text.dart';
import '../../shared/local_data_failure.dart';
import '../title/title_routes.dart';
import 'ratings_model.dart';

/// "My ratings": everything rated, from the local database — works offline.
class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prepared = ref.watch(ratingsPageDataProvider);
    final saved = ref.watch(ratedTitlesProvider);
    final data = prepared.value;
    final RatingsListView view =
        data?.view ?? ref.watch<RatingsListView>(ratingsViewProvider);
    final all = data?.all;
    final shown = data?.shown;
    final items = data?.items ?? const <RatingListItem>[];
    final byDivergence = view.sort == RatingsSort.divergence;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabRatings),
        actions: [
          PopupMenuButton<RatingsSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.ratingsSort,
            initialValue: view.sort,
            onSelected: ref.read(ratingsViewProvider.notifier).sortBy,
            itemBuilder: (context) => [
              for (final sort in RatingsSort.values)
                PopupMenuItem(value: sort, child: Text(_sortLabel(l10n, sort))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: switch (shown) {
        null when prepared.hasError || saved.hasError => LocalDataFailure(
          onRetry: () {
            ref.invalidate(ratedTitlesProvider);
            ref.invalidate(ratingsPageDataProvider);
          },
        ),
        null => const Center(child: CircularProgressIndicator()),
        _ when all!.isEmpty => EmptyMessage(
          icon: Icons.star_outline,
          text: l10n.ratingsEmpty,
        ),
        final shown => Column(
          children: [
            KindFilter(
              selected: view.kind,
              onSelected: ref.read(ratingsViewProvider.notifier).filter,
            ),
            if (byDivergence) _DivergenceControls(view: view, titles: all),
            Expanded(
              child: shown.isEmpty
                  ? EmptyMessage(
                      icon: Icons.filter_alt_off_outlined,
                      text: l10n.ratingsEmptyKind,
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => switch (items[index]) {
                        RatingDay(:final date) => _DayHeading(date: date),
                        RatingItem(:final title) => _RatedRow(
                          title: title,
                          compareWith: byDivergence ? view.compareWith : null,
                        ),
                      },
                    ),
            ),
          ],
        ),
      },
    );
  }

  static String _sortLabel(AppLocalizations l10n, RatingsSort sort) =>
      switch (sort) {
        RatingsSort.scoredAt => l10n.ratingsSortDate,
        RatingsSort.score => l10n.ratingsSortScore,
        RatingsSort.year => l10n.ratingsSortYear,
        RatingsSort.title => l10n.ratingsSortTitle,
        RatingsSort.divergence => l10n.ratingsSortDivergence,
      };
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final text = date == today
        ? l10n.ratingDayToday
        : date == yesterday
        ? l10n.ratingDayYesterday
        : DateFormat.yMMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// Which source to compare with and in which direction, and how much of it
/// background refresh has loaded.
class _DivergenceControls extends ConsumerWidget {
  const _DivergenceControls({required this.view, required this.titles});

  final RatingsListView view;
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(ratingsViewProvider.notifier);
    final orders = <(DivergenceOrder, String)>[
      (DivergenceOrder.furthest, l10n.divergenceFurthest),
      (DivergenceOrder.higher, l10n.divergenceHigher),
      (DivergenceOrder.lower, l10n.divergenceLower),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipRow(
          children: [
            for (final source in compareSources)
              ChoiceChip(
                label: Text(ratingSourceLabel(l10n, source)),
                selected: source == view.compareWith,
                onSelected: (_) => notifier.compareWith(source),
              ),
            const SizedBox(height: 24, child: VerticalDivider(width: 8)),
            for (final (order, label) in orders)
              ChoiceChip(
                label: Text(label),
                selected: order == view.order,
                onSelected: (_) => notifier.orderBy(order),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CoverageLine(source: view.compareWith, titles: titles),
        ),
      ],
    );
  }
}

class _RatedRow extends StatelessWidget {
  const _RatedRow({required this.title, this.compareWith});

  final RatedTitle title;

  /// Sorting by divergence: show the value compared with and the gap.
  final RatingSource? compareWith;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = Text(
      formatMyScore(title.rating.scoreHalf),
      style: theme.textTheme.headlineSmall?.copyWith(
        color: scoreColor(context, title.rating.scoreHalf / 2),
        fontWeight: FontWeight.w600,
      ),
    );
    return TitleRow(
      posterPath: title.posterPath,
      lines: describeRated(l10n, title),
      onTap: () =>
          context.go('${Routes.ratings}/${TitleRoutes.path(title.key)}'),
      trailing: switch (compareWith) {
        null => score,
        final source => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            score,
            Text(
              switch ((title.divergenceFrom(source), title.external[source])) {
                (final d?, final row?) =>
                  '${formatScore(row.value!)} · ${formatDivergence(d)}',
                _ => l10n.ratingNoData,
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      },
    );
  }
}
