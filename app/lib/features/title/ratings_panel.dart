import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/api_source.dart';
import '../../data/library/divergence.dart';
import '../../data/library/library.dart';
import '../../data/ratings_service.dart';
import '../../data/source_failure.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import 'title_ratings.dart';

/// A card's external rating cells. Each source is its own cell with its own
/// state: one failing never breaks the others. Once you have rated the title,
/// a 1–10 cell also shows "mine − theirs".
class RatingsPanel extends ConsumerWidget {
  const RatingsPanel({super.key, required this.target});

  final RatingTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(titleRatingsProvider(target));
    final service = ref.watch(ratingsServiceProvider);
    final mine = ref.watch(myRatingProvider(target.key)).value?.scoreHalf;
    final kind = target.key.kind;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final source in RatingsService.shownFor(kind))
          _RatingCell(
            source: source,
            seasonAverage:
                kind == WorkKind.season && source == RatingSource.imdb,
            state: ratingCellState(
              source: source,
              view: view,
              provider: service.providerOf(source, kind),
              nowMillis: now,
            ),
            myScoreHalf: mine,
          ),
      ],
    );
  }
}

class _RatingCell extends StatelessWidget {
  const _RatingCell({
    required this.source,
    required this.state,
    required this.seasonAverage,
    required this.myScoreHalf,
  });

  final RatingSource source;
  final RatingCellState state;

  /// Your own score, `null` if the title isn't rated.
  final int? myScoreHalf;

  /// A season's IMDb is the episode average, not a rating of the season.
  final bool seasonAverage;

  static const width = 104.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.outline);

    final (Widget value, String? caption) = switch (state) {
      RatingShown(:final row, :final stale) => (
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _value(row.value!, source),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: stale ? scheme.outline : null,
              ),
            ),
            if (myScoreHalf case final mine?)
              if (divergence(mine, row) case final d?) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    formatDivergence(d),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    semanticsLabel: l10n.ratingDivergence(formatDivergence(d)),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
          ],
        ),
        stale
            ? l10n.ratingAsOf(context.formatTimestamp(row.fetchedAt))
            : seasonAverage
            ? l10n.ratingSeasonAverage
            : row.votes == null
            ? null
            : l10n.ratingVotes(context.formatCount(row.votes!)),
      ),
      RatingNoData() => (_dash(theme), l10n.ratingNoData),
      RatingNeedsKey() => (_dash(theme), l10n.ratingNeedsKey),
      RatingLoading() => (
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        null,
      ),
      RatingFailed(:final failure) => (
        _dash(theme),
        switch (failure) {
          SourceFailure.offline => l10n.ratingOffline,
          SourceFailure.limitReached => l10n.ratingLimit,
          SourceFailure.unauthorized => l10n.ratingKeyRejected,
          SourceFailure.notFound || SourceFailure.failed => l10n.ratingFailed,
        },
      ),
    };

    final refreshing = switch (state) {
      RatingShown(:final refreshing) => refreshing,
      _ => false,
    };
    final opensSettings = switch (state) {
      RatingNeedsKey() ||
      RatingFailed(failure: SourceFailure.unauthorized) => true,
      _ => false,
    };

    final cell = Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ratingSourceLabel(l10n, source),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
              if (refreshing)
                const SizedBox.square(
                  dimension: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: Align(alignment: Alignment.centerLeft, child: value),
          ),
          Text(
            caption ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ],
      ),
    );

    if (!opensSettings) return cell;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(Routes.sources),
      child: cell,
    );
  }

  static Widget _dash(ThemeData theme) => Text(
    '—',
    style: theme.textTheme.headlineSmall?.copyWith(
      color: theme.colorScheme.outline,
    ),
  );

  /// RT is a percentage, Metacritic a whole number of 100, the rest one
  /// decimal.
  static String _value(double value, RatingSource source) => switch (source) {
    RatingSource.rt => '${value.round()}%',
    RatingSource.metacritic => '${value.round()}',
    RatingSource.kp ||
    RatingSource.imdb ||
    RatingSource.tmdb => formatScore(value),
  };
}
