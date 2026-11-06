import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

void main() {
  test(
    'selective watchlist matches full-state semantics across 450 series and fences',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final random = Random(84);
      final rows = <WatchlistCompanion>[];
      await db.batch((batch) {
        final works = <WorksCompanion>[];
        final ratings = <RatingsCompanion>[];
        for (var id = 1; id <= 450; id++) {
          for (final key in [
            WorkKey.tv(id),
            WorkKey.season(id, 1),
            WorkKey.season(id, 2),
          ]) {
            works.add(
              WorksCompanion.insert(
                workKey: key.toString(),
                kind: key.kind,
                tmdbId: id,
                title: key.toString(),
                parentKey: Value(key.parent?.toString()),
                seasonNumber: Value(key.season),
                snapshotUpdatedAt: 1,
              ),
            );
            final time = random.nextInt(100) + 1;
            rows.add(
              WatchlistCompanion.insert(
                workKey: key.toString(),
                addedAt: rows.length + 1,
                updatedAt: time,
                updatedBy: id.isEven ? 'a' : 'b',
                deletedAt: Value(id % 11 == 0 ? time : null),
              ),
            );
            if (key.kind == WorkKind.season && id % 3 == 0) {
              ratings.add(
                RatingsCompanion.insert(
                  workKey: key.toString(),
                  scoreHalf: 16,
                  note: Value('A private note. ' * 100),
                  createdAt: 1,
                  scoredAt: 1,
                  updatedAt: 1,
                  updatedBy: 'a',
                  deletedAt: Value(id % 6 == 0 ? 2 : null),
                ),
              );
            }
          }
        }
        batch.insertAll(db.works, works);
        batch.insertAll(db.watchlist, rows);
        batch.insertAll(db.ratings, ratings);
      });
      final store = SyncStore(db);
      await store.saveFences([
        for (var id = 5; id <= 450; id += 5)
          WatchlistFence(
            seriesKey: WorkKey.tv(id).toString(),
            season: id.isEven,
            updatedAt: 110,
            updatedBy: 'remote',
          ),
      ]);
      Future<void> compare() async {
        final state = await store.read();
        final rated = {
          for (final row in state.ratings)
            if (row.deletedAt == null) row.workKey,
        };
        final sorted = [...state.watchlist]
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
        final expected = [
          for (final row in sorted)
            if ((WorkKey.parse(row.workKey).kind != WorkKind.season ||
                    !rated.contains(row.workKey)) &&
                visibleWatchlistEntry(row, state.watchlistFences))
              row.workKey,
        ];
        final actual = await Library(
          db,
          deviceId: 'test',
        ).watchWatchlist().first;
        expect(actual.map((row) => row.entry.workKey), expected);
        expect(
          actual.where((row) => row.key.kind == WorkKind.season),
          isNotEmpty,
        );
        for (final row in actual) {
          expect(row.series?.workKey, row.key.parent?.toString());
        }
      }

      await compare();
      await store.saveFences([
        const WatchlistFence(
          seriesKey: 'tmdb:tv:1',
          season: true,
          updatedAt: 200,
          updatedBy: 'remote',
        ),
      ]);
      await db.customStatement('UPDATE ratings SET deleted_at = NULL');
      await compare();
    },
  );
}
