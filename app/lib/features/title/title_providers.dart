import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';

// Cards come from TMDB through the HTTP cache. Both the season and the
// episode screen need the series (title, the series' imdb id); nested routes
// keep the parent screen alive, so there is no second request.

final movieProvider = FutureProvider.autoDispose.family<MovieDetails, int>(
  (ref, id) => ref.watch(tmdbProvider).movie(id),
);

final tvProvider = FutureProvider.autoDispose.family<TvDetails, int>(
  (ref, id) => ref.watch(tmdbProvider).tv(id),
);

/// The argument is the season's key.
final seasonProvider = FutureProvider.autoDispose
    .family<SeasonDetails, WorkKey>(
      (ref, key) => ref.watch(tmdbProvider).season(key.tmdbId, key.season!),
    );

/// The episode's imdb id. If it fails to load, `null`: OMDb is then asked by
/// the series' imdb id and numbers, so the card doesn't fail because of it.
final episodeImdbIdProvider = FutureProvider.autoDispose
    .family<String?, WorkKey>((ref, key) async {
      try {
        return await ref
            .watch(tmdbProvider)
            .episodeImdbId(key.tmdbId, key.season!, key.episode!);
      } on SourceException {
        return null;
      }
    });

/// An episode's cast and crew; empty if they fail to load — the card is
/// complete without them.
final episodeCreditsProvider = FutureProvider.autoDispose
    .family<Credits, WorkKey>((ref, key) async {
      try {
        return await ref
            .watch(tmdbProvider)
            .episodeCredits(key.tmdbId, key.season!, key.episode!);
      } on SourceException {
        return const Credits();
      }
    });
