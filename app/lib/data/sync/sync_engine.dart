import 'dart:math';

import 'package:intl/intl.dart';

import 'merge.dart';
import 'sync_file.dart';
import 'sync_store.dart';

/// A file in the app's hidden Drive folder.
final class RemoteFile {
  const RemoteFile({
    required this.id,
    required this.name,
    required this.modifiedTime,
    required this.createdTime,
  });

  final String id;
  final String name;

  /// Compared for equality only: changed means someone else wrote the file.
  final String modifiedTime;
  final String createdTime;
}

/// Where the shared state lives: Google Drive's `appDataFolder` in the app,
/// memory in tests. Errors are [SyncException].
abstract interface class SyncRemote {
  Future<List<RemoteFile>> list();
  Future<RemoteFile> metadata(String id);
  Future<List<int>> download(String id);
  Future<RemoteFile> create(String name, List<int> bytes);
  Future<RemoteFile> update(String id, List<int> bytes);
  Future<void> delete(String id);
}

/// How a sync attempt ended (docs/sync.md, "Errors").
enum SyncFailure {
  /// Quietly put off until the next occasion.
  offline,

  /// "Sign in again" in settings.
  unauthorized,

  /// Drive is full; local work doesn't suffer.
  quotaExceeded,

  /// The file in Drive can't be read; it is never overwritten.
  broken,

  /// Written by a newer app: sync is off until this one is updated.
  tooNew,

  /// Drive answered something unexpected, or the file kept changing.
  failed,
}

final class SyncException implements Exception {
  const SyncException(this.failure, [this.detail]);

  final SyncFailure failure;
  final String? detail;

  @override
  String toString() =>
      'SyncException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// The user's answer about this device's unsynced changes that Drive's
/// compact deletion would beat (docs/sync.md, "Tombstones").
enum StaleChoice {
  /// They become new versions and go to Drive.
  keep,

  /// They are dropped, as Drive's state says.
  discard,
}

/// What a pass did.
final class SyncReport {
  const SyncReport({
    required this.applied,
    required this.uploaded,
    required this.modifiedTime,
    this.syncedAt,
    this.pendingChanges = false,
    this.stale = 0,
    this.staleFingerprint,
  });

  /// The pass stopped before changing anything: [stale] live rows of this
  /// device's, changed since its last sync, would be dropped, and the user
  /// decides first. Sync again with a [StaleChoice].
  const SyncReport.paused(this.stale, this.staleFingerprint)
    : applied = 0,
      uploaded = false,
      modifiedTime = null,
      syncedAt = null,
      pendingChanges = false;

  /// Rows that came from Drive and won, or were beaten by a deletion.
  final int applied;
  final bool uploaded;
  final String? modifiedTime;

  /// UTC ms the pass started, written to `last_sync_at`; `null` — paused.
  final int? syncedAt;
  final bool pendingChanges;
  final int stale;
  final String? staleFingerprint;

  bool get paused => stale > 0;
}

/// One pass of the algorithm in docs/sync.md ("One pass of the algorithm"),
/// plus the daily copies ("Backup").
final class SyncEngine {
  SyncEngine(
    this._store,
    this._remote, {
    required this.deviceId,
    required this.appVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SyncStore _store;
  final SyncRemote _remote;
  final String deviceId;
  final String appVersion;
  final DateTime Function() _clock;

  static const attempts = 3;
  static const backupsKept = 7;
  static const backupPrefix = 'framebook-backup-';

  /// `framebook-backup-2026-10-25.json.gz`, by the device's local date.
  static String backupName(DateTime day) =>
      '$backupPrefix${DateFormat('yyyy-MM-dd').format(day)}.json.gz';

  static bool isBackup(RemoteFile file) =>
      file.name.startsWith(backupPrefix) && file.name.endsWith('.json.gz');

  int get _now => _clock().toUtc().millisecondsSinceEpoch;

  /// The state in Drive, or `null` when there is no file yet — for the first
  /// sign-in dialog. Duplicates are merged here too, without writing.
  Future<SyncState?> peek() async {
    final mains = _mains(await _remote.list());
    if (mains.isEmpty) return null;
    var state = const SyncState();
    for (final file in mains) {
      state = mergeStates(state, _decode(await _download(file.id)));
    }
    return state;
  }

  /// Merges Drive and the device both ways. When the merge would drop live
  /// rows this device changed since its last sync, nothing is changed and
  /// the report is [SyncReport.paused] until the pass is run again with
  /// [stale] (docs/sync.md, "Tombstones"). Throws [SyncException].
  Future<SyncReport> sync({
    StaleChoice? stale,
    String? reviewedFingerprint,
  }) async {
    final started = _now;
    final lastSync = int.tryParse(
      await _store.stateValue(SyncStore.lastSyncKey) ?? '',
    );
    var applied = 0;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      final files = await _remote.list();
      final mains = _mains(files);
      if (mains.isEmpty) {
        var local = await _store.read();
        if (local.isEmpty) {
          return _done(
            started,
            applied: 0,
            uploaded: false,
            modified: null,
            acknowledged: local,
          );
        }
        await _store.purge(_watermark(local));
        local = await _store.read();
        final created = await _remote.create(SyncFile.name, _encode(local));
        return _done(
          started,
          applied: 0,
          uploaded: true,
          modified: created.modifiedTime,
          acknowledged: local,
        );
      }

      // Two devices that created the first file at the same time: merge them
      // all into the oldest and delete the rest once that is uploaded.
      final main = mains.first;
      final extras = mains.skip(1).toList();
      final bytes = await _download(main.id);
      var remote = _decode(bytes);
      for (final extra in extras) {
        remote = mergeStates(remote, _decode(await _download(extra.id)));
      }

      try {
        applied += await _store.apply(
          remote,
          guard: true,
          lastSyncAt: lastSync,
          reviewedFingerprint: reviewedFingerprint,
          keep: stale == null ? null : stale == StaleChoice.keep,
          deviceId: deviceId,
          now: _now,
        );
      } on StaleReviewRequired catch (review) {
        return SyncReport.paused(review.count, review.fingerprint);
      }

      var local = await _store.read();
      final watermark = _watermark(local);
      final purgeable =
          local.ratings.any(
            (r) => r.deletedAt != null && r.updatedAt < watermark,
          ) ||
          local.watchlist.any(
            (w) => w.deletedAt != null && w.updatedAt < watermark,
          );
      if (!remoteBehind(local, remote) && extras.isEmpty && !purgeable) {
        return _done(
          started,
          applied: applied,
          uploaded: false,
          modified: main.modifiedTime,
          acknowledged: local,
        );
      }

      // Every write to Drive moves the watermark up and purges below it.
      await _store.purge(watermark);
      local = await _store.read();
      await _dailyCopy(files, bytes);
      // No conditional write in Drive v3: re-read the metadata, and start
      // over if someone wrote the file since we downloaded it.
      var changed = false;
      for (final file in mains) {
        if ((await _remote.metadata(file.id)).modifiedTime !=
            file.modifiedTime) {
          changed = true;
          break;
        }
      }
      if (changed) continue;
      final written = await _remote.update(main.id, _encode(local));
      for (final extra in extras) {
        if ((await _remote.metadata(extra.id)).modifiedTime !=
            extra.modifiedTime) {
          changed = true;
          break;
        }
        await _remote.delete(extra.id);
      }
      if (changed) continue;
      return _done(
        started,
        applied: applied,
        uploaded: true,
        modified: written.modifiedTime,
        acknowledged: local,
      );
    }
    throw const SyncException(
      SyncFailure.failed,
      'the file kept changing during sync',
    );
  }

  /// The daily copies, newest first.
  Future<List<RemoteFile>> backups() async =>
      (await _remote.list()).where(isBackup).toList()
        ..sort((a, b) => b.name.compareTo(a.name));

  Future<SyncState> readBackup(RemoteFile backup) async =>
      _decode(await _download(backup.id));

  /// Step 6 of the pass: what `last_sync_at` says from now on is that every
  /// row changed before [started] is in Drive.
  Future<SyncReport> _done(
    int started, {
    required int applied,
    required bool uploaded,
    required String? modified,
    required SyncState acknowledged,
  }) async {
    await _store.setStateValue(SyncStore.lastSyncKey, '$started');
    await _store.setStateValue(SyncStore.modifiedKey, modified);
    return SyncReport(
      applied: applied,
      uploaded: uploaded,
      modifiedTime: modified,
      syncedAt: started,
      pendingChanges: remoteBehind(await _store.read(), acknowledged),
    );
  }

  /// P = max(the file's, this device's, now − N) — the file's is already in
  /// [local] once it is applied.
  int _watermark(SyncState local) =>
      max(local.purgedBefore, purgeWatermark(_now));

  /// "Delete data from Google Drive": the file and every copy.
  Future<void> deleteAll() async {
    for (final file in await _remote.list()) {
      await _remote.delete(file.id);
    }
  }

  /// The first sync of the day copies the file as it is before overwriting
  /// it, and keeps the last [backupsKept] copies.
  Future<void> _dailyCopy(List<RemoteFile> files, List<int> current) async {
    final today = backupName(_clock());
    final copies = files.where(isBackup).toList();
    if (copies.any((f) => f.name == today)) return;
    await _remote.create(today, current);
    copies.sort((a, b) => b.name.compareTo(a.name));
    for (final old in copies.skip(backupsKept - 1)) {
      await _remote.delete(old.id);
    }
  }

  List<int> _encode(SyncState state) => SyncFile.encode(
    state,
    writtenAt: _clock().toUtc().millisecondsSinceEpoch,
    writtenBy: deviceId,
    appVersion: appVersion,
  );

  /// A file that can't be read is an error, never something to overwrite.
  /// Its watermark is clamped to this device's clock.
  SyncState _decode(List<int> bytes) {
    try {
      final state = SyncFile.decode(bytes);
      return state.withPurgedBefore(clampWatermark(state.purgedBefore, _now));
    } on SyncFileTooNew catch (e) {
      throw SyncException(SyncFailure.tooNew, 'format ${e.version}');
    } on SyncFileBroken catch (e) {
      throw SyncException(SyncFailure.broken, e.reason);
    }
  }

  Future<List<int>> _download(String id) => _remote.download(id);

  /// State files, oldest first.
  static List<RemoteFile> _mains(List<RemoteFile> files) =>
      files.where((f) => f.name == SyncFile.name).toList()..sort(
        (a, b) => a.createdTime != b.createdTime
            ? a.createdTime.compareTo(b.createdTime)
            : a.id.compareTo(b.id),
      );
}
