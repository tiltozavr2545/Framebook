import 'package:dio/dio.dart';

import '../../response_cache.dart';
import '../../source_failure.dart';
import 'tmdb_models.dart';

/// The catalog: search, cards, seasons, images. Errors are [SourceException].
abstract interface class TmdbApi {
  /// Films and series only: people are dropped.
  Future<SearchPage> search(String query, {int page = 1});
  Future<MovieDetails> movie(int id);
  Future<TvDetails> tv(int id);
  Future<SeasonDetails> season(int tvId, int season);

  /// The episode's `imdb_id`, if TMDB knows it. The season response lacks it.
  Future<String?> episodeImdbId(int tvId, int season, int episode);
  Future<ImageConfig> imageConfig();
}

/// Lifetimes of responses in the HTTP cache (docs/external-sources.md, "Cache
/// and lifetimes").
abstract final class TmdbTtl {
  static const search = Duration(days: 1);
  static const details = Duration(days: 7);
  static const configuration = Duration(days: 30);

  /// An episode's external ids don't change: kept as long as configuration.
  static const externalIds = Duration(days: 30);

  /// Past this an entry is useless even offline.
  static const longest = configuration;
}

final class TmdbClient implements TmdbApi {
  TmdbClient(
    this._dio,
    this._cache, {
    required String key,
    required this.language,
    DateTime Function()? clock,
  }) : _auth = auth(key),
       _clock = clock ?? DateTime.now;

  static const _base = 'https://api.themoviedb.org/3';

  final Dio _dio;
  final ResponseCache _cache;
  final ({Map<String, String> headers, Map<String, String> query}) _auth;
  final DateTime Function() _clock;

  /// `ru-RU` / `en-US`: the language of titles and overviews.
  final String language;

  /// Accepts both the API Read Access Token (`eyJ…`, in a header) and the
  /// short v3 API key (a query parameter) — docs/api-keys.md.
  static ({Map<String, String> headers, Map<String, String> query}) auth(
    String key,
  ) => key.startsWith('eyJ')
      ? (headers: {'Authorization': 'Bearer $key'}, query: const {})
      : (headers: const {}, query: {'api_key': key});

  /// Cache key: path and sorted parameters, without the API key. The key
  /// isn't needed to name an entry and must not end up on disk.
  static String cacheKey(String path, Map<String, String> query) {
    final params = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final encoded = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'tmdb:$path?$encoded';
  }

  @override
  Future<SearchPage> search(String query, {int page = 1}) async {
    final json = await _get('/search/multi', {
      'query': query,
      'page': '$page',
      'include_adult': 'false',
    }, TmdbTtl.search);
    return SearchPage(
      [
        for (final item in json.objects('results'))
          if (TitleSummary.fromSearchJson(item) case final parsed?) parsed,
      ],
      page: json.integer('page') ?? page,
      pages: json.integer('total_pages') ?? page,
    );
  }

  @override
  Future<MovieDetails> movie(int id) async => MovieDetails.fromJson(
    await _get('/movie/$id', {
      'append_to_response': 'external_ids',
    }, TmdbTtl.details),
  );

  @override
  Future<TvDetails> tv(int id) async => TvDetails.fromJson(
    await _get('/tv/$id', {
      'append_to_response': 'external_ids',
    }, TmdbTtl.details),
  );

  @override
  Future<SeasonDetails> season(int tvId, int season) async =>
      SeasonDetails.fromJson(
        tvId,
        await _get('/tv/$tvId/season/$season', const {}, TmdbTtl.details),
      );

  @override
  Future<String?> episodeImdbId(int tvId, int season, int episode) async {
    final json = await _get(
      '/tv/$tvId/season/$season/episode/$episode/external_ids',
      const {},
      TmdbTtl.externalIds,
      localized: false,
    );
    final id = json.string('imdb_id');
    return id != null && id.startsWith('tt') ? id : null;
  }

  @override
  Future<ImageConfig> imageConfig() async => ImageConfig.fromJson(
    await _get(
      '/configuration',
      const {},
      TmdbTtl.configuration,
      localized: false,
    ),
  );

  /// Cache → network → stale cache. A fresh entry is returned without a
  /// request; if the request fails because of the network or the service, a
  /// stale entry is returned too: an old overview beats an error screen.
  Future<Json> _get(
    String path,
    Map<String, String> params,
    Duration ttl, {
    bool localized = true,
  }) async {
    final query = {...params, if (localized) 'language': language};
    final key = cacheKey(path, query);
    final cached = await _cache.read(key);
    final now = _clock().toUtc().millisecondsSinceEpoch;
    if (cached != null && now - cached.storedAt < ttl.inMilliseconds) {
      return _decode(cached.body);
    }

    final Response<String> response;
    try {
      response = await _dio.get<String>(
        '$_base$path',
        queryParameters: {...query, ..._auth.query},
        options: Options(
          headers: _auth.headers,
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (e) {
      if (cached != null) return _decode(cached.body);
      throw SourceException.fromDio(e);
    }

    final body = response.data ?? '';
    switch (response.statusCode) {
      case 200:
        final json = _decode(body);
        await _cache.write(key, CachedResponse(body, now));
        return json;
      case 401:
        throw const SourceException(SourceFailure.unauthorized);
      case 404:
        throw const SourceException(SourceFailure.notFound);
      default:
        if (cached != null) return _decode(cached.body);
        throw SourceException(
          SourceFailure.failed,
          'HTTP ${response.statusCode}',
        );
    }
  }

  static Json _decode(String body) =>
      tryJson(body) ??
      (throw const SourceException(SourceFailure.failed, 'not JSON'));
}
