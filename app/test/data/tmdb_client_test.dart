import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

void main() {
  late Dio dio;
  late FakeHttpAdapter http;
  late MemoryResponseCache cache;
  late DateTime now;

  TmdbClient client({String key = 'eyJtoken'}) =>
      TmdbClient(dio, cache, key: key, language: 'ru-RU', clock: () => now);

  void serve(Reply? Function(RequestOptions) respond) {
    http = FakeHttpAdapter(respond);
    dio.httpClientAdapter = http;
  }

  setUp(() {
    dio = createDio();
    cache = MemoryResponseCache();
    now = DateTime.utc(2026, 10, 24, 12);
    serve(apiFixtures);
  });

  group('search', () {
    test('keeps films and series, in TMDB order', () async {
      final page = await client().search('Матрица');
      expect(page.results.map((r) => r.key.toString()).take(4), [
        'tmdb:movie:603',
        'tmdb:movie:604',
        'tmdb:tv:711',
        'tmdb:movie:605',
      ]);
      final matrix = page.results.first;
      expect(matrix.title, 'Матрица');
      expect(matrix.originalTitle, 'The Matrix');
      expect(matrix.year, 1999);
      expect(matrix.posterPath, '/kEDbym5htJgDQNenjUtSJxAHysB.jpg');
      expect(matrix.vote.average, closeTo(8.261, 1e-9));

      final series = page.results[2];
      expect(series.title, 'Матрица: Угроза');
      expect(series.originalTitle, 'Threat Matrix');
      expect(series.year, 2003);
      expect(page.page, 1);
      expect(page.pages, 1);
    });

    test('drops people and anything without a title', () {
      final person = TitleSummary.fromSearchJson(
        const Json({'id': 6384, 'media_type': 'person', 'name': 'Keanu'}),
      );
      final untitled = TitleSummary.fromSearchJson(
        const Json({'id': 1, 'media_type': 'movie'}),
      );
      expect(person, isNull);
      expect(untitled, isNull);
    });

    test('an empty release date is no date, not a crash', () {
      final unreleased = TitleSummary.fromSearchJson(
        const Json({
          'id': 1,
          'media_type': 'movie',
          'title': 'Soon',
          'release_date': '',
          'vote_average': 0,
          'vote_count': 0,
        }),
      )!;
      expect(unreleased.releaseDate, isNull);
      expect(unreleased.year, isNull);
      // Zero on TMDB means "no votes", not a score of 0.
      expect(unreleased.vote.average, isNull);
    });

    test('sends the query, page and language; key in the header', () async {
      await client().search('Матрица', page: 2);
      final request = http.requests.single;
      expect(request.uri.path, '/3/search/multi');
      expect(request.uri.queryParameters, {
        'query': 'Матрица',
        'page': '2',
        'include_adult': 'false',
        'language': 'ru-RU',
      });
      expect(request.headers['Authorization'], 'Bearer eyJtoken');
    });
  });

  group('cards', () {
    test('movie: details and imdb id', () async {
      final movie = await client().movie(603);
      expect(movie.key, const WorkKey.movie(603));
      expect(movie.title, 'Матрица');
      expect(movie.imdbId, 'tt0133093');
      expect(movie.runtime, 136);
      expect(movie.genres.map((g) => g.name), ['боевик', 'фантастика']);
      expect(movie.tagline, '«Добро пожаловать в реальный мир»');
      expect(movie.vote.count, 29028);
    });

    test('series: imdb id from external_ids, seasons with specials', () async {
      final tv = await client().tv(1399);
      expect(tv.key, const WorkKey.tv(1399));
      expect(tv.title, 'Игра Престолов');
      expect(tv.imdbId, 'tt0944947');
      expect(tv.status, TvStatus.ended);
      expect(tv.firstYear, 2011);
      expect(tv.lastYear, 2019);
      expect(tv.episodeCount, 73);
      expect(tv.seasons.first.key, const WorkKey.season(1399, 0));
      // Specials have vote_average 0, which means "no votes".
      expect(tv.seasons.first.vote.average, isNull);
      expect(tv.regularSeasonCount, 8);
      final first = tv.seasons[1];
      expect(first.key, const WorkKey.season(1399, 1));
      expect(first.episodeCount, 10);
      expect(first.vote.average, 8.4);
    });

    test('season: every episode with its key', () async {
      final season = await client().season(1399, 1);
      expect(season.key, const WorkKey.season(1399, 1));
      expect(season.episodes, hasLength(10));
      final third = season.episodes[2];
      expect(third.key, const WorkKey.episode(1399, 1, 3));
      expect(third.name, 'Лорд Сноу');
      expect(third.airDate, '2011-05-01');
      expect(third.runtime, 58);
      expect(third.vote.average, closeTo(8.061, 1e-9));
    });

    test('episode imdb id matches what OMDb knows', () async {
      expect(await client().episodeImdbId(1399, 1, 3), 'tt1829962');
      // Not localized: a language parameter would only bloat the cache.
      expect(http.requests.single.uri.queryParameters, isEmpty);
    });

    test('image base URL from the configuration', () async {
      final config = await client().imageConfig();
      expect(
        config.url('/abc.jpg', ImageSize.w185).toString(),
        'https://image.tmdb.org/t/p/w185/abc.jpg',
      );
    });
  });

  group('failures', () {
    test('404 is not found', () async {
      await expectLater(
        client().movie(999999999),
        throwsA(
          isA<SourceException>().having(
            (e) => e.failure,
            'failure',
            SourceFailure.notFound,
          ),
        ),
      );
    });

    test('401 is a rejected key', () async {
      serve(
        (_) => (
          status: 401,
          body: '{"status_code":7,"status_message":"Invalid API key"}',
        ),
      );
      await expectLater(
        client().movie(603),
        throwsA(
          isA<SourceException>().having(
            (e) => e.failure,
            'failure',
            SourceFailure.unauthorized,
          ),
        ),
      );
    });

    test('no network and nothing cached is offline', () async {
      serve((_) => null);
      await expectLater(
        client().movie(603),
        throwsA(
          isA<SourceException>().having(
            (e) => e.failure,
            'failure',
            SourceFailure.offline,
          ),
        ),
      );
    });
  });

  group('cache', () {
    test('a fresh entry answers without the network', () async {
      await client().movie(603);
      now = now.add(const Duration(days: 6));
      serve((_) => fail('should not hit the network'));
      expect((await client().movie(603)).title, 'Матрица');
    });

    test('an entry past its TTL is fetched again', () async {
      await client().movie(603);
      now = now.add(TmdbTtl.details);
      await client().movie(603);
      expect(http.requests, hasLength(2));
    });

    test('a stale entry is better than an error when offline', () async {
      await client().movie(603);
      now = now.add(const Duration(days: 60));
      serve((_) => null);
      expect((await client().movie(603)).title, 'Матрица');
    });

    test('... and when TMDB fails', () async {
      await client().movie(603);
      now = now.add(const Duration(days: 60));
      serve((_) => (status: 503, body: 'Service Unavailable'));
      expect((await client().movie(603)).title, 'Матрица');
    });

    test('errors are not cached', () async {
      serve((_) => (status: 503, body: 'Service Unavailable'));
      await expectLater(client().movie(603), throwsA(isA<SourceException>()));
      expect(cache.entries, isEmpty);
    });

    test('the key never lands in the cache key', () async {
      await client(key: 'short-v3-key').movie(603);
      expect(
        http.requests.single.uri.queryParameters['api_key'],
        'short-v3-key',
      );
      expect(cache.entries.keys.single, isNot(contains('short-v3-key')));
      expect(
        cache.entries.keys.single,
        'tmdb:/movie/603?append_to_response=external_ids&language=ru-RU',
      );
    });

    test('language is part of the key', () async {
      await client().movie(603);
      await TmdbClient(
        dio,
        cache,
        key: 'eyJtoken',
        language: 'en-US',
        clock: () => now,
      ).movie(603);
      expect(http.requests, hasLength(2));
      expect(cache.entries, hasLength(2));
    });
  });
}
