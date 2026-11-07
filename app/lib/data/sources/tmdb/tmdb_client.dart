import 'package:dio/dio.dart';

import '../../response_cache.dart';
import '../../source_failure.dart';
import '../../work_key.dart';
import 'tmdb_models.dart';

/// The catalog: search, cards, seasons, images. Errors are [SourceException].
abstract interface class TmdbApi {
  /// Films and series only; people have a separate search mode.
  Future<SearchPage> search(String query, {int page = 1});
  Future<SearchPage> searchPeople(String query, {int page = 1});
  Future<MovieDetails> movie(int id);
  Future<TvDetails> tv(int id);
  Future<SeasonDetails> season(int tvId, int season);

  /// The episode's `imdb_id`, if TMDB knows it. The season response lacks it.
  Future<String?> episodeImdbId(int tvId, int season, int episode);
  Future<ImageConfig> imageConfig();

  /// Poster variants, or stills for an episode.
  Future<List<TmdbImage>> images(WorkKey key);

  /// Profile photographs of a person.
  Future<List<TmdbImage>> personImages(int id);

  /// The names of the genres for films ([WorkKind.movie]) or series
  /// ([WorkKind.tv]); the two lists share most ids.
  Future<List<Genre>> genres(WorkKind kind);

  /// Films and series trending this week.
  Future<List<TitleSummary>> trending();

  /// Films in cinemas now.
  Future<List<TitleSummary>> nowPlaying();

  /// The best rated films or series with enough votes to mean it.
  Future<List<TitleSummary>> best(WorkKind kind);

  /// TMDB's recommendations for a film or a series.
  Future<List<TitleSummary>> recommendations(WorkKey key);

  Future<List<TitleSummary>> similar(WorkKey key);
  Future<List<TitleSummary>> collection(int id);

  /// An episode's cast, guest stars included, and its crew.
  Future<Credits> episodeCredits(int tvId, int season, int episode);

  /// A person with their filmography.
  Future<Person> person(int id);

  Future<List<PersonSummary>> popularPeople();

  /// Verify numbered parts against the rated identity before attributing work.
  Future<List<PeopleCredit>> peopleCredits(WorkKey key, int expectedId);

  /// A small discovery pool for local ranking, separate from the all-time best.
  Future<List<TitleSummary>> discoverRecommendations(
    WorkKind kind, {
    int? genre,
  });
}

/// Lifetimes of responses in the HTTP cache (docs/external-sources.md, "Cache
/// and lifetimes").
abstract final class TmdbTtl {
  static const search = Duration(days: 1);
  static const details = Duration(days: 7);
  static const configuration = Duration(days: 30);

  /// Genre names hardly ever change.
  static const genres = Duration(days: 30);

  /// Trending and now playing change daily.
  static const shelf = Duration(days: 1);

  /// The best of all time and recommendations hardly move in a week.
  static const slowShelf = Duration(days: 7);

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
    Future<Json?> Function(String)? parseJson,
  }) : _parseJson = parseJson ?? tryJsonAsync,
       _auth = auth(key),
       _clock = clock ?? DateTime.now;

  static const _base = 'https://api.themoviedb.org/3';

  final Future<Json?> Function(String) _parseJson;
  final _inFlight = <String, Future<Json>>{};
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
  Future<SearchPage> searchPeople(String query, {int page = 1}) async {
    final json = await _get('/search/person', {
      'query': query,
      'page': '$page',
      'include_adult': 'false',
    }, TmdbTtl.search);
    return SearchPage(
      const [],
      people: [
        for (final item in json.objects('results'))
          if (PersonSummary.fromJson(item) case final person?) person,
      ],
      page: json.integer('page') ?? page,
      pages: json.integer('total_pages') ?? page,
    );
  }

  @override
  Future<MovieDetails> movie(int id) async => MovieDetails.fromJson(
    await _get('/movie/$id', {
      'append_to_response': 'external_ids,credits,release_dates',
    }, TmdbTtl.details),
  );

  @override
  Future<TvDetails> tv(int id) async => TvDetails.fromJson(
    await _get('/tv/$id', {
      'append_to_response': 'external_ids,aggregate_credits',
    }, TmdbTtl.details),
  );

  @override
  Future<SeasonDetails> season(int tvId, int season) async =>
      SeasonDetails.fromJson(
        tvId,
        await _get('/tv/$tvId/season/$season', const {
          'append_to_response': 'aggregate_credits',
        }, TmdbTtl.details),
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
  Future<List<TmdbImage>> images(WorkKey key) async {
    final path = switch (key.kind) {
      WorkKind.movie => '/movie/${key.tmdbId}/images',
      WorkKind.tv => '/tv/${key.tmdbId}/images',
      WorkKind.season => '/tv/${key.tmdbId}/season/${key.season}/images',
      WorkKind.episode =>
        '/tv/${key.tmdbId}/season/${key.season}/episode/${key.episode}/images',
    };
    final json = await _get(path, const {}, TmdbTtl.details, localized: false);
    return [
      for (final image in json.objects(
        key.kind == WorkKind.episode ? 'stills' : 'posters',
      ))
        if (image.string('file_path') case final path?
            when path.startsWith('/'))
          TmdbImage(path, image.string('iso_639_1')),
    ];
  }

  @override
  Future<List<TmdbImage>> personImages(int id) async {
    final json = await _get(
      '/person/$id/images',
      const {},
      TmdbTtl.details,
      localized: false,
    );
    return [
      for (final image in json.objects('profiles'))
        if (image.string('file_path') case final path?
            when path.startsWith('/'))
          TmdbImage(path, image.string('iso_639_1')),
    ];
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

  @override
  Future<List<Genre>> genres(WorkKind kind) async => parseGenres(
    await _get(
      switch (kind) {
        WorkKind.movie => '/genre/movie/list',
        WorkKind.tv => '/genre/tv/list',
        WorkKind.season ||
        WorkKind.episode => throw ArgumentError.value(kind, 'kind'),
      },
      const {},
      TmdbTtl.genres,
    ),
  );

  @override
  Future<List<TitleSummary>> trending() async =>
      _titles(await _get('/trending/all/week', const {}, TmdbTtl.shelf));

  @override
  Future<List<TitleSummary>> nowPlaying() async => _titles(
    await _get('/movie/now_playing', const {'page': '1'}, TmdbTtl.shelf),
    kind: WorkKind.movie,
  );

  @override
  Future<List<TitleSummary>> best(WorkKind kind) async {
    final movie = kind == WorkKind.movie;
    // /top_rated is crowded with new titles that have a handful of votes.
    return _titles(
      await _get(movie ? '/discover/movie' : '/discover/tv', {
        'sort_by': 'vote_average.desc',
        'vote_count.gte': movie ? '10000' : '3000',
        'page': '1',
      }, TmdbTtl.slowShelf),
      kind: kind,
    );
  }

  @override
  Future<List<TitleSummary>> discoverRecommendations(
    WorkKind kind, {
    int? genre,
  }) async {
    if (kind != WorkKind.movie && kind != WorkKind.tv) {
      throw ArgumentError.value(kind, 'kind');
    }
    final movie = kind == WorkKind.movie;
    final now = _clock();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _titles(
      await _get(movie ? '/discover/movie' : '/discover/tv', {
        'sort_by': 'popularity.desc',
        'include_adult': 'false',
        'vote_count.gte': movie ? '50' : '25',
        'vote_average.gte': '6',
        if (genre != null) 'with_genres': '$genre',
        if (movie)
          'primary_release_date.lte': today
        else
          'first_air_date.lte': today,
      }, TmdbTtl.shelf),
      kind: kind,
    );
  }

  @override
  Future<List<TitleSummary>> recommendations(WorkKey key) async => _titles(
    await _get(
      key.kind == WorkKind.movie
          ? '/movie/${key.tmdbId}/recommendations'
          : '/tv/${key.tmdbId}/recommendations',
      const {'page': '1'},
      TmdbTtl.slowShelf,
    ),
  );

  @override
  Future<List<TitleSummary>> similar(WorkKey key) async {
    final kind = key.kind;
    if (kind != WorkKind.movie && kind != WorkKind.tv) {
      throw ArgumentError.value(key, 'key');
    }
    return _titles(
      await _get(
        '/${kind == WorkKind.movie ? 'movie' : 'tv'}/${key.tmdbId}/similar',
        const {'page': '1'},
        TmdbTtl.slowShelf,
      ),
      kind: kind,
    );
  }

  @override
  Future<List<TitleSummary>> collection(int id) async {
    final json = await _get('/collection/$id', const {}, TmdbTtl.details);
    final titles = [
      for (final part in json.objects('parts'))
        if (TitleSummary.fromListJson(part, WorkKind.movie) case final title?)
          title,
    ];
    titles.sort((a, b) {
      final date = (a.releaseDate ?? '9999').compareTo(b.releaseDate ?? '9999');
      return date != 0 ? date : a.key.tmdbId.compareTo(b.key.tmdbId);
    });
    return titles;
  }

  @override
  Future<Credits> episodeCredits(int tvId, int season, int episode) async =>
      Credits.fromJson(
        await _get(
          '/tv/$tvId/season/$season/episode/$episode/credits',
          const {},
          TmdbTtl.details,
        ),
        guestStars: true,
      );

  @override
  Future<Person> person(int id) async => Person.fromJson(
    await _get('/person/$id', const {
      'append_to_response': 'combined_credits',
    }, TmdbTtl.details),
  );

  @override
  Future<List<PersonSummary>> popularPeople() async {
    final json = await _get('/person/popular', const {}, TmdbTtl.shelf);
    return [
      for (final row in json.objects('results'))
        if (PersonSummary.fromJson(row) case final person?) person,
    ];
  }

  @override
  Future<List<PeopleCredit>> peopleCredits(WorkKey key, int expectedId) async {
    final path = switch (key.kind) {
      WorkKind.movie => '/movie/${key.tmdbId}/credits',
      WorkKind.tv => '/tv/${key.tmdbId}',
      WorkKind.season => '/tv/${key.tmdbId}/season/${key.season}',
      WorkKind.episode =>
        '/tv/${key.tmdbId}/season/${key.season}/episode/${key.episode}',
    };
    final json = await _get(path, switch (key.kind) {
      WorkKind.movie => const {},
      WorkKind.tv ||
      WorkKind.season => const {'append_to_response': 'aggregate_credits'},
      WorkKind.episode => const {'append_to_response': 'credits'},
    }, TmdbTtl.details);
    if (json.integer('id') != expectedId) {
      throw const SourceException(
        SourceFailure.notFound,
        'changed title identity',
      );
    }
    return PeopleCredit.parse(json);
  }

  /// A list of titles: of one [kind], or mixed with `media_type`.
  static List<TitleSummary> _titles(Json json, {WorkKind? kind}) => [
    for (final item in json.objects('results'))
      if ((kind == null
              ? TitleSummary.fromSearchJson(item)
              : TitleSummary.fromListJson(item, kind))
          case final title?)
        title,
  ];

  /// Cache → network → stale cache. A fresh entry is returned without a
  /// request; if the request fails because of the network or the service, a
  /// stale entry is returned too: an old overview beats an error screen.
  Future<Json> _get(
    String path,
    Map<String, String> params,
    Duration ttl, {
    bool localized = true,
  }) async {
    final key = cacheKey(path, {
      ...params,
      if (localized) 'language': language,
    });
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final pending = _load(path, params, ttl, localized: localized);
    _inFlight[key] = pending;
    try {
      return await pending;
    } finally {
      final removed = _inFlight.remove(key);
      assert(identical(removed, pending));
    }
  }

  Future<Json> _load(
    String path,
    Map<String, String> params,
    Duration ttl, {
    bool localized = true,
  }) async {
    final query = {...params, if (localized) 'language': language};
    final key = cacheKey(path, query);
    final cached = await _cache.read(key);
    // The cache is evictable and may be damaged. Only a decoded body can
    // satisfy a request or serve as an offline fallback.
    final cachedJson = cached == null ? null : await _parseJson(cached.body);
    final now = _clock().toUtc().millisecondsSinceEpoch;
    if (cachedJson != null &&
        now - cached!.storedAt >= 0 &&
        now - cached.storedAt < ttl.inMilliseconds) {
      return cachedJson;
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
      if (cachedJson != null) return cachedJson;
      throw SourceException.fromDio(e);
    }

    final body = response.data ?? '';
    switch (response.statusCode) {
      case 200:
        final json = await _parseJson(body);
        if (json == null) {
          if (cachedJson != null) return cachedJson;
          throw const SourceException(SourceFailure.failed, 'not JSON');
        }
        await _cache.write(key, CachedResponse(body, now));
        return json;
      case 401:
        throw const SourceException(SourceFailure.unauthorized);
      case 404:
        throw const SourceException(SourceFailure.notFound);
      default:
        if (cachedJson != null) return cachedJson;
        throw SourceException(
          SourceFailure.failed,
          'HTTP ${response.statusCode}',
        );
    }
  }
}
