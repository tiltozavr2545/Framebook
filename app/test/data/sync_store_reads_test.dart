import 'package:drift/drift.dart' show ApplyInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

import '../support/query_counter.dart';

void main() {
  test(
    'worker-backed deletion review rejects stale consent and preserves Keep',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final library = Library(
        db,
        deviceId: 'local',
        clock: () => DateTime.fromMillisecondsSinceEpoch(1, isUtc: true),
      );
      const key = WorkKey.movie(1);
      await library.rate(
        const [WorkSnapshot(key: key, tmdbId: 1, title: 'Film')],
        scoreHalf: 16,
        note: 'Retain this note',
      );
      final store = SyncStore(db);
      final remote = SyncState(
        ratingDeletions: [
          for (var id = 1; id <= 2001; id++)
            DeletionRecord(
              workKey: '${WorkKey.movie(id)}',
              updatedAt: 10,
              updatedBy: 'remote',
              tieBreak: '0' * 64,
            ),
        ],
      );
      Future<StaleReviewRequired> review([String? fingerprint]) async {
        try {
          await store.apply(
            remote,
            guard: true,
            lastSyncAt: 0,
            keep: false,
            reviewedFingerprint: fingerprint,
            deviceId: 'local',
            now: 20,
          );
        } on StaleReviewRequired catch (question) {
          return question;
        }
        fail('Unreviewed deletion was applied');
      }

      final first = await review();
      expect(first.count, 1);
      await library.rescore(key, 18);
      final second = await review(first.fingerprint);
      expect(second.fingerprint, isNot(first.fingerprint));
      expect((await library.watchRating(key).first)?.scoreHalf, 18);
      await store.apply(
        remote,
        guard: true,
        lastSyncAt: 0,
        keep: true,
        reviewedFingerprint: second.fingerprint,
        deviceId: 'local',
        now: 20,
      );
      final state = await store.read();
      expect(state.ratings.single.scoreHalf, 18);
      expect(state.ratings.single.note, 'Retain this note');
      expect(state.ratings.single.updatedAt, greaterThan(10));
      expect(state.ratingDeletions, hasLength(2001));
    },
  );
  for (final size in [240, 600]) {
    test(
      'initial and unchanged sync apply preserve $size rows with bounded reads',
      () async {
        final counter = SelectCounter();
        final db = AppDatabase(NativeDatabase.memory().interceptWith(counter));
        addTearDown(db.close);
        final store = SyncStore(db);
        final remote = mergeStates(
          const SyncState(),
          SyncState(
            works: [
              for (var id = 1; id <= size; id++)
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
              for (var id = 1; id <= size ~/ 2; id++)
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
              for (var id = size ~/ 2 + 1; id <= size; id++)
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
        for (final expectedChanges in [size * 2, 0]) {
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
  }

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
