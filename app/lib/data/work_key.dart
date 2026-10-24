/// A title's kind. The names match the values of the `works.kind` column and
/// the `kind` field in the sync file — don't rename them.
enum WorkKind { movie, tv, season, episode }

/// A title's key: `tmdb:movie:603`, `tmdb:tv:1399`, `tmdb:tv:1399:s1`,
/// `tmdb:tv:1399:s1:e3`.
///
/// Natural, not random: two offline ratings of the same film on two devices
/// must become one row with a conflict, not two duplicates
/// (docs/data-model.md). The type is required: TMDB numbers films and series
/// separately, and `603` without a type is two different titles (see the
/// pitfalls in AGENTS.md).
///
/// This is the only place a key is built and parsed: never glue the string by
/// hand.
final class WorkKey {
  const WorkKey._(this.kind, this.tmdbId, this.season, this.episode);

  const WorkKey.movie(int tmdbId) : this._(WorkKind.movie, tmdbId, null, null);

  const WorkKey.tv(int tmdbId) : this._(WorkKind.tv, tmdbId, null, null);

  /// Season 0 is specials, as in TMDB.
  const WorkKey.season(int seriesTmdbId, int season)
    : this._(WorkKind.season, seriesTmdbId, season, null);

  const WorkKey.episode(int seriesTmdbId, int season, int episode)
    : this._(WorkKind.episode, seriesTmdbId, season, episode);

  final WorkKind kind;

  /// For a season and an episode, the series' id, not their own TMDB id.
  final int tmdbId;
  final int? season;
  final int? episode;

  static const _prefix = 'tmdb';

  static final _pattern = RegExp(
    r'^tmdb:(movie|tv):([1-9][0-9]{0,9})(?::s(0|[1-9][0-9]{0,3})(?::e([1-9][0-9]{0,4}))?)?$',
  );

  /// Parses a string key. Throws [FormatException] on anything [toString] would
  /// not have produced: leading zeros, spaces, a season on a film.
  static WorkKey parse(String source) {
    final match = _pattern.firstMatch(source);
    if (match == null) {
      throw FormatException('Not a work key', source);
    }
    final type = match.group(1)!;
    final id = int.parse(match.group(2)!);
    final season = match.group(3);
    final episode = match.group(4);
    if (type == 'movie') {
      if (season != null) {
        throw FormatException('A movie has no seasons', source);
      }
      return WorkKey.movie(id);
    }
    if (season == null) return WorkKey.tv(id);
    if (episode == null) return WorkKey.season(id, int.parse(season));
    return WorkKey.episode(id, int.parse(season), int.parse(episode));
  }

  static WorkKey? tryParse(String source) {
    try {
      return parse(source);
    } on FormatException {
      return null;
    }
  }

  /// The series for a season, the season for an episode; `null` for a film and
  /// a series. Matches the `works.parent_key` column.
  WorkKey? get parent => switch (kind) {
    WorkKind.movie || WorkKind.tv => null,
    WorkKind.season => WorkKey.tv(tmdbId),
    WorkKind.episode => WorkKey.season(tmdbId, season!),
  };

  /// The key itself and all its ancestors, from the series down. Each of them
  /// must have a snapshot in `works` (an invariant from docs/data-model.md).
  List<WorkKey> get lineage {
    final chain = <WorkKey>[this];
    var current = parent;
    while (current != null) {
      chain.insert(0, current);
      current = current.parent;
    }
    return chain;
  }

  @override
  String toString() => switch (kind) {
    WorkKind.movie => '$_prefix:movie:$tmdbId',
    WorkKind.tv => '$_prefix:tv:$tmdbId',
    WorkKind.season => '$_prefix:tv:$tmdbId:s$season',
    WorkKind.episode => '$_prefix:tv:$tmdbId:s$season:e$episode',
  };

  @override
  bool operator ==(Object other) =>
      other is WorkKey &&
      other.kind == kind &&
      other.tmdbId == tmdbId &&
      other.season == season &&
      other.episode == episode;

  @override
  int get hashCode => Object.hash(kind, tmdbId, season, episode);
}
