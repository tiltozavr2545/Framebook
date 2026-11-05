import '../api_source.dart';
import '../work_key.dart';
import 'library_models.dart';

/// How "My ratings" is ordered.
enum RatingsSort { scoredAt, score, year, title, divergence }

/// The direction of the divergence sort.
enum DivergenceOrder {
  /// The largest gap either way first.
  furthest,

  /// Where I rate higher than [compareWith] first.
  higher,

  /// Where I rate lower first.
  lower,
}

/// Filters "My ratings" by kind (`null` — all) and sorts it. Ties are broken
/// by the most recent score, so the order is stable. Sorting by divergence
/// compares with [compareWith]; titles without its value go to the end rather
/// than dropping out (docs/data-model.md, "Key queries").
List<RatedTitle> arrangeRatings(
  Iterable<RatedTitle> titles, {
  WorkKind? kind,
  RatingsSort sort = RatingsSort.scoredAt,
  RatingSource compareWith = RatingSource.kp,
  DivergenceOrder order = DivergenceOrder.furthest,
}) {
  int byRecent(RatedTitle a, RatedTitle b) =>
      b.rating.scoredAt.compareTo(a.rating.scoredAt);
  int byDivergence(RatedTitle a, RatedTitle b) {
    final da = a.divergenceFrom(compareWith);
    final db = b.divergenceFrom(compareWith);
    if (da == null || db == null) {
      return da == db ? 0 : (da == null ? 1 : -1);
    }
    return switch (order) {
      DivergenceOrder.furthest => db.abs().compareTo(da.abs()),
      DivergenceOrder.higher => db.compareTo(da),
      DivergenceOrder.lower => da.compareTo(db),
    };
  }

  final list = [
    for (final title in titles)
      if (kind == null || title.work.kind == kind) title,
  ];
  list.sort(
    (a, b) => switch (sort) {
      RatingsSort.scoredAt => byRecent(a, b),
      RatingsSort.score => _then(
        b.rating.scoreHalf.compareTo(a.rating.scoreHalf),
        () => byRecent(a, b),
      ),
      // Newest first; titles without a year go last.
      RatingsSort.year => _then(
        _yearDescending(a.work.year, b.work.year),
        () => byRecent(a, b),
      ),
      RatingsSort.title => _then(
        sortTitle(a).compareTo(sortTitle(b)),
        () => byRecent(a, b),
      ),
      RatingsSort.divergence => _then(byDivergence(a, b), () => byRecent(a, b)),
    },
  );
  return list;
}

/// What a title sorts by: a season or an episode sorts under its series, in
/// number order.
String sortTitle(RatedTitle title) {
  final key = title.key;
  final name = (title.series?.title ?? title.work.title).toLowerCase();
  String pad(int? n, int width) => (n ?? 0).toString().padLeft(width, '0');
  return switch (key.kind) {
    WorkKind.movie || WorkKind.tv => name,
    WorkKind.season => '$name\u0000${pad(key.season, 4)}',
    WorkKind.episode =>
      '$name\u0000${pad(key.season, 4)}${pad(key.episode, 5)}',
  };
}

int _then(int first, int Function() next) => first != 0 ? first : next();

/// Newer years first; a title without a year goes after every dated one.
int _yearDescending(int? a, int? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}
