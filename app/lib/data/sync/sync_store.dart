import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../work_key.dart';
import 'merge.dart';
import 'sync_file.dart';

final class StaleReviewRequired implements Exception {
  const StaleReviewRequired(this.count, this.fingerprint);
  final int count;
  final String fingerprint;
}

/// The database side of sync, export and import: reading the shared state
/// and applying someone else's (docs/sync.md).
final class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  /// `sync_state` keys (docs/data-model.md).
  static const lastSyncKey = 'last_sync_at';
  static const modifiedKey = 'last_remote_modified_time';
  static const purgedBeforeKey = 'purged_before';
  static const ratingDeletionsKey = 'rating_deletions';
  static const watchlistDeletionsKey = 'watchlist_deletions';
  static const watchlistFencesKey = 'watchlist_fences';

  /// Everything that goes into the file: every rating and watchlist row,
  /// tombstones included, the snapshots they refer to with their ancestors,
  /// and this device's purge watermark.
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
      purgedBefore: await _purgedBefore(),
      ratingDeletions: await _deletions(ratingDeletionsKey),
      watchlistDeletions: await _deletions(watchlistDeletionsKey),
      watchlistFences: mergeStates(
        SyncState(watchlistFences: await fences()),
        SyncState(
          watchlistFences: [
            for (final row in watchlist)
              if (row.deletedAt == null)
                if (WorkKey.tryParse(row.workKey) case final key?
                    when key.kind == WorkKind.tv || key.kind == WorkKind.season)
                  WatchlistFence(
                    seriesKey: (key.kind == WorkKind.tv ? key : key.parent!)
                        .toString(),
                    season: key.kind == WorkKind.season,
                    updatedAt: row.updatedAt,
                    updatedBy: row.updatedBy,
                  ),
          ],
        ),
      ).watchlistFences,
    );
  });

  /// Applies the per-key register merge in a transaction. When [guard] is
  /// set, the reviewed fingerprint is checked in that same transaction.
  Future<int> apply(
    SyncState remote, {
    int? lastSyncAt,
    String? reviewedFingerprint,
    bool? keep,
    String? deviceId,
    int? now,
    bool guard = false,
  }) => _db.transaction(() async {
    var local = await read();
    if (guard) {
      final drops = unsyncedDrops(local, remote, lastSyncAt: lastSyncAt);
      final count = drops.ratings.length + drops.watchlist.length;
      if (count > 0) {
        final fingerprint = staleFingerprint(
          local,
          remote,
          lastSyncAt: lastSyncAt,
        );
        if (keep == null || reviewedFingerprint != fingerprint) {
          throw StaleReviewRequired(count, fingerprint);
        }
        if (keep) {
          await restamp(
            ratings: drops.ratings,
            watchlist: drops.watchlist,
            deviceId: deviceId!,
            now: now!,
            remote: remote,
          );
          local = await read();
        }
      }
    }
    final merged = mergeStates(local, remote);
    var changed = 0;
    for (final work in _parentsFirst(merged.works)) {
      final old = await _work(work.workKey);
      if (old == null || compareWorks(work, old) > 0) {
        await _db.into(_db.works).insertOnConflictUpdate(_full(work));
        changed++;
      }
    }
    final ratings = {for (final r in merged.ratings) r.workKey: r};
    for (final old in local.ratings) {
      if (!ratings.containsKey(old.workKey)) {
        changed += await (_db.delete(
          _db.ratings,
        )..where((r) => r.workKey.equals(old.workKey))).go();
      }
    }
    for (final row in merged.ratings) {
      final old = await _rating(row.workKey);
      if (old == null || compareRatings(row, old) > 0) {
        await _db.into(_db.ratings).insertOnConflictUpdate(_full(row));
        changed++;
      }
    }
    final listed = {for (final w in merged.watchlist) w.workKey: w};
    for (final old in local.watchlist) {
      if (!listed.containsKey(old.workKey)) {
        changed += await (_db.delete(
          _db.watchlist,
        )..where((w) => w.workKey.equals(old.workKey))).go();
      }
    }
    for (final row in merged.watchlist) {
      final old = await _listed(row.workKey);
      if (old == null || compareWatchlist(row, old) > 0) {
        await _db.into(_db.watchlist).insertOnConflictUpdate(_full(row));
        changed++;
      }
    }
    await _saveDeletions(merged);
    await saveFences(merged.watchlistFences);
    await _setPurgedBefore(merged.purgedBefore);
    await _pruneWorks();
    return changed;
  });

  /// Keeps this device's rows that a merge would drop (the user's "Keep"):
  /// each becomes a new version by [deviceId], newer than the matching deletion, so
  /// it survives the merge and goes to Drive with the next upload.
  Future<void> restamp({
    required Set<String> ratings,
    required Set<String> watchlist,
    required String deviceId,
    required int now,
    SyncState? remote,
  }) => _db.transaction(() async {
    final normalized = mergeStates(
      const SyncState(),
      remote ?? const SyncState(),
    );
    final localState = await read();
    final rd = {for (final d in normalized.ratingDeletions) d.workKey: d};
    final localRd = {for (final d in localState.ratingDeletions) d.workKey: d};
    final remoteRatings = {for (final r in normalized.ratings) r.workKey: r};
    final wd = {for (final d in normalized.watchlistDeletions) d.workKey: d};
    final localWd = {
      for (final d in localState.watchlistDeletions) d.workKey: d,
    };
    final remoteWatchlist = {
      for (final w in normalized.watchlist) w.workKey: w,
    };
    for (final key in ratings) {
      final local = await _rating(key);
      if (local == null) continue;
      await (_db.update(
        _db.ratings,
      )..where((r) => r.workKey.equals(key))).write(
        RatingsCompanion(
          updatedAt: Value(
            _next(
              now,
              [
                local.updatedAt,
                rd[key]?.updatedAt ?? 0,
                localRd[key]?.updatedAt ?? 0,
                remoteRatings[key]?.updatedAt ?? 0,
              ].reduce(max),
            ),
          ),
          updatedBy: Value(deviceId),
        ),
      );
    }
    for (final key in watchlist) {
      final local = await _listed(key);
      if (local == null) continue;
      await (_db.update(
        _db.watchlist,
      )..where((w) => w.workKey.equals(key))).write(
        WatchlistCompanion(
          updatedAt: Value(
            _next(
              now,
              [
                local.updatedAt,
                wd[key]?.updatedAt ?? 0,
                localWd[key]?.updatedAt ?? 0,
                remoteWatchlist[key]?.updatedAt ?? 0,
              ].reduce(max),
            ),
          ),
          updatedBy: Value(deviceId),
        ),
      );
    }
  });

  /// The cleanup before a write to Drive (docs/sync.md, "Tombstones"):
  /// raises this device's watermark to [before] and compacts the tombstones
  /// older than it, then removes snapshots nothing refers to. Returns
  /// how many tombstones went.
  Future<int> purge(int before) => _db.transaction(() async {
    final state = await read();
    final p = max(state.purgedBefore, before);
    final ratings = state.ratings
        .where((r) => r.deletedAt != null && r.updatedAt < p)
        .toList();
    final listed = state.watchlist
        .where((w) => w.deletedAt != null && w.updatedAt < p)
        .toList();
    final compact = mergeStates(
      state,
      SyncState(
        purgedBefore: p,
        ratingDeletions: [for (final r in ratings) ratingDeletion(r)],
        watchlistDeletions: [for (final w in listed) watchlistDeletion(w)],
      ),
    );
    await _saveDeletions(compact);
    await _setPurgedBefore(p);
    for (final chunk in _chunks([for (final r in ratings) r.workKey])) {
      await (_db.delete(_db.ratings)..where((r) => r.workKey.isIn(chunk))).go();
    }
    for (final chunk in _chunks([for (final w in listed) w.workKey])) {
      await (_db.delete(
        _db.watchlist,
      )..where((w) => w.workKey.isIn(chunk))).go();
    }
    await _pruneWorks();
    return ratings.length + listed.length;
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
    // Replacement is an explicit edit of retained data, but an old export
    // must not turn a row already forgotten here into a new live version.
    final localState = await read();
    final registers = mergeStates(localState, file);
    final absent = droppedBy(file, registers);
    await apply(
      SyncState(
        ratingDeletions: registers.ratingDeletions,
        watchlistDeletions: registers.watchlistDeletions,
        watchlistFences: registers.watchlistFences,
      ),
    );
    file = SyncState(
      works: file.works,
      ratings: [
        for (final row in file.ratings)
          if (!absent.ratings.contains(row.workKey)) row,
      ],
      watchlist: [
        for (final row in file.watchlist)
          if (!absent.watchlist.contains(row.workKey) &&
              (row.deletedAt != null ||
                  visibleWatchlistEntry(row, file.watchlistFences)))
            row,
      ],
      purgedBefore: file.purgedBefore,
      ratingDeletions: file.ratingDeletions,
      watchlistDeletions: file.watchlistDeletions,
      watchlistFences: file.watchlistFences,
    );
    await _saveDeletions(mergeStates(localState, file));
    var changed = 0;
    if (file.purgedBefore > await _purgedBefore()) {
      await _setPurgedBefore(file.purgedBefore);
    }
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
      final key = WorkKey.parse(wanted.workKey);
      final series = key.kind == WorkKind.tv
          ? key
          : key.kind == WorkKind.season
          ? key.parent
          : null;
      var previous = max(wanted.updatedAt, local?.updatedAt ?? 0);
      if (series != null) {
        for (final fence in registers.watchlistFences) {
          if (fence.seriesKey == series.toString()) {
            previous = max(previous, fence.updatedAt);
          }
        }
      }
      final compact = registers.watchlistDeletions
          .where((d) => d.workKey == wanted.workKey)
          .firstOrNull;
      previous = max(previous, compact?.updatedAt ?? 0);
      if (local != null &&
          local.addedAt == wanted.addedAt &&
          (local.deletedAt == null) == (wanted.deletedAt == null) &&
          (local.deletedAt != null ||
              visibleWatchlistEntry(local, registers.watchlistFences))) {
        continue;
      }
      await _db
          .into(_db.watchlist)
          .insertOnConflictUpdate(
            _full(
              wanted.copyWith(
                updatedAt: _next(now, previous),
                updatedBy: deviceId,
              ),
            ),
          );
      changed++;
    }
    await saveFences((await read()).watchlistFences);
    await _pruneWorks();
    return changed;
  });

  /// Deletes the snapshots outside the lineage of every rating and
  /// watchlist row left, tombstones included (docs/data-model.md, `works`).
  Future<void> _pruneWorks() async {
    final referenced = <String>{
      for (final key in [
        for (final r in await _db.select(_db.ratings).get()) r.workKey,
        for (final w in await _db.select(_db.watchlist).get()) w.workKey,
      ])
        for (final k in WorkKey.parse(key).lineage) k.toString(),
    };
    final orphans = [
      for (final w in await _db.select(_db.works).get())
        if (!referenced.contains(w.workKey)) w.workKey,
    ];
    for (final chunk in _chunks(orphans)) {
      await (_db.delete(_db.works)..where((w) => w.workKey.isIn(chunk))).go();
    }
  }

  /// The matching compact deletion's timestamp, or -1 when none exists.
  Future<int> deletionTime(String storageKey, String workKey) async {
    final entries = await _deletions(storageKey);
    for (final entry in entries) {
      if (entry.workKey == workKey) return entry.updatedAt;
    }
    return -1;
  }

  Future<List<WatchlistFence>> fences() async {
    final value = await stateValue(watchlistFencesKey);
    if (value == null) return [];
    return [
      for (final row in jsonDecode(value) as List<dynamic>)
        WatchlistFence.fromJson(row),
    ];
  }

  Future<void> saveFences(List<WatchlistFence> fences) => setStateValue(
    watchlistFencesKey,
    jsonEncode([for (final f in fences) f.toJson()]),
  );

  Future<List<DeletionRecord>> _deletions(String key) async {
    final value = await stateValue(key);
    if (value == null) return [];
    return [
      for (final row in jsonDecode(value) as List<dynamic>)
        DeletionRecord.fromJson(row),
    ];
  }

  Future<void> _saveDeletions(SyncState state) async {
    await setStateValue(
      ratingDeletionsKey,
      jsonEncode([for (final d in state.ratingDeletions) d.toJson()]),
    );
    await setStateValue(
      watchlistDeletionsKey,
      jsonEncode([for (final d in state.watchlistDeletions) d.toJson()]),
    );
  }

  Future<int> _purgedBefore() async =>
      int.tryParse(await stateValue(purgedBeforeKey) ?? '') ?? 0;

  Future<void> _setPurgedBefore(int value) =>
      setStateValue(purgedBeforeKey, '$value');

  /// Under SQLite's limit on bound variables.
  static Iterable<List<String>> _chunks(List<String> keys) sync* {
    for (var i = 0; i < keys.length; i += 500) {
      yield keys.sublist(i, i + 500 > keys.length ? keys.length : i + 500);
    }
  }

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
