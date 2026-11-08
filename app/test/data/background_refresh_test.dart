import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/background_refresh.dart';
import 'package:framebook/data/budget.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/stats.dart';
import 'package:framebook/data/library/work_snapshot.dart';
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
  late Library library;
  late DateTime now;
  const day = '2026-10-25';

  final matrix = WorkSnapshot.movie(
    MovieDetails.fromJson(Json(_json('tmdb/movie_603_ru.json'))),
  );
  final thrones = WorkSnapshot.tv(
    TvDetails.fromJson(Json(_json('tmdb/tv_1399_ru.json'))),
  );
  final season1 = SeasonDetails.fromJson(
    1399,
    Json(_json('tmdb/tv_1399_season_1_ru.json')),
  );
  final episode3 = [
    thrones,
    WorkSnapshot.season(season1),
    WorkSnapshot.episode(season1.episodes[2], imdbId: 'tt1829962'),
  ];

  /// A film the sources don't know, to fill the queue.
  List<WorkSnapshot> film(int id) => [
    WorkSnapshot(
      key: WorkKey.movie(id),
      tmdbId: id,
      title: 'Film $id',
      imdbId: 'tt${id.toString().padLeft(7, '0')}',
    ),
  ];

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

  /// One pass with no real pauses; returns how many pauses it took.
  Future<int> run(RatingsService service, {bool Function()? cancelled}) async {
    var pauses = 0;
    await BackgroundRefresh(
      db,
      service,
    ).run(cancelled: cancelled ?? () => false, wait: (_) async => pauses++);
    return pauses;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = createDio();
    now = DateTime.utc(2026, 10, 25, 12);
    library = Library(db, deviceId: 'd', clock: () => now);
    serve(apiFixtures);
  });

  tearDown(() => db.close());

  group('queue', () {
    test('only live ratings: not the watchlist, not deleted', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      await library.addToWatchlist([thrones]);
      await library.rate(film(7), scoreHalf: 12, note: null);
      await library.deleteRating(const WorkKey.movie(7));
      final queue = await BackgroundRefresh(db, service()).queue();
      expect([for (final t in queue) t.key], [const WorkKey.movie(603)]);
    });

    test(
      'no rating at all first, then the oldest; fresh ones skipped',
      () async {
        for (final id in [1, 2, 3]) {
          await library.rate(film(id), scoreHalf: 14, note: null);
        }
        final s = service();
        Future<void> fetchedAt(int id, DateTime at) async {
          now = at;
          await s.refresh(
            RatingTarget(key: WorkKey.movie(id), imdbId: 'tt$id'),
          );
        }

        final today = now;
        await fetchedAt(1, today.subtract(const Duration(days: 20)));
        await fetchedAt(2, today.subtract(const Duration(days: 40)));
        await fetchedAt(3, today.subtract(const Duration(days: 1)));
        now = today;
        await library.rate([matrix], scoreHalf: 17, note: null);

        final queue = await BackgroundRefresh(db, s).queue();
        // Matrix has nothing yet; "not found" lives 30 days, so film 2's (40
        // days old) is due, film 1's (20) and film 3's (1) are not.
        expect(
          [for (final t in queue) t.key],
          [const WorkKey.movie(603), const WorkKey.movie(2)],
        );
      },
    );

    test('a value lives 14 days for background refresh', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final s = service();
      await s.refresh(RatingTarget(key: matrix.key, imdbId: matrix.imdbId));
      now = now.add(const Duration(days: 13));
      expect(await BackgroundRefresh(db, s).queue(), isEmpty);
      now = now.add(const Duration(days: 1));
      expect(await BackgroundRefresh(db, s).queue(), hasLength(1));
    });

    test('a season and an episode are looked up by the series', () async {
      await library.rate(episode3, scoreHalf: 18, note: null);
      await library.rate(
        [thrones, WorkSnapshot.season(season1)],
        scoreHalf: 16,
        note: null,
      );
      final queue = await BackgroundRefresh(db, service()).queue();
      final byKey = {for (final t in queue) t.key: t};
      final episode = byKey[WorkKey.parse('tmdb:tv:1399:s1:e3')]!;
      expect(episode.imdbId, 'tt1829962');
      expect(episode.seriesImdbId, 'tt0944947');
      final season = byKey[WorkKey.parse('tmdb:tv:1399:s1')]!;
      expect(season.imdbId, isNull);
      expect(season.seriesImdbId, 'tt0944947');
      // The series itself isn't rated.
      expect(byKey, hasLength(2));
    });

    test('without keys there is nothing to ask', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final s = service(poiskkino: false, omdb: false);
      expect(await BackgroundRefresh(db, s).queue(), isEmpty);
    });
  });

  group('a pass', () {
    test(
      'a large backlog resumes on later days and enters statistics',
      () async {
        for (var id = 1; id <= 155; id++) {
          await library.rate(film(id), scoreHalf: 16, note: 'Saved note $id');
        }
        final before = await db.select(db.ratings).get();
        serve((r) {
          final id = int.parse(
            r.uri.queryParameters['externalId.imdb']!.substring(2),
          );
          return (
            status: 200,
            body: jsonEncode({
              'docs': [
                {
                  'id': id,
                  'rating': {'kp': 7.0, 'imdb': 7.5},
                  'votes': {'kp': 100, 'imdb': 100},
                },
              ],
            }),
          );
        });
        final s = service(omdb: false);
        await db.exhaustBudget(ApiSource.poiskkino, day, 180);
        await run(s);
        expect(http.requests, isEmpty);
        expect(
          computeStats(await library.watchRatings().first).deviation,
          isEmpty,
        );

        now = now.add(const Duration(days: 1));
        final tomorrow = AppDatabase.budgetDay(now);
        await run(s);
        expect(http.requests, hasLength(150));
        expect(await db.budgetUsed(ApiSource.poiskkino, tomorrow), 150);
        final stats = computeStats(await library.watchRatings().first);
        expect(stats.count, 155);
        expect(stats.deviation[RatingSource.kp]!.count, 150);
        expect(stats.deviation[RatingSource.kp]!.signed, 1.0);
        expect(
          coverage(
            await library.watchRatings().first,
            RatingSource.kp,
            (_) => true,
          ),
          (loaded: 150, total: 155),
        );

        // Reopening does not reset the counter. A card can still use its share.
        final reopened = service(omdb: false);
        await run(reopened);
        expect(http.requests, hasLength(150));
        final pending = await BackgroundRefresh(
          db,
          reopened,
        ).queue(missingOnly: true);
        expect(pending, hasLength(5));
        await reopened.refresh(pending.first);
        expect(http.requests, hasLength(151));
        await run(reopened);
        expect(http.requests, hasLength(151));

        now = now.add(const Duration(days: 1));
        await run(reopened);
        expect(http.requests, hasLength(155));
        expect(
          computeStats(
            await library.watchRatings().first,
          ).deviation[RatingSource.kp]!.count,
          155,
        );
        expect(await BackgroundRefresh(db, reopened).queue(), isEmpty);
        expect(await db.select(db.ratings).get(), before);
      },
    );

    test(
      'KP gaps precede refreshing known KP values even when IMDb is missing',
      () async {
        for (final id in [1, 2]) {
          await library.rate(film(id), scoreHalf: 16, note: null);
        }
        await db.putExternalRatings([
          ExternalRating(
            workKey: 'tmdb:movie:1',
            source: RatingSource.kp,
            status: RatingStatus.ok,
            value: 7,
            scale: 10,
            via: ApiSource.poiskkino,
            fetchedAt: now
                .subtract(const Duration(days: 20))
                .millisecondsSinceEpoch,
          ),
          ExternalRating(
            workKey: 'tmdb:movie:2',
            source: RatingSource.kp,
            status: RatingStatus.error,
            scale: 10,
            via: ApiSource.poiskkino,
            fetchedAt: now.millisecondsSinceEpoch,
          ),
        ]);
        await db.exhaustBudget(ApiSource.poiskkino, day, 149);
        await run(service());
        final kp = http.requests
            .where((r) => r.uri.host == 'api.poiskkino.dev')
            .toList();
        expect(kp, hasLength(1));
        expect(kp.single.uri.queryParameters['externalId.imdb'], 'tt0000002');
        expect(
          (await db.externalRatingsFor(
            'tmdb:movie:1',
          )).singleWhere((r) => r.source == RatingSource.kp).value,
          7,
        );
        expect(
          (await db.externalRatingsFor(
            'tmdb:movie:2',
          )).singleWhere((r) => r.source == RatingSource.kp).status,
          RatingStatus.notFound,
        );
      },
    );

    test(
      'a provider quota error just before midnight retries on the next day',
      () async {
        await library.rate([matrix], scoreHalf: 17, note: null);
        now = DateTime.utc(2026, 10, 25, 23, 59);
        serve((_) => (status: 403, body: '{}'));
        final s = service(omdb: false);
        await run(s);
        expect(http.requests, hasLength(1));
        expect(await db.budgetUsed(ApiSource.poiskkino, day), 200);
        now = now.add(const Duration(minutes: 2));
        serve(apiFixtures);
        await run(s);
        expect(http.requests, hasLength(1));
        expect(
          (await db.externalRatingsFor(
            matrix.key.toString(),
          )).singleWhere((r) => r.source == RatingSource.kp).value,
          8.501,
        );
        expect(
          computeStats(
            await library.watchRatings().first,
          ).deviation[RatingSource.kp]!.count,
          1,
        );
      },
    );

    test(
      'missing lookup IDs neither consume budget nor add pacing waits',
      () async {
        await library.rate(
          [
            const WorkSnapshot(
              key: WorkKey.movie(7),
              tmdbId: 7,
              title: 'No ID',
            ),
          ],
          scoreHalf: 14,
          note: null,
        );
        expect(await run(service(poiskkino: false)), 0);
        expect(http.requests, isEmpty);
        expect(await db.budgetUsed(ApiSource.omdb, day), 0);
        expect(
          (await db.externalRatingsFor('tmdb:movie:7')).map((r) => r.status),
          everyElement(RatingStatus.notFound),
        );
      },
    );

    test(
      'cancellation during a source prevents the next source request',
      () async {
        await library.rate([matrix], scoreHalf: 16, note: null);
        var cancelled = false;
        serve((request) {
          cancelled = true;
          return apiFixtures(request);
        });
        expect(await run(service(), cancelled: () => cancelled), 0);
        expect(http.requests, hasLength(1));
        expect(http.requests.single.uri.host, 'api.poiskkino.dev');
        expect(await db.budgetUsed(ApiSource.omdb, day), 0);
      },
    );

    test(
      'fills the ratings, leaves TMDB alone, pauses after requests',
      () async {
        await library.rate([matrix], scoreHalf: 17, note: null);
        await library.rate(episode3, scoreHalf: 18, note: null);
        expect(await run(service()), 2);

        final film = {
          for (final row in await db.externalRatingsFor('tmdb:movie:603'))
            row.source: row,
        };
        expect(film[RatingSource.kp]!.value, 8.501);
        expect(film[RatingSource.imdb]!.value, 8.7);
        // No card, no TMDB vote: the row is not written.
        expect(film[RatingSource.tmdb], isNull);
        final episode = await db.externalRatingsFor('tmdb:tv:1399:s1:e3');
        expect(episode.single.source, RatingSource.imdb);
        expect(episode.single.status, RatingStatus.ok);

        // Everything is fresh now: the next pass asks nothing.
        http.requests.clear();
        expect(await run(service()), 0);
        expect(http.requests, isEmpty);
      },
    );

    test('keeps to the background ceiling of the budget', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final quota = ApiQuota.of(ApiSource.poiskkino)!;
      for (var i = 0; i < quota.background; i++) {
        await db.consumeBudget(ApiSource.poiskkino, day);
      }
      await run(service());
      // OMDb still had budget; PoiskKino got no request.
      expect([for (final r in http.requests) r.uri.host], ['www.omdbapi.com']);
      expect(await db.budgetUsed(ApiSource.poiskkino, day), quota.background);
      final rows = {
        for (final row in await db.externalRatingsFor('tmdb:movie:603'))
          row.source: row,
      };
      expect(rows[RatingSource.kp], isNull);
    });

    test('stops once every source is out of its background budget', () async {
      for (final id in [1, 2, 3, 4]) {
        await library.rate(film(id), scoreHalf: 14, note: null);
      }
      for (final api in [ApiSource.poiskkino, ApiSource.omdb]) {
        final ceiling = ApiQuota.of(api)!.background;
        for (var i = 0; i < ceiling - 1; i++) {
          await db.consumeBudget(api, day);
        }
      }
      // One request per source is left: the first title spends both, and
      // nobody else gets a request or a row.
      await run(service());
      expect(http.requests, hasLength(2));
      for (final id in [2, 3, 4]) {
        expect(await db.externalRatingsFor('tmdb:movie:$id'), isEmpty);
      }
      for (final api in [ApiSource.poiskkino, ApiSource.omdb]) {
        expect(await db.budgetUsed(api, day), ApiQuota.of(api)!.background);
      }
    });

    test('ends at once without a network', () async {
      for (final id in [1, 2, 3]) {
        await library.rate(film(id), scoreHalf: 14, note: null);
      }
      serve((_) => null);
      expect(await run(service()), 0);
      // The first title tried both sources; nobody else was asked.
      expect(http.requests, hasLength(2));
      // Offline is not an answer: nothing is written.
      for (final id in [1, 2, 3]) {
        expect(await db.externalRatingsFor('tmdb:movie:$id'), isEmpty);
      }
    });

    test('a failure moves on to the next title', () async {
      await library.rate(film(1), scoreHalf: 14, note: null);
      await library.rate(film(2), scoreHalf: 14, note: null);
      serve(
        (r) =>
            r.uri.queryParameters['i'] == 'tt0000001' ||
                r.uri.queryParameters['externalId.imdb'] == 'tt0000001'
            ? (status: 500, body: '')
            : apiFixtures(r),
      );
      await run(service());
      final failed = await db.externalRatingsFor('tmdb:movie:1');
      final missing = await db.externalRatingsFor('tmdb:movie:2');
      expect(
        failed.map((r) => r.source),
        unorderedEquals([
          RatingSource.kp,
          RatingSource.imdb,
          RatingSource.rt,
          RatingSource.metacritic,
        ]),
      );
      expect(
        missing.map((r) => r.source),
        unorderedEquals([
          RatingSource.kp,
          RatingSource.imdb,
          RatingSource.rt,
          RatingSource.metacritic,
        ]),
      );
      expect(failed.map((r) => r.status), everyElement(RatingStatus.error));
      expect(missing.map((r) => r.status), everyElement(RatingStatus.notFound));
    });

    test('stops when cancelled', () async {
      for (final id in [1, 2, 3]) {
        await library.rate(film(id), scoreHalf: 14, note: null);
      }
      var pauses = 0;
      await BackgroundRefresh(
        db,
        service(),
      ).run(cancelled: () => pauses > 0, wait: (_) async => pauses++);
      expect(pauses, 1);
      expect(http.requests, hasLength(2));
    });
  });
}

Map<String, Object?> _json(String path) =>
    jsonDecode(fixture(path)) as Map<String, Object?>;
