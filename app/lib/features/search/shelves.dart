import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/library/library.dart';
import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/poster.dart';
import '../title/my_rating.dart';
import '../title/title_routes.dart';

// The Discover shelves (Stage 6): what to look at when there is nothing to
// search for yet. All of them come from TMDB through the HTTP cache — a day
// for what changes daily, a week for the rest.

/// How many of your 8+ ratings seed "like your favourites".
const _seeds = 3;

/// "Like your favourites": TMDB's recommendations for your latest films and
/// series rated 8 or higher, interleaved, without what you have rated.
/// Empty until there is such a rating.
final forYouShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>((
  ref,
) async {
  final tmdb = ref.watch(tmdbProvider);
  // Rebuilt when the seeds change, not on every new external rating.
  final seeds = await ref.watch(
    ratedTitlesProvider.selectAsync((titles) {
      final favourites = [
        for (final t in titles)
          if ((t.key.kind == WorkKind.movie || t.key.kind == WorkKind.tv) &&
              t.rating.scoreHalf >= 16)
            t,
      ]..sort((a, b) => b.rating.scoredAt.compareTo(a.rating.scoredAt));
      return [
        for (final t in favourites.take(_seeds)) t.key.toString(),
      ].join(',');
    }),
  );
  if (seeds.isEmpty) return const [];
  final rated = {
    for (final t in await ref.read(ratedTitlesProvider.future))
      t.key.toString(),
  };
  final lists = await Future.wait([
    for (final key in seeds.split(','))
      // One seed failing doesn't empty the shelf.
      tmdb
          .recommendations(WorkKey.parse(key))
          .catchError((Object _) => const <TitleSummary>[]),
  ]);
  return [
    for (final title in _interleave(lists))
      if (!rated.contains(title.key.toString())) title,
  ];
});

final trendingShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>(
  (ref) => ref.watch(tmdbProvider).trending(),
);

final nowPlayingShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>(
  (ref) => ref.watch(tmdbProvider).nowPlaying(),
);

/// Films and series together, alternating.
final bestShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>((
  ref,
) async {
  final tmdb = ref.watch(tmdbProvider);
  final lists = await Future.wait([
    tmdb.best(WorkKind.movie),
    tmdb.best(WorkKind.tv),
  ]);
  return _interleave(lists);
});

/// a1, b1, c1, a2, b2… without repeats.
List<TitleSummary> _interleave(List<List<TitleSummary>> lists) {
  final seen = <String>{};
  final out = <TitleSummary>[];
  final longest = lists.fold(0, (n, l) => l.length > n ? l.length : n);
  for (var i = 0; i < longest; i++) {
    for (final list in lists) {
      if (i < list.length && seen.add(list[i].key.toString())) {
        out.add(list[i]);
      }
    }
  }
  return out;
}

/// The shelves, top to bottom. Offline with nothing cached, one message
/// instead of four empty rows.
class Shelves extends ConsumerWidget {
  const Shelves({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shelves = [
      (l10n.shelfForYou, forYouShelfProvider),
      (l10n.shelfTrending, trendingShelfProvider),
      (l10n.shelfNowPlaying, nowPlayingShelfProvider),
      (l10n.shelfBest, bestShelfProvider),
    ];
    final values = [for (final (_, p) in shelves) ref.watch(p)];
    final allFailed = values.skip(1).every((v) => v.hasError);
    if (allFailed) {
      final error = values[1].error;
      return _Offline(
        failure: error is SourceException ? error.failure : null,
        onRetry: () {
          for (final (_, p) in shelves) {
            ref.invalidate(p);
          }
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final (i, (label, _)) in shelves.indexed)
          _Shelf(label: label, value: values[i]),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.label, required this.value});

  final String label;
  final AsyncValue<List<TitleSummary>> value;

  static const _width = 112.0;
  static const _height = _width * 3 / 2 + 64;

  @override
  Widget build(BuildContext context) {
    final titles = value.value;
    // A shelf that failed or has nothing is left out, not shown empty.
    if (value.hasError || (titles != null && titles.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
        ),
        SizedBox(
          height: _height,
          child: titles == null
              ? const _Skeleton(width: _width)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: titles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _ShelfItem(title: titles[index], width: _width),
                ),
        ),
      ],
    );
  }
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({required this.title, required this.width});

  final TitleSummary title;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () =>
            context.go('${Routes.search}/${TitleRoutes.path(title.key)}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Poster(
                  title.posterPath,
                  size: ImageSize.w185,
                  width: width,
                  icon: title.key.kind == WorkKind.movie
                      ? Icons.movie_outlined
                      : Icons.live_tv_outlined,
                ),
                // Your own mark on what you have already rated.
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: MyScoreBadge(title.key, onPoster: true),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            if (title.year case final year?)
              Text(
                '$year',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Reel.of(context).edge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grey posters while a shelf loads: the page keeps its shape.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => ListView.separated(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(width: 12),
    itemBuilder: (context, _) => Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: width,
        height: width * 3 / 2,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
  );
}

class _Offline extends StatelessWidget {
  const _Offline({required this.failure, required this.onRetry});

  final SourceFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure == SourceFailure.offline || failure == null
                  ? l10n.shelvesOffline
                  : catalogFailureText(l10n, failure!),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
