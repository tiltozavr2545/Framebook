import 'package:dio/dio.dart';

import '../../source_failure.dart';

/// What one PoiskKino request returns: the Kinopoisk id, the Kinopoisk
/// rating and a fallback IMDb rating. A `null` rating means Kinopoisk has
/// none.
final class KpRatings {
  const KpRatings({
    required this.kpId,
    required this.kp,
    required this.kpVotes,
    required this.imdb,
    required this.imdbVotes,
  });

  static KpRatings? fromJson(Json json) {
    final id = json.integer('id');
    if (id == null || id <= 0) return null;
    final rating = json.object('rating');
    final votes = json.object('votes');
    return KpRatings(
      kpId: id,
      kp: _rating(rating?.number('kp')),
      kpVotes: votes?.integer('kp'),
      imdb: _rating(rating?.number('imdb')),
      imdbVotes: votes?.integer('imdb'),
    );
  }

  final int kpId;
  final double? kp;
  final int? kpVotes;
  final double? imdb;
  final int? imdbVotes;
}

/// Kinopoisk rates films and series only, never seasons or episodes
/// (docs/external-sources.md). `null` from any method means not found.
abstract interface class PoiskKinoApi {
  /// A refresh by an already known Kinopoisk id.
  Future<KpRatings?> byKpId(int kpId);

  /// First match: an imdb id is globally unique.
  Future<KpRatings?> byImdbId(String imdbId, {required bool isSeries});

  /// First match without an imdb id. PoiskKino stores the tmdb id without its
  /// type, so the [isSeries] filter is mandatory.
  Future<KpRatings?> byTmdbId(int tmdbId, {required bool isSeries});
}

final class PoiskKinoClient implements PoiskKinoApi {
  PoiskKinoClient(this._dio, this._key);

  static const _base = 'https://api.poiskkino.dev/v1.5';

  /// Outside this range PoiskKino answers 400 rather than "not found"
  /// (fixture `movie_by_tmdb_out_of_range.json`), so such ids never go out.
  static const _maxTmdbId = 2000000;

  final Dio _dio;
  final String _key;

  @override
  Future<KpRatings?> byKpId(int kpId) async {
    final json = await _get('/movie/$kpId', const {});
    return json == null ? null : KpRatings.fromJson(json);
  }

  @override
  Future<KpRatings?> byImdbId(String imdbId, {required bool isSeries}) async {
    final json = await _get('/movie', {'externalId.imdb': imdbId});
    final docs = json?.objects('docs') ?? const [];
    // A single answer by imdb id is the one, even if the two databases
    // disagree on the type (a TMDB miniseries can be a film on Kinopoisk).
    // Several — pick by type.
    if (docs.length == 1) return KpRatings.fromJson(docs.single);
    return _single(docs, isSeries);
  }

  @override
  Future<KpRatings?> byTmdbId(int tmdbId, {required bool isSeries}) async {
    if (tmdbId < 1 || tmdbId > _maxTmdbId) return null;
    final json = await _get('/movie', {'externalId.tmdb': '$tmdbId'});
    return _single(json?.objects('docs') ?? const [], isSeries);
  }

  /// Exactly one of the right type is the one; zero or several is not found.
  /// Never guess (docs/external-sources.md, "Matching ids"). Filter by
  /// `isSeries`, not `type`: `type` splits into `cartoon`, `anime`,
  /// `animated-series`.
  static KpRatings? _single(List<Json> docs, bool isSeries) {
    final matching = docs.where((d) => d.boolean('isSeries') == isSeries);
    return matching.length == 1 ? KpRatings.fromJson(matching.single) : null;
  }

  /// `null` on 404 (no such id).
  Future<Json?> _get(String path, Map<String, String> query) async {
    final Response<String> response;
    try {
      response = await _dio.get<String>(
        '$_base$path',
        queryParameters: query,
        options: Options(
          headers: {'X-API-KEY': _key},
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (e) {
      throw SourceException.fromDio(e);
    }
    return switch (response.statusCode) {
      200 =>
        tryJson(response.data) ??
            (throw const SourceException(SourceFailure.failed, 'not JSON')),
      404 => null,
      401 => throw const SourceException(SourceFailure.unauthorized),
      403 => throw const SourceException(SourceFailure.limitReached),
      final code => throw SourceException(SourceFailure.failed, 'HTTP $code'),
    };
  }
}

/// Zero on Kinopoisk means "no ratings yet" (that is how an unreleased
/// title looks), not a 0.
double? _rating(double? value) => value != null && value > 0 ? value : null;
