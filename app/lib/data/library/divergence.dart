import '../api_source.dart';
import '../db/database.dart';

/// What "My ratings" and the statistics compare your scores with.
const compareSources = [RatingSource.kp, RatingSource.imdb];

/// Whether a source's value compares with your score as a plain difference.
/// Kinopoisk, IMDb and TMDB use the same 1–10 scale (docs/project-brief.md);
/// Rotten Tomatoes is a share of positive reviews and Metacritic a 0–100
/// score, so a difference with them would be a conversion, not a comparison.
bool comparable(RatingSource source) => switch (source) {
  RatingSource.kp || RatingSource.imdb || RatingSource.tmdb => true,
  RatingSource.rt || RatingSource.metacritic => false,
};

/// "Mine − theirs" in points: positive when you rate higher. `null` when
/// there is no value to compare with.
double? divergence(int scoreHalf, ExternalRating? row) {
  final value = row?.value;
  if (row == null ||
      value == null ||
      row.status != RatingStatus.ok ||
      !comparable(row.source)) {
    return null;
  }
  return scoreHalf / 2 - value;
}
