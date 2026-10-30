import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../db/database.dart';
import 'sync_file.dart';

const purgeAge = Duration(days: 180);
int purgeWatermark(int now) => max(0, now - purgeAge.inMilliseconds);
int clampWatermark(int watermark, int now) =>
    min(watermark, max(0, now - purgeAge.inMilliseconds ~/ 2));

String _canonical(Map<String, Object?> row) {
  final keys = row.keys.toList()..sort();
  return jsonEncode({for (final k in keys) k: row[k]});
}

String _hash(Map<String, Object?> row) {
  final keys = row.keys.toList()..sort();
  return sha256
      .convert(utf8.encode(jsonEncode({for (final k in keys) k: row[k]})))
      .toString();
}

DeletionRecord ratingDeletion(Rating r) => DeletionRecord(
  workKey: r.workKey,
  updatedAt: r.updatedAt,
  updatedBy: r.updatedBy,
  tieBreak: _hash(SyncFile.ratingToJson(r)),
);
DeletionRecord watchlistDeletion(WatchlistEntry w) => DeletionRecord(
  workKey: w.workKey,
  updatedAt: w.updatedAt,
  updatedBy: w.updatedBy,
  tieBreak: _hash(SyncFile.watchlistToJson(w)),
);
int compareDeletions(DeletionRecord a, DeletionRecord b) => _version(
  a.updatedAt,
  a.updatedBy,
  true,
  a.tieBreak,
  b.updatedAt,
  b.updatedBy,
  true,
  b.tieBreak,
);
int _version(
  int at,
  String by,
  bool deleted,
  String hash,
  int bt,
  String bb,
  bool bd,
  String bh,
) {
  final time = at.compareTo(bt);
  if (time != 0) return time;
  final device = by.compareTo(bb);
  if (device != 0) return device;
  final deletion = (deleted ? 1 : 0).compareTo(bd ? 1 : 0);
  return deletion != 0 ? deletion : hash.compareTo(bh);
}

int compareRatings(Rating a, Rating b) => _version(
  a.updatedAt,
  a.updatedBy,
  a.deletedAt != null,
  _hash(SyncFile.ratingToJson(a)),
  b.updatedAt,
  b.updatedBy,
  b.deletedAt != null,
  _hash(SyncFile.ratingToJson(b)),
);
int compareWatchlist(WatchlistEntry a, WatchlistEntry b) => _version(
  a.updatedAt,
  a.updatedBy,
  a.deletedAt != null,
  _hash(SyncFile.watchlistToJson(a)),
  b.updatedAt,
  b.updatedBy,
  b.deletedAt != null,
  _hash(SyncFile.watchlistToJson(b)),
);
int compareWorks(Work a, Work b) {
  final time = a.snapshotUpdatedAt.compareTo(b.snapshotUpdatedAt);
  return time != 0
      ? time
      : _canonical(
          SyncFile.workToJson(a),
        ).compareTo(_canonical(SyncFile.workToJson(b)));
}

int compareRatingDeletion(Rating r, DeletionRecord d) => _version(
  r.updatedAt,
  r.updatedBy,
  r.deletedAt != null,
  _hash(SyncFile.ratingToJson(r)),
  d.updatedAt,
  d.updatedBy,
  true,
  d.tieBreak,
);
int compareWatchlistDeletion(WatchlistEntry w, DeletionRecord d) => _version(
  w.updatedAt,
  w.updatedBy,
  w.deletedAt != null,
  _hash(SyncFile.watchlistToJson(w)),
  d.updatedAt,
  d.updatedBy,
  true,
  d.tieBreak,
);

List<T> _merge<T>(
  List<T> a,
  List<T> b,
  String Function(T) key,
  int Function(T, T) compare,
) {
  final rows = <String, T>{};
  for (final row in [...a, ...b]) {
    final k = key(row), current = rows[k];
    if (current == null || compare(row, current) > 0) rows[k] = row;
  }
  final keys = rows.keys.toList()..sort();
  return [for (final k in keys) rows[k] as T];
}

SyncState mergeStates(SyncState a, SyncState b) {
  final rd = _merge(
    a.ratingDeletions,
    b.ratingDeletions,
    (d) => d.workKey,
    compareDeletions,
  );
  final wd = _merge(
    a.watchlistDeletions,
    b.watchlistDeletions,
    (d) => d.workKey,
    compareDeletions,
  );
  final rm = {for (final d in rd) d.workKey: d};
  final wm = {for (final d in wd) d.workKey: d};
  return SyncState(
    works: _merge(a.works, b.works, (w) => w.workKey, compareWorks),
    ratings: [
      for (final r in _merge(
        a.ratings,
        b.ratings,
        (r) => r.workKey,
        compareRatings,
      ))
        if (!rm.containsKey(r.workKey) ||
            compareRatingDeletion(r, rm[r.workKey]!) > 0)
          r,
    ],
    watchlist: [
      for (final w in _merge(
        a.watchlist,
        b.watchlist,
        (w) => w.workKey,
        compareWatchlist,
      ))
        if (!wm.containsKey(w.workKey) ||
            compareWatchlistDeletion(w, wm[w.workKey]!) > 0)
          w,
    ],
    ratingDeletions: rd,
    watchlistDeletions: wd,
    purgedBefore: max(a.purgedBefore, b.purgedBefore),
  );
}

bool remoteBehind(SyncState local, SyncState remote) {
  final merged = mergeStates(local, remote);
  bool same<T>(
    List<T> a,
    List<T> b,
    String Function(T) key,
    int Function(T, T) compare,
  ) {
    if (a.length != b.length) return false;
    final map = {for (final x in b) key(x): x};
    return a.every(
      (x) => map[key(x)] != null && compare(x, map[key(x)] as T) == 0,
    );
  }

  return merged.purgedBefore != remote.purgedBefore ||
      !same(merged.works, remote.works, (w) => w.workKey, compareWorks) ||
      !same(merged.ratings, remote.ratings, (r) => r.workKey, compareRatings) ||
      !same(
        merged.watchlist,
        remote.watchlist,
        (w) => w.workKey,
        compareWatchlist,
      ) ||
      !same(
        merged.ratingDeletions,
        remote.ratingDeletions,
        (d) => d.workKey,
        compareDeletions,
      ) ||
      !same(
        merged.watchlistDeletions,
        remote.watchlistDeletions,
        (d) => d.workKey,
        compareDeletions,
      );
}

({Set<String> ratings, Set<String> watchlist}) droppedBy(
  SyncState local,
  SyncState remote, {
  bool liveOnly = false,
}) {
  final normalized = mergeStates(const SyncState(), remote);
  final rd = {for (final d in normalized.ratingDeletions) d.workKey: d};
  final wd = {for (final d in normalized.watchlistDeletions) d.workKey: d};
  final liveRatings = {
    for (final r in normalized.ratings)
      if (r.deletedAt == null) r.workKey,
  };
  final liveWatchlist = {
    for (final w in normalized.watchlist)
      if (w.deletedAt == null) w.workKey,
  };
  return (
    ratings: {
      for (final r in local.ratings)
        if ((!liveOnly || r.deletedAt == null) &&
            !liveRatings.contains(r.workKey) &&
            rd.containsKey(r.workKey) &&
            compareRatingDeletion(r, rd[r.workKey]!) <= 0)
          r.workKey,
    },
    watchlist: {
      for (final w in local.watchlist)
        if ((!liveOnly || w.deletedAt == null) &&
            !liveWatchlist.contains(w.workKey) &&
            wd.containsKey(w.workKey) &&
            compareWatchlistDeletion(w, wd[w.workKey]!) <= 0)
          w.workKey,
    },
  );
}

({Set<String> ratings, Set<String> watchlist}) unsyncedDrops(
  SyncState local,
  SyncState remote, {
  required int? lastSyncAt,
}) {
  final dropped = droppedBy(local, remote, liveOnly: true);
  return (
    ratings: {
      for (final r in local.ratings)
        if (dropped.ratings.contains(r.workKey) &&
            (lastSyncAt == null || r.updatedAt >= lastSyncAt))
          r.workKey,
    },
    watchlist: {
      for (final w in local.watchlist)
        if (dropped.watchlist.contains(w.workKey) &&
            (lastSyncAt == null || w.updatedAt >= lastSyncAt))
          w.workKey,
    },
  );
}

String staleFingerprint(
  SyncState local,
  SyncState remote, {
  required int? lastSyncAt,
}) {
  remote = mergeStates(const SyncState(), remote);
  final d = unsyncedDrops(local, remote, lastSyncAt: lastSyncAt);
  final rows = <String>[];
  final remoteRatings = {
    for (final r in remote.ratings) r.workKey: SyncFile.ratingToJson(r),
  };
  final remoteWatchlist = {
    for (final w in remote.watchlist) w.workKey: SyncFile.watchlistToJson(w),
  };
  for (final r in local.ratings) {
    if (d.ratings.contains(r.workKey)) {
      rows.add(
        'r:${jsonEncode(SyncFile.ratingToJson(r))}:${jsonEncode(remote.ratingDeletions.firstWhere((x) => x.workKey == r.workKey).toJson())}:${jsonEncode(remoteRatings[r.workKey])}',
      );
    }
  }
  for (final w in local.watchlist) {
    if (d.watchlist.contains(w.workKey)) {
      rows.add(
        'w:${jsonEncode(SyncFile.watchlistToJson(w))}:${jsonEncode(remote.watchlistDeletions.firstWhere((x) => x.workKey == w.workKey).toJson())}:${jsonEncode(remoteWatchlist[w.workKey])}',
      );
    }
  }
  rows.sort();
  return sha256.convert(utf8.encode(jsonEncode(rows))).toString();
}
