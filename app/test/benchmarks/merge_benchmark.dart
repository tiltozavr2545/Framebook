// Optional host microbenchmark: flutter test test/benchmarks/merge_benchmark.dart
// This is not a device/frame/battery benchmark or a timing gate in CI.
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/work_key.dart';

void main() {
  test('merge 6000 snapshots, 3000 ratings and 3000 watchlist entries', () {
    SyncState sample(int version) => SyncState(
      works: [
        for (var i = 1; i <= 6000; i++)
          Work(
            workKey: 'tmdb:movie:$i',
            kind: WorkKind.movie,
            tmdbId: i,
            title: 'Film $i',
            genreIds: '[]',
            snapshotUpdatedAt: version,
          ),
      ],
      ratings: [
        for (var i = 1; i <= 3000; i++)
          Rating(
            workKey: 'tmdb:movie:$i',
            scoreHalf: 16,
            note: 'A note. ' * 64,
            createdAt: 1,
            scoredAt: 1,
            updatedAt: version,
            updatedBy: 'device',
          ),
      ],
      watchlist: [
        for (var i = 3001; i <= 6000; i++)
          WatchlistEntry(
            workKey: 'tmdb:movie:$i',
            addedAt: 1,
            updatedAt: version,
            updatedBy: 'device',
          ),
      ],
    );
    final a = sample(1);
    final b = sample(2);
    final samples = <int>[];
    for (var run = 0; run < 7; run++) {
      final watch = Stopwatch()..start();
      final merged = mergeStates(a, b);
      final behind = remoteBehind(a, b);
      watch.stop();
      expect(merged.ratings, hasLength(3000));
      expect(merged.watchlist, hasLength(3000));
      expect(merged.ratings.first.updatedAt, 2);
      expect(behind, isFalse);
      if (run >= 2) samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    // ignore: avoid_print
    print(
      'Host merge+remoteBehind median: ${samples[2]} us; samples: $samples',
    );
  });
}
