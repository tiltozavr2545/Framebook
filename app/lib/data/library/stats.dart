import '../api_source.dart';
import '../work_key.dart';
import 'divergence.dart';
import 'library.dart';

/// The average deviation of your scores from a source, over the titles that
/// have its value.
final class Deviation {
  const Deviation({
    required this.signed,
    required this.absolute,
    required this.count,
  });

  /// The mean of "mine − theirs": positive when you rate higher on average.
  final double signed;

  /// The mean gap either way.
  final double absolute;

  /// How many ratings it was computed over.
  final int count;
}

/// The average score of a group: a genre or a decade.
final class GroupAverage {
  const GroupAverage({
    required this.key,
    required this.average,
    required this.count,
  });

  /// A TMDB genre id, or a decade's first year (1990).
  final int key;

  /// In points, 1.0…10.0.
  final double average;
  final int count;
}

/// Everything the Stats tab shows, computed from the live ratings
/// (docs/project-brief.md, "Statistics").
final class RatingStats {
  const RatingStats({
    required this.count,
    required this.average,
    required this.distribution,
    required this.deviation,
    required this.genres,
    required this.decades,
  });

  final int count;

  /// In points; `null` without ratings.
  final double? average;

  /// How many times each score was given: index 0 is 1, index 18 is 10.
  final List<int> distribution;

  /// Against Kinopoisk and IMDb; a source is absent when no rated title has
  /// its value yet.
  final Map<RatingSource, Deviation> deviation;

  /// Most rated genres first.
  final List<GroupAverage> genres;

  /// Oldest decade first.
  final List<GroupAverage> decades;

  bool get isEmpty => count == 0;
}

RatingStats computeStats(Iterable<RatedTitle> titles) {
  final distribution = List.filled(19, 0);
  var sum = 0;
  var count = 0;
  final deviations = {for (final source in compareSources) source: <double>[]};
  final genres = <int, List<int>>{};
  final decades = <int, List<int>>{};

  for (final title in titles) {
    final half = title.rating.scoreHalf;
    count++;
    sum += half;
    distribution[half - 2]++;
    for (final source in compareSources) {
      if (title.divergenceFrom(source) case final d?) {
        deviations[source]!.add(d);
      }
    }
    for (final genre in title.genreIds.toSet()) {
      genres.putIfAbsent(genre, () => []).add(half);
    }
    if (title.work.year case final year?) {
      decades.putIfAbsent(year - year % 10, () => []).add(half);
    }
  }

  List<GroupAverage> averages(Map<int, List<int>> groups) => [
    for (final MapEntry(:key, value: scores) in groups.entries)
      GroupAverage(
        key: key,
        average: scores.reduce((a, b) => a + b) / scores.length / 2,
        count: scores.length,
      ),
  ];

  return RatingStats(
    count: count,
    average: count == 0 ? null : sum / count / 2,
    distribution: distribution,
    deviation: {
      for (final MapEntry(key: source, value: ds) in deviations.entries)
        if (ds.isNotEmpty)
          source: Deviation(
            signed: ds.reduce((a, b) => a + b) / ds.length,
            absolute:
                ds.map((d) => d.abs()).reduce((a, b) => a + b) / ds.length,
            count: ds.length,
          ),
    },
    genres: averages(genres)
      ..sort(
        (a, b) => b.count != a.count
            ? b.count.compareTo(a.count)
            : b.average.compareTo(a.average),
      ),
    decades: averages(decades)..sort((a, b) => a.key.compareTo(b.key)),
  );
}

/// How far background refresh has got with [source]: of the [total] rated
/// titles it covers with the current keys ([covers]), how many have an answer
/// — a value or a definite "not there".
({int loaded, int total}) coverage(
  Iterable<RatedTitle> titles,
  RatingSource source,
  bool Function(WorkKind kind) covers,
) {
  var loaded = 0;
  var total = 0;
  for (final title in titles) {
    if (!covers(title.work.kind)) continue;
    total++;
    final status = title.external[source]?.status;
    if (status == RatingStatus.ok || status == RatingStatus.notFound) loaded++;
  }
  return (loaded: loaded, total: total);
}
