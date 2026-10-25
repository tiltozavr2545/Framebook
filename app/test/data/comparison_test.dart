import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/divergence.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/stats.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/shared/format.dart';

ExternalRating _row(
  String key,
  RatingSource source,
  double? value, {
  RatingStatus status = RatingStatus.ok,
  int fetchedAt = 0,
}) => ExternalRating(
  workKey: key,
  source: source,
  status: value == null && status == RatingStatus.ok
      ? RatingStatus.notFound
      : status,
  value: value,
  scale: source == RatingSource.rt || source == RatingSource.metacritic
      ? 100
      : 10,
  via: source == RatingSource.kp ? ApiSource.poiskkino : ApiSource.omdb,
  fetchedAt: fetchedAt,
);

Work _work(String key, {int? year, List<int> genres = const []}) => Work(
  workKey: key,
  kind: WorkKey.parse(key).kind,
  tmdbId: 1,
  title: key,
  year: year,
  genreIds: jsonEncode(genres),
  snapshotUpdatedAt: 0,
);

/// A rated title with its cached Kinopoisk and IMDb values; a `null` value
/// means "not there".
RatedTitle _rated(
  String key,
  int half, {
  int scoredAt = 0,
  double? kp,
  double? imdb,
  bool kpChecked = true,
  int? year,
  List<int> genres = const [],
  Work? series,
}) => RatedTitle(
  rating: Rating(
    workKey: key,
    scoreHalf: half,
    createdAt: 0,
    scoredAt: scoredAt,
    updatedAt: 0,
    updatedBy: 'd',
  ),
  work: _work(key, year: year, genres: genres),
  series: series,
  external: {
    if (kpChecked) RatingSource.kp: _row(key, RatingSource.kp, kp),
    if (imdb != null) RatingSource.imdb: _row(key, RatingSource.imdb, imdb),
  },
);

void main() {
  group('divergence', () {
    test('mine minus theirs, on the same 1–10 scale', () {
      expect(divergence(17, _row('k', RatingSource.kp, 8.0)), 0.5);
      expect(
        divergence(12, _row('k', RatingSource.imdb, 8.7)),
        closeTo(-2.7, 1e-9),
      );
      expect(divergence(16, _row('k', RatingSource.tmdb, 8.0)), 0);
    });

    test('nothing to compare with: no row, not found, an error', () {
      expect(divergence(16, null), isNull);
      expect(divergence(16, _row('k', RatingSource.kp, null)), isNull);
      expect(
        divergence(
          16,
          _row('k', RatingSource.kp, null, status: RatingStatus.error),
        ),
        isNull,
      );
    });

    test('Rotten Tomatoes and Metacritic are other scales', () {
      expect(divergence(16, _row('k', RatingSource.rt, 83)), isNull);
      expect(divergence(16, _row('k', RatingSource.metacritic, 73)), isNull);
    });

    test('formatted with its sign, one decimal', () {
      expect(formatDivergence(0.5), '+0.5');
      expect(formatDivergence(-2.7), '−2.7');
      expect(formatDivergence(1), '+1.0');
      expect(formatDivergence(0.04), '±0');
      expect(formatDivergence(-0.04), '±0');
      // 8.5 − 8.501 is a hair below zero, and still "±0".
      expect(formatDivergence(8.5 - 8.501), '±0');
    });
  });

  group('sorting by divergence', () {
    final list = [
      _rated('tmdb:movie:1', 16, scoredAt: 1, kp: 7.0, imdb: 8.5), // +1, −0.5
      _rated('tmdb:movie:2', 12, scoredAt: 2, kp: 8.0, imdb: 6.0), // −2, 0
      _rated('tmdb:movie:3', 18, scoredAt: 3, kp: 8.5), // +0.5, no IMDb
      _rated('tmdb:movie:4', 14, scoredAt: 4, kpChecked: false), // nothing
      _rated('tmdb:tv:5:s1', 15, scoredAt: 5, imdb: 7.0), // no KP, +0.5
    ];
    List<String> keys(List<RatedTitle> l) => [
      for (final t in l) t.work.workKey,
    ];
    List<String> arrange(RatingSource source, DivergenceOrder order) => keys(
      arrangeRatings(
        list,
        sort: RatingsSort.divergence,
        compareWith: source,
        order: order,
      ),
    );

    test('furthest apart first, either way; no data last, recent first', () {
      expect(arrange(RatingSource.kp, DivergenceOrder.furthest), [
        'tmdb:movie:2',
        'tmdb:movie:1',
        'tmdb:movie:3',
        'tmdb:tv:5:s1',
        'tmdb:movie:4',
      ]);
    });

    test('where I rate higher first', () {
      expect(arrange(RatingSource.kp, DivergenceOrder.higher).take(3), [
        'tmdb:movie:1',
        'tmdb:movie:3',
        'tmdb:movie:2',
      ]);
    });

    test('where I rate lower first', () {
      expect(arrange(RatingSource.kp, DivergenceOrder.lower).take(3), [
        'tmdb:movie:2',
        'tmdb:movie:3',
        'tmdb:movie:1',
      ]);
    });

    test('against IMDb, a season counts too', () {
      expect(arrange(RatingSource.imdb, DivergenceOrder.higher), [
        'tmdb:tv:5:s1',
        'tmdb:movie:2',
        'tmdb:movie:1',
        'tmdb:movie:4',
        'tmdb:movie:3',
      ]);
    });
  });

  group('statistics', () {
    test('nothing rated', () {
      final stats = computeStats(const []);
      expect(stats.isEmpty, isTrue);
      expect(stats.average, isNull);
      expect(stats.distribution, List.filled(19, 0));
      expect(stats.deviation, isEmpty);
      expect(stats.genres, isEmpty);
      expect(stats.decades, isEmpty);
    });

    test('count, average and the distribution by half points', () {
      final stats = computeStats([
        _rated('tmdb:movie:1', 2),
        _rated('tmdb:movie:2', 15),
        _rated('tmdb:movie:3', 15),
        _rated('tmdb:movie:4', 20),
      ]);
      expect(stats.count, 4);
      expect(stats.average, (1 + 7.5 + 7.5 + 10) / 4);
      expect(stats.distribution[0], 1); // 1
      expect(stats.distribution[13], 2); // 7.5
      expect(stats.distribution[18], 1); // 10
      expect(stats.distribution.reduce((a, b) => a + b), 4);
    });

    test('deviation: signed and absolute, over the titles that have it', () {
      final stats = computeStats([
        _rated('tmdb:movie:1', 16, kp: 7.0, imdb: 8.5), // +1, −0.5
        _rated('tmdb:movie:2', 12, kp: 8.0), // −2
        _rated('tmdb:movie:3', 18, kpChecked: false),
        _rated('tmdb:movie:4', 18), // Kinopoisk doesn't know it
      ]);
      final kp = stats.deviation[RatingSource.kp]!;
      expect(kp.count, 2);
      expect(kp.signed, -0.5);
      expect(kp.absolute, 1.5);
      final imdb = stats.deviation[RatingSource.imdb]!;
      expect(imdb.count, 1);
      expect(imdb.signed, -0.5);
      expect(imdb.absolute, 0.5);
    });

    test('a source with no values is absent, not zero', () {
      final stats = computeStats([_rated('tmdb:movie:1', 16, kp: 7.0)]);
      expect(stats.deviation.keys, [RatingSource.kp]);
    });

    test('by genre: most rated first; episodes count under the series', () {
      final series = _work('tmdb:tv:9', genres: [18, 10765]);
      final stats = computeStats([
        _rated('tmdb:movie:1', 16, genres: [28, 878]),
        _rated('tmdb:movie:2', 12, genres: [28]),
        _rated('tmdb:tv:9:s1:e1', 18, series: series),
        _rated('tmdb:tv:9:s1:e2', 20, series: series),
        _rated('tmdb:tv:9', 14, genres: [18, 10765]),
      ]);
      final byId = {for (final g in stats.genres) g.key: g};
      expect(byId[18]!.count, 3);
      expect(byId[18]!.average, (9 + 10 + 7) / 3);
      expect(byId[28]!.count, 2);
      expect(byId[28]!.average, 7);
      expect(byId[878]!.count, 1);
      expect(stats.genres.first.key, isIn([18, 10765]));
      expect(stats.genres.last.key, 878);
    });

    test('by decade, oldest first; undated titles are left out', () {
      final stats = computeStats([
        _rated('tmdb:movie:1', 16, year: 1999),
        _rated('tmdb:movie:2', 12, year: 1990),
        _rated('tmdb:movie:3', 20, year: 2010),
        _rated('tmdb:movie:4', 20),
      ]);
      expect([for (final d in stats.decades) d.key], [1990, 2010]);
      expect(stats.decades.first.count, 2);
      expect(stats.decades.first.average, 7);
    });
  });

  test('coverage: an answer counts, a missing row or an error does not', () {
    final titles = [
      _rated('tmdb:movie:1', 16, kp: 7.0),
      _rated('tmdb:movie:2', 16), // not found: an answer too
      _rated('tmdb:movie:3', 16, kpChecked: false),
      _rated('tmdb:tv:4:s1', 16), // Kinopoisk doesn't rate seasons
      RatedTitle(
        rating: _rated('tmdb:movie:5', 16).rating,
        work: _work('tmdb:movie:5'),
        external: {
          RatingSource.kp: _row(
            'tmdb:movie:5',
            RatingSource.kp,
            null,
            status: RatingStatus.error,
          ),
        },
      ),
    ];
    expect(
      coverage(
        titles,
        RatingSource.kp,
        (kind) => kind == WorkKind.movie || kind == WorkKind.tv,
      ),
      (loaded: 2, total: 4),
    );
  });

  test('the database list carries the Kinopoisk and IMDb rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final library = Library(db, deviceId: 'd');
    final film = WorkSnapshot(
      key: const WorkKey.movie(1),
      tmdbId: 1,
      title: 'Film',
    );
    final other = WorkSnapshot(
      key: const WorkKey.movie(2),
      tmdbId: 2,
      title: 'Other',
    );
    await library.rate([film], scoreHalf: 16, note: null);
    await library.rate([other], scoreHalf: 12, note: null);
    await db.putExternalRatings([
      _row('tmdb:movie:1', RatingSource.kp, 7.0),
      _row('tmdb:movie:1', RatingSource.imdb, 7.5),
      // Not compared with: stays out of the list.
      _row('tmdb:movie:1', RatingSource.rt, 90),
    ]);

    final emitted = <List<RatedTitle>>[];
    final subscription = library.watchRatings().listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    final rated = emitted.last.firstWhere(
      (t) => t.work.workKey == 'tmdb:movie:1',
    );
    expect(rated.external.keys, unorderedEquals(compareSources));
    expect(rated.divergenceFrom(RatingSource.kp), 1);
    expect(rated.divergenceFrom(RatingSource.imdb), 0.5);
    expect(
      emitted.last.firstWhere((t) => t.work.workKey == 'tmdb:movie:2').external,
      isEmpty,
    );

    // A value arriving later (background refresh) updates the list.
    final before = emitted.length;
    await db.putExternalRatings([_row('tmdb:movie:2', RatingSource.kp, 8.0)]);
    await pumpEventQueue();
    expect(emitted.length, greaterThan(before));
    expect(
      emitted.last
          .firstWhere((t) => t.work.workKey == 'tmdb:movie:2')
          .divergenceFrom(RatingSource.kp),
      -2,
    );
  });
}
