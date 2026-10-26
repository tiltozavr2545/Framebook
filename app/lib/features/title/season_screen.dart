import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/library/work_snapshot.dart';
import '../../data/ratings_service.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/title_text.dart';
import 'cast_section.dart';
import 'my_rating.dart';
import 'ratings_panel.dart';
import 'title_layout.dart';
import 'title_providers.dart';
import 'title_routes.dart';

class SeasonScreen extends ConsumerWidget {
  const SeasonScreen({
    super.key,
    required this.seasonKey,
    required this.location,
  });

  final WorkKey seasonKey;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final season = ref.watch(seasonProvider(seasonKey));
    // The series is needed for the header title and its imdb id: a season
    // has none of its own.
    final tv = ref.watch(tvProvider(seasonKey.tmdbId));
    return TitlePage<(SeasonDetails, TvDetails)>(
      value: combineAsync(season, tv),
      savedKey: seasonKey,
      onRetry: () {
        ref.invalidate(seasonProvider(seasonKey));
        ref.invalidate(tvProvider(seasonKey.tmdbId));
      },
      builder: (context, data) {
        final (season, tv) = data;
        return [
          TitleHeader(
            posterPath: season.posterPath ?? tv.posterPath,
            title: seasonName(l10n, season.number, season.name),
            facts: [
              tv.title,
              joinFacts([
                season.year?.toString(),
                if (season.episodes.isNotEmpty)
                  l10n.episodeCount(season.episodes.length),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          MyRatingSection(
            lineage: [WorkSnapshot.tv(tv), WorkSnapshot.season(season)],
          ),
          const SizedBox(height: 16),
          RatingsPanel(
            target: RatingTarget(
              key: season.key,
              tmdbVote: season.vote,
              seriesImdbId: tv.imdbId,
            ),
          ),
          ...overviewSection(context, season.overview),
          ...castSection(context, season.credits),
          if (season.episodes.isNotEmpty) SectionTitle(l10n.titleEpisodes),
          for (final episode in season.episodes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                child: Text('${episode.number}'),
              ),
              title: Text(
                episode.name ?? l10n.episodeNumber(episode.number),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(context.formatDate(episode.airDate) ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [MyScoreBadge(episode.key), TmdbScore(episode.vote)],
              ),
              onTap: () => context.go(
                '$location/${TitleRoutes.episodeSegment(episode.number)}',
              ),
            ),
        ];
      },
    );
  }
}
