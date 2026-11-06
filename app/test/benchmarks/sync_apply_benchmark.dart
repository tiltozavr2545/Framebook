// Optional host benchmark: flutter test test/benchmarks/sync_apply_benchmark.dart
// Counts actual SELECTs as well as time; no timing threshold gates CI.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

import '../support/query_counter.dart';

void main() {
  test(
    'reapply unchanged sync with 1500 ratings and 1500 watchlist entries',
    () async {
      final reads = SelectCounter();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
      try {
        await db.batch((batch) {
          batch.insertAll(db.works, [
            for (var id = 1; id <= 3000; id++)
              WorksCompanion.insert(
                workKey: 'tmdb:movie:$id',
                kind: WorkKind.movie,
                tmdbId: id,
                title: 'Film $id',
                snapshotUpdatedAt: 1,
              ),
          ]);
          batch.insertAll(db.ratings, [
            for (var id = 1; id <= 1500; id++)
              RatingsCompanion.insert(
                workKey: 'tmdb:movie:$id',
                scoreHalf: 16,
                note: Value('A note. ' * 64),
                createdAt: 1,
                scoredAt: 1,
                updatedAt: 1,
                updatedBy: 'device',
              ),
          ]);
          batch.insertAll(db.watchlist, [
            for (var id = 1501; id <= 3000; id++)
              WatchlistCompanion.insert(
                workKey: 'tmdb:movie:$id',
                addedAt: 1,
                updatedAt: 1,
                updatedBy: 'device',
              ),
          ]);
        });
        final store = SyncStore(db);
        final state = await store.read();
        final samples = <int>[];
        final counts = <int>[];
        for (var run = 0; run < 7; run++) {
          reads.selects = 0;
          final watch = Stopwatch()..start();
          expect(await store.apply(state), 0);
          watch.stop();
          if (run >= 2) {
            samples.add(watch.elapsedMicroseconds);
            counts.add(reads.selects);
          }
        }
        final after = await store.read();
        expect(after.works, state.works);
        expect(after.ratings, state.ratings);
        expect(after.watchlist, state.watchlist);
        samples.sort();
        // ignore: avoid_print
        print(
          'Host unchanged sync apply median: ${samples[2]} us; '
          'samples: $samples; SELECTs: $counts',
        );
      } finally {
        await db.close();
      }
    },
  );
}
