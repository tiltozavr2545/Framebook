import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/recommendations/catalog.dart';
import '../../data/recommendations/hidden.dart';
import '../../data/recommendations/providers.dart';
import '../../data/recommendations/ranking.dart';

export '../../data/recommendations/catalog.dart';
import '../../data/source_failure.dart';
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

/// The shelves, top to bottom. Offline with nothing cached, one message
/// instead of four empty rows.
class Shelves extends ConsumerWidget {
  const Shelves({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(recommendationFeedProvider);
    final pool = ref.watch(recommendationPoolProvider);
    final hidden = ref.watch(hiddenRecommendationsProvider);
    final shelves = [
      (l10n.shelfTrending, trendingShelfProvider),
      (l10n.shelfNowPlaying, nowPlayingShelfProvider),
      (l10n.shelfBest, bestShelfProvider),
    ];
    final values = [
      for (final (_, p) in shelves)
        ref
            .watch(p)
            .whenData(
              (titles) => [
                for (final title in titles)
                  if (!hidden.contains(title.key)) title,
              ],
            ),
    ];
    final allFailed = values.every((v) => v.hasError);
    if (allFailed && feed.isEmpty && hidden.isEmpty) {
      final error = values[0].error;
      return _Offline(
        failure: error is SourceException ? error.failure : null,
        onRetry: () {
          for (final (_, p) in shelves) {
            ref.invalidate(p);
          }
          ref.invalidate(recommendationPoolProvider);
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Shelf(
          label: l10n.shelfForYou,
          value:
              feed.forYou.isEmpty &&
                  (pool.isLoading || (pool.value?.running ?? false))
              ? const AsyncLoading()
              : AsyncData([for (final p in feed.forYou) p.title]),
          reasons: {for (final p in feed.forYou) p.title.key: p},
          action: hidden.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.visibility_off_outlined),
                  tooltip: l10n.recommendationsHidden,
                  onPressed: () => _restoreHidden(context, ref),
                ),
          showEmpty: hidden.isNotEmpty,
        ),
        for (final (label, items) in [
          (l10n.recommendationsWatchlist, feed.watchlist),
          (l10n.recommendationsPeople, feed.people),
          (l10n.recommendationsExplore, feed.explore),
        ])
          _Shelf(
            label: label,
            value: AsyncData([for (final p in items) p.title]),
            reasons: {for (final p in items) p.title.key: p},
          ),
        if (pool.hasError || (pool.value?.failed ?? 0) > 0 && feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.recommendationsRetry),
              onPressed: () => ref.invalidate(recommendationPoolProvider),
            ),
          ),
        for (final (i, (label, _)) in shelves.indexed)
          _Shelf(label: label, value: values[i]),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.label,
    required this.value,
    this.reasons = const {},
    this.action,
    this.showEmpty = false,
  });

  final String label;
  final AsyncValue<List<TitleSummary>> value;
  final Map<WorkKey, RecommendationPick> reasons;
  final Widget? action;
  final bool showEmpty;

  static const _width = 112.0;

  @override
  Widget build(BuildContext context) {
    final titles = value.value;
    // A shelf that failed or has nothing is left out, not shown empty.
    if (value.hasError || (titles != null && titles.isEmpty && !showEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        if (titles != null && titles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(AppLocalizations.of(context).recommendationsEmpty),
          )
        else
          SizedBox(
            height: _shelfHeight(context, reasons.isNotEmpty),
            child: titles == null
                ? const _Skeleton(width: _width)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: titles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _ShelfItem(
                      title: titles[index],
                      width: _width,
                      reason: reasons[titles[index].key],
                    ),
                  ),
          ),
      ],
    );
  }
}

class _ShelfItem extends ConsumerWidget {
  const _ShelfItem({required this.title, required this.width, this.reason});

  final TitleSummary title;
  final double width;
  final RecommendationPick? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Positioned(
                  right: 0,
                  top: 0,
                  child: PopupMenuButton<String>(
                    tooltip: AppLocalizations.of(
                      context,
                    ).recommendationsActions,
                    icon: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.more_vert, size: 18),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 160),
                    onSelected: (_) => _hideTitle(context, ref, title),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'hide',
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).recommendationsNotInterested,
                        ),
                      ),
                    ],
                  ),
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
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _reasonText(AppLocalizations.of(context), reason!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _reasonText(AppLocalizations l10n, RecommendationPick pick) =>
    switch (pick.reason) {
      RecommendationReason.similar => l10n.recommendationsBecauseTitle(
        pick.detail ?? '',
      ),
      RecommendationReason.person => l10n.recommendationsBecausePerson(
        pick.detail ?? '',
      ),
      RecommendationReason.author => l10n.recommendationsBecauseAuthor(
        pick.detail ?? '',
      ),
      RecommendationReason.genre => l10n.recommendationsBecauseTaste,
      RecommendationReason.discovery => l10n.recommendationsBecauseExplore,
      RecommendationReason.watchlist => l10n.recommendationsBecauseWatchlist,
    };

double _shelfHeight(BuildContext context, bool reason) {
  final theme = Theme.of(context);
  double height(TextStyle? style, int lines, {String sample = 'Ag'}) {
    final p = TextPainter(
      text: TextSpan(text: List.filled(lines, sample).join('\n'), style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 112);
    final h = p.height;
    p.dispose();
    return h;
  }

  return 168 +
      6 +
      height(theme.textTheme.titleSmall, 2) +
      height(theme.textTheme.labelMedium, 1, sample: '2000') +
      (reason ? 4 + height(theme.textTheme.labelSmall, 2) : 0) +
      8;
}

Future<void> _hideTitle(
  BuildContext context,
  WidgetRef ref,
  TitleSummary title,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final hidden = ref.read(hiddenRecommendationsProvider.notifier);
  try {
    await hidden.hide(title.key);
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.recommendationsHiddenTitle(title.title)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            try {
              await hidden.restore(title.key);
            } on Object {
              if (messenger.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.recommendationsSaveFailed)),
                );
              }
            }
          },
        ),
      ),
    );
  } on Object {
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recommendationsSaveFailed)),
      );
    }
  }
}

Future<void> _restoreHidden(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final hidden = ref.read(hiddenRecommendationsProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final restore = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.recommendationsHidden),
      content: Text(l10n.recommendationsRestoreHint),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.recommendationsRestore),
        ),
      ],
    ),
  );
  if (restore != true) return;
  try {
    await hidden.clear();
  } on Object {
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recommendationsSaveFailed)),
      );
    }
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
