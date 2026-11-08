import 'dart:isolate';

import 'merge.dart';
import 'sync_file.dart';

int _rows(SyncState state) =>
    state.works.length +
    state.ratings.length +
    state.watchlist.length +
    state.favoritePeople.length +
    state.pairComparisons.length +
    state.ratingDeletions.length +
    state.watchlistDeletions.length +
    state.watchlistFences.length;

bool _needsWorker(SyncState a, SyncState b) => _rows(a) + _rows(b) > 2000;

/// Keep pure register merging off the UI isolate for large sync states.
/// Only detached row values cross the boundary, never a database/transaction.
Future<SyncState> mergeStatesAsync(SyncState a, SyncState b) =>
    _needsWorker(a, b)
    ? Isolate.run(() => mergeStates(a, b))
    : Future.value(mergeStates(a, b));

Future<bool> remoteBehindAsync(SyncState local, SyncState remote) =>
    _needsWorker(local, remote)
    ? Isolate.run(() => remoteBehind(local, remote))
    : Future.value(remoteBehind(local, remote));

typedef SyncDrops = ({Set<String> ratings, Set<String> watchlist});
typedef SyncStaleReview = ({SyncDrops drops, String fingerprint});

SyncStaleReview _review(SyncState local, SyncState remote, int? lastSyncAt) {
  final drops = unsyncedDrops(local, remote, lastSyncAt: lastSyncAt);
  final empty = drops.ratings.isEmpty && drops.watchlist.isEmpty;
  return (
    drops: drops,
    fingerprint: staleFingerprint(
      empty ? const SyncState() : local,
      empty ? const SyncState() : remote,
      lastSyncAt: lastSyncAt,
    ),
  );
}

Future<SyncStaleReview> reviewStaleAsync(
  SyncState local,
  SyncState remote, {
  required int? lastSyncAt,
}) => _needsWorker(local, remote)
    ? Isolate.run(() => _review(local, remote, lastSyncAt))
    : Future.value(_review(local, remote, lastSyncAt));

Future<SyncDrops> droppedByAsync(SyncState local, SyncState remote) =>
    _needsWorker(local, remote)
    ? Isolate.run(() => droppedBy(local, remote))
    : Future.value(droppedBy(local, remote));
