import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../source_failure.dart' show yearOf;
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';

/// A title's mini snapshot — exactly what the offline list of ratings needs
/// (docs/data-model.md, "Three layers of data"), built from a TMDB card.
///
/// A rating or a watchlist entry is always saved with the snapshots of the
/// title and all its ancestors (the invariant in data-model.md), so cards
/// pass the whole lineage: `[series, season, episode]`.
final class WorkSnapshot {
  const WorkSnapshot({
    required this.key,
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.releaseDate,
    this.posterPath,
    this.imdbId,
    this.genreIds = const [],
  });

  factory WorkSnapshot.movie(MovieDetails movie) => WorkSnapshot(
    key: movie.key,
    tmdbId: movie.key.tmdbId,
    title: movie.title,
    originalTitle: movie.originalTitle,
    releaseDate: movie.releaseDate,
    posterPath: movie.posterPath,
    imdbId: movie.imdbId,
    genreIds: [for (final genre in movie.genres) genre.id],
  );

  factory WorkSnapshot.tv(TvDetails tv) => WorkSnapshot(
    key: tv.key,
    tmdbId: tv.key.tmdbId,
    title: tv.title,
    originalTitle: tv.originalTitle,
    releaseDate: tv.firstAirDate,
    posterPath: tv.posterPath,
    imdbId: tv.imdbId,
    genreIds: [for (final genre in tv.genres) genre.id],
  );

  /// A season keeps TMDB's own name ("Season 1"), possibly empty; lists add
  /// the series' title from its snapshot. Seasons have no genres or imdb id
  /// of their own.
  factory WorkSnapshot.season(SeasonDetails season) => WorkSnapshot(
    key: season.key,
    // The CHECK wants a positive id; the series' id stands in when TMDB
    // didn't send the season's own.
    tmdbId: season.tmdbId ?? season.key.tmdbId,
    title: season.name ?? '',
    releaseDate: season.airDate,
    posterPath: season.posterPath,
  );

  /// A season from the series' season list — what a rating moved there by
  /// renumbering is saved with when the season's own card isn't open.
  factory WorkSnapshot.seasonSummary(SeasonSummary season) => WorkSnapshot(
    key: season.key,
    tmdbId: season.tmdbId ?? season.key.tmdbId,
    title: season.name ?? '',
    releaseDate: season.airDate,
    posterPath: season.posterPath,
  );

  /// An episode has no poster of its own (a still is 16:9); lists show the
  /// season's or the series' poster.
  factory WorkSnapshot.episode(EpisodeSummary episode, {String? imdbId}) =>
      WorkSnapshot(
        key: episode.key,
        tmdbId: episode.tmdbId ?? episode.key.tmdbId,
        title: episode.name ?? '',
        releaseDate: episode.airDate,
        imdbId: imdbId,
      );

  /// Back from a stored row — e.g. to put a title back on the watchlist after
  /// "undo".
  factory WorkSnapshot.fromWork(Work work) => WorkSnapshot(
    key: WorkKey.parse(work.workKey),
    tmdbId: work.tmdbId,
    title: work.title,
    originalTitle: work.originalTitle,
    releaseDate: work.releaseDate,
    posterPath: work.posterPath,
    imdbId: work.imdbId,
    genreIds: _genreIds(work.genreIds),
  );

  final WorkKey key;
  final int tmdbId;
  final String title;
  final String? originalTitle;

  /// `YYYY-MM-DD` as it came from the API.
  final String? releaseDate;
  final String? posterPath;
  final String? imdbId;
  final List<int> genreIds;

  int? get year => yearOf(releaseDate);

  /// The row to upsert. `kp_id` is left absent on purpose, and so is an
  /// unknown `imdb_id`: an upsert must not wipe an id found earlier.
  WorksCompanion toCompanion(int now) => WorksCompanion(
    workKey: Value(key.toString()),
    kind: Value(key.kind),
    parentKey: Value(key.parent?.toString()),
    tmdbId: Value(tmdbId),
    seasonNumber: Value(key.season),
    episodeNumber: Value(key.episode),
    imdbId: imdbId == null ? const Value.absent() : Value(imdbId),
    title: Value(title),
    originalTitle: Value(originalTitle),
    releaseDate: Value(releaseDate),
    year: Value(year),
    posterPath: Value(posterPath),
    genreIds: Value(jsonEncode(genreIds)),
    snapshotUpdatedAt: Value(now),
  );

  static List<int> _genreIds(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is List<Object?> ? decoded.whereType<int>().toList() : [];
    } on FormatException {
      return [];
    }
  }
}
