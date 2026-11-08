import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/poiskkino/poiskkino_client.dart';
import 'package:framebook/data/sources/omdb/omdb_client.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/title_ratings.dart';

class _PendingKp implements PoiskKinoApi {
  final result = Completer<KpRatings?>();
  final requested = Completer<void>();
  int calls = 0;

  @override
  Future<KpRatings?> byTmdbId(int tmdbId, {required bool isSeries}) {
    calls++;
    if (!requested.isCompleted) requested.complete();
    return result.future;
  }

  @override
  Future<KpRatings?> byImdbId(String imdbId, {required bool isSeries}) =>
      byTmdbId(1, isSeries: isSeries);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Omdb extends Fake implements OmdbApi {
  int calls = 0;

  @override
  Future<OmdbRatings?> byImdbId(String imdbId) async {
    calls++;
    return null;
  }
}

void main() {
  test(
    'closing a card stops subsequent source lookups after an in-flight request',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final kp = _PendingKp();
      final omdb = _Omdb();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ratingsServiceProvider.overrideWithValue(
            RatingsService(db, poiskkino: kp, omdb: omdb),
          ),
        ],
      );
      addTearDown(container.dispose);
      const target = RatingTarget(key: WorkKey.movie(1), imdbId: 'tt1234567');
      final subscription = container.listen(
        titleRatingsProvider(target),
        (_, _) {},
      );
      await kp.requested.future;
      subscription.close();
      await pumpEventQueue();
      kp.result.complete(null);
      await pumpEventQueue(times: 100);
      expect(omdb.calls, 0);
      expect(
        await db.budgetUsed(
          ApiSource.omdb,
          AppDatabase.budgetDay(DateTime.now()),
        ),
        0,
      );
      expect(await db.externalRatingsFor('${target.key}'), isNotEmpty);
    },
  );
  test(
    'a late failure cannot overwrite a rating fetched with a new key',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final old = _PendingKp();
      final next = _PendingKp();
      const target = RatingTarget(key: WorkKey.movie(1));
      final oldPass = RatingsService(db, poiskkino: old).refresh(target);
      await old.requested.future;
      final nextPass = RatingsService(db, poiskkino: next).refresh(target);
      await next.requested.future;
      next.result.complete(
        const KpRatings(
          kpId: 1,
          kp: 8.5,
          kpVotes: 100,
          imdb: 8,
          imdbVotes: 200,
        ),
      );
      await nextPass;
      old.result.completeError(
        const SourceException(SourceFailure.unauthorized),
      );
      await oldPass;
      final rows = await db.externalRatingsFor(target.key.toString());
      expect(rows, hasLength(2));
      expect(rows.map((row) => row.status), everyElement(RatingStatus.ok));
      expect(
        rows.singleWhere((row) => row.source == RatingSource.kp).value,
        8.5,
      );
      expect(
        rows.singleWhere((row) => row.source == RatingSource.imdb).value,
        8,
      );
    },
  );

  test(
    'an old key response cannot replace a rebuilt card request status',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final old = _PendingKp();
      final next = _PendingKp();
      var service = RatingsService(db, poiskkino: old);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ratingsServiceProvider.overrideWith((ref) => service),
        ],
      );
      const target = RatingTarget(key: WorkKey.movie(1));
      final provider = titleRatingsProvider(target);
      container.listen(provider, (_, _) {});
      try {
        for (var i = 0; i < 100 && old.calls == 0; i++) {
          await pumpEventQueue();
        }
        expect(old.calls, 1);
        service = RatingsService(db, poiskkino: next);
        container.invalidate(ratingsServiceProvider);
        container.read(provider);
        for (var i = 0; i < 100 && next.calls == 0; i++) {
          await pumpEventQueue();
        }
        expect(next.calls, 1);
        next.result.completeError(const SourceException(SourceFailure.offline));
        for (
          var i = 0;
          i < 100 && container.read(provider).failures.isEmpty;
          i++
        ) {
          await pumpEventQueue();
        }
        expect(
          container.read(provider).failures[ApiSource.poiskkino],
          SourceFailure.offline,
        );
        old.result.completeError(
          const SourceException(SourceFailure.unauthorized),
        );
        await pumpEventQueue(times: 100);
        expect(
          container.read(provider).failures[ApiSource.poiskkino],
          SourceFailure.offline,
        );
        expect(container.read(provider).loading, isEmpty);
      } finally {
        container.dispose();
        await pumpEventQueue();
        await db.close();
      }
    },
  );
}
