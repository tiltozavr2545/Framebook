import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/pair_calibration.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_compute.dart';
import 'package:framebook/data/sync/sync_file.dart';

import '../support/sync_workload.dart';
import 'insights_test.dart' show rated;
import 'pair_calibration_test.dart' show evidence;

List<int> _encode(SyncState state) => SyncFile.encode(
  state,
  writtenAt: 100,
  writtenBy: 'test',
  appVersion: '0.9.5+25',
);

void main() {
  test(
    'empty and small asynchronous merges preserve synchronous results',
    () async {
      const state = SyncState(purgedBefore: 1);
      expect(
        _encode(await mergeStatesAsync(const SyncState(), state)),
        _encode(state),
      );
      expect(await remoteBehindAsync(state, const SyncState()), isTrue);
      expect(await remoteBehindAsync(state, state), isFalse);
    },
  );

  test(
    'large worker merges preserve every register, notes and conflict result',
    () async {
      final a = syncWorkload(1);
      final newer = syncWorkload(2);
      final b = SyncState(
        works: newer.works,
        ratings: newer.ratings,
        watchlist: newer.watchlist,
        purgedBefore: 1,
        ratingDeletions: [
          ratingDeletion(
            newer.ratings.first.copyWith(
              updatedAt: 3,
              deletedAt: const Value(3),
            ),
          ),
        ],
        watchlistDeletions: [
          watchlistDeletion(
            newer.watchlist.first.copyWith(
              updatedAt: 3,
              deletedAt: const Value(3),
            ),
          ),
        ],
        watchlistFences: const [
          WatchlistFence(
            seriesKey: 'tmdb:tv:1',
            season: true,
            updatedAt: 3,
            updatedBy: 'remote',
          ),
        ],
        favoritePeople: const [
          FavoritePerson(
            personId: 1,
            name: 'Person',
            profilePath: '/person.jpg',
            updatedAt: 3,
            updatedBy: 'remote',
          ),
        ],
        pairComparisons: [
          evidence(
            CalibrationPair(rated(1, 16), rated(2, 18)),
            PairPreference.left,
          ),
        ],
      );
      final expected = mergeStates(a, b);
      final actual = await mergeStatesAsync(a, b);
      expect(_encode(actual), _encode(expected));
      expect(actual.ratings, hasLength(2999));
      expect(actual.watchlist, hasLength(2999));
      expect(
        actual.ratings.every((row) => row.note == 'A note. ' * 64),
        isTrue,
      );
      expect(actual.favoritePeople.single.name, 'Person');
      expect(actual.pairComparisons.single.preference, PairPreference.left);
      expect(
        actual.ratingDeletions.single.workKey,
        newer.ratings.first.workKey,
      );
      expect(
        actual.watchlistDeletions.single.workKey,
        newer.watchlist.first.workKey,
      );
      for (final pair in [(a, b), (b, a), (b, b)]) {
        expect(
          await remoteBehindAsync(pair.$1, pair.$2),
          remoteBehind(pair.$1, pair.$2),
        );
      }
      final dropped = await droppedByAsync(a, b);
      final expectedDrops = droppedBy(a, b);
      expect(dropped.ratings, expectedDrops.ratings);
      expect(dropped.watchlist, expectedDrops.watchlist);
      for (final lastSyncAt in [null, 4]) {
        final review = await reviewStaleAsync(a, b, lastSyncAt: lastSyncAt);
        final expectedReview = unsyncedDrops(a, b, lastSyncAt: lastSyncAt);
        expect(review.drops.ratings, expectedReview.ratings);
        expect(review.drops.watchlist, expectedReview.watchlist);
        expect(
          review.fingerprint,
          staleFingerprint(a, b, lastSyncAt: lastSyncAt),
        );
      }
    },
  );
}
