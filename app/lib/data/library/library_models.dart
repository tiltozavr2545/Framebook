import '../api_source.dart';
import '../db/database.dart';
import '../work_key.dart';
import 'divergence.dart';
import 'work_snapshot.dart';

/// A live rating with its title's snapshot and, for a season or an episode,
/// the snapshots of its ancestors — what a list row needs to say
/// "Game of Thrones · S1E3".
final class RatedTitle {
  const RatedTitle({
    required this.rating,
    required this.work,
    this.series,
    this.season,
    this.external = const {},
  });

  final Rating rating;
  final Work work;

  /// The cached Kinopoisk and IMDb rows, of any status — what "My ratings"
  /// and the statistics compare with. Only [watchRatings] fills them.
  final Map<RatingSource, ExternalRating> external;

  /// The series of a season or an episode.
  final Work? series;

  /// The season of an episode.
  final Work? season;

  WorkKey get key => WorkKey.parse(work.workKey);

  /// A poster for the row: an episode has none of its own, so the season's
  /// or the series' is used.
  String? get posterPath =>
      work.posterPath ?? season?.posterPath ?? series?.posterPath;

  /// "Mine − theirs" against [source], `null` without a cached value.
  double? divergenceFrom(RatingSource source) =>
      divergence(rating.scoreHalf, external[source]);

  /// The genres a title counts under: a season and an episode take the
  /// series' (docs/data-model.md, `works.genre_ids`).
  List<int> get genreIds => WorkSnapshot.fromWork(series ?? work).genreIds;
}

/// A live watchlist entry with its title's snapshot (films and series only).
final class WatchlistTitle {
  const WatchlistTitle({required this.entry, required this.work, this.series});

  final WatchlistEntry entry;
  final Work work;
  final Work? series;

  WorkKey get key => WorkKey.parse(work.workKey);
}

/// The average of a series' or a season's rated parts — a hint next to its
/// own score (docs/data-model.md, "Key queries").
final class PartsAverage {
  const PartsAverage({
    required this.average,
    required this.count,
    required this.parts,
  });

  /// In points, 1.0…10.0.
  final double average;
  final int count;

  /// [WorkKind.season] or [WorkKind.episode].
  final WorkKind parts;
}

/// What the calibration sheet shows after a score is saved: titles of the
/// same kind with the same score, and the nearest existing scores above and
/// below (docs/data-model.md, "Key queries").
final class Calibration {
  const Calibration({
    required this.same,
    required this.above,
    required this.below,
  });

  /// What fits under the score reel: four of the same, two each side.
  static const sameLimit = 4;
  static const neighbourLimit = 2;

  final List<RatedTitle> same;
  final List<RatedTitle> above;
  final List<RatedTitle> below;

  bool get isEmpty => same.isEmpty && above.isEmpty && below.isEmpty;
}
