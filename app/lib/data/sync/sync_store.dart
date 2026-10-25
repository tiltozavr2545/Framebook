import 'package:drift/drift.dart';

import '../db/database.dart';
import '../work_key.dart';
import 'merge.dart';
import 'sync_file.dart';

/// The database side of sync, export and import: reading the shared state
/// and applying someone else's (docs/sync.md).
final class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  /// Everything that goes into the file: every rating and watchlist row,
  /// tombstones included, and the snapshots they refer to with their
  /// ancestors.
  Future<SyncState> read() => _db.transaction(() async {
    final ratings = await _db.select(_db.ratings).get();
    final watchlist = await _db.select(_db.watchlist).get();
    final referenced = <String>{
      for (final key in [
        for (final r in ratings) r.workKey,
        for (final w in watchlist) w.workKey,
      ])
        for (final k in WorkKey.parse(key).lineage) k.toString(),
    };
    final works = await _db.select(_db.works).get();
    return SyncState(
      works: [
        for (final w in works)
          if (referenced.contains(w.workKey)) w,
      ]..sort((a, b) => a.workKey.compareTo(b.workKey)),
      ratings: ratings..sort((a, b) => a.workKey.compareTo(b.workKey)),
      watchlist: watchlist..sort((a, b) => a.workKey.compareTo(b.workKey)),
    );
  });

  /// Merges [remote] into the database in one transaction: a row is written
  /// only where its version wins over the one stored now — read inside the
  /// transaction, so an edit made meanwhile is never rolled back. Returns how
  /// many rows changed.
  Future<int> apply(SyncState remote) => _db.transaction(() async {
    var changed = 0;
    // Ancestors first: the foreign keys and the parent references want them.
    for (final work in _parentsFirst(remote.works)) {
      final local = await _work(work.workKey);
      if (local == null || compareWorks(work, local) > 0) {
        await _db.into(_db.works).insertOnConflictUpdate(_full(work));
        changed++;
      }
    }
    for (final rating in remote.ratings) {
      final local = await _rating(rating.workKey);
      if (local == null || compareRatings(rating, local) > 0) {
        await _db.into(_db.ratings).insertOnConflictUpdate(_full(rating));
        changed++;
      }
    }
    for (final entry in remote.watchlist) {
      final local = await _listed(entry.workKey);
      if (local == null || compareWatchlist(entry, local) > 0) {
        await _db.into(_db.watchlist).insertOnConflictUpdate(_full(entry));
        changed++;
      }
    }
    return changed;
  });

  /// "Replace everything" from an import or a daily copy (docs/sync.md,
  /// "Backup"): the database ends up holding what [file] holds. Every change
  /// is a new version by this device, so it spreads to the other devices
  /// instead of being rolled back by them: what isn't in the file gets a
  /// tombstone, what differs gets the file's content.
  Future<int> replaceWith(
    SyncState file, {
    required String deviceId,
    required int now,
  }) => _db.transaction(() async {
    var changed = 0;
    for (final work in _parentsFirst(file.works)) {
      final local = await _work(work.workKey);
      if (local == null || compareWorks(work, local) > 0) {
        await _db.into(_db.works).insertOnConflictUpdate(_full(work));
      }
    }

    final ratings = {for (final r in file.ratings) r.workKey: r};
    for (final local in await _db.select(_db.ratings).get()) {
      if (ratings.containsKey(local.workKey) || local.deletedAt != null) {
        continue;
      }
      await _db
          .into(_db.ratings)
          .insertOnConflictUpdate(
            _full(
              local.copyWith(
                deletedAt: Value(now),
                updatedAt: _next(now, local.updatedAt),
                updatedBy: deviceId,
              ),
            ),
          );
      changed++;
    }
    for (final wanted in file.ratings) {
      final local = await _rating(wanted.workKey);
      if (local != null && _sameRating(local, wanted)) continue;
      await _db
          .into(_db.ratings)
          .insertOnConflictUpdate(
            _full(
              wanted.copyWith(
                updatedAt: _next(
                  now,
                  local == null || local.updatedAt < wanted.updatedAt
                      ? wanted.updatedAt
                      : local.updatedAt,
                ),
                updatedBy: deviceId,
              ),
            ),
          );
      changed++;
    }

    final listed = {for (final w in file.watchlist) w.workKey: w};
    for (final local in await _db.select(_db.watchlist).get()) {
      if (listed.containsKey(local.workKey) || local.deletedAt != null) {
        continue;
      }
      await _db
          .into(_db.watchlist)
          .insertOnConflictUpdate(
            _full(
              local.copyWith(
                deletedAt: Value(now),
                updatedAt: _next(now, local.updatedAt),
                updatedBy: deviceId,
              ),
            ),
          );
      changed++;
    }
    for (final wanted in file.watchlist) {
      final local = await _listed(wanted.workKey);
      if (local != null &&
          local.addedAt == wanted.addedAt &&
          (local.deletedAt == null) == (wanted.deletedAt == null)) {
        continue;
      }
      await _db
          .into(_db.watchlist)
          .insertOnConflictUpdate(
            _full(
              wanted.copyWith(
                updatedAt: _next(
                  now,
                  local == null || local.updatedAt < wanted.updatedAt
                      ? wanted.updatedAt
                      : local.updatedAt,
                ),
                updatedBy: deviceId,
              ),
            ),
          );
      changed++;
    }
    return changed;
  });

  /// `sync_state` key-value rows (docs/data-model.md).
  Future<String?> stateValue(String key) async => (await (_db.select(
    _db.syncState,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setStateValue(String key, String? value) => value == null
      ? (_db.delete(_db.syncState)..where((s) => s.key.equals(key))).go()
      : _db
            .into(_db.syncState)
            .insertOnConflictUpdate(
              SyncStateCompanion.insert(key: key, value: value),
            );

  /// Every column, nulls included. A data class passed to drift as is
  /// leaves its null fields out of the update, so a remote tombstone revived
  /// elsewhere, or a removed note, would keep the stale local value.
  static Insertable<T> _full<T>(Insertable<T> row) => switch (row) {
    final Work w => w.toCompanion(false) as Insertable<T>,
    final Rating r => r.toCompanion(false) as Insertable<T>,
    final WatchlistEntry e => e.toCompanion(false) as Insertable<T>,
    _ => throw ArgumentError.value(row),
  };

  /// The same score, note, dates and liveness — the version fields aside.
  static bool _sameRating(Rating a, Rating b) =>
      a.scoreHalf == b.scoreHalf &&
      a.note == b.note &&
      a.createdAt == b.createdAt &&
      a.scoredAt == b.scoredAt &&
      (a.deletedAt == null) == (b.deletedAt == null);

  /// Monotonic within a row (docs/sync.md, "Device clocks").
  static int _next(int now, int previous) =>
      now > previous ? now : previous + 1;

  static List<Work> _parentsFirst(List<Work> works) =>
      [...works]..sort((a, b) => _depth(a).compareTo(_depth(b)));

  static int _depth(Work work) => switch (work.kind) {
    WorkKind.movie || WorkKind.tv => 0,
    WorkKind.season => 1,
    WorkKind.episode => 2,
  };

  Future<Work?> _work(String key) => (_db.select(
    _db.works,
  )..where((w) => w.workKey.equals(key))).getSingleOrNull();

  Future<Rating?> _rating(String key) => (_db.select(
    _db.ratings,
  )..where((r) => r.workKey.equals(key))).getSingleOrNull();

  Future<WatchlistEntry?> _listed(String key) => (_db.select(
    _db.watchlist,
  )..where((w) => w.workKey.equals(key))).getSingleOrNull();
}
