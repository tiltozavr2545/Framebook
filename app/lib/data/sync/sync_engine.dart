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

/// What a successful pass did.
final class SyncReport {
  const SyncReport({
    required this.applied,
    required this.uploaded,
    required this.modifiedTime,
  });

  /// Rows that came from Drive and won.
  final int applied;
  final bool uploaded;
  final String? modifiedTime;
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

  /// Merges Drive and the device both ways. Throws [SyncException].
  Future<SyncReport> sync() async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      final files = await _remote.list();
      final mains = _mains(files);
      if (mains.isEmpty) {
        final local = await _store.read();
        if (local.isEmpty) {
          return const SyncReport(
            applied: 0,
            uploaded: false,
            modifiedTime: null,
          );
        }
        final created = await _remote.create(SyncFile.name, _encode(local));
        return SyncReport(
          applied: 0,
          uploaded: true,
          modifiedTime: created.modifiedTime,
        );
      }

      // Two devices that created the first file at the same time: merge them
      // all into the oldest and delete the rest once that is uploaded.
      final main = mains.first;
      final extras = mains.skip(1).toList();
      final bytes = await _download(main.id);
      var applied = await _store.apply(_decode(bytes));
      for (final extra in extras) {
        applied += await _store.apply(_decode(await _download(extra.id)));
      }

      final remote = _decode(bytes);
      final local = await _store.read();
      if (!remoteBehind(local, remote) && extras.isEmpty) {
        return SyncReport(
          applied: applied,
          uploaded: false,
          modifiedTime: main.modifiedTime,
        );
      }

      await _dailyCopy(files, bytes);
      // No conditional write in Drive v3: re-read the metadata, and start
      // over if someone wrote the file since we downloaded it.
      final fresh = await _remote.metadata(main.id);
      if (fresh.modifiedTime != main.modifiedTime) continue;
      final written = await _remote.update(main.id, _encode(local));
      for (final extra in extras) {
        await _remote.delete(extra.id);
      }
      return SyncReport(
        applied: applied,
        uploaded: true,
        modifiedTime: written.modifiedTime,
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
  static SyncState _decode(List<int> bytes) {
    try {
      return SyncFile.decode(bytes);
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
