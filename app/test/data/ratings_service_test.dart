import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/omdb/omdb_client.dart';
import 'package:framebook/data/sources/poiskkino/poiskkino_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

void main() {
  late AppDatabase db;
  late Dio dio;
  late FakeHttpAdapter http;
  late DateTime now;
  const day = '2026-10-24';

  const matrix = RatingTarget(
    key: WorkKey.movie(603),
    tmdbVote: TmdbVote(8.261, 29028),
    imdbId: 'tt0133093',
  );
  const thrones = RatingTarget(
    key: WorkKey.tv(1399),
    tmdbVote: TmdbVote(8.475, 28001),
    imdbId: 'tt0944947',
  );

  RatingsService service({bool poiskkino = true, bool omdb = true}) =>
      RatingsService(
        db,
        poiskkino: poiskkino ? PoiskKinoClient(dio, 'PK') : null,
        omdb: omdb ? OmdbClient(dio, 'OM') : null,
        clock: () => now,
      );

  void serve(Reply? Function(RequestOptions) respond) {
    http = FakeHttpAdapter(respond);
    dio.httpClientAdapter = http;
  }

  Future<Map<RatingSource, ExternalRating>> rows(RatingTarget target) async => {
    for (final row in await db.externalRatingsFor(target.key.toString()))
      row.source: row,
  };

  List<String> hosts() => [for (final r in http.requests) r.uri.host];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = createDio();
    now = DateTime.utc(2026, 10, 24, 12);
    serve(apiFixtures);
  });

  tearDown(() => db.close());

  group('a film with every key', () {
    test('one request per source fills every rating', () async {
      final outcomes = await service().refresh(matrix);
      expect(outcomes, {ApiSource.poiskkino: null, ApiSource.omdb: null});
      final r = await rows(matrix);
      expect(r[RatingSource.kp]!.value, 8.501);
      expect(r[RatingSource.kp]!.votes, 816869);
      expect(r[RatingSource.kp]!.via, ApiSource.poiskkino);
      // IMDb comes from OMDb, since its key is set, not from PoiskKino.
      expect(r[RatingSource.imdb]!.value, 8.7);
      expect(r[RatingSource.imdb]!.votes, 2284373);
      expect(r[RatingSource.imdb]!.via, ApiSource.omdb);
      expect(r[RatingSource.rt]!.value, 83);
      expect(r[RatingSource.rt]!.scale, 100);
      expect(r[RatingSource.metacritic]!.value, 73);
      expect(r[RatingSource.tmdb]!.value, 8.261);
      expect(r[RatingSource.tmdb]!.via, ApiSource.tmdb);
      expect(hosts(), ['api.poiskkino.dev', 'www.omdbapi.com']);
      expect(await db.budgetUsed(ApiSource.poiskkino, day), 1);
      expect(await db.budgetUsed(ApiSource.omdb, day), 1);
    });

    test('within a week the cache answers: no requests, no budget', () async {
      await service().refresh(matrix);
      now = now.add(const Duration(days: 6));
      serve((_) => fail('should not hit the network'));
      expect(await service().refresh(matrix), isEmpty);
      expect(await db.budgetUsed(ApiSource.poiskkino, day), 1);
    });

    test('after a week the open card asks again', () async {
      await service().refresh(matrix);
      now = now.add(RatingTtl.interactive);
      await service().refresh(matrix);
      expect(http.requests, hasLength(4));
    });

    test('the same film opened twice at once is asked once', () async {
      final s = service();
      await Future.wait([s.refresh(matrix), s.refresh(matrix)]);
      expect(http.requests, hasLength(2));
    });
  });

  group('which source answers', () {
    test(
      'without OMDb, IMDb comes from PoiskKino; no RT or Metacritic',
      () async {
        final s = service(omdb: false);
        await s.refresh(matrix);
        final r = await rows(matrix);
        expect(r[RatingSource.imdb]!.value, 8.7);
        expect(r[RatingSource.imdb]!.votes, 2200000);
        expect(r[RatingSource.imdb]!.via, ApiSource.poiskkino);
        expect(r.containsKey(RatingSource.rt), isFalse);
        expect(hosts(), ['api.poiskkino.dev']);
        expect(s.providerOf(RatingSource.rt, WorkKind.movie), isNull);
      },
    );

    test('adding an OMDb key later replaces IMDb from PoiskKino', () async {
      await service(omdb: false).refresh(matrix);
      await service().refresh(matrix);
      final r = await rows(matrix);
      expect(r[RatingSource.imdb]!.via, ApiSource.omdb);
      expect(r[RatingSource.imdb]!.votes, 2284373);
      // Kinopoisk is fresh, so PoiskKino isn't asked a second time.
      expect(hosts(), ['api.poiskkino.dev', 'www.omdbapi.com']);
    });

    test('without keys only TMDB is there, and nothing is requested', () async {
      final s = service(poiskkino: false, omdb: false);
      expect(await s.refresh(matrix), isEmpty);
      expect((await rows(matrix)).keys, [RatingSource.tmdb]);
      expect(http.requests, isEmpty);
      expect(s.providerOf(RatingSource.kp, WorkKind.movie), isNull);
    });

    test('TMDB with no votes is "no data", not zero', () async {
      await service().refresh(
        const RatingTarget(
          key: WorkKey.movie(603),
          tmdbVote: TmdbVote(null, 0),
        ),
      );
      expect(
        (await rows(matrix))[RatingSource.tmdb]!.status,
        RatingStatus.notFound,
      );
    });
  });

  group('matching ids', () {
    test(
      'no imdb id: PoiskKino by tmdb id and type; OMDb is not asked',
      () async {
        const noImdb = RatingTarget(
          key: WorkKey.movie(603),
          tmdbVote: TmdbVote(8.261, 29028),
        );
        await service().refresh(noImdb);
        final r = await rows(noImdb);
        // tmdb 603 returns a 1997 series first; the film is the one taken.
        expect(r[RatingSource.kp]!.value, 8.501);
        expect(r[RatingSource.imdb]!.status, RatingStatus.notFound);
        expect(r[RatingSource.rt]!.status, RatingStatus.notFound);
        expect(hosts(), ['api.poiskkino.dev']);
        expect(
          http.requests.single.uri.queryParameters['externalId.tmdb'],
          '603',
        );
        expect(await db.budgetUsed(ApiSource.omdb, day), 0);
      },
    );

    test('a series by tmdb id', () async {
      const noImdb = RatingTarget(
        key: WorkKey.tv(1399),
        tmdbVote: TmdbVote(8.475, 28001),
      );
      await service(omdb: false).refresh(noImdb);
      expect((await rows(noImdb))[RatingSource.kp]!.value, 9.009);
    });

    test('a series with every key', () async {
      await service().refresh(thrones);
      final r = await rows(thrones);
      expect(r[RatingSource.imdb]!.value, 9.2);
      expect(r.keys, containsAll([RatingSource.kp, RatingSource.tmdb]));
      // RT and Metacritic are not shown for series.
      expect(r.containsKey(RatingSource.rt), isFalse);
    });

    test('a known kp id is used instead of searching, '
        'and a found one is remembered', () async {
      await db
          .into(db.works)
          .insert(
            WorksCompanion.insert(
              workKey: 'tmdb:movie:603',
              kind: WorkKind.movie,
              tmdbId: 603,
              title: 'Матрица',
              snapshotUpdatedAt: 0,
            ),
          );
      await service(omdb: false).refresh(matrix);
      expect(await db.kpIdFor('tmdb:movie:603'), 301);
      now = now.add(RatingTtl.interactive);
      await service(omdb: false).refresh(matrix);
      expect(http.requests.last.uri.path, '/v1.5/movie/301');
    });

    test('a season: IMDb average over episodes, no Kinopoisk', () async {
      const season = RatingTarget(
        key: WorkKey.season(1399, 1),
        tmdbVote: TmdbVote(8.4, null),
        seriesImdbId: 'tt0944947',
      );
      await service().refresh(season);
      final r = await rows(season);
      expect(r[RatingSource.imdb]!.value, closeTo(8.97, 1e-9));
      expect(r.containsKey(RatingSource.kp), isFalse);
      expect(hosts(), ['www.omdbapi.com']);
    });

    test('an episode by its own imdb id, or by series and numbers', () async {
      const byId = RatingTarget(
        key: WorkKey.episode(1399, 1, 3),
        tmdbVote: TmdbVote(8.061, 279),
        imdbId: 'tt1829962',
        seriesImdbId: 'tt0944947',
      );
      await service().refresh(byId);
      expect((await rows(byId))[RatingSource.imdb]!.value, 8.5);
      expect(http.requests.single.uri.queryParameters['i'], 'tt1829962');

      const byNumbers = RatingTarget(
        key: WorkKey.episode(1399, 1, 4),
        tmdbVote: TmdbVote(8.179, 257),
        seriesImdbId: 'tt0944947',
      );
      await service().refresh(byNumbers);
      expect(http.requests.last.uri.queryParameters, {
        'i': 'tt0944947',
        'Season': '1',
        'Episode': '4',
        'apikey': 'OM',
      });
    });
  });

  group('budget and failures', () {
    test(
      'the interactive ceiling stops requests, cached values stay',
      () async {
        await service().refresh(matrix);
        now = now.add(RatingTtl.interactive);
        // The counter is per UTC day: spend today's.
        final today = AppDatabase.budgetDay(now);
        for (var i = 0; i < 180; i++) {
          await db.consumeBudget(ApiSource.poiskkino, today);
        }
        final outcomes = await service().refresh(matrix);
        expect(outcomes[ApiSource.poiskkino], SourceFailure.limitReached);
        expect(outcomes[ApiSource.omdb], isNull);
        expect(hosts().where((h) => h == 'api.poiskkino.dev'), hasLength(1));
        expect((await rows(matrix))[RatingSource.kp]!.value, 8.501);
      },
    );

    test('"limit reached" from the service closes the day at once', () async {
      serve(
        (r) => r.uri.host == 'api.poiskkino.dev'
            ? (status: 403, body: '{}')
            : apiFixtures(r),
      );
      final outcomes = await service().refresh(matrix);
      expect(outcomes[ApiSource.poiskkino], SourceFailure.limitReached);
      expect(await db.budgetUsed(ApiSource.poiskkino, day), 200);
      // There was no value: an error takes its place, not an endless spinner.
      expect((await rows(matrix))[RatingSource.kp]!.status, RatingStatus.error);
    });

    test('a failure never overwrites an older value', () async {
      await service().refresh(matrix);
      now = now.add(RatingTtl.interactive);
      serve(
        (r) => r.uri.host == 'www.omdbapi.com'
            ? (status: 500, body: 'oops')
            : apiFixtures(r),
      );
      final outcomes = await service().refresh(matrix);
      expect(outcomes[ApiSource.omdb], SourceFailure.failed);
      final imdb = (await rows(matrix))[RatingSource.imdb]!;
      expect(imdb.status, RatingStatus.ok);
      expect(imdb.value, 8.7);
    });

    test('after a failure the same title waits an hour; '
        'a new key retries at once', () async {
      serve(
        (r) => r.uri.host == 'www.omdbapi.com'
            ? (status: 401, body: fixture('omdb/invalid_key.json'))
            : apiFixtures(r),
      );
      final s = service();
      expect(
        (await s.refresh(matrix))[ApiSource.omdb],
        SourceFailure.unauthorized,
      );
      final asked = http.requests.length;
      expect(
        (await s.refresh(matrix))[ApiSource.omdb],
        SourceFailure.unauthorized,
      );
      expect(http.requests, hasLength(asked));

      // A new key recreates the service, which tries right away.
      serve(apiFixtures);
      await service().refresh(matrix);
      expect((await rows(matrix))[RatingSource.imdb]!.value, 8.7);
    });

    test('offline is not remembered and writes nothing', () async {
      serve((_) => null);
      final s = service();
      final outcomes = await s.refresh(matrix);
      expect(outcomes[ApiSource.poiskkino], SourceFailure.offline);
      expect((await rows(matrix)).keys, [RatingSource.tmdb]);
      serve(apiFixtures);
      await s.refresh(matrix);
      expect((await rows(matrix))[RatingSource.kp]!.value, 8.501);
    });
  });
}
