import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/library/work_snapshot.dart';
import '../../data/ratings_service.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/poster.dart';
import '../../shared/title_text.dart';
import 'my_rating.dart';
import 'ratings_panel.dart';
import 'title_layout.dart';
import 'title_providers.dart';
import 'title_routes.dart';

class TvScreen extends ConsumerWidget {
  const TvScreen({super.key, required this.id, required this.location});

  final int id;

  /// This screen's path: seasons open nested under it.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TitlePage(
      value: ref.watch(tvProvider(id)),
      title: (tv) => tv.title,
      onRetry: () => ref.invalidate(tvProvider(id)),
      builder: (context, tv) => [
        TitleHeader(
          posterPath: tv.posterPath,
          title: tv.title,
          originalTitle: tv.originalTitle,
          facts: [
            joinFacts([_years(tv), _status(l10n, tv.status)]),
            joinFacts([
              if (tv.regularSeasonCount > 0)
                l10n.seasonCount(tv.regularSeasonCount),
              if (tv.episodeCount case final count? when count > 0)
                l10n.episodeCount(count),
            ]),
            tv.genres.map((g) => g.name).join(', '),
          ],
          tagline: tv.tagline,
        ),
        const SizedBox(height: 16),
        MyRatingSection(lineage: [WorkSnapshot.tv(tv)]),
        const SizedBox(height: 16),
        RatingsPanel(
          target: RatingTarget(
            key: tv.key,
            tmdbVote: tv.vote,
            imdbId: tv.imdbId,
          ),
        ),
        ...overviewSection(context, tv.overview),
        if (tv.seasons.isNotEmpty) SectionTitle(l10n.titleSeasons),
        for (final season in tv.seasons)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Poster(
              season.posterPath ?? tv.posterPath,
              size: ImageSize.w92,
              width: 40,
            ),
            title: Text(seasonName(l10n, season.number, season.name)),
            subtitle: Text(
              joinFacts([
                if (season.episodeCount > 0)
                  l10n.episodeCount(season.episodeCount),
                season.year?.toString(),
              ]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [MyScoreBadge(season.key), TmdbScore(season.vote)],
            ),
            onTap: () => context.go(
              '$location/${TitleRoutes.seasonSegment(season.number)}',
            ),
          ),
      ],
    );
  }

  /// "2011–2019", "2011–" while running, "2011" if it started and ended in
  /// the same year.
  static String? _years(TvDetails tv) {
    final first = tv.firstYear;
    if (first == null) return null;
    final last = tv.lastYear;
    return switch (tv.status) {
      TvStatus.running => '$first–',
      _ when last == null || last == first => '$first',
      _ => '$first–$last',
    };
  }

  static String? _status(AppLocalizations l10n, TvStatus status) =>
      switch (status) {
        TvStatus.running => l10n.tvStatusRunning,
        TvStatus.ended => l10n.tvStatusEnded,
        TvStatus.canceled => l10n.tvStatusCanceled,
        TvStatus.unknown => null,
      };
}
