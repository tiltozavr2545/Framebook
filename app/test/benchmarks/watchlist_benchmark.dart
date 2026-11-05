// Optional host microbenchmark: flutter test test/benchmarks/watchlist_benchmark.dart
// The joined-query comparison covers a movie-only fixture, not season fences.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';

void main() {
  test(
    'watchlist reads alongside 3000 ratings with 1024-character notes',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await db.batch((batch) {
          batch.insertAll(db.works, [
            for (var id = 1; id <= 3050; id++)
              WorksCompanion.insert(
                workKey: 'tmdb:movie:$id',
                kind: WorkKind.movie,
                tmdbId: id,
                title: 'Film $id',
                snapshotUpdatedAt: 1,
              ),
          ]);
          batch.insertAll(db.ratings, [
            for (var id = 1; id <= 3000; id++)
              RatingsCompanion.insert(
                workKey: 'tmdb:movie:$id',
                scoreHalf: 16,
                note: Value('A note. ' * 128),
                createdAt: 1,
                scoredAt: 1,
                updatedAt: 1,
                updatedBy: 'device',
              ),
          ]);
          batch.insertAll(db.watchlist, [
            for (var id = 3001; id <= 3050; id++)
              WatchlistCompanion.insert(
                workKey: 'tmdb:movie:$id',
                addedAt: id,
                updatedAt: id,
                updatedBy: 'device',
              ),
          ]);
        });
        final library = Library(db, deviceId: 'device');
        final full = <int>[];
        final joined = <int>[];
        for (var run = 0; run < 7; run++) {
          final watch = Stopwatch()..start();
          final rows = await library.watchWatchlist().first;
          watch.stop();
          expect(rows, hasLength(50));
          expect(rows.first.work.workKey, 'tmdb:movie:3050');
          if (run >= 2) full.add(watch.elapsedMicroseconds);

          watch.reset();
          watch.start();
          final candidates =
              await (db.select(db.watchlist).join([
                      innerJoin(
                        db.works,
                        db.works.workKey.equalsExp(db.watchlist.workKey),
                      ),
                    ])
                    ..where(db.watchlist.deletedAt.isNull())
                    ..orderBy([OrderingTerm.desc(db.watchlist.addedAt)]))
                  .get();
          watch.stop();
          expect(
            candidates.map((row) => row.readTable(db.works).workKey),
            rows.map((row) => row.work.workKey),
          );
          if (run >= 2) joined.add(watch.elapsedMicroseconds);
        }
        full.sort();
        joined.sort();
        // ignore: avoid_print
        print(
          'Host movie-only watchlist median: ${full[2]} us; joined-query '
          'comparison: ${joined[2]} us; samples: $full / $joined',
        );
      } finally {
        await db.close();
      }
    },
  );
}
