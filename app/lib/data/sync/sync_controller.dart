import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../db/database.dart';
import '../db/database_provider.dart';
import '../library/library.dart';
import 'google_account.dart';
import 'merge.dart';
import 'sync_engine.dart';
import 'sync_file.dart';
import 'sync_store.dart';

/// What the Sync and backup screen shows.
final class SyncStatus {
  const SyncStatus({
    required this.configured,
    this.account,
    this.busy = false,
    this.lastSyncAt,
    this.error,
  });

  /// Whether this build can sign in to Google at all.
  final bool configured;

  /// The signed-in email; `null` — sync is off.
  final String? account;
  final bool busy;

  /// UTC ms of the last successful sync.
  final int? lastSyncAt;

  /// How the last attempt failed; `null` after a success. Offline is not
  /// kept: it is quietly put off (docs/sync.md, "Errors").
  final SyncFailure? error;

  SyncStatus copyWith({
    String? Function()? account,
    bool? busy,
    int? Function()? lastSyncAt,
    SyncFailure? Function()? error,
  }) => SyncStatus(
    configured: configured,
    account: account == null ? this.account : account(),
    busy: busy ?? this.busy,
    lastSyncAt: lastSyncAt == null ? this.lastSyncAt : lastSyncAt(),
    error: error == null ? this.error : error(),
  );
}

/// The counters of the first sign-in dialog (docs/sync.md, "First sign-in").
typedef FirstSync = ({int device, int drive, int merged});

/// The app version written into the file; read from the platform in `main()`.
final appVersionProvider = Provider<String>((ref) => 'unknown');

/// The result of reading an import file, for its dialog.
typedef ImportPreview = ({SyncState file, int device, int inFile, int merged});

/// Sync with Google Drive, the daily copies, export and import
/// (docs/sync.md). Syncs on launch and on returning to the app when the last
/// sync is more than [resumeAfter] old, [debounce] after a change, and on the
/// button.
class SyncController extends Notifier<SyncStatus> {
  static const resumeAfter = Duration(minutes: 5);
  static const debounce = Duration(seconds: 30);

  static const _accountKey = 'sync_account';
  static const _lastSyncKey = 'last_sync_at';
  static const _errorKey = 'last_sync_error';
  static const _modifiedKey = 'last_remote_modified_time';

  late GoogleAccount _google;
  late SyncStore _store;
  Timer? _debounce;
  Future<void>? _running;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  SyncStatus build() {
    _google = ref.watch(googleAccountProvider);
    _store = SyncStore(ref.watch(databaseProvider));
    final prefs = ref.watch(sharedPreferencesProvider);
    final account = _google.configured ? prefs.getString(_accountKey) : null;

    final changes = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([_db.ratings, _db.watchlist]),
        )
        .listen((_) => _changed());
    final lifecycle = AppLifecycleListener(onResume: () => _maybeSync());
    ref.onDispose(() {
      changes.cancel();
      lifecycle.dispose();
      _debounce?.cancel();
    });

    unawaited(_load(account));
    return SyncStatus(configured: _google.configured, account: account);
  }

  /// Reads the last sync from `sync_state`, then — if signed in — restores
  /// the session silently and syncs if it is due.
  Future<void> _load(String? account) async {
    final last = int.tryParse(await _store.stateValue(_lastSyncKey) ?? '');
    final error = await _store.stateValue(_errorKey);
    if (!ref.mounted) return;
    state = state.copyWith(
      lastSyncAt: () => last,
      error: () => SyncFailure.values.where((f) => f.name == error).firstOrNull,
    );
    if (account == null) return;
    await _google.restore();
    await _maybeSync();
  }

  Future<void> _maybeSync() async {
    if (state.account == null) return;
    final last = state.lastSyncAt;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (last != null && now - last < resumeAfter.inMilliseconds) return;
    await sync();
  }

  void _changed() {
    // Our own writes while applying Drive's rows aren't a reason to sync.
    if (state.account == null || state.busy) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, () => unawaited(sync()));
  }

  /// Signs in. When Drive already has data and so does the device, returns
  /// the counters for the merge dialog, and nothing is synced until
  /// [confirmFirstSync]; otherwise syncs at once and returns `null`. Throws
  /// [SignInException] and [SyncException].
  Future<FirstSync?> signIn() async {
    final email = await _google.signIn();
    final drive = await _withDrive((engine) => engine.peek());
    final device = await _store.read();
    await ref.read(sharedPreferencesProvider).setString(_accountKey, email);
    state = state.copyWith(account: () => email, error: () => null);
    if (drive == null || device.liveRatings == 0) {
      await sync();
      return null;
    }
    return (
      device: device.liveRatings,
      drive: drive.liveRatings,
      merged: mergeStates(device, drive).liveRatings,
    );
  }

  Future<void> confirmFirstSync() => sync();

  /// One sync pass; a pass already under way is waited for instead. Errors
  /// end up in [SyncStatus.error], never thrown.
  Future<void> sync() => _running ??= _sync().whenComplete(() {
    _running = null;
  });

  Future<void> _sync() async {
    if (state.account == null) return;
    _debounce?.cancel();
    state = state.copyWith(busy: true);
    try {
      final report = await _withDrive((engine) => engine.sync());
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _store.setStateValue(_lastSyncKey, '$now');
      await _store.setStateValue(_modifiedKey, report.modifiedTime);
      await _store.setStateValue(_errorKey, null);
      if (ref.mounted) {
        state = state.copyWith(lastSyncAt: () => now, error: () => null);
      }
    } on SyncException catch (e) {
      await _fail(e.failure);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<void> _fail(SyncFailure failure) async {
    // No connection is not an error worth showing: the next occasion retries.
    if (failure == SyncFailure.offline) return;
    await _store.setStateValue(_errorKey, failure.name);
    if (ref.mounted) state = state.copyWith(error: () => failure);
  }

  /// Runs [action] with Drive access; once Drive says the token expired,
  /// drops it and tries again with a fresh one.
  Future<T> _withDrive<T>(Future<T> Function(SyncEngine engine) action) async {
    var access = await _google.drive();
    try {
      return await action(_engine(access.remote));
    } on SyncException catch (e) {
      if (e.failure != SyncFailure.unauthorized) rethrow;
      await access.expire();
      access = await _google.drive();
      return action(_engine(access.remote));
    }
  }

  SyncEngine _engine(SyncRemote remote) => SyncEngine(
    _store,
    remote,
    deviceId: ref.read(deviceIdProvider),
    appVersion: ref.read(appVersionProvider),
  );

  /// Signing out keeps the data, both here and in Drive.
  Future<void> signOut() async {
    _debounce?.cancel();
    await _google.signOut();
    await ref.read(sharedPreferencesProvider).remove(_accountKey);
    await _store.setStateValue(_errorKey, null);
    state = state.copyWith(account: () => null, error: () => null);
  }

  /// Deletes the file and the daily copies from Drive and signs out here.
  /// Throws [SyncException].
  Future<void> deleteDriveData() async {
    await _withDrive((engine) => engine.deleteAll());
    await _store.setStateValue(_lastSyncKey, null);
    await _store.setStateValue(_modifiedKey, null);
    state = state.copyWith(lastSyncAt: () => null);
    await signOut();
  }

  /// The daily copies, newest first. Throws [SyncException].
  Future<List<RemoteFile>> backups() =>
      _withDrive((engine) => engine.backups());

  /// Restoring a daily copy is an import that replaces everything. Throws
  /// [SyncException].
  Future<void> restore(RemoteFile backup) async {
    final copy = await _withDrive((engine) => engine.readBackup(backup));
    await _replace(copy);
  }

  /// The export file: the same format as the file in Drive.
  Future<List<int>> export() async => SyncFile.encode(
    await _store.read(),
    writtenAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    writtenBy: ref.read(deviceIdProvider),
    appVersion: ref.read(appVersionProvider),
  );

  /// Reads an import file. Throws [SyncFileException].
  Future<ImportPreview> previewImport(List<int> bytes) async {
    final file = SyncFile.decode(bytes);
    final device = await _store.read();
    return (
      file: file,
      device: device.liveRatings,
      inFile: file.liveRatings,
      merged: mergeStates(device, file).liveRatings,
    );
  }

  /// Merges the file in by the usual rules, or replaces everything with it.
  Future<void> import(SyncState file, {required bool replace}) async {
    if (replace) {
      await _replace(file);
    } else {
      await _store.apply(file);
      if (state.account != null) unawaited(sync());
    }
  }

  Future<void> _replace(SyncState file) async {
    await _store.replaceWith(
      file,
      deviceId: ref.read(deviceIdProvider),
      now: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    if (state.account != null) unawaited(sync());
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
