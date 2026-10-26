import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import '../support/fake_http.dart';

void main() {
  late AppDatabase db;
  late Library library;
  late DateTime now;

  final matrix = WorkSnapshot.movie(
    MovieDetails.fromJson(Json(_json('tmdb/movie_603_ru.json'))),
  );
  final thrones = TvDetails.fromJson(Json(_json('tmdb/tv_1399_ru.json')));
  final season1 = SeasonDetails.fromJson(
    1399,
    Json(_json('tmdb/tv_1399_season_1_ru.json')),
  );
  List<WorkSnapshot> episode(int n) => [
    WorkSnapshot.tv(thrones),
    WorkSnapshot.season(season1),
    WorkSnapshot.episode(season1.episodes[n - 1]),
  ];
  List<WorkSnapshot> season() => [
    WorkSnapshot.tv(thrones),
    WorkSnapshot.season(season1),
  ];

  /// Another film, for calibration tests.
  List<WorkSnapshot> film(int id, {String? title}) => [
    WorkSnapshot(
      key: WorkKey.movie(id),
      tmdbId: id,
      title: title ?? 'Film $id',
      releaseDate: '20${(id % 90).toString().padLeft(2, '0')}-01-01',
    ),
  ];

  int ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;

  Future<Rating?> ratingRow(WorkKey key) => (db.select(
    db.ratings,
  )..where((r) => r.workKey.equals(key.toString()))).getSingleOrNull();

  Future<WatchlistEntry?> watchRow(WorkKey key) => (db.select(
    db.watchlist,
  )..where((w) => w.workKey.equals(key.toString()))).getSingleOrNull();

  Future<Work?> workRow(String key) => (db.select(
    db.works,
  )..where((w) => w.workKey.equals(key))).getSingleOrNull();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 10, 25, 12);
    library = Library(db, deviceId: 'device-a', clock: () => now);
  });

  tearDown(() => db.close());

  group('snapshots', () {
    test('a film keeps what the offline list needs, and no more', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final work = (await workRow('tmdb:movie:603'))!;
      expect(work.kind, WorkKind.movie);
      expect(work.parentKey, isNull);
      expect(work.title, 'Матрица');
      expect(work.originalTitle, 'The Matrix');
      expect(work.year, 1999);
      expect(work.releaseDate, '1999-03-31');
      expect(work.imdbId, 'tt0133093');
      expect(jsonDecode(work.genreIds), [28, 878]);
      expect(work.snapshotUpdatedAt, ms(now));
    });

    test('rating an episode stores the series and the season too', () async {
      await library.rate(episode(3), scoreHalf: 17, note: null);
      final series = (await workRow('tmdb:tv:1399'))!;
      final season = (await workRow('tmdb:tv:1399:s1'))!;
      final ep = (await workRow('tmdb:tv:1399:s1:e3'))!;
      expect(series.kind, WorkKind.tv);
      expect(season.parentKey, 'tmdb:tv:1399');
      expect(season.seasonNumber, 1);
      expect(season.tmdbId, 3624);
      expect(ep.parentKey, 'tmdb:tv:1399:s1');
      expect(ep.episodeNumber, 3);
      expect(ep.tmdbId, 63058);
      expect(ep.title, 'Лорд Сноу');
    });

    test(
      'an upsert keeps a Kinopoisk id and an imdb id found earlier',
      () async {
        await library.rate(
          [
            ...season(),
            WorkSnapshot.episode(season1.episodes[2], imdbId: 'tt1829962'),
          ],
          scoreHalf: 17,
          note: null,
        );
        await db.rememberKpId('tmdb:tv:1399', 464963);
        // The card reopened before the episode's imdb id loaded.
        await library.refreshSnapshots(episode(3));
        expect((await workRow('tmdb:tv:1399'))!.kpId, 464963);
        expect((await workRow('tmdb:tv:1399:s1:e3'))!.imdbId, 'tt1829962');
      },
    );

    test(
      'refreshing only touches snapshots that exist, never ratings',
      () async {
        await library.rate([matrix], scoreHalf: 17, note: null);
        final before = (await ratingRow(matrix.key))!;
        now = now.add(const Duration(days: 40));
        await library.refreshSnapshots([matrix, ...film(5)]);
        expect((await workRow('tmdb:movie:603'))!.snapshotUpdatedAt, ms(now));
        expect(await workRow('tmdb:movie:5'), isNull);
        expect((await ratingRow(matrix.key))!.updatedAt, before.updatedAt);
      },
    );

    test('a snapshot survives a round trip through its row', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final back = WorkSnapshot.fromWork((await workRow('tmdb:movie:603'))!);
      expect(back.key, matrix.key);
      expect(back.genreIds, [28, 878]);
      expect(back.imdbId, 'tt0133093');
    });
  });

  group('rating', () {
    test('a new rating', () async {
      await library.rate([matrix], scoreHalf: 17, note: '  Классика  ');
      final row = (await ratingRow(matrix.key))!;
      expect(row.scoreHalf, 17);
      expect(row.note, 'Классика');
      expect(row.createdAt, ms(now));
      expect(row.scoredAt, ms(now));
      expect(row.updatedAt, ms(now));
      expect(row.updatedBy, 'device-a');
      expect(row.deletedAt, isNull);
    });

    test('a blank note is no note', () async {
      await library.rate([matrix], scoreHalf: 17, note: '   ');
      expect((await ratingRow(matrix.key))!.note, isNull);
    });

    test('changing only the note keeps scored_at, moves updated_at', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final first = now;
      now = now.add(const Duration(hours: 1));
      await library.rate([matrix], scoreHalf: 17, note: 'Пересмотрел');
      final row = (await ratingRow(matrix.key))!;
      expect(row.scoredAt, ms(first));
      expect(row.updatedAt, ms(now));
      expect(row.note, 'Пересмотрел');
    });

    test('changing the score moves scored_at', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      now = now.add(const Duration(hours: 1));
      await library.rate([matrix], scoreHalf: 18, note: null);
      final row = (await ratingRow(matrix.key))!;
      expect(row.scoreHalf, 18);
      expect(row.scoredAt, ms(now));
    });

    test('saving the same thing again writes no new version', () async {
      await library.rate([matrix], scoreHalf: 17, note: 'x');
      final first = (await ratingRow(matrix.key))!.updatedAt;
      now = now.add(const Duration(hours: 1));
      await library.rate([matrix], scoreHalf: 17, note: 'x');
      expect((await ratingRow(matrix.key))!.updatedAt, first);
    });

    test('updated_at never goes back, even with a lagging clock', () async {
      await library.rate([matrix], scoreHalf: 17, note: null);
      final first = (await ratingRow(matrix.key))!.updatedAt;
      now = now.subtract(const Duration(hours: 1));
      await library.rate([matrix], scoreHalf: 16, note: null);
      expect((await ratingRow(matrix.key))!.updatedAt, first + 1);
    });

    test('scores outside 1…10 are refused', () {
      expect(
        () => library.rate([matrix], scoreHalf: 1, note: null),
        throwsRangeError,
      );
      expect(
        () => library.rate([matrix], scoreHalf: 21, note: null),
        throwsRangeError,
      );
    });

    test('deleting is a tombstone; rating again revives the row', () async {
      await library.rate([matrix], scoreHalf: 17, note: 'x');
      final created = now;
      now = now.add(const Duration(days: 1));
      await library.deleteRating(matrix.key);
      final deleted = (await ratingRow(matrix.key))!;
      expect(deleted.deletedAt, ms(now));
      expect(deleted.updatedAt, ms(now));
      expect(await library.watchRating(matrix.key).first, isNull);

      now = now.add(const Duration(days: 1));
      await library.rate([matrix], scoreHalf: 15, note: null);
      final revived = (await ratingRow(matrix.key))!;
      expect(revived.deletedAt, isNull);
      expect(revived.scoreHalf, 15);
      expect(revived.createdAt, ms(created));
      expect(revived.scoredAt, ms(now));
    });

    test('rescore changes the score and keeps the note', () async {
      await library.rate([matrix], scoreHalf: 17, note: 'x');
      now = now.add(const Duration(minutes: 1));
      await library.rescore(matrix.key, 18);
      final row = (await ratingRow(matrix.key))!;
      expect(row.scoreHalf, 18);
      expect(row.note, 'x');
      expect(row.scoredAt, ms(now));
    });
  });

  group('watchlist', () {
    test('add, remove, add again — one row throughout', () async {
      await library.addToWatchlist([matrix]);
      expect(await library.watchInWatchlist(matrix.key).first, isTrue);
      now = now.add(const Duration(minutes: 1));
      await library.removeFromWatchlist(matrix.key);
      expect(await library.watchInWatchlist(matrix.key).first, isFalse);
      expect((await watchRow(matrix.key))!.deletedAt, ms(now));
      now = now.add(const Duration(minutes: 1));
      await library.addToWatchlist([matrix]);
      final row = (await watchRow(matrix.key))!;
      expect(row.deletedAt, isNull);
      expect(row.addedAt, ms(now));
    });

    test('rating a title takes it off the watchlist', () async {
      await library.addToWatchlist([matrix]);
      now = now.add(const Duration(minutes: 1));
      await library.rate([matrix], scoreHalf: 17, note: null);
      expect((await watchRow(matrix.key))!.deletedAt, ms(now));
    });

    test('deleting a rating does not put it back', () async {
      await library.addToWatchlist([matrix]);
      await library.rate([matrix], scoreHalf: 17, note: null);
      await library.deleteRating(matrix.key);
      expect(await library.watchInWatchlist(matrix.key).first, isFalse);
    });

    test('only films and series go on the watchlist', () {
      expect(() => library.addToWatchlist(season()), throwsArgumentError);
    });
  });

  group('calibration', () {
    Future<void> rate(List<WorkSnapshot> lineage, int half) async {
      now = now.add(const Duration(minutes: 1));
      await library.rate(lineage, scoreHalf: half, note: null);
    }

    test('the same score, recent first, without the title itself', () async {
      await rate(film(1), 16);
      await rate(film(2), 16);
      await rate([matrix], 16);
      final c = await library.calibration(matrix.key, 16);
      expect(c.same.map((t) => t.work.workKey), [
        'tmdb:movie:2',
        'tmdb:movie:1',
      ]);
    });

    test('neighbours are the nearest existing scores, not ±0.5', () async {
      await rate(film(1), 20);
      await rate(film(2), 18);
      await rate(film(3), 18);
      await rate(film(4), 10);
      await rate([matrix], 15);
      final c = await library.calibration(matrix.key, 15);
      expect(c.same, isEmpty);
      expect(c.above.map((t) => t.rating.scoreHalf), [18, 18]);
      expect(c.below.map((t) => t.rating.scoreHalf), [10]);
    });

    test(
      'only the same kind: films with films, episodes with episodes',
      () async {
        await rate(episode(1), 16);
        await rate(season(), 16);
        await rate([matrix], 16);
        final forFilm = await library.calibration(matrix.key, 16);
        expect(forFilm.isEmpty, isTrue);
        await rate(episode(3), 16);
        final forEpisode = await library.calibration(episode(3).last.key, 16);
        expect(forEpisode.same.single.work.workKey, 'tmdb:tv:1399:s1:e1');
        // An episode row knows its series and season for the subtitle.
        expect(forEpisode.same.single.series!.title, 'Игра Престолов');
        expect(forEpisode.same.single.season!.workKey, 'tmdb:tv:1399:s1');
      },
    );

    test('deleted ratings are not neighbours', () async {
      await rate(film(1), 16);
      await library.deleteRating(const WorkKey.movie(1));
      await rate([matrix], 16);
      expect((await library.calibration(matrix.key, 16)).isEmpty, isTrue);
    });

    test('limits: four of the same, two per neighbour', () async {
      for (var id = 1; id <= 8; id++) {
        await rate(film(id), 16);
      }
      for (var id = 11; id <= 15; id++) {
        await rate(film(id), 18);
      }
      await rate([matrix], 16);
      final c = await library.calibration(matrix.key, 16);
      // What fits under the score reel.
      expect(c.same, hasLength(4));
      expect(c.above, hasLength(2));
    });
  });

  group('parts average', () {
    test('a season averages its rated episodes', () async {
      await library.rate(episode(1), scoreHalf: 16, note: null);
      await library.rate(episode(2), scoreHalf: 17, note: null);
      final avg = (await library
          .watchPartsAverage(const WorkKey.season(1399, 1))
          .first)!;
      expect(avg.parts, WorkKind.episode);
      expect(avg.count, 2);
      expect(avg.average, 8.25);
    });

    test('a series averages its seasons, or else all its episodes', () async {
      const series = WorkKey.tv(1399);
      expect(await library.watchPartsAverage(series).first, isNull);
      await library.rate(episode(1), scoreHalf: 14, note: null);
      await library.rate(episode(2), scoreHalf: 18, note: null);
      var avg = (await library.watchPartsAverage(series).first)!;
      expect((avg.parts, avg.count, avg.average), (WorkKind.episode, 2, 8.0));
      await library.rate(season(), scoreHalf: 19, note: null);
      avg = (await library.watchPartsAverage(series).first)!;
      expect((avg.parts, avg.count, avg.average), (WorkKind.season, 1, 9.5));
    });

    test('another series with a similar id is not mixed in', () async {
      await library.rate(
        [
          WorkSnapshot(
            key: const WorkKey.tv(13990),
            tmdbId: 13990,
            title: 'Other',
          ),
          WorkSnapshot(
            key: const WorkKey.season(13990, 1),
            tmdbId: 13990,
            title: '',
          ),
        ],
        scoreHalf: 2,
        note: null,
      );
      expect(
        await library.watchPartsAverage(const WorkKey.tv(1399)).first,
        isNull,
      );
    });
  });

  group('my ratings list', () {
    RatedTitle rated(
      String key,
      int half, {
      int scoredAt = 0,
      int? year,
      String title = 't',
      String? seriesTitle,
    }) {
      final k = WorkKey.parse(key);
      Work work(String key, String title, int? year) => Work(
        workKey: key,
        kind: WorkKey.parse(key).kind,
        tmdbId: 1,
        title: title,
        year: year,
        genreIds: '[]',
        snapshotUpdatedAt: 0,
      );
      return RatedTitle(
        rating: Rating(
          workKey: key,
          scoreHalf: half,
          createdAt: 0,
          scoredAt: scoredAt,
          updatedAt: 0,
          updatedBy: 'd',
        ),
        work: work(key, title, year),
        series: seriesTitle == null
            ? null
            : work(WorkKey.tv(k.tmdbId).toString(), seriesTitle, null),
      );
    }

    final list = [
      rated('tmdb:movie:1', 16, scoredAt: 3, year: 1999, title: 'Matrix'),
      rated('tmdb:movie:2', 18, scoredAt: 1, year: 2010, title: 'Inception'),
      rated('tmdb:movie:3', 18, scoredAt: 2, title: 'Alien'),
      rated('tmdb:tv:7:s1:e10', 14, scoredAt: 4, seriesTitle: 'Breaking Bad'),
      rated('tmdb:tv:7:s1:e2', 15, scoredAt: 5, seriesTitle: 'Breaking Bad'),
    ];
    List<String> keys(List<RatedTitle> l) => [
      for (final t in l) t.work.workKey,
    ];

    test('by date rated, newest first', () {
      expect(keys(arrangeRatings(list)), [
        'tmdb:tv:7:s1:e2',
        'tmdb:tv:7:s1:e10',
        'tmdb:movie:1',
        'tmdb:movie:3',
        'tmdb:movie:2',
      ]);
    });

    test('by score, ties by the more recent', () {
      expect(keys(arrangeRatings(list, sort: RatingsSort.score)).take(3), [
        'tmdb:movie:3',
        'tmdb:movie:2',
        'tmdb:movie:1',
      ]);
    });

    test('by year, newest first, undated last', () {
      expect(
        keys(
          arrangeRatings(list, kind: WorkKind.movie, sort: RatingsSort.year),
        ),
        ['tmdb:movie:2', 'tmdb:movie:1', 'tmdb:movie:3'],
      );
    });

    test('by title; episodes under their series, in number order', () {
      expect(keys(arrangeRatings(list, sort: RatingsSort.title)), [
        'tmdb:movie:3',
        'tmdb:tv:7:s1:e2',
        'tmdb:tv:7:s1:e10',
        'tmdb:movie:2',
        'tmdb:movie:1',
      ]);
    });

    test('filter by kind', () {
      expect(keys(arrangeRatings(list, kind: WorkKind.episode)), [
        'tmdb:tv:7:s1:e2',
        'tmdb:tv:7:s1:e10',
      ]);
    });

    test(
      'the database list carries ancestors and the poster fallback',
      () async {
        await library.rate(episode(3), scoreHalf: 17, note: null);
        await library.rate([matrix], scoreHalf: 16, note: null);
        final all = await library.watchRatings().first;
        final ep = all.firstWhere((t) => t.work.kind == WorkKind.episode);
        expect(ep.series!.title, 'Игра Престолов');
        // An episode has no poster; the season's is used.
        expect(ep.posterPath, '/uJf2z3T3SbaAElNnR8A6EaPPZHj.jpg');
        expect(
          all.firstWhere((t) => t.work.kind == WorkKind.movie).series,
          isNull,
        );
      },
    );
  });
}

Map<String, Object?> _json(String path) =>
    jsonDecode(fixture(path)) as Map<String, Object?>;
