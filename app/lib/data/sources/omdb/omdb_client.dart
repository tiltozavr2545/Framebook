import 'package:dio/dio.dart';

import '../../source_failure.dart';

/// Ratings from one OMDb response. Rotten Tomatoes and Metacritic are 0…100
/// and exist for films only.
final class OmdbRatings {
  const OmdbRatings({
    required this.imdb,
    required this.imdbVotes,
    required this.rottenTomatoes,
    required this.metacritic,
  });

  factory OmdbRatings.fromJson(Json json) {
    int? rt;
    int? mc;
    for (final rating in json.objects('Ratings')) {
      final value = rating.string('Value');
      switch (rating.string('Source')) {
        case 'Rotten Tomatoes':
          rt = _leadingInt(value, suffix: '%');
        case 'Metacritic':
          mc = _leadingInt(value, suffix: '/100');
      }
    }
    return OmdbRatings(
      imdb: _decimal(json.string('imdbRating')),
      imdbVotes: _count(json.string('imdbVotes')),
      rottenTomatoes: rt,
      metacritic: mc,
    );
  }

  final double? imdb;
  final int? imdbVotes;
  final int? rottenTomatoes;
  final int? metacritic;
}

/// A season has no IMDb rating of its own; the episode average is shown.
final class SeasonAverage {
  const SeasonAverage(this.average, this.episodes);

  final double average;

  /// How many rated episodes went into the average.
  final int episodes;
}

/// `null` from any method means not found.
abstract interface class OmdbApi {
  /// A film, series or episode by its own imdb id.
  Future<OmdbRatings?> byImdbId(String imdbId);

  /// An episode whose imdb id TMDB doesn't know.
  Future<OmdbRatings?> episode(String seriesImdbId, int season, int episode);

  Future<SeasonAverage?> seasonAverage(String seriesImdbId, int season);
}

final class OmdbClient implements OmdbApi {
  OmdbClient(this._dio, this._key);

  static const _base = 'https://www.omdbapi.com/';

  final Dio _dio;
  final String _key;

  @override
  Future<OmdbRatings?> byImdbId(String imdbId) async {
    final json = await _get({'i': imdbId});
    return json == null ? null : OmdbRatings.fromJson(json);
  }

  @override
  Future<OmdbRatings?> episode(
    String seriesImdbId,
    int season,
    int episode,
  ) async {
    final json = await _get({
      'i': seriesImdbId,
      'Season': '$season',
      'Episode': '$episode',
    });
    return json == null ? null : OmdbRatings.fromJson(json);
  }

  @override
  Future<SeasonAverage?> seasonAverage(String seriesImdbId, int season) async {
    final json = await _get({'i': seriesImdbId, 'Season': '$season'});
    if (json == null) return null;
    // `"N/A"` is skipped; the list can have extra items such as "episode 0"
    // of Game of Thrones, which have no rating anyway.
    final ratings = [
      for (final episode in json.objects('Episodes'))
        if (_decimal(episode.string('imdbRating')) case final rating?) rating,
    ];
    if (ratings.isEmpty) return null;
    final sum = ratings.reduce((a, b) => a + b);
    return SeasonAverage(sum / ratings.length, ratings.length);
  }

  /// OMDb errors differ only by the `Error` text (docs/external-sources.md).
  /// `null` means not found.
  Future<Json?> _get(Map<String, String> query) async {
    final Response<String> response;
    try {
      response = await _dio.get<String>(
        _base,
        queryParameters: {...query, 'apikey': _key},
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (e) {
      throw SourceException.fromDio(e);
    }
    final json = tryJson(response.data);
    final error = json?.string('Error');
    if (error == 'Invalid API key!') {
      throw const SourceException(SourceFailure.unauthorized);
    }
    if (error == 'Request limit reached!') {
      throw const SourceException(SourceFailure.limitReached);
    }
    if (response.statusCode != 200 || json == null) {
      throw SourceException(
        SourceFailure.failed,
        'HTTP ${response.statusCode}',
      );
    }
    if (json.string('Response') == 'True') return json;
    // `Error getting data.`, `Incorrect IMDb ID.`, `Movie not found!`,
    // `Series or episode not found!` — all of these mean "no such title".
    if (error != null &&
        (error.contains('not found') ||
            error == 'Error getting data.' ||
            error == 'Incorrect IMDb ID.')) {
      return null;
    }
    throw SourceException(SourceFailure.failed, error ?? 'no Response');
  }
}

/// OMDb sends numbers as strings; `"N/A"` means none, not zero.
double? _decimal(String? value) {
  final parsed = value == null ? null : double.tryParse(value);
  return parsed != null && parsed > 0 ? parsed : null;
}

/// `"2,284,373"` → 2284373.
int? _count(String? value) =>
    value == null ? null : int.tryParse(value.replaceAll(',', ''));

/// `"83%"` → 83, `"73/100"` → 73.
int? _leadingInt(String? value, {required String suffix}) {
  if (value == null || !value.endsWith(suffix)) return null;
  return int.tryParse(value.substring(0, value.length - suffix.length));
}
