import 'dart:convert';

import '../db/database.dart';
import 'sync_file.dart';

// Last write wins, row by row (docs/sync.md, "Merging"). A `ratings` or
// `watchlist` row wins by the larger `(updated_at, updated_by)`, a `works` row
// by the larger `snapshot_updated_at`. Two different rows with equal versions
// shouldn't happen, but if they do the larger canonical JSON wins, so the
// merge stays commutative, associative and idempotent whatever the input.

/// Positive when [a] wins over [b], zero when they are the same row.
int compareRatings(Rating a, Rating b) => _then(
  a.updatedAt.compareTo(b.updatedAt),
  () => _then(
    a.updatedBy.compareTo(b.updatedBy),
    () => _canonical(
      SyncFile.ratingToJson(a),
    ).compareTo(_canonical(SyncFile.ratingToJson(b))),
  ),
);

int compareWatchlist(WatchlistEntry a, WatchlistEntry b) => _then(
  a.updatedAt.compareTo(b.updatedAt),
  () => _then(
    a.updatedBy.compareTo(b.updatedBy),
    () => _canonical(
      SyncFile.watchlistToJson(a),
    ).compareTo(_canonical(SyncFile.watchlistToJson(b))),
  ),
);

int compareWorks(Work a, Work b) => _then(
  a.snapshotUpdatedAt.compareTo(b.snapshotUpdatedAt),
  () => _canonical(
    SyncFile.workToJson(a),
  ).compareTo(_canonical(SyncFile.workToJson(b))),
);

/// The merged state of [a] and [b]: for every key, the winning version.
SyncState mergeStates(SyncState a, SyncState b) => SyncState(
  works: _merge(a.works, b.works, (w) => w.workKey, compareWorks),
  ratings: _merge(a.ratings, b.ratings, (r) => r.workKey, compareRatings),
  watchlist: _merge(
    a.watchlist,
    b.watchlist,
    (w) => w.workKey,
    compareWatchlist,
  ),
);

/// Whether [remote] lacks something [local] has: a row it doesn't know, or
/// an older version of one. Then the merged state has to be uploaded.
bool remoteBehind(SyncState local, SyncState remote) =>
    _behind(local.works, remote.works, (w) => w.workKey, compareWorks) ||
    _behind(local.ratings, remote.ratings, (r) => r.workKey, compareRatings) ||
    _behind(
      local.watchlist,
      remote.watchlist,
      (w) => w.workKey,
      compareWatchlist,
    );

List<T> _merge<T>(
  List<T> a,
  List<T> b,
  String Function(T) key,
  int Function(T, T) compare,
) {
  final byKey = <String, T>{};
  for (final row in [...a, ...b]) {
    final k = key(row);
    final current = byKey[k];
    if (current == null || compare(row, current) > 0) byKey[k] = row;
  }
  final keys = byKey.keys.toList()..sort();
  return [for (final k in keys) byKey[k] as T];
}

bool _behind<T>(
  List<T> local,
  List<T> remote,
  String Function(T) key,
  int Function(T, T) compare,
) {
  final theirs = {for (final row in remote) key(row): row};
  for (final row in local) {
    final other = theirs[key(row)];
    if (other == null || compare(row, other) > 0) return true;
  }
  return false;
}

/// JSON with sorted keys: the same row always gives the same string.
String _canonical(Map<String, Object?> json) {
  final keys = json.keys.toList()..sort();
  return jsonEncode({for (final k in keys) k: json[k]});
}

int _then(int first, int Function() next) => first != 0 ? first : next();
