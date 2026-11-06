import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

void main() {
  test('TMDB votes reject values outside the rating scale', () {
    for (final value in [double.infinity, double.nan, 10.1, -1, 0]) {
      expect(TmdbVote.fromJson(Json({'vote_average': value})).average, isNull);
    }
    expect(TmdbVote.fromJson(const Json({'vote_average': 10})).average, 10);
  });

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

  test('popular people use their own cached endpoint', () async {
    final people = await client().popularPeople();
    expect(people.single.id, 6384);
    expect(http.requests.last.uri.path, '/3/person/popular');
    await client().popularPeople();
    expect(http.requests.length, 1);
  });

  test(
    'personal discovery uses typed genre pools and release filters without personal scores',
    () async {
      await client().discoverRecommendations(WorkKind.movie, genre: 28);
      var q = http.requests.last.uri.queryParameters;
      expect(http.requests.last.uri.path, '/3/discover/movie');
      expect(q['with_genres'], '28');
      expect(q['sort_by'], 'popularity.desc');
      expect(q['vote_count.gte'], '50');
      expect(q['primary_release_date.lte'], '2026-10-24');
      expect(q.keys, isNot(contains('score_half')));
      await client().discoverRecommendations(WorkKind.tv);
      q = http.requests.last.uri.queryParameters;
      expect(http.requests.last.uri.path, '/3/discover/tv');
      expect(q['with_genres'], isNull);
      expect(q['vote_count.gte'], '25');
      expect(q['first_air_date.lte'], '2026-10-24');
      await expectLater(
        client().discoverRecommendations(WorkKind.episode),
        throwsArgumentError,
      );
    },
  );

  test(
    'analytics credits keep all professions and reject displaced identities',
    () async {
      final people = await client().peopleCredits(
        const WorkKey.movie(603),
        603,
      );
      expect(people.any((p) => p.role == FilmographyRole.acting), isTrue);
      expect(people.any((p) => p.role == FilmographyRole.directing), isTrue);
      expect(people.any((p) => p.role == FilmographyRole.production), isTrue);
      expect(people.any((p) => p.role == FilmographyRole.camera), isTrue);
      await expectLater(
        client().peopleCredits(const WorkKey.movie(603), 999),
        throwsA(isA<SourceException>()),
      );
      await expectLater(
        client().peopleCredits(const WorkKey.season(1399, 1), 999),
        throwsA(isA<SourceException>()),
      );
    },
  );

  test('person photos come from the profile images endpoint', () async {
    final images = await client().personImages(6384);
    expect(http.requests.last.uri.path, '/3/person/6384/images');
    expect(images.map((image) => image.path), ['/one.jpg', '/two.jpg']);
  });

  test(
    'analytics uses aggregate TV credits and preserves every crew role',
    () async {
      serve(
        (request) => (
          status: 200,
          body: '''{
        "id":1399,
        "aggregate_credits":{
          "cast":[{"id":1,"name":"Earlier actor"}],
          "crew":[{"id":2,"name":"Director and writer","jobs":[
            {"job":"Director"},{"job":"Writer"},{"job":"Director"}
          ]}]
        },
        "credits":{"cast":[{"id":3,"name":"Latest only"}]},
        "created_by":[{"id":4,"name":"Creator"}]
      }''',
        ),
      );
      for (final key in [
        const WorkKey.tv(1399),
        const WorkKey.season(1399, 1),
      ]) {
        final people = await client().peopleCredits(key, 1399);
        expect(
          http.requests.last.uri.queryParameters['append_to_response'],
          'aggregate_credits',
        );
        expect(people.map((p) => (p.id, p.role)), [
          (1, FilmographyRole.acting),
          (2, FilmographyRole.directing),
          (2, FilmographyRole.writing),
          (4, FilmographyRole.writing),
        ]);
      }
    },
  );

  test('episode analytics keeps ordinary credits and guest stars', () async {
    serve(
      (request) => (
        status: 200,
        body: '''{
        "id":99,
        "credits":{
          "cast":[{"id":1,"name":"Regular"}],
          "guest_stars":[{"id":2,"name":"Guest"}],
          "crew":[{"id":3,"name":"Writer","job":"Writer"}]
        },
        "guest_stars":[{"id":2,"name":"Guest"}]
      }''',
      ),
    );
    final people = await client().peopleCredits(
      const WorkKey.episode(1399, 1, 1),
      99,
    );
    expect(
      http.requests.last.uri.queryParameters['append_to_response'],
      'credits',
    );
    expect(people.map((p) => (p.id, p.role)), [
      (1, FilmographyRole.acting),
      (2, FilmographyRole.acting),
      (3, FilmographyRole.writing),
    ]);
  });

  test(
    'image endpoints use posters for seasons and stills for episodes',
    () async {
      serve((request) {
        if (request.path.endsWith('/episode/1/images')) {
          return (status: 200, body: fixture('tmdb/episode_images.json'));
        }
        return (status: 200, body: fixture('tmdb/season_images.json'));
      });
      await client().images(const WorkKey.movie(603));
      expect(http.requests.last.uri.path, '/3/movie/603/images');
      await client().images(const WorkKey.tv(1399));
      expect(http.requests.last.uri.path, '/3/tv/1399/images');
      final season = await client().images(const WorkKey.season(1399, 1));
      expect(http.requests.last.uri.path, '/3/tv/1399/season/1/images');
      expect(season.first.language, 'en');
      final episode = await client().images(const WorkKey.episode(1399, 1, 1));
      expect(
        http.requests.last.uri.path,
        '/3/tv/1399/season/1/episode/1/images',
      );
      expect(episode.single.language, isNull);
    },
  );

  test(
    'people search parses results and uses its own cached endpoint',
    () async {
      final page = await client().searchPeople('Киану', page: 1);
      expect(http.requests.last.uri.path, '/3/search/person');
      expect(http.requests.last.uri.queryParameters['include_adult'], 'false');
      expect(page.people.single.id, 6384);
      expect(page.people.single.knownFor, ['Матрица']);
      expect(page.results, isEmpty);
      await client().searchPeople('Киану');
      expect(http.requests.length, 1);
    },
  );

  test('filmography groups actual jobs without duplicating titles', () {
    final person = Person.fromJson(
      const Json({
        'id': 1,
        'name': 'Author',
        'combined_credits': {
          'cast': [
            {
              'id': 10,
              'media_type': 'movie',
              'title': 'Film',
              'character': 'Hero',
            },
          ],
          'crew': [
            {
              'id': 10,
              'media_type': 'movie',
              'title': 'Film',
              'job': 'Director',
            },
            {
              'id': 10,
              'media_type': 'movie',
              'title': 'Film',
              'job': 'Producer',
            },
            {
              'id': 10,
              'media_type': 'movie',
              'title': 'Film',
              'job': 'Executive Producer',
            },
            {
              'id': 10,
              'media_type': 'movie',
              'title': 'Film',
              'job': 'Screenplay',
            },
            {
              'id': 11,
              'media_type': 'tv',
              'name': 'Series',
              'job': 'Assistant Director',
            },
          ],
        },
      }),
    );
    final groups = person.filmography;
    expect(groups[FilmographyRole.directing]!.single.roles, ['Director']);
    expect(groups[FilmographyRole.production]!.single.roles, [
      'Producer',
      'Executive Producer',
    ]);
    expect(groups[FilmographyRole.writing]!.single.roles, ['Screenplay']);
    expect(groups[FilmographyRole.acting]!.single.roles, ['Hero']);
    expect(groups[FilmographyRole.other]!.single.roles, ['Assistant Director']);
    expect(groups.containsKey(FilmographyRole.music), isFalse);
  });

  group('search', () {
    test('keeps films and series, in TMDB order', () async {
      final page = await client().search('Матрица');
      expect(page.results.map((r) => r.key.toString()).take(4), [
        'tmdb:movie:603',
        'tmdb:tv:711',
        'tmdb:movie:604',
        'tmdb:movie:624860',
      ]);
      final matrix = page.results.first;
      expect(matrix.title, 'Матрица');
      expect(matrix.originalTitle, 'The Matrix');
      expect(matrix.year, 1999);
      expect(matrix.posterPath, '/kEDbym5htJgDQNenjUtSJxAHysB.jpg');
      expect(matrix.vote.average, closeTo(8.261, 1e-9));

      final series = page.results[1];
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
      expect(movie.budget, 63000000);
      expect(movie.revenue, 463517383);
      expect(movie.countries, ['United States of America']);
      expect(movie.collection?.id, 2344);
      expect(movie.premiereDate, '1999-03-31');
      expect(
        http.requests.last.uri.queryParameters['append_to_response'],
        contains('release_dates'),
      );
      expect(movie.genres.map((g) => g.name), ['боевик', 'фантастика']);
      expect(movie.tagline, '«Добро пожаловать в реальный мир»');
      expect(movie.vote.count, 29070);
    });

    test('unknown movie finances are absent rather than zero', () {
      for (final value in [null, 0, -1, 'N/A']) {
        final movie = MovieDetails.fromJson(
          Json({'id': 1, 'budget': value, 'revenue': value}),
        );
        expect(movie.budget, isNull);
        expect(movie.revenue, isNull);
      }
    });

    test(
      'world premiere uses the earliest valid calendar date without time zones',
      () {
        final movie = MovieDetails.fromJson(
          const Json({
            'id': 1,
            'release_date': '2000-01-10',
            'release_dates': {
              'results': [
                {
                  'release_dates': [
                    {'release_date': '2000-01-09T23:00:00.000Z'},
                    {'release_date': '1999-12-31T00:00:00.000Z'},
                    {'release_date': '1999-02-30T00:00:00.000Z'},
                    {'release_date': 'bad'},
                  ],
                },
                {
                  'release_dates': [
                    {'release_date': '2000-02-10T00:00:00.000Z'},
                  ],
                },
              ],
            },
          }),
        );
        expect(movie.premiereDate, '1999-12-31');
        expect(movie.releaseDate, '2000-01-10');
        expect(
          MovieDetails.fromJson(const Json({'id': 1})).premiereDate,
          isNull,
        );
      },
    );

    test('production countries skip malformed and duplicate entries', () {
      expect(
        productionCountries(
          const Json({
            'production_countries': [
              {'name': 'Australia'},
              {'name': 'Australia'},
              {'name': ''},
              {'name': 'United States of America'},
              {'name': 2},
              null,
            ],
          }),
        ),
        ['Australia', 'United States of America'],
      );
    });

    test(
      'collection uses movie identities and release order, with undated parts last',
      () async {
        serve(
          (_) => (
            status: 200,
            body: '''{"parts":[
        {"id":3,"title":"Undated"},
        {"id":2,"title":"Sequel","release_date":"2003-01-01"},
        {"id":1,"title":"First","release_date":"1999-01-01"},
        {"title":"Invalid"}
      ]}''',
          ),
        );
        final titles = await client().collection(2344);
        expect(http.requests.single.uri.path, '/3/collection/2344');
        expect(titles.map((title) => title.key), [
          const WorkKey.movie(1),
          const WorkKey.movie(2),
          const WorkKey.movie(3),
        ]);
        await client().collection(2344);
        expect(http.requests.length, 1);
      },
    );

    test(
      'similar endpoints preserve the movie or TV kind and use the cache',
      () async {
        serve(
          (_) => (
            status: 200,
            body: '{"results":[{"id":603,"title":"Film","name":"TV"}]}',
          ),
        );
        final movie = await client().similar(const WorkKey.movie(1));
        expect(http.requests.last.uri.path, '/3/movie/1/similar');
        expect(movie.single.key, const WorkKey.movie(603));
        final tv = await client().similar(const WorkKey.tv(1));
        expect(http.requests.last.uri.path, '/3/tv/1/similar');
        expect(tv.single.key, const WorkKey.tv(603));
        await client().similar(const WorkKey.tv(1));
        expect(http.requests.length, 2);
        await expectLater(
          client().similar(const WorkKey.season(1, 1)),
          throwsArgumentError,
        );
      },
    );

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
      // The season's own id, which a rating follows when TMDB renumbers.
      expect(first.tmdbId, 3624);
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
      expect(third.vote.average, closeTo(8.1, 1e-9));
    });

    test('episode imdb id matches what OMDb knows', () async {
      expect(await client().episodeImdbId(1399, 1, 3), 'tt1829962');
      // Not localized: a language parameter would only bloat the cache.
      expect(http.requests.single.uri.queryParameters, isEmpty);
    });

    test('image base URL from the configuration', () async {
      final config = await client().imageConfig();
      expect(config.posterLarge, ImageSize.w780);
      expect(config.stillLarge, ImageSize.original);
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
    test(
      'a damaged cached body is refetched instead of blocking the card',
      () async {
        await client().movie(603);
        final key = cache.entries.keys.single;
        cache.entries[key] = CachedResponse(
          'not JSON',
          now.millisecondsSinceEpoch,
        );
        expect((await client().movie(603)).title, 'Матрица');
        expect(http.requests, hasLength(2));
        expect(cache.entries[key]!.body, isNot('not JSON'));
      },
    );

    test(
      'an invalid successful response falls back to the stale card',
      () async {
        await client().movie(603);
        final saved = cache.entries.values.single.body;
        now = now.add(TmdbTtl.details);
        serve((_) => (status: 200, body: '<html>Proxy error</html>'));
        expect((await client().movie(603)).title, 'Матрица');
        expect(http.requests, hasLength(1));
        expect(cache.entries.values.single.body, saved);
      },
    );

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
        'tmdb:/movie/603?append_to_response=external_ids%2Ccredits%2Crelease_dates&language=ru-RU',
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

  group('cast and crew', () {
    test(
      'series and seasons request aggregate credits and parse all roles and jobs',
      () async {
        const aggregate = '''{
        "cast":[
          {"id":1,"name":"Earlier season actor","roles":[{"character":"First role"},{"character":"Second role"},{"character":"First role"}]},
          {"id":2,"name":"Guest actor","roles":[{"character":"Guest"}]}
        ],
        "crew":[{"id":3,"name":"Director and writer","jobs":[{"job":"Director"},{"job":"Writer"},{"job":"Director"}]}]
      }''';
        serve(
          (request) => (
            status: 200,
            body:
                '{"id":393189,"name":"Series","season_number":1,"created_by":[{"id":4,"name":"Creator"}],"aggregate_credits":$aggregate,"credits":{"cast":[{"id":5,"name":"Latest only"}]}}',
          ),
        );
        final tv = await client().tv(393189);
        expect(
          http.requests.last.uri.queryParameters['append_to_response'],
          'external_ids,aggregate_credits',
        );
        expect(tv.credits.cast.map((p) => p.name), [
          'Earlier season actor',
          'Guest actor',
        ]);
        expect(tv.credits.cast.first.character, 'First role / Second role');
        expect(tv.credits.crewByRole.keys, [
          CrewRole.creator,
          CrewRole.director,
          CrewRole.writer,
        ]);
        final season = await client().season(393189, 1);
        expect(
          http.requests.last.uri.queryParameters['append_to_response'],
          'aggregate_credits',
        );
        expect(season.credits.cast, hasLength(2));
        expect(season.credits.crew, hasLength(2));
      },
    );
    test('a film: cast in billing order, the key crew by role', () async {
      final credits = (await client().movie(603)).credits;
      expect(credits.cast.first.name, 'Киану Ривз');
      expect(credits.cast.first.character, 'Neo');
      expect(credits.cast.first.personId, 6384);
      final crew = credits.crewByRole;
      expect(crew.keys, [
        CrewRole.director,
        CrewRole.writer,
        CrewRole.composer,
        CrewRole.cinematographer,
      ]);
      expect(crew[CrewRole.director]!.map((c) => c.name), [
        'Лана Вачовски',
        'Энди Вачовски',
      ]);
      expect(crew[CrewRole.composer]!.single.name, 'Don Davis');
      // Producers, grips and the rest stay out.
      expect(credits.crew.every((c) => c.name != 'Joel Silver'), isTrue);
    });

    test('a series: its creators, and the cast', () async {
      final credits = (await client().tv(1399)).credits;
      expect(credits.crewByRole[CrewRole.creator]!.map((c) => c.name), [
        'Дэвид Бениофф',
        'Д. Б. Уайс',
      ]);
      expect(credits.cast.first.name, 'Питер Динклэйдж');
    });

    test('a season has its own cast', () async {
      final season = await client().season(1399, 1);
      expect(season.credits.cast.take(3).map((c) => c.name), [
        'Питер Динклэйдж',
        'Кит Харингтон',
        'Шон Бин',
      ]);
    });

    test('an episode: guest stars after the cast, its director', () async {
      final credits = await client().episodeCredits(1399, 1, 3);
      expect(credits.cast, hasLength(19 + 24));
      expect(credits.crewByRole[CrewRole.director]!.single.name, 'Брайан Кирк');
      expect(credits.crewByRole[CrewRole.writer], hasLength(2));
    });
  });

  group('a person', () {
    test('who they are, and what they made', () async {
      final person = await client().person(6384);
      expect(person.name, 'Киану Ривз');
      expect(person.birthday, '1964-09-02');
      final matrix = person.acting.firstWhere(
        (c) => c.title.key == const WorkKey.movie(603),
      );
      expect(matrix.roles, ['Neo']);
      expect(person.crew.any((c) => c.roles.contains('Director')), isTrue);
    });

    test(
      'talk shows and news where they appear as themselves are left out',
      () async {
        final person = await client().person(6384);
        expect(
          person.acting.map((c) => c.title.title),
          isNot(contains(startsWith('Джимми Киммел'))),
        );
      },
    );

    test('newest first, undated titles on top', () async {
      final acting = (await client().person(6384)).acting;
      final dates = [for (final c in acting) c.title.releaseDate];
      final dated = dates.whereType<String>().toList();
      expect(dated, [...dated]..sort((a, b) => b.compareTo(a)));
      final firstDated = dates.indexWhere((d) => d != null);
      expect(dates.skip(firstDated).every((d) => d != null), isTrue);
    });
  });

  group('shelves', () {
    test('trending mixes films and series', () async {
      final titles = await client().trending();
      expect(titles, isNotEmpty);
      expect(titles.map((t) => t.key.kind).toSet(), {
        WorkKind.movie,
        WorkKind.tv,
      });
    });

    test('now playing is films', () async {
      final titles = await client().nowPlaying();
      expect(titles, isNotEmpty);
      expect(titles.every((t) => t.key.kind == WorkKind.movie), isTrue);
    });

    test('the best of all time, by kind', () async {
      final films = await client().best(WorkKind.movie);
      expect(films.first.title, 'Побег из Шоушенка');
      final series = await client().best(WorkKind.tv);
      expect(series.first.title, 'Во все тяжкие');
      expect(series.every((t) => t.key.kind == WorkKind.tv), isTrue);
      final request = http.requests.last.uri.queryParameters;
      expect(request['sort_by'], 'vote_average.desc');
      expect(request['vote_count.gte'], '3000');
    });

    test('recommendations for a film', () async {
      final titles = await client().recommendations(const WorkKey.movie(603));
      expect(titles.first.title, 'Матрица: Революция');
    });
  });
}
