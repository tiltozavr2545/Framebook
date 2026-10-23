/// Тип произведения. Имена совпадают со значениями колонки `works.kind` и
/// с полем `kind` в файле синхронизации — не переименовывать.
enum WorkKind { movie, tv, season, episode }

/// Ключ произведения: `tmdb:movie:603`, `tmdb:tv:1399`, `tmdb:tv:1399:s1`,
/// `tmdb:tv:1399:s1:e3`.
///
/// Естественный, а не случайный: две офлайн-оценки одного фильма на двух
/// устройствах должны стать одной строкой с конфликтом, а не двумя дублями
/// (docs/data-model.md). Тип обязателен: у TMDB фильмы и сериалы нумеруются
/// раздельно, и `603` без типа — это два разных произведения (см. «Грабли» в
/// AGENTS.md).
///
/// Это единственное место, где ключ собирается и разбирается: строку руками
/// нигде не склеивать.
final class WorkKey {
  const WorkKey._(this.kind, this.tmdbId, this.season, this.episode);

  const WorkKey.movie(int tmdbId) : this._(WorkKind.movie, tmdbId, null, null);

  const WorkKey.tv(int tmdbId) : this._(WorkKind.tv, tmdbId, null, null);

  /// Сезон 0 — спецвыпуски, как в TMDB.
  const WorkKey.season(int seriesTmdbId, int season)
    : this._(WorkKind.season, seriesTmdbId, season, null);

  const WorkKey.episode(int seriesTmdbId, int season, int episode)
    : this._(WorkKind.episode, seriesTmdbId, season, episode);

  final WorkKind kind;

  /// Для сезона и серии — id сериала, а не их собственный id в TMDB.
  final int tmdbId;
  final int? season;
  final int? episode;

  static const _prefix = 'tmdb';

  static final _pattern = RegExp(
    r'^tmdb:(movie|tv):([1-9][0-9]{0,9})(?::s(0|[1-9][0-9]{0,3})(?::e([1-9][0-9]{0,4}))?)?$',
  );

  /// Разбирает строковый ключ. Бросает [FormatException] на всё, что не
  /// собрал бы [toString]: лишние нули, пробелы, сезон у фильма.
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

  /// Сериал для сезона, сезон для серии; у фильма и сериала — `null`.
  /// Совпадает с колонкой `works.parent_key`.
  WorkKey? get parent => switch (kind) {
    WorkKind.movie || WorkKind.tv => null,
    WorkKind.season => WorkKey.tv(tmdbId),
    WorkKind.episode => WorkKey.season(tmdbId, season!),
  };

  /// Сам ключ и все его предки, от сериала вниз. Снимок обязан лежать в
  /// `works` у каждого из них (инвариант из docs/data-model.md).
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
