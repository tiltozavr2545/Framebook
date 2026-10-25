import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library/work_snapshot.dart';
import '../../data/ratings_service.dart';
import '../../data/source_failure.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import 'my_rating.dart';
import 'ratings_panel.dart';
import 'title_layout.dart';
import 'title_providers.dart';

class EpisodeScreen extends ConsumerWidget {
  const EpisodeScreen({super.key, required this.episodeKey});

  final WorkKey episodeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final seasonKey = episodeKey.parent!;
    // There is no separate episode request: everything but the imdb id is in
    // the season response, already cached — that is where we came from.
    final season = ref.watch(seasonProvider(seasonKey));
    final tv = ref.watch(tvProvider(episodeKey.tmdbId));
    final imdbId = ref.watch(episodeImdbIdProvider(episodeKey));
    return TitlePage<(SeasonDetails, TvDetails)>(
      value: combineAsync(season, tv),
      title: (data) => data.$2.title,
      onRetry: () {
        ref.invalidate(seasonProvider(seasonKey));
        ref.invalidate(tvProvider(episodeKey.tmdbId));
      },
      builder: (context, data) {
        final (season, tv) = data;
        final episode = season.episodes
            .where((e) => e.key == episodeKey)
            .firstOrNull;
        if (episode == null) {
          // A number from the address that the season doesn't have (TMDB
          // renumbered it).
          return [
            const SizedBox(height: 48),
            const FailureView(error: SourceException(SourceFailure.notFound)),
          ];
        }
        return [
          Poster(
            episode.stillPath,
            size: ImageSize.w500,
            width: MediaQuery.sizeOf(context).width - 32,
            aspectRatio: 16 / 9,
            icon: Icons.live_tv_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            episode.name ?? l10n.episodeNumber(episode.number),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            joinFacts([
              l10n.episodeCode(episode.season, episode.number),
              context.formatDate(episode.airDate),
              if (episode.runtime case final runtime?)
                context.formatRuntime(runtime),
            ]),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          MyRatingSection(
            lineage: [
              WorkSnapshot.tv(tv),
              WorkSnapshot.season(season),
              WorkSnapshot.episode(episode, imdbId: imdbId.value),
            ],
          ),
          const SizedBox(height: 16),
          switch (imdbId) {
            AsyncData(:final value) => RatingsPanel(
              target: RatingTarget(
                key: episode.key,
                tmdbVote: episode.vote,
                imdbId: value,
                seriesImdbId: tv.imdbId,
              ),
            ),
            _ => const SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            ),
          },
          ...overviewSection(context, episode.overview),
        ];
      },
    );
  }
}
