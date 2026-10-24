import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/work_key.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  WorksCompanion movie(int id) => WorksCompanion.insert(
    workKey: WorkKey.movie(id).toString(),
    kind: WorkKind.movie,
    tmdbId: id,
    title: 'Movie $id',
    snapshotUpdatedAt: 1,
  );

  RatingsCompanion rating(String key, int scoreHalf) => RatingsCompanion.insert(
    workKey: key,
    scoreHalf: scoreHalf,
    createdAt: 1,
    scoredAt: 1,
    updatedAt: 1,
    updatedBy: 'device',
  );

  group('device id', () {
    test('is created once and then stays the same', () async {
      final first = await db.deviceId();
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(await db.deviceId(), first);
    });
  });

  group('api budget', () {
    test('counts per source and per day', () async {
      expect(await db.consumeBudget(ApiSource.poiskkino, '2026-10-23'), 1);
      expect(await db.consumeBudget(ApiSource.poiskkino, '2026-10-23'), 2);
      expect(await db.consumeBudget(ApiSource.omdb, '2026-10-23'), 1);
      expect(await db.consumeBudget(ApiSource.poiskkino, '2026-10-24'), 1);
      expect(await db.budgetUsed(ApiSource.poiskkino, '2026-10-23'), 2);
      expect(await db.budgetUsed(ApiSource.tmdb, '2026-10-23'), 0);
    });

    test('the budget day is the UTC date', () {
      // 01:30 in Moscow (UTC+3) is still the previous day in UTC.
      final moscowEarlyMorning = DateTime.parse('2026-10-24T01:30:00+03:00');
      expect(AppDatabase.budgetDay(moscowEarlyMorning), '2026-10-23');
    });

    test(
      'tryConsume stops at the ceiling and spends nothing past it',
      () async {
        const day = '2026-10-24';
        expect(await db.tryConsumeBudget(ApiSource.omdb, day, 2), isTrue);
        expect(await db.tryConsumeBudget(ApiSource.omdb, day, 2), isTrue);
        expect(await db.tryConsumeBudget(ApiSource.omdb, day, 2), isFalse);
        expect(await db.budgetUsed(ApiSource.omdb, day), 2);
      },
    );

    test(
      'exhaust raises the counter to the daily limit, never lowers it',
      () async {
        const day = '2026-10-24';
        await db.consumeBudget(ApiSource.poiskkino, day);
        await db.exhaustBudget(ApiSource.poiskkino, day, 200);
        expect(await db.budgetUsed(ApiSource.poiskkino, day), 200);
        await db.consumeBudget(ApiSource.poiskkino, day);
        await db.exhaustBudget(ApiSource.poiskkino, day, 200);
        expect(await db.budgetUsed(ApiSource.poiskkino, day), 201);
      },
    );

    test('rows older than a week are pruned', () async {
      await db.consumeBudget(ApiSource.omdb, '2026-10-16');
      await db.consumeBudget(ApiSource.omdb, '2026-10-17');
      await db.pruneBudget(DateTime.utc(2026, 10, 24, 12));
      expect(await db.budgetUsed(ApiSource.omdb, '2026-10-16'), 0);
      expect(await db.budgetUsed(ApiSource.omdb, '2026-10-17'), 1);
    });
  });

  group('constraints', () {
    test('score_half accepts 2..20 and nothing else', () async {
      await db.into(db.works).insert(movie(1));
      await db.into(db.ratings).insert(rating('tmdb:movie:1', 2));
      await db
          .into(db.ratings)
          .insert(rating('tmdb:movie:1', 20), mode: InsertMode.insertOrReplace);
      for (final bad in [0, 1, 21]) {
        await expectLater(
          db
              .into(db.ratings)
              .insert(
                rating('tmdb:movie:1', bad),
                mode: InsertMode.insertOrReplace,
              ),
          throwsA(isA<SqliteException>()),
          reason: 'score_half $bad must be rejected',
        );
      }
    });

    test('a rating needs a work snapshot (foreign key)', () async {
      await expectLater(
        db.into(db.ratings).insert(rating('tmdb:movie:404', 15)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('unknown kinds and sources are rejected by the database', () async {
      await expectLater(
        db.customStatement(
          "INSERT INTO works (work_key, kind, tmdb_id, title, snapshot_updated_at) "
          "VALUES ('tmdb:film:1', 'film', 1, 'x', 1)",
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO external_ratings (work_key, source, status, scale, via, fetched_at) "
          "VALUES ('tmdb:movie:1', 'letterboxd', 'ok', 10, 'omdb', 1)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('external rating scale is 10 or 100', () async {
      ExternalRatingsCompanion row(int scale) =>
          ExternalRatingsCompanion.insert(
            workKey: 'tmdb:movie:1',
            source: RatingSource.rt,
            status: RatingStatus.ok,
            value: const Value(83),
            scale: scale,
            via: ApiSource.omdb,
            fetchedAt: 1,
          );
      await db.into(db.externalRatings).insert(row(100));
      await expectLater(
        db
            .into(db.externalRatings)
            .insert(row(5), mode: InsertMode.insertOrReplace),
        throwsA(isA<SqliteException>()),
      );
    });

    test('season numbers start at 0, episode numbers at 1', () async {
      await db
          .into(db.works)
          .insert(
            WorksCompanion.insert(
              workKey: const WorkKey.season(1399, 0).toString(),
              kind: WorkKind.season,
              tmdbId: 1399,
              seasonNumber: const Value(0),
              title: 'Specials',
              snapshotUpdatedAt: 1,
            ),
          );
      await expectLater(
        db
            .into(db.works)
            .insert(
              WorksCompanion.insert(
                workKey: 'tmdb:tv:1399:s1:e0',
                kind: WorkKind.episode,
                tmdbId: 1399,
                seasonNumber: const Value(1),
                episodeNumber: const Value(0),
                title: 'Episode 0',
                snapshotUpdatedAt: 1,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
