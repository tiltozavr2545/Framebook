// Optional host scheduling experiment, including isolate transfer.
import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_compute.dart';

import '../support/sync_workload.dart';

Future<void> _measure(
  String label,
  Future<(SyncState, bool)> Function() work,
) async {
  final totals = <int>[];
  final gaps = <int>[];
  for (var run = 0; run < 7; run++) {
    final clock = Stopwatch()..start();
    var previous = 0;
    var longest = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
      final current = clock.elapsedMicroseconds;
      longest = max(longest, current - previous);
      previous = current;
    });
    try {
      final (merged, behind) = await work();
      clock.stop();
      longest = max(longest, clock.elapsedMicroseconds - previous);
      expect(merged.ratings, hasLength(3000));
      expect(merged.watchlist, hasLength(3000));
      expect(merged.ratings.first.updatedAt, 2);
      expect(behind, isFalse);
      if (run >= 2) {
        totals.add(clock.elapsedMicroseconds);
        gaps.add(longest);
      }
    } finally {
      timer.cancel();
    }
  }
  final sortedTotals = [...totals]..sort();
  final sortedGaps = [...gaps]..sort();
  // ignore: avoid_print
  print(
    'Host sync $label: total median ${sortedTotals[2]} us; '
    'scheduler gap median ${sortedGaps[2]} us; totals $totals; gaps $gaps',
  );
}

void main() {
  test(
    'large sync merges and behind checks include transfer scheduling',
    () async {
      final a = syncWorkload(1), b = syncWorkload(2);
      await _measure(
        'inline',
        () async => (mergeStates(a, b), remoteBehind(a, b)),
      );
      await _measure(
        'production worker',
        () async =>
            (await mergeStatesAsync(a, b), await remoteBehindAsync(a, b)),
      );
    },
  );
  test('large guarded sync work includes stale-edit review', () async {
    final a = syncWorkload(1), b = syncWorkload(2);
    await _measure('guarded inline', () async {
      final drops = unsyncedDrops(a, b, lastSyncAt: null);
      if (drops.ratings.isNotEmpty || drops.watchlist.isNotEmpty) {
        throw StateError('Unexpected stale edit');
      }
      return (mergeStates(a, b), remoteBehind(a, b));
    });
    await _measure('guarded production worker', () async {
      final review = await reviewStaleAsync(a, b, lastSyncAt: null);
      if (review.drops.ratings.isNotEmpty ||
          review.drops.watchlist.isNotEmpty) {
        throw StateError('Unexpected stale edit');
      }
      return (await mergeStatesAsync(a, b), await remoteBehindAsync(a, b));
    });
  });
}
