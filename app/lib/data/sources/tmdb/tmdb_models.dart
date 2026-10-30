import '../../source_failure.dart';
import '../../work_key.dart';
import 'tmdb_people.dart';

export 'tmdb_people.dart';

// Catalog domain values. Parsed by hand, not with json_serializable: a film
// and a series name the same field differently (`title`/`name`,
// `release_date`/`first_air_date`), dates can be an empty string, and a zero
// rating means "no votes" — there would be more converters than fields.

/// TMDB rating. `average == null` means no votes: TMDB sends
/// `vote_average: 0`, which is not a score of 0 (docs/external-sources.md).
final class TmdbVote {
  const TmdbVote(this.average, this.count);

  factory TmdbVote.fromJson(Json json) {
    final average = json.number('vote_average');
    final count = json.integer('vote_count');
    final voted = average != null && average > 0 && (count ?? 1) > 0;
    return TmdbVote(voted ? average : null, count);
  }

  final double? average;
  final int? count;

  @override
  bool operator ==(Object other) =>
      other is TmdbVote && other.average == average && other.count == count;

  @override
  int get hashCode => Object.hash(average, count);
}

final class Genre {
  const Genre(this.id, this.name);

  final int id;
  final String name;
}

/// A search result: a film or a series.
final class TitleSummary {
  const TitleSummary({
    required this.key,
    required this.title,
    required this.originalTitle,
    required this.releaseDate,
    required this.posterPath,
    required this.vote,
    required this.genreIds,
  });

  /// `null` for anything that is not a film or a series (a person), or has
  /// no id. The kind comes from `media_type`: search, trending,
  /// recommendations and a person's credits mix films and series.
  static TitleSummary? fromSearchJson(Json json) =>
      switch (json.string('media_type')) {
        'movie' => fromListJson(json, WorkKind.movie),
        'tv' => fromListJson(json, WorkKind.tv),
        _ => null,
      };

  /// A list of one kind (now playing, discover), without `media_type`.
  static TitleSummary? fromListJson(Json json, WorkKind kind) {
    final id = json.integer('id');
    if (id == null || id <= 0) return null;
    final movie = kind == WorkKind.movie;
    final title = json.string(movie ? 'title' : 'name');
    if (title == null) return null;
    return TitleSummary(
      key: movie ? WorkKey.movie(id) : WorkKey.tv(id),
      title: title,
      originalTitle: json.string(movie ? 'original_title' : 'original_name'),
      releaseDate: json.string(movie ? 'release_date' : 'first_air_date'),
      posterPath: json.string('poster_path'),
      vote: TmdbVote.fromJson(json),
      genreIds: json.integers('genre_ids'),
    );
  }

  final WorkKey key;
  final String title;
  final String? originalTitle;
  final String? releaseDate;
  final String? posterPath;
  final TmdbVote vote;
  final List<int> genreIds;

  int? get year => yearOf(releaseDate);
}

final class SearchPage {
  const SearchPage(this.results, {required this.page, required this.pages});

  final List<TitleSummary> results;
  final int page;
  final int pages;
}

final class MovieDetails {
  const MovieDetails({
    required this.key,
    required this.title,
    required this.originalTitle,
    required this.releaseDate,
    required this.posterPath,
    required this.genres,
    required this.overview,
    required this.tagline,
    required this.runtime,
    required this.imdbId,
    required this.vote,
    this.originalLanguage,
    this.credits = const Credits(),
  });

  factory MovieDetails.fromJson(Json json) {
    final id = json.integer('id');
    if (id == null || id <= 0) {
      throw const SourceException(SourceFailure.failed, 'movie without id');
    }
    return MovieDetails(
      key: WorkKey.movie(id),
      title: json.string('title') ?? json.string('original_title') ?? '',
      originalTitle: json.string('original_title'),
      originalLanguage: json.string('original_language'),
      releaseDate: json.string('release_date'),
      posterPath: json.string('poster_path'),
      genres: _genres(json),
      overview: json.string('overview'),
      tagline: json.string('tagline'),
      runtime: _positive(json.integer('runtime')),
      // A film has imdb_id both at the root and in external_ids; the root is
      // more reliable.
      imdbId:
          _imdb(json.string('imdb_id')) ??
          _imdb(json.object('external_ids')?.string('imdb_id')),
      vote: TmdbVote.fromJson(json),
      credits: Credits.fromJson(json.object('credits')),
    );
  }

  final WorkKey key;
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? releaseDate;
  final String? posterPath;
  final List<Genre> genres;
  final String? overview;
  final String? tagline;

  /// Minutes.
  final int? runtime;
  final String? imdbId;
  final TmdbVote vote;

  /// Cast and key crew, when the request appended `credits`.
  final Credits credits;

  int? get year => yearOf(releaseDate);
}

final class TvDetails {
  const TvDetails({
    required this.key,
    required this.title,
    required this.originalTitle,
    required this.firstAirDate,
    required this.lastAirDate,
    required this.posterPath,
    required this.genres,
    required this.overview,
    required this.tagline,
    required this.status,
    required this.episodeCount,
    required this.seasons,
    required this.imdbId,
    required this.vote,
    this.originalLanguage,
    this.credits = const Credits(),
  });

  factory TvDetails.fromJson(Json json) {
    final id = json.integer('id');
    if (id == null || id <= 0) {
      throw const SourceException(SourceFailure.failed, 'tv without id');
    }
    return TvDetails(
      key: WorkKey.tv(id),
      title: json.string('name') ?? json.string('original_name') ?? '',
      originalTitle: json.string('original_name'),
      originalLanguage: json.string('original_language'),
      firstAirDate: json.string('first_air_date'),
      lastAirDate: json.string('last_air_date'),
      posterPath: json.string('poster_path'),
      genres: _genres(json),
      overview: json.string('overview'),
      tagline: json.string('tagline'),
      status: TvStatus.parse(json.string('status')),
      episodeCount: json.integer('number_of_episodes'),
      seasons: [
        for (final season in json.objects('seasons'))
          if (SeasonSummary.fromJson(id, season) case final parsed?) parsed,
      ],
      imdbId: _imdb(json.object('external_ids')?.string('imdb_id')),
      vote: TmdbVote.fromJson(json),
      credits: Credits.fromJson(
        json.object('credits'),
        createdBy: json.objects('created_by'),
      ),
    );
  }

  final WorkKey key;
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? firstAirDate;
  final String? lastAirDate;
  final String? posterPath;
  final List<Genre> genres;
  final String? overview;
  final String? tagline;
  final TvStatus status;
  final int? episodeCount;

  /// In TMDB order: specials (season 0) first, if there are any.
  final List<SeasonSummary> seasons;
  final String? imdbId;
  final TmdbVote vote;

  /// Cast and key crew, when the request appended `credits`.
  final Credits credits;

  int? get firstYear => yearOf(firstAirDate);
  int? get lastYear => yearOf(lastAirDate);

  /// Regular seasons, specials excluded.
  int get regularSeasonCount => seasons.where((s) => s.number > 0).length;
}

/// Series status — only what changes the label in the header.
enum TvStatus {
  running,
  ended,
  canceled,
  unknown;

  static TvStatus parse(String? value) => switch (value) {
    'Returning Series' || 'In Production' || 'Planned' => running,
    'Ended' => ended,
    'Canceled' || 'Cancelled' => canceled,
    _ => unknown,
  };
}

/// A season in a series' season list.
final class SeasonSummary {
  const SeasonSummary({
    required this.key,
    required this.name,
    required this.airDate,
    required this.episodeCount,
    required this.posterPath,
    required this.vote,
    this.tmdbId,
  });

  static SeasonSummary? fromJson(int tvId, Json json) {
    final number = json.integer('season_number');
    if (number == null || number < 0) return null;
    return SeasonSummary(
      key: WorkKey.season(tvId, number),
      tmdbId: _positive(json.integer('id')),
      name: json.string('name'),
      airDate: json.string('air_date'),
      episodeCount: json.integer('episode_count') ?? 0,
      posterPath: json.string('poster_path'),
      vote: TmdbVote.fromJson(json),
    );
  }

  final WorkKey key;

  /// The season's own TMDB id (not the series'): how a rated season is found
  /// again after TMDB renumbers the seasons.
  final int? tmdbId;

  /// TMDB names it "Season 1" itself, but it can be empty.
  final String? name;
  final String? airDate;
  final int episodeCount;
  final String? posterPath;
  final TmdbVote vote;

  int get number => key.season!;
  int? get year => yearOf(airDate);
}

final class SeasonDetails {
  const SeasonDetails({
    required this.key,
    required this.name,
    required this.overview,
    required this.airDate,
    required this.posterPath,
    required this.episodes,
    required this.vote,
    this.tmdbId,
    this.credits = const Credits(),
  });

  factory SeasonDetails.fromJson(int tvId, Json json) {
    final number = json.integer('season_number');
    if (number == null || number < 0) {
      throw const SourceException(SourceFailure.failed, 'season w/o number');
    }
    return SeasonDetails(
      key: WorkKey.season(tvId, number),
      tmdbId: _positive(json.integer('id')),
      name: json.string('name'),
      overview: json.string('overview'),
      airDate: json.string('air_date'),
      posterPath: json.string('poster_path'),
      episodes: [
        for (final episode in json.objects('episodes'))
          if (EpisodeSummary.fromJson(tvId, number, episode) case final parsed?)
            parsed,
      ],
      vote: TmdbVote.fromJson(json),
      credits: Credits.fromJson(json.object('credits')),
    );
  }

  final WorkKey key;

  /// The season's own TMDB id (not the series'): follows the season when
  /// TMDB renumbers (lib/data/library/renumbering.dart).
  final int? tmdbId;
  final String? name;
  final String? overview;
  final String? airDate;
  final String? posterPath;
  final List<EpisodeSummary> episodes;
  final TmdbVote vote;

  /// Cast and key crew, when the request appended `credits`.
  final Credits credits;

  int get number => key.season!;
  int? get year => yearOf(airDate);
}

/// An episode from the season response: everything the episode card shows
/// except `imdb_id` (that is a separate request).
final class EpisodeSummary {
  const EpisodeSummary({
    required this.key,
    required this.name,
    required this.overview,
    required this.airDate,
    required this.runtime,
    required this.stillPath,
    required this.vote,
    this.tmdbId,
  });

  static EpisodeSummary? fromJson(int tvId, int season, Json json) {
    final number = json.integer('episode_number');
    if (number == null || number <= 0) return null;
    return EpisodeSummary(
      key: WorkKey.episode(tvId, season, number),
      tmdbId: _positive(json.integer('id')),
      name: json.string('name'),
      overview: json.string('overview'),
      airDate: json.string('air_date'),
      runtime: _positive(json.integer('runtime')),
      stillPath: json.string('still_path'),
      vote: TmdbVote.fromJson(json),
    );
  }

  final WorkKey key;

  /// The episode's own TMDB id (not the series'): follows the episode when
  /// TMDB renumbers (lib/data/library/renumbering.dart).
  final int? tmdbId;
  final String? name;
  final String? overview;
  final String? airDate;
  final int? runtime;
  final String? stillPath;
  final TmdbVote vote;

  int get season => key.season!;
  int get number => key.episode!;
}

/// Where TMDB images live (`GET /configuration`).
/// An image path and its language, or null for an image without text.
final class TmdbImage {
  const TmdbImage(this.path, this.language);
  final String path;
  final String? language;
}

final class ImageConfig {
  const ImageConfig(
    this.baseUrl, {
    this.posterLarge = ImageSize.w780,
    this.stillLarge = ImageSize.original,
  });

  factory ImageConfig.fromJson(Json json) {
    final images = json.object('images');
    final base = images?.string('secure_base_url');
    if (base == null || !base.startsWith('https://')) return fallback;
    ImageSize choose(String field, ImageSize defaultSize) {
      final sizes = images?.raw[field];
      if (sizes is! List) return defaultSize;
      for (final size in [
        ImageSize.w780,
        ImageSize.original,
        ImageSize.w500,
        ImageSize.w342,
        ImageSize.w300,
        ImageSize.w185,
        ImageSize.w92,
      ]) {
        if (sizes.contains(size.name)) return size;
      }
      return defaultSize;
    }

    return ImageConfig(
      base,
      posterLarge: choose('poster_sizes', ImageSize.w780),
      stillLarge: choose('still_sizes', ImageSize.original),
    );
  }

  /// Used until the configuration loads, and if it never does. The address
  /// hasn't changed in years; image cache keys don't depend on it.
  static const fallback = ImageConfig('https://image.tmdb.org/t/p/');

  final String baseUrl;
  final ImageSize posterLarge;
  final ImageSize stillLarge;

  Uri url(String path, ImageSize size) =>
      Uri.parse('$baseUrl${size.name}$path');
}

/// Sizes present in the configuration's `poster_sizes` / `still_sizes`.
enum ImageSize { w92, w185, w300, w342, w500, w780, original }

/// A `{"genres": [{"id", "name"}]}` list: a card's genres, or the whole
/// list from `genre/movie/list`.
List<Genre> parseGenres(Json json) => _genres(json);

List<Genre> _genres(Json json) => [
  for (final genre in json.objects('genres'))
    if ((genre.integer('id'), genre.string('name')) case (
      final id?,
      final name?,
    ))
      Genre(id, name),
];

int? _positive(int? value) => value != null && value > 0 ? value : null;

final _imdbPattern = RegExp(r'^tt[0-9]{7,10}$');

String? _imdb(String? value) =>
    value != null && _imdbPattern.hasMatch(value) ? value : null;
