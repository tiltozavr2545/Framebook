import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

const _series = WorkSnapshot(key: WorkKey.tv(2), tmdbId: 2, title: 'Series');
const _season = WorkSnapshot(
  key: WorkKey.season(2, 1),
  tmdbId: 21,
  title: 'Season',
);

void main() {
  test(
    'unrelated score-cache writes do not republish the rating library',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final library = Library(db, deviceId: 'local');
      await library.rate([_series, _season], scoreHalf: 16, note: 'Original');
      final events = <List<RatedTitle>>[];
      final subscription = library.watchRatings().listen(events.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(events, hasLength(1));
      ExternalRating score(String key, RatingSource source, double value) =>
          ExternalRating(
            workKey: key,
            source: source,
            status: RatingStatus.ok,
            value: value,
            scale: 10,
            via: source == RatingSource.tmdb
                ? ApiSource.tmdb
                : ApiSource.poiskkino,
            fetchedAt: 1,
          );
      await db.putExternalRatings([
        score('tmdb:movie:999', RatingSource.kp, 8),
        score('${_season.key}', RatingSource.tmdb, 8),
      ]);
      await pumpEventQueue();
      expect(events, hasLength(1));
      final compared = score('${_season.key}', RatingSource.imdb, 7);
      await db.putExternalRatings([compared]);
      await pumpEventQueue();
      expect(events, hasLength(2));
      expect(events.last.single.external[RatingSource.imdb]?.value, 7);
      await db.putExternalRatings([compared]);
      await pumpEventQueue();
      expect(events, hasLength(2));
      await library.rate([_series, _season], scoreHalf: 16, note: 'Changed');
      await pumpEventQueue();
      expect(events.last.single.rating.note, 'Changed');
      final beforeAncestor = events.length;
      await (db.update(db.works)
            ..where((row) => row.workKey.equals('${_series.key}')))
          .write(const WorksCompanion(title: Value('Translated series')));
      await pumpEventQueue();
      expect(events, hasLength(beforeAncestor + 1));
      expect(events.last.single.series?.title, 'Translated series');
      await library.deleteRating(_season.key);
      await pumpEventQueue();
      expect(events.last, isEmpty);
    },
  );

  test(
    'sync bookkeeping does not republish unchanged watchlist rows',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final library = Library(db, deviceId: 'local');
      await library.addToWatchlist([_series]);
      final events = <List<WatchlistTitle>>[];
      final subscription = library.watchWatchlist().listen(events.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(events, hasLength(1));
      final store = SyncStore(db);
      await store.setStateValue(SyncStore.lastSyncKey, '123');
      await pumpEventQueue();
      expect(events, hasLength(1));
      await store.saveFences([
        WatchlistFence(
          seriesKey: '${_series.key}',
          season: true,
          updatedAt: DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          updatedBy: 'remote',
        ),
      ]);
      await pumpEventQueue();
      expect(events, hasLength(2));
      expect(events.last, isEmpty);
    },
  );
}
