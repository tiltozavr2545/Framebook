import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/library/library.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/title_row.dart';
import '../../shared/title_text.dart';
import '../title/title_routes.dart';

/// The chosen filter and order of "My ratings". Kept while the app is open.
typedef RatingsListView = ({WorkKind? kind, RatingsSort sort});

class RatingsListViewNotifier extends Notifier<RatingsListView> {
  @override
  RatingsListView build() => (kind: null, sort: RatingsSort.scoredAt);

  void filter(WorkKind? kind) => state = (kind: kind, sort: state.sort);

  void sortBy(RatingsSort sort) => state = (kind: state.kind, sort: sort);
}

final ratingsViewProvider =
    NotifierProvider<RatingsListViewNotifier, RatingsListView>(
      RatingsListViewNotifier.new,
    );

/// "My ratings": everything rated, from the local database — works offline.
class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(ratingsViewProvider);
    final all = ref.watch(ratedTitlesProvider).value;
    final shown = all == null
        ? null
        : arrangeRatings(all, kind: view.kind, sort: view.sort);

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
        null => const Center(child: CircularProgressIndicator()),
        _ when all!.isEmpty => EmptyMessage(
          icon: Icons.star_outline,
          text: l10n.ratingsEmpty,
        ),
        final shown => Column(
          children: [
            _KindFilter(selected: view.kind),
            Expanded(
              child: shown.isEmpty
                  ? EmptyMessage(
                      icon: Icons.filter_alt_off_outlined,
                      text: l10n.ratingsEmptyKind,
                    )
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, index) =>
                          _RatedRow(title: shown[index]),
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
      };
}

class _KindFilter extends ConsumerWidget {
  const _KindFilter({required this.selected});

  final WorkKind? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(ratingsViewProvider.notifier);
    final options = <(WorkKind?, String)>[
      (null, l10n.kindAll),
      (WorkKind.movie, l10n.kindMovies),
      (WorkKind.tv, l10n.kindSeries),
      (WorkKind.season, l10n.kindSeasons),
      (WorkKind.episode, l10n.kindEpisodes),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          for (final (kind, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: kind == selected,
                onSelected: (_) => notifier.filter(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatedRow extends StatelessWidget {
  const _RatedRow({required this.title});

  final RatedTitle title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TitleRow(
      posterPath: title.posterPath,
      lines: describeRated(l10n, title),
      onTap: () =>
          context.go('${Routes.ratings}/${TitleRoutes.path(title.key)}'),
      trailing: Text(
        formatMyScore(title.rating.scoreHalf),
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
