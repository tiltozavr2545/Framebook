import 'package:drift/drift.dart' show ApplyInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

import '../support/query_counter.dart';

void main() {
  test(
    'initial and unchanged sync apply use bounded reads and preserve every row',
    () async {
      final counter = SelectCounter();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
      addTearDown(db.close);
      final store = SyncStore(db);
      final remote = mergeStates(
        const SyncState(),
        SyncState(
          works: [
            for (var id = 1; id <= 240; id++)
              Work(
                workKey: 'tmdb:movie:$id',
                kind: WorkKind.movie,
                tmdbId: id,
                title: 'Film $id',
                genreIds: '[]',
                snapshotUpdatedAt: 1,
              ),
          ],
          ratings: [
            for (var id = 1; id <= 120; id++)
              Rating(
                workKey: 'tmdb:movie:$id',
                scoreHalf: 16,
                note: 'Keep $id',
                createdAt: 1,
                scoredAt: 1,
                updatedAt: 1,
                updatedBy: 'remote',
              ),
          ],
          watchlist: [
            for (var id = 121; id <= 240; id++)
              WatchlistEntry(
                workKey: 'tmdb:movie:$id',
                addedAt: 1,
                updatedAt: 1,
                updatedBy: 'remote',
              ),
          ],
        ),
      );
      // Initialize schema before counting the application queries.
      await store.read();
      for (final expectedChanges in [480, 0]) {
        counter.selects = 0;
        expect(await store.apply(remote), expectedChanges);
        expect(counter.selects, lessThan(30));
        final actual = await store.read();
        expect(actual.works, remote.works);
        expect(actual.ratings, remote.ratings);
        expect(actual.watchlist, remote.watchlist);
      }
    },
  );

  test(
    'a newer unreferenced snapshot survives incoming older metadata',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      const newer = Work(
        workKey: 'tmdb:movie:1',
        kind: WorkKind.movie,
        tmdbId: 1,
        title: 'Newer snapshot',
        genreIds: '[]',
        snapshotUpdatedAt: 10,
      );
      await db.into(db.works).insert(newer.toCompanion(false));
      final store = SyncStore(db);
      expect((await store.read()).works, isEmpty);
      await store.apply(
        SyncState(
          works: [
            newer.copyWith(title: 'Older snapshot', snapshotUpdatedAt: 1),
          ],
          ratings: [
            const Rating(
              workKey: 'tmdb:movie:1',
              scoreHalf: 16,
              createdAt: 1,
              scoredAt: 1,
              updatedAt: 1,
              updatedBy: 'remote',
            ),
          ],
        ),
      );
      final actual = await store.read();
      expect(actual.works, [newer]);
      expect(actual.ratings.single.scoreHalf, 16);
    },
  );
}
