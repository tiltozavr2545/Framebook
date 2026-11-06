// Optional host microbenchmark: flutter test test/benchmarks/watchlist_benchmark.dart
// Compare the selective stream with the former full-state read on movie data.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/data/sync/sync_store.dart';

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
          final state = await SyncStore(db).read();
          final works = {for (final work in state.works) work.workKey: work};
          final candidates = [...state.watchlist]
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
          final baseline = [
            for (final entry in candidates)
              if (entry.deletedAt == null && works.containsKey(entry.workKey))
                entry.workKey,
          ];
          watch.stop();
          expect(baseline, rows.map((row) => row.work.workKey));
          if (run >= 2) joined.add(watch.elapsedMicroseconds);
        }
        full.sort();
        joined.sort();
        // ignore: avoid_print
        print(
          'Host movie-only watchlist median: selective ${full[2]} us; full-state '
          'baseline ${joined[2]} us; samples: $full / $joined',
        );
      } finally {
        await db.close();
      }
    },
  );
}
